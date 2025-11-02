// Original code is haxe.format.JsonParser.hx

/* 
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package backend;

import hrk.Eseq;
import haxe.Timer;
import haxe.ds.Vector;

/**
	An implementation of JSON parser in Haxe.

	This class is used by `haxe.Json` when native JSON implementation
	is not available.

	@see https://haxe.org/manual/std-Json-parsing.html
**/
class SongJson {
	/**
		Parses given JSON-encoded `str` and returns the resulting object.

		JSON objects are parsed into anonymous structures and JSON arrays
		are parsed into `Array<Dynamic>`.

		If given `str` is not valid JSON, an exception will be thrown.

		If `str` is null, the result is unspecified.
	**/
	static public inline function parse(str:String):Dynamic {
		return new SongJson(str).doParse();
	}

	var str:String;
	var pos:Int;
	var time:Float = Timer.stamp();
	public static var skipChart:Bool = false;
	public static var log:Bool = true;

	function new(str:String) {
		this.str = str;
		this.pos = 0;
		this.bracketMode = 0;
	}

	var prepareSkipMode:Bool = false;
	var skipMode:Bool = false;
	var skipDone:Bool = false;

	function doParse():Dynamic {
		var result = parseRec();
		showProgress(true);
		while (!StringTools.isEof(c = nextChar())) {
			switch (c) {
				case ' '.code, '\r'.code, '\n'.code, '\t'.code:
				// allow trailing whitespace
				default:
					invalidChar();
			}
		}
		if (log) Sys.print("\n");
		return result;
	}
	
	var c:Int = 0;
	var field:String = null;
	var comma:Null<Bool> = null;
	var save:Int = 0;

	var bracketMode:Int = 0; // 0, 1 = inside notes, 2 = exit notes
	var b_p:Vector<Null<Int>> = new Vector<Null<Int>>(4, null); // it's for "[", "]", "{", "}".
	var b_s:Vector<Null<Int>> = new Vector<Null<Int>>(4, null); // it's for "[", "]", "{", "}".
	final skipPattern:String = "[]{}";

	var objLayer:Int = -1;
	var obj:Array<Dynamic> = [];

	var arrLayer:Int = -1;
	var arr = [];

	var returnObject:Array<Dynamic> = [];

