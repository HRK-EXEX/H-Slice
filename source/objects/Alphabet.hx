package objects;

import haxe.Json;
import openfl.utils.Assets;

enum Alignment
{
	LEFT;
	CENTERED;
	RIGHT;
}

class Alphabet extends FlxSpriteGroup
{
	public var text(default, set):String;

	public var bold:Bool = false;
	public var letters:Array<AlphaCharacter> = [];

	public var isMenuItem:Bool = false;
	public var targetY:Int = 0;
	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var alignment(default, set):Alignment = LEFT;
	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;
	public var rows:Int = 0;

	public var distancePerItem:FlxPoint = FlxPoint.get(20, 120);
	public var startPosition:FlxPoint = FlxPoint.get(0, 0); //for the calculations

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true)
	{
		super(x, y);

		this.startPosition.x = x;
		this.startPosition.y = y;
		this.bold = bold;
		this.text = text;

		moves = false;
		immovable = true;
	}

	public function setAlignmentFromString(align:String)
	{
		switch(align.toLowerCase().trim())
		{
			case 'right':
				alignment = RIGHT;
			case 'center' | 'centered':
				alignment = CENTERED;
			default:
				alignment = LEFT;
		}
	}

	private function set_alignment(align:Alignment)
	{
		alignment = align;
		updateAlignment();
		return align;
	}

	var newOffset:Float = 0;
	private function updateAlignment()
	{
		for (letter in letters)
		{
			newOffset = 0;
			switch(alignment)
			{
				case CENTERED:
					newOffset = letter.rowWidth / 2;
				case RIGHT:
					newOffset = letter.rowWidth;
				default:
					newOffset = 0;
			}
	
			letter.offset.x -= letter.alignOffset;
			letter.alignOffset = newOffset * scale.x;
			letter.offset.x += letter.alignOffset;
		}
	}

	private function set_text(newText:String)
	{
		newText = newText.replace('\\n', '\n');
		clearLetters();
		createLetters(newText);
		updateAlignment();
		this.text = newText;
		return newText;
	}

	var letter:AlphaCharacter;
	var letterLength:Int;
	public function clearLetters()
	{
		letterLength = letters.length;
		while (letterLength > 0)
		{
			letter = letters[--letterLength];
			if(letter != null)
			{
				letter.kill();
				letters.remove(letter);
				remove(letter);
			}
		}
		letters = [];
		rows = 0;
	}

	var lastX:Float;
	var lastY:Float;
	public function setScale(newX:Float, newY:Null<Float> = null)
	{
		lastX = scale.x;
		lastY = scale.y;
		if(newY == null) newY = newX;
		@:bypassAccessor
			scaleX = newX;
		@:bypassAccessor
			scaleY = newY;

		scale.x = newX;
		scale.y = newY;
		softReloadLetters(newX / lastX, newY / lastY);
	}

	var ratio:Float;
	private function set_scaleX(value:Float)
	{
		if (value == scaleX) return value;

		ratio = value / scale.x;
		scale.x = value;
		scaleX = value;
		softReloadLetters(ratio, 1);
		return value;
	}

	private function set_scaleY(value:Float)
	{
		if (value == scaleY) return value;

		ratio = value / scale.y;
		scale.y = value;
		scaleY = value;
		softReloadLetters(1, ratio);
		return value;
	}

	public function softReloadLetters(ratioX:Float = 1, ratioY:Null<Float> = null)
	{
		if(ratioY == null) ratioY = ratioX;

		for (letter in letters)
		{
			if(letter != null)
			{
				letter.setupAlphaCharacter(
					(letter.x - x) * ratioX + x,
					(letter.y - y) * ratioY + y
				);
			}
		}
	}

	var lerpVal:Float;
	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			lerpVal = Math.exp(-elapsed * 9.6);
			if(changeX) x = FlxMath.lerp((targetY * distancePerItem.x) + startPosition.x, x, lerpVal);
			if(changeY) y = FlxMath.lerp((targetY * 1.3 * distancePerItem.y) + startPosition.y, y, lerpVal);
		}
		super.update(elapsed);
	}

	public function snapToPosition()
	{
		if (isMenuItem)
		{
			if(changeX)
				x = (targetY * distancePerItem.x) + startPosition.x;
			if(changeY)
				y = (targetY * 1.3 * distancePerItem.y) + startPosition.y;
		}
	}

	private static var Y_PER_ROW:Float = 85;


	private function createLetters(newText:String)
	{
		var consecutiveSpaces:Int = 0;
		var character:String;
		var xPos:Float = 0;
		var rowData:Array<Float> = [];

		var spaceChar:Bool;
		var isAlphabet:Bool;
		var off:Float;

		rows = 0;
		for (i in 0...newText.length)
		{
			character = newText.charAt(i);
			if(character != '\n')
			{
				spaceChar = (character == " " || (bold && character == "_"));
				if (spaceChar) consecutiveSpaces++;

				isAlphabet = AlphaCharacter.isTypeAlphabet(character.toLowerCase());
				if (AlphaCharacter.allLetters.exists(character.toLowerCase()) && (!bold || !spaceChar))
				{
					if (consecutiveSpaces > 0)
					{
						xPos += 28 * consecutiveSpaces * scaleX;
						rowData[rows] = xPos;
						if(!bold && xPos >= FlxG.width * 0.65)
						{
							xPos = 0;
							rows++;
						}
					}
					consecutiveSpaces = 0;

					letter = cast recycle(AlphaCharacter, true);
					letter.scale.x = scaleX;
					letter.scale.y = scaleY;
					letter.rowWidth = 0;

					letter.setupAlphaCharacter(xPos, rows * Y_PER_ROW * scale.y, character, bold);
					@:privateAccess letter.parent = this;

					letter.row = rows;
					off = 0;
					if(!bold) off = 2;
					xPos += letter.width + (letter.letterOffset[0] + off) * scale.x;
					rowData[rows] = xPos;

					add(letter);
					letters.push(letter);
				}
			}
			else
			{
				xPos = 0;
				rows++;
			}
		}

		for (letter in letters)
		{
			letter.rowWidth = rowData[letter.row] / scale.x;
		}

		if(letters.length > 0) rows++;
	}

	override function destroy(){
		distancePerItem.put();
		startPosition.put();
		letters = FlxDestroyUtil.destroyArray(letters);
		active = false;
		super.destroy();
	}
}


