package backend;

import cpp.Float64;

#if windows
@:cppFileCode('
	#include <stdlib.h>
	#include <string>
	#include <chrono>
	#include <thread>
	#include <stdio.h>
	#include <iostream>
	#include <windows.h>
')
#elseif desktop
@:cppFileCode('
	#include <stdlib.h>
	#include <string>
	#include <chrono>
	#include <thread>
	#include <stdio.h>
	#include <iostream>
')
#else
@:cppFileCode('
	#include <stdlib.h>
	#include <string>
	#include <chrono>
	#include <thread>
')
#end

class CoolUtil
{
	public static final MIN_VALUE_DOUBLE = 2.225073858507201383090232717332404064219215980462331830553327416887204434813918195854283159012511020564067339731035811005152434161553460108856012385377718821130777993532002330479610147442583636071921565046942503734208375250806650616658158948720491179968591639648500635908770118304874799780887753749949451580451605050915399856582470818645113537935804992115981085766051992433352114352390148795699609591288891602992641511063466313393663477586513029371762047325631781485664350872122828637642044846811407613911477062801689853244110024161447421618567166150540154285084716752901903161322778896729707373123334086988983175067838846926092773977972858659654941091369095406136467568702398678315290680984617210924625396728515625e-308;

	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		//trace(snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		if(NativeFileSystem.exists(path)) daList = NativeFileSystem.getContent(path);
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}
	
	/**
	 * Fill numbers with a specified number of digits and right-align with the number.
	 * @param value Floating-point number
	 * @param digits Integer
	 * @param code Integer (use fastCodeAt)
	 */
	static var format:StringBuf = new StringBuf();
	inline public static function fillNumber(value:Dynamic, digits:Int, code:Int, delimit:Null<Bool> = null) {
		var defined:String = customNumberDelimiter(value, delimit);

		var length:Int = defined.length;
		var str:String = null;
		format = new StringBuf();

		if (delimit == null && ClientPrefs.data.numberFormat || delimit)
			digits += Std.int(Math.max(0.0, (digits - 1) / 3));

		if (length < digits) {
			for (i in 0...(digits - length))
				format.addChar(code);
			format.add(defined);
		} else format.add(defined);

		str = format.toString(); format = null;
		return str;
	}

	inline public static function logX(value:Float, exp:Float) {
		return Math.log(value) / Math.log(exp);
	}

	inline public static function interpolate(start:Float, end:Float, progress:Float, exponent:Float = 1) {
		progress = FlxMath.bound(progress, 0, 1);
		return FlxMath.lerp(start, end, Math.pow(progress, exponent));
	}

	inline public static function normalize(x:Float, min:Float, max:Float, isBound:Bool = true) {
		return isBound ? FlxMath.bound((x - min) / (max - min), 0, 1) : (x - min) / (max - min);
	}

	inline public static function bool(value:Dynamic):Null<Bool> {
		if (value is Int || value is Float) {
			return (value >= 1);
		}
		return null;
	}

	inline public static function int(value:Dynamic):Null<Int> {
		if (value is Int || value is Float) {
			return Std.int(value);
		} else if (value is Bool) {
			return value ? 1 : 0;
		} else if (value is String) {
			return Std.parseInt(value);
		} else return null;
	}

	inline public static function hex2bin(str:String, reversed:Bool = false) {
		var returnVal:String = "";
		var tmpStr:String = "";
		var hex:Int = 0;
		for (i in 0...str.length) {
			hex = Std.parseInt("0x"+str.charAt(i));
			tmpStr = "";
			for (j in 0...4) {
				tmpStr = ((hex & 1<<j) == 1<<j ? "1" : "0") + tmpStr;
			}
			returnVal += tmpStr + " ";
		}
		return returnVal.substr(0, returnVal.length-1);
	}

	inline public static function dec2bin(int:Int, digits:Int) {
		var str:String = "";
		digits = FlxMath.minInt(digits, 32);

		while (digits > 0) {
			str = Std.string(int % 2) + str;
			int >>= 1; digits--;
		}

		return str;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.ffloor(value);

		return Math.ffloor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
	}
	
	inline public static function decimal(value:Float, decimals:Int, mode:Int = 1):Float
	{
		var up:Float = Math.pow(10, decimals);
		var down:Float = Math.pow(10, -decimals);
		var mod:Float = value * up;

		switch (mode) {
			case 0: // floor
				value = Math.ffloor(mod);
			case 2: // ceil
				value = Math.fceil(mod);
			case 1 | _: // round
				value = Math.fround(mod);
		}

		return value * down;
	}
	
	inline public static function floatToStringPrecision(number:Float, prec:Int, exponent:Bool = false){
		var str:String;
		var abs:Null<Float> = Math.abs(number);
		var len:Null<Int>;
		var result:String;
		
		// for number delimiter
		var mode:Bool = !exponent || (abs >= Math.pow(0.1, prec) && abs < Math.pow(10, 6));

		if (mode) {
			str = Std.string(Math.fround(abs * Math.pow(10, prec)));
			len = str.length;
			if(len <= prec){
				// Smaller than 1
				while(len < prec){
					str = '0'+str;
					len++;
				}
				result = '0.'+str;
			} else {
				// Larger than 1
				if (str.length == prec) result = str;
				else {
					result = str.substr(0, str.length-prec) + (prec > 0 ? '.'+str.substr(str.length-prec) : '');
				}
			}
		} else {
			str = ''+Math.fround(
				abs * Math.pow(10, Math.floor( -logX(abs, 10) ) ) * Math.pow(10, prec) * 10
			);
			result = (number > MIN_VALUE_DOUBLE ? str.substr(0,1) + '.' + str.substr(1) : '0') + 'e' + Math.floor(logX(abs, 10));
		}
		str = null; len = null; abs = null;
		result = (number < 0 ? "-" : "") + result;

		if (mode && ClientPrefs.data.numberFormat) {
			result = customNumberDelimiter(result);
		}

		return result;
	}

	/**
	 * Mathematic Function for Decimal Array.
	 * @param array Array of Float Type
	 * @param type Maximum = 0, Minimum = 1, Average = 2
	 */
	inline public static function decimalArrayUtil(array:Array<Float>, type:Int) {
		if (array.length == 0) return null;
		var value:Float = array[0];
		for (i in 1...array.length) {
			switch (type) {
				case 0: value = Math.max(value, array[i]);
				case 1: value = Math.min(value, array[i]);
				case 2: value += array[i];
			}
		}
		if (type == 2) value /= array.length;
		return value;
	}

	/**
	 * Mathematic Function for Integer Array.
	 * @param array Array of Integer Type
	 * @param type Maximum = 0, Minimum = 1, Average = 2
	 */
	inline public static function integerArrayUtil(array:Array<Int>, type:Int) {
		if (array.length == 0) return null;
		var value:Float = array[0];
		for (i in 1...array.length) {
			switch (type) {
				case 0: value = Math.max(value, array[i]);
				case 1: value = Math.min(value, array[i]);
				case 2: value += array[i];
			}
		}
		if (type == 2) value /= array.length;
		return Math.round(value);
	}

	inline public static function customNumberDelimiter(value:Dynamic, delimit:Null<Bool> = null) {
		var defined:String = null;
		if (value is String) {
			if (Std.parseFloat(value) != Math.NaN) {
				defined = value;
			} else throw "Given string, but It cannot convert to number";
		} else if (value is Float || value is Int) {
			defined = Std.string(value);
		} else throw "It's invalid type. You need the number or numerical string.";
		if (!ClientPrefs.data.numberFormat || !delimit) return Std.string(value);
		
		// for number delimiter
		var cnt:Int = -1;
		var decimal:Bool;
		var pos:Int = 0;

		decimal = defined.lastIndexOf(".") != -1;
		cnt = 0;
		pos = defined.length - 1;
		// Sys.print('$defined (decimal: $decimal): ');
		for (i in 0...defined.length) {
			// Sys.print('$cnt, ');
			var char:Int = defined.fastCodeAt(pos);
			if (decimal) {
				if (char == ".".code) {decimal = false;}
			} else {
				if (48 <= char && char < 58) ++cnt;
				if (cnt > 3) {
					cnt -= 3;
					defined = defined.substr(0, pos+1) + "," + defined.substr(pos+1);
				}
			}
			--pos;
		}
		// Sys.print('end\n');
		return defined;
	}

	public static function searchFromStrings(target:String, strings:Array<String>):Bool {
		var result = false;
		for (s in strings) {
			result = searchFromString(target, s);
			if (result) return result;
		}
		return false;
	}

	public static function searchFromString(target:String, string:String):Bool {
		for (i in 0...(target.length - string.length + 1)) {
			if (target.substr(i, string.length) == string) return true;
		}
		return false;
	}

	public static function reverseString(str:String) {
		var reversed:String = "";
		for (i in 0...str.length) {
			reversed = str.charAt(i) + reversed;
		}
		return reversed;
	}

	public static function sortAlphabetically(list:Array<String>):Array<String> {
		if (list == null) return [];

		list.sort((a, b) -> {
			var upperA = a.toUpperCase();
			var upperB = b.toUpperCase();
			
			return upperA < upperB ? -1 : upperA > upperB ? 1 : 0;
		});
		return list;
	}

	@:functionCode('		
		// Get the current time
		auto now = std::chrono::high_resolution_clock::now();
		
		// Time elapsed since the epoch is obtained as DURATION (converted to seconds)
		auto duration = now.time_since_epoch();
		auto seconds = std::chrono::duration_cast<std::chrono::duration<double>>(duration);
		
		// Returns the second as double
		return seconds.count();
	')
	static public function getNanoTime():Float64
	{
		return -1;
	}
	
	// stolen and modded from FlxStringUtil
	public static function formatTime(seconds:Float, precision:Int = 0):String
	{
		var timeString:String = Math.floor(seconds / 60) + ":";
		var timeStringHelper:Int = Math.floor(seconds) % 60;
		var timePresition:Int = Math.round(Math.pow(10, precision));

		if (timeStringHelper < 10)
		{
			timeString += "0";
		}
		timeString += timeStringHelper;
		if (precision > 0)
		{
			timeString += ".";
			timeStringHelper = Math.floor((seconds - Math.floor(seconds)) * timePresition);
			timeString += fillNumber(timeStringHelper, ClientPrefs.data.timePrec, '0'.charCodeAt(0));
		}

		return timeString;
	}

	// stolen and modded from FlxStringUtil
	public static function formatMoney(amount:Float, showDecimal:Int = 0, englishStyle:Bool = true):String
	{
		var isNegative:Null<Bool> = amount < 0;
		amount = Math.abs(amount);

		var string:String = "";
		var comma:String = "";
		var amount:Null<Float> = Math.ffloor(amount);
		var zeroes:String = "";
		var helper:Null<Float>;
		var power:Null<Float>;

		while (amount > 0)
		{
			if (string.length > 0 && comma.length <= 0)
				comma = (englishStyle ? "," : ".");

			zeroes = "";
			helper = amount - Math.ffloor(amount / 1000) * 1000;
			amount = Math.ffloor(amount / 1000);
			if (amount > 0)
			{
				if (helper < 100)
					zeroes += "0";
				if (helper < 10)
					zeroes += "0";
			}
			string = zeroes + helper + comma + string;
		}

		if (string == "")
			string = "0";

		if (showDecimal > 0)
		{
			power = Math.pow(10, showDecimal);
			amount = Math.ffloor(amount * power) - (Math.ffloor(amount) * power);
			string += (englishStyle ? "." : ",");
			if (amount < 10)
				string += "0";
			string += amount;
		}

		if (isNegative)
			string = "-" + string;

		comma = zeroes = null;
		amount = helper = power = null; isNegative = null;

		return string;
	}

	// stolen and modded from FlxStringUtil
	static final byteUnits:Array<String> = ["Bytes", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "RB", "QB"];
	static var curUnit:Int;
	public static function formatBytes(bytes:Float, precision:Int = 2, keepPrec:Bool = false, fixedSI:Int = -1):String
	{
		curUnit = 0;
		if(fixedSI < 0) {
			while (bytes >= 1024 && curUnit < byteUnits.length - 1)
			{
				bytes /= 1024;
				curUnit++;
			}
		} else {
			while (curUnit < fixedSI && curUnit < byteUnits.length - 1)
			{
				bytes /= 1024;
				curUnit++;
			}
		}
		if(keepPrec) {
			if(fixedSI < 0) {
				precision = (precision+3) - Std.int(logX(bytes, 10) + 1);
				if (precision < 0) precision = 0;
			}
			return CoolUtil.floatToStringPrecision(bytes, precision) + byteUnits[curUnit];
		}
		else
			return CoolUtil.floorDecimal(bytes, precision) + byteUnits[curUnit];
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth)
		{
			for(row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
					countByColor[colorOfThisPixel] = count + 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key => count in countByColor)
		{
			if(count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function notBlank(s:String) {
		return s != null && s.length > 0;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			#if linux
			var command:String = '/usr/bin/xdg-open';
			#else
			var command:String = 'explorer.exe';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.log.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	// why doesn't it work
	public static function deleteDirectoryWithFiles(path:String) {
		#if sys
		path = FileSystem.fullPath(path).replace(#if windows "/", "\\" #else "\\", "/" #end);
		if (NativeFileSystem.exists(path) && NativeFileSystem.isDirectory(path)) {
			var files = NativeFileSystem.readDirectory(path);
			var converted:String = "";

			for (file in files) {
				converted = FileSystem.fullPath(path + "/" + file).replace(#if windows "/", "\\" #else "\\", "/" #end);
				// trace(converted);
				if (NativeFileSystem.isDirectory(converted)) {
					deleteDirectoryWithFiles(converted);
				} else NativeFileSystem.deleteFile(converted);
			}

			FileSystem.deleteDirectory(path);
		}
		#else
			FlxG.error("Platform is not supported for CoolUtil.deleteDirectoryWithFiles");
		#end
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate("PsychEngine")}'; //! hardcoding for backwards compatibility
		// #end
	}

	@:functionCode('
		unsigned int cnt = std::thread::hardware_concurrency();
		return cnt;
	')
	public static function getThreadCount():Int {
		return 0;
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch(border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	#if windows
	@:functionCode('
		HWND hWnd = GetActiveWindow();
        LPCSTR lwDesc = desc.c_str();
        LPCSTR lwCap = cap.c_str();

        res = MessageBoxA(
            hWnd,
            lwDesc,
            NULL,
            MB_OK
        );
	')
	static public function sendMsgBox(desc:String = "", cap:String = "", res:Int = 0) // TODO: Linux and macOS (will do soon)
	{
		return res;
	}
	#end

	public static function showPopUp(title:String, message:String):Void
	{
		#if android
		AndroidTools.showAlertDialog(title, message, {name: "OK", func: null}, null);
		#elseif windows
		sendMsgBox(message, title);
		#else
		FlxG.stage.window.alert(message, title);
		#end
	}

	#if cpp
    @:functionCode('
        return std::thread::hardware_concurrency();
    ')
	#end
    public static function getCPUThreadsCount():Int
    {
        return 1;
    }
}