	function parseRec():Dynamic {
		while (true) {
			if(obj[objLayer + 1] != null) obj[objLayer + 1] == null;
			if(arr[arrLayer + 1] != null) arr[arrLayer + 1] == null;
			c = nextChar();
			if (skipMode) {
				showProgress();

				for (i in 0...b_s.length) {
					b_p[i] = b_s[i] ?? str.indexOf(skipPattern.charAt(i), pos - 1);
					b_s[i] = str.indexOf(skipPattern.charAt(i), pos);
					if (b_s[i] == -1) b_s[i] = null;
				}

				if (b_s[2] < b_s[3]) {
					bracketMode = 0; // "{" < "}"
					if (b_s[1] < b_s[2]) bracketMode = 2; // "]" < "{"
				}
				else if (b_s[2] == null || b_s[3] < b_s[2]) {
					bracketMode = 1; // found '{' && "}" < "{"
					if (b_s[2] == null) {
						if (b_p[3] < b_s[1]) bracketMode = 2; // old "}" < new "]"
					} 
				}
				
				if (b_s[1] != null && (b_s[2] != null || b_s[3] != null)) {
					switch (bracketMode) {
						case 0, 1:
							pos = FlxMath.minInt(b_s[2] ?? b_s[3] ?? pos, b_s[3] ?? b_s[2] ?? pos);
						case 2:
							pos = b_s[1] ?? pos;
					} // lmao
				} // else pos = FlxMath.maxInt(FlxMath.maxInt(FlxMath.maxInt(b_s[0] ?? pos, b_s[1] ?? pos), b_s[2] ?? pos), b_s[3] ?? pos);
				c = nextChar(); --pos;
				// trace(b_s[0].hex(8), b_s[1].hex(8), b_s[2].hex(8), b_s[3].hex(8), pos.hex(8), bracketMode, String.fromCharCode(c));
				
				if (bracketMode == 2) {
					prepareSkipMode = skipMode = false; ++pos; comma = true;
					#if debug trace('skipMode deactivated at $pos, $field'); #end
					skipDone = true;
				}
				
				if (pos > str.length) {
					prepareSkipMode = skipMode = false;
				} // emergency stop

				skipDone ? return [] : continue;
			}

			switch (c) {
				case ' '.code, '\r'.code, '\n'.code, '\t'.code:
				// loop
				case '{'.code:
					obj[++objLayer] = {};
					field = null;
					comma = null;
					while (true) {
						showProgress();
						c = nextChar();
						switch (c) {
							case ' '.code, '\r'.code, '\n'.code, '\t'.code:
							// loop
							case '}'.code:
								if (field != null || comma == false)
									invalidChar();
								comma = null;
								return obj[objLayer--];
							case ':'.code:
								if (field == null)
									invalidChar();
								Reflect.setField(obj[objLayer], field, parseRec());
								field = null;
								comma = true;
							case ','.code:
								if (comma) comma = false else invalidChar();
							case '"'.code:
								if (field != null || comma) invalidChar();
								field = parseString();
								// #if debug if (!skipMode) trace('field: $field'); #end
								if (skipChart && field == "notes") prepareSkipMode = true;
							default:
								invalidChar();
						}
					}
				case '['.code:
					if (prepareSkipMode) {
						var chrode:Int = 0;
						
						do {
							chrode = nextChar();
							if (chrode == ']'.code) {
								if (comma == false) invalidChar();
								comma = null; prepareSkipMode = false;
								return [];
							}
						} while (chrode == ' '.code || chrode == '\r'.code || chrode == '\n'.code || chrode == '\t'.code);
						
						skipMode = true;
						#if debug trace('skipMode activated at $pos'); #end
						continue;
					}
					arr[++arrLayer] = [];
					comma = null;
					while (true) {
						showProgress();
						c = nextChar();
						switch (c) {
							case ' '.code, '\r'.code, '\n'.code, '\t'.code:
							// loop
							case ']'.code:
								if (comma == false) invalidChar();
								comma = null;
								return arr[arrLayer--];
							case ','.code:
								if (comma) comma = false else invalidChar();
							default:
								if (comma) invalidChar();
								pos--;
								arr[arrLayer].push(parseRec());
								comma = true;
						}
					}
				case 't'.code: // judge "true"
					save = pos;
					if (nextChar() != 'r'.code || nextChar() != 'u'.code || nextChar() != 'e'.code) {
						pos = save;
						invalidChar();
					}
					return true;
				case 'f'.code: // judge "false"
					save = pos;
					if (nextChar() != 'a'.code || nextChar() != 'l'.code || nextChar() != 's'.code || nextChar() != 'e'.code) {
						pos = save;
						invalidChar();
					}
					return false;
				case 'n'.code: // judge "null"
					save = pos;
					if (nextChar() != 'u'.code || nextChar() != 'l'.code || nextChar() != 'l'.code) {
						pos = save;
						invalidChar();
					}
					return null;
				case '"'.code:
					return parseString();
				case '0'.code, '1'.code, '2'.code, '3'.code, '4'.code, '5'.code, '6'.code, '7'.code, '8'.code, '9'.code, '-'.code:
					return parseNumber(c);
				default:
					if (StringTools.isEof(c)) return returnObject;
					invalidChar();
			}
		}
	}

	function showProgress(force:Bool = false) {
		if (force || Timer.stamp() - time > 0.01) {
			if (log) {
				if (ClientPrefs.data.numberFormat)
					Eseq.p('${CoolUtil.formatMoney(pos)}/${CoolUtil.formatMoney(str.length)}');
				else
					Eseq.p('$pos/${str.length}');
			}
			time = Timer.stamp();
		}
	}