///////////////////////////////////////////
// ALPHABET LETTERS, SYMBOLS AND NUMBERS //
///////////////////////////////////////////

/*enum LetterType
{
	ALPHABET;
	NUMBER_OR_SYMBOL;
}*/

typedef Letter = {
	?anim:Null<String>,
	?offsets:Array<Float>,
	?offsetsBold:Array<Float>
}

class AlphaCharacter extends FlxSprite
{
	//public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";
	//public static var numbers:String = "1234567890";
	//public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";

	public var image(default, set):String;

	public static var allLetters:Map<String, Null<Letter>>;

	public static function loadAlphabetData(request:String = 'alphabet')
	{
		var path:String = Paths.getPath('images/$request.json');
		if(!NativeFileSystem.exists(path))
			path = Paths.getPath('images/alphabet.json');

		allLetters = new Map<String, Null<Letter>>();
		try
		{

			var data:Dynamic = Json.parse(NativeFileSystem.getContent(path));

			if(data.allowed != null && data.allowed.length > 0)
			{
				for (i in 0...data.allowed.length)
				{
					var char:String = data.allowed.charAt(i);
					if(char == ' ') continue;
					
					allLetters.set(char.toLowerCase(), null); //Allows character to be used in Alphabet
				}
			}

			if(data.characters != null)
			{
				for (char in Reflect.fields(data.characters))
				{
					var letterData = Reflect.field(data.characters, char);
					var character:String = char.toLowerCase().substr(0, 1);
					if((letterData.animation != null || letterData.normal != null || letterData.bold != null) && allLetters.exists(character))
						allLetters.set(character, {anim: letterData.animation, offsets: letterData.normal, offsetsBold: letterData.bold});
				}
			}
			trace('Reloaded letters successfully ($path)!');
		}
		catch(e:Dynamic)
		{
			FlxG.log.error('Error on loading alphabet data: $e');
			trace('Error on loading alphabet data: $e');
		}

		if(!allLetters.exists('?'))
			allLetters.set('?', {anim: 'question'});
	}

	var parent:Alphabet;
	public var alignOffset:Float = 0; //Don't change this
	public var letterOffset:Array<Float> = [0, 0];

	public var row:Int = 0;
	public var rowWidth:Float = 0;
	public var character:String = '?';
	public function new()
	{
		super(x, y);
		image = 'alphabet';
		antialiasing = ClientPrefs.data.antialiasing;

		moves = false;
		immovable = true;
	}
	
	public var curLetter:Letter = null;
	public function setupAlphaCharacter(x:Float, y:Float, ?character:String = null, ?bold:Null<Bool> = null)
	{
		this.x = x;
		this.y = y;

		if(parent != null)
		{
			if(bold == null)
				bold = parent.bold;
			this.scale.x = parent.scaleX;
			this.scale.y = parent.scaleY;
		}
		
		if(character != null)
		{
			this.character = character;
			curLetter = null;
			var lowercase:String = this.character.toLowerCase();
			if(allLetters.exists(lowercase)) curLetter = allLetters.get(lowercase);
			else curLetter = allLetters.get('?');

			var postfix:String = '';
			if(!bold)
			{
				if(isTypeAlphabet(lowercase))
				{
					if(lowercase != this.character)
						postfix = ' uppercase';
					else
						postfix = ' lowercase';
				}
				else postfix = ' normal';
			}
			else postfix = ' bold';

			var alphaAnim:String = lowercase;
			if(curLetter != null && curLetter.anim != null) alphaAnim = curLetter.anim;

			var anim:String = alphaAnim + postfix;
			#if debug //! This only exists to prevent annoying beeps!
			animation.addByPrefix(anim, anim+" instance ", 24);
			#else
			animation.addByPrefix(anim, anim, 24);
			#end
			animation.play(anim, true);
			if(animation.curAnim == null)
			{
				if(postfix != ' bold') postfix = ' normal';
				anim = 'question' + postfix;
				animation.addByPrefix(anim, anim, 24);
				animation.play(anim, true);
			}
		}
		updateHitbox();
	}

	public static function isTypeAlphabet(c:String) // thanks kade
	{
		var ascii = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90)
			|| (ascii >= 97 && ascii <= 122)
			|| (ascii >= 192 && ascii <= 214)
			|| (ascii >= 216 && ascii <= 246)
			|| (ascii >= 248 && ascii <= 255);
	}

	private function set_image(name:String)
	{
		if(frames == null) //first setup
		{
			image = name;
			frames = Paths.getSparrowAtlas(name);
			return name;
		}

		var lastAnim:String = null;
		if (animation != null)
		{
			lastAnim = animation.name;
		}
		image = name;
		frames = Paths.getSparrowAtlas(name);
		this.scale.x = parent.scaleX;
		this.scale.y = parent.scaleY;
		alignOffset = 0;
		
		if (lastAnim != null)
		{
			animation.addByPrefix(lastAnim, lastAnim, 24);
			animation.play(lastAnim, true);
			
			updateHitbox();
		}
		return name;
	}

	public function updateLetterOffset()
	{
		if (animation.curAnim == null)
		{
			trace(character);
			return;
		}

		var add:Float = 110;
		if(animation.curAnim.name.endsWith('bold'))
		{
			if(curLetter != null && curLetter.offsetsBold != null)
			{
				letterOffset[0] = curLetter.offsetsBold[0];
				letterOffset[1] = curLetter.offsetsBold[1];
			}
			add = 70;
		}
		else
		{
			if(curLetter != null && curLetter.offsets != null)
			{
				letterOffset[0] = curLetter.offsets[0];
				letterOffset[1] = curLetter.offsets[1];
			}
		}
		add *= scale.y;
		offset.x += letterOffset[0] * scale.x;
		offset.y += letterOffset[1] * scale.y - (add - height);
	}

	override public function updateHitbox()
	{
		super.updateHitbox();
		updateLetterOffset();
	}

	override function destroy(){
		active = false;
		super.destroy();
	}
}