	var start:Int;
	var buf:StringBuf = null;
	var prev:Int;
	var uc:Int;
	function parseString() {
		start = pos;
		buf = null;
		#if target.unicode
		prev = -1;
		inline function cancelSurrogate() {
			// invalid high surrogate (not followed by low surrogate)
			buf.addChar(0xFFFD);
			prev = -1;
		}
		#end
		while (true) {
			c = nextChar();
			if (c == '"'.code)
				break;
			if (c == '\\'.code) {
				if (buf == null) {
					buf = new StringBuf();
				}
				buf.addSub(str, start, pos - start - 1);
				c = nextChar();
				#if target.unicode
				if (c != "u".code && prev != -1)
					cancelSurrogate();
				#end
				switch (c) {
					case "r".code:
						buf.addChar("\r".code);
					case "n".code:
						buf.addChar("\n".code);
					case "t".code:
						buf.addChar("\t".code);
					case "b".code:
						buf.addChar(8);
					case "f".code:
						buf.addChar(12);
					case "/".code, '\\'.code, '"'.code:
						buf.addChar(c);
					case 'u'.code:
						uc = Std.parseInt("0x" + str.substr(pos, 4));
						pos += 4;
						#if !target.unicode
						if (uc <= 0x7F)
							buf.addChar(uc);
						else if (uc <= 0x7FF) {
							buf.addChar(0xC0 | (uc >> 6));
							buf.addChar(0x80 | (uc & 63));
						} else if (uc <= 0xFFFF) {
							buf.addChar(0xE0 | (uc >> 12));
							buf.addChar(0x80 | ((uc >> 6) & 63));
							buf.addChar(0x80 | (uc & 63));
						} else {
							buf.addChar(0xF0 | (uc >> 18));
							buf.addChar(0x80 | ((uc >> 12) & 63));
							buf.addChar(0x80 | ((uc >> 6) & 63));
							buf.addChar(0x80 | (uc & 63));
						}
						#else
						if (prev != -1) {
							if (uc < 0xDC00 || uc > 0xDFFF)
								cancelSurrogate();
							else {
								buf.addChar(((prev - 0xD800) << 10) + (uc - 0xDC00) + 0x10000);
								prev = -1;
							}
						} else if (uc >= 0xD800 && uc <= 0xDBFF)
							prev = uc;
						else
							buf.addChar(uc);
						#end
					default:
						throw "Invalid escape sequence \\" + String.fromCharCode(c) + " at position 0x" + (pos - 1).hex(8) + ' (${pos - 1})';
				}
				start = pos;
			}
			#if !(target.unicode)
			// ensure utf8 chars are not cut
			else if (c >= 0x80) {
				pos++;
				if (c >= 0xFC)
					pos += 4;
				else if (c >= 0xF8)
					pos += 3;
				else if (c >= 0xF0)
					pos += 2;
				else if (c >= 0xE0)
					pos++;
			}
			#end
			else if (StringTools.isEof(c))
			throw "Unclosed string";
		}
		#if target.unicode
		if (prev != -1)
			cancelSurrogate();
		#end
		if (buf == null) {
			return str.substr(start, pos - start - 1);
		} else {
			buf.addSub(str, start, pos - start - 1);
			return buf.toString();
		}
	}
	
	var minus:Bool; var digit:Bool; var zero:Bool;
	var point:Bool = false; var e:Bool = false;
	var pm:Bool = false; var end:Bool = false;
	var f:Float; var i:Int;
	inline function parseNumber(c:Int):Dynamic {
		start = pos - 1;
		minus = c == '-'.code; digit = !minus; zero = c == '0'.code;
		point = e = pm = end = false;
		while (true) {
			switch (c = nextChar()) {
				case '0'.code:
					if (zero && !point)
						invalidNumber(start);
					if (minus) {
						minus = false;
						zero = true;
					}
					digit = true;
				case '1'.code, '2'.code, '3'.code, '4'.code, '5'.code, '6'.code, '7'.code, '8'.code, '9'.code:
					if (zero && !point)
						invalidNumber(start);
					if (minus)
						minus = false;
					digit = true;
					zero = false;
				case '.'.code:
					if (minus || point || e)
						invalidNumber(start);
					digit = false;
					point = true;
				case 'e'.code, 'E'.code:
					if (minus || zero || e)
						invalidNumber(start);
					digit = false;
					e = true;
				case '+'.code, '-'.code:
					if (!e || pm)
						invalidNumber(start);
					digit = false;
					pm = true;
				default:
					if (!digit)
						invalidNumber(start);
					pos--;
					end = true;
			}
			if (end)
				break;
		}

		f = Std.parseFloat(str.substr(start, pos - start));
		if(point) {
			return f;
		} else {
			i = Std.int(f);
			return if (i == f) i else f;
		}
	}

	inline function nextChar() {
		return StringTools.fastCodeAt(str, pos++);
	}

	function invalidChar() {
		pos--; // rewind
		throw "Invalid char " + StringTools.fastCodeAt(str, pos) + " at position " + pos.hex();
	}

	function invalidNumber(start:Int) {
		throw "Invalid number at position " + start.hex() + ": " + str.substr(start, pos - start);
	}
}