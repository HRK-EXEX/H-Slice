package objects;

import flixel.math.FlxAngle;
import haxe.ds.Vector;
import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.FlxGraphic;
import backend.animation.PsychAnimationController;
import backend.NoteTypesConfig;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import objects.StrumNote;

import flixel.math.FlxRect;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

typedef CastNote = {
	var strumTime:Float;
	// noteData and flags
	// 1st-8th bits are for noteData (256keys)
	// 9th bit is for mustHit
	// 10th bit is for isHold
	// 11th bit is for isHoldEnd
	// 12th bit is for gfNote
	// 13th bit is for altAnim
	// 14th bit is for noAnim & noMissAnim
	// 15th bit is for blockHit
	// 16th bit is for ignoreNote
	var noteData:Int;
	var holdLength:Null<Float>;
	@:optional var noteType:String;
}

var toBool = CoolUtil.bool;
var toInt = CoolUtil.int;

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final DEFAULT_NOTE_TYPES:Array<String> = [
		'', //Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public static final DEFAULT_CAST:CastNote = {
		strumTime: 0,
		noteData: 0,
		noteType: "",
		holdLength: 0
	};

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	public var strum:StrumNote = null;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var sustainScale:Float = 1.0;
	public var isSustainNote:Bool = false;
	public var isSustainEnds:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var isBotplay:Bool = false;

	public static final SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var originalWidth:Float = swagWidth;
	public static var originalHeight:Float = swagWidth;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';
	public static var chartArrowSkin:String = null;
	public static var pixelWidth:Vector<Int> = new Vector(2, 0);
	public static var pixelHeight:Vector<Int> = new Vector(2, 0);

	public var correctionOffset:Float = 55; //dont mess with this, it makes the hold notes look better

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: PlayState.SONG != null && !PlayState.SONG.disableNoteRGB && ClientPrefs.data.noteShaders,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};
	public var noteHoldSplash:SustainSplash;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var multAlpha:Float = 1;
	// public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	// public var copyScale:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;
	// public var prevDownScr:Bool = false;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsound';

	// private function set_multSpeed(value:Float):Float {
	// 	resizeByRatio(value / multSpeed);
	// 	multSpeed = value;
	// 	//trace('fuck cock');
	// 	return value;
	// }

	inline public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation != null && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	static var noteFramesCollection:FlxFramesCollection;
	static var noteFramesAnimation:FlxAnimationController;
	
	// It's only used newing instances
	private function set_texture(value:String):String {
		if (value == null || value.length == 0) {
			value = defaultNoteSkin + getNoteSkinPostfix();
		}
		// if (!PlayState.isPixelStage) {
		if(texture != value) {
			if (!Paths.noteSkinFramesMap.exists(value)) inline Paths.initNote(value);

			noteFramesCollection = Paths.noteSkinFramesMap.get(value);
			noteFramesAnimation = Paths.noteSkinAnimsMap.get(value);
			if (frames != noteFramesCollection) frames = noteFramesCollection;
			if (animation != noteFramesAnimation) animation.copyFrom(noteFramesAnimation);
			
			antialiasing = ClientPrefs.data.antialiasing;
			if (originalWidth != width || originalHeight != height) {
				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				originalWidth = width;
				originalHeight = height;
			}
		} else return value;
		texture = value;
		return value;
	}

	static var colArr:Array<FlxColor>;
	public function defaultRGB()
	{
		colArr = PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[noteData] : ClientPrefs.data.arrowRGB[noteData];

		if (colArr != null && noteData > -1 && noteData <= colArr.length)
		{
			rgbShader.r = colArr[0];
			rgbShader.g = colArr[1];
			rgbShader.b = colArr[2];
		}
		else
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
		}
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';
		if (rgbShader != null && rgbShader.enabled) defaultRGB();

		if (noteData > -1) {
			if (value == 'Hurt Note') {
				ignoreNote = mustPress && isBotplay;
				//this used to change the note texture to HURTNOTE_assets.png,
				//but i've changed it to something more optimized with the implementation of RGBPalette:

				// note colors
				if (rgbShader != null && rgbShader.enabled) {
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;
				} else {
					try {
						reloadNote('HURTNOTE_assets');
					} catch (e) {alpha = 0.5; }
				}

				// splash data and colors
				noteSplashData.r = 0xFFFF0000;
				noteSplashData.g = 0xFF101010;
				noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

				// gameplay data
				lowPriority = true;
				missHealth = isSustainNote ? 0.25 : 0.1;
				hitCausesMiss = true;
				hitsound = 'cancelMenu';
				hitsoundChartEditor = false;
			}
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	// strumTime:Float, noteData:Int, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null
	public function new()
	{
		super();
		// animation = new PsychAnimationController(this);
		antialiasing = ClientPrefs.data.antialiasing;

		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		// x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		y -= 2000;

		try {
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if (PlayState.SONG != null && PlayState.SONG.disableNoteRGB || !ClientPrefs.data.noteShaders) rgbShader.enabled = false;
		} catch (e) { rgbShader = null; }
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB = new RGBPalette();
			globalRgbShaders[noteData] = newRGB;

			colArr = PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[noteData] : ClientPrefs.data.arrowRGB[noteData];
			
			if (colArr != null && noteData > -1 && noteData <= colArr.length)
			{
				newRGB.r = colArr[0];
				newRGB.g = colArr[1];
				newRGB.b = colArr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}
		}
		return globalRgbShaders[noteData];
	}

	var rSkin:String;
	var rAnimName:String;

	var rSkinPixel:String;
	var rLastScaleY:Float;
	var rSkinPostfix:String;
	var rCustomSkin:String;
	var rPath:String;

	var rGraphic:FlxGraphic;

	static var _lastValidChecked:String; //optimization
	public function reloadNote(texture:String = '', postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		rSkin = texture + postfix;
		if(texture.length < 1)
		{
			rSkin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(rSkin == null || rSkin.length < 1)
				rSkin = defaultNoteSkin + postfix;
		}
		else rgbShader.enabled = false;

		rAnimName = null;
		if(animation.curAnim != null) {
			rAnimName = animation.curAnim.name;
		}

		rPath = PlayState.isPixelStage ? 'pixelUI/' : '';
		rSkinPixel = rPath + rSkin;
		rLastScaleY = scale.y;
		rSkinPostfix = getNoteSkinPostfix();
		rCustomSkin = rSkin + rSkinPostfix;

		if (rCustomSkin == _lastValidChecked || Paths.fileExists('images/' + rPath + rCustomSkin + '.png', IMAGE))
		{
			rSkin = rCustomSkin;
			_lastValidChecked = rCustomSkin;
		}
		else rSkinPostfix = '';

		if (PlayState.isPixelStage) {
			rGraphic = Paths.image(rSkinPixel + (isSustainNote ? 'ENDS' : '') + rSkinPostfix);
			loadGraphic(rGraphic, true, Math.floor(rGraphic.width / 4), Math.floor(rGraphic.height / (isSustainNote ? 2 : 5)));
			
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;
			
			pixelWidth[isSustainNote ? 1:0] = frameWidth;
			pixelHeight[isSustainNote ? 1:0] = frameHeight;
		} else {
			frames = Paths.getSparrowAtlas(rSkin);
			loadNoteAnims();
			if(!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if(isSustainNote) {
			scale.y = rLastScaleY;
		}
		updateHitbox();

		if(rAnimName != null)
			animation.play(rAnimName, true);
	}

	static var skin:String = '';
	public static function getNoteSkinPostfix()
	{
		skin = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end', 24, true);
			animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece', 24, true);
		}
		else animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if(isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		} else animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
	}

	
	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	var songTime:Float = 0;
	var safeZone:Float = 0;
	override function update(elapsed:Float)
	{
		if (isBotplay) return;
		super.update(elapsed);

		songTime = Conductor.songPosition;
		safeZone = Conductor.safeZoneOffset;

		if (mustPress)
		{
			canBeHit = (strumTime > songTime - (safeZone * lateHitMult) &&
						strumTime < songTime + (safeZone * earlyHitMult));

			if (strumTime < songTime - safeZone && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= songTime)
			{
				if(!isSustainNote || !ignoreNote)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}
	
	var angleDir:Float;
	var angleRad:Float;
	public function followStrumNote(songSpeed:Float = 1, distance:Float = 0)
	{
		if (isSustainNote)
		{
			scale.set(0.7, animation != null && animation.curAnim != null && animation.curAnim.name.endsWith('end') ? 0.7 : Conductor.stepCrochet * 0.0105 * songSpeed * sustainScale);
			if (PlayState.isPixelStage)
			{
				scale.x = PlayState.daPixelZoom;
				scale.y *= PlayState.daPixelZoom * 1.19;
			}

			updateHitbox();
		}

		this.distance = -distance;
		
		angleDir = strum.direction + (strum.downScroll ? 180 : 0); // convert direction to degrees
		angleRad = angleDir * Math.PI / 180;
		if (copyAngle)
			angle = isSustainNote ? strum.direction - 90 : strum.angle;

		if (copyAlpha)
			alpha = strum.alpha * multAlpha;

		if (copyX)
		{
			x = strum.x + offsetX + Math.cos(angleRad) * this.distance;
			if (isSustainNote)
			{
				// x -= frameWidth * scale.x - Note.swagWidth * (Math.cos(angleRad) * 0.25 - 0.5);
				x += height * Math.cos(angleRad) * 0.5;
			}
		}

		if (copyY)
		{
			y = strum.y + offsetY + Math.sin(angleRad) * this.distance;
			if (isSustainNote)
			{
				if(PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y += correctionOffset * Math.sin(angleRad) + (originalHeight - height) * (-Math.sin(angleRad) + 1) * 0.5;
			}
		}

		// wtf is this
		// if (copyScale) {
		// 	scale.x = strum.scale.x;
		// 	if(!isSustainNote) scale.y = strum.scale.y;
		// 	updateHitbox();
		// }
	}

	var swagRect:FlxRect;
	public function clipToStrumNote()
	{
		if((mustPress || !ignoreNote) && (wasGoodHit || hitByOpponent || !canBeHit))
		{
			if (swagRect == null) {
				swagRect = new FlxRect(0, 0, frameWidth, frameHeight);
			} else {
				swagRect.setPosition(0, 0);
				swagRect.setSize(frameWidth, frameHeight);
			}
			swagRect.y = -distance / scale.y;
			swagRect.height = frameHeight - swagRect.y;

			clipRect = swagRect;
		}
	}

	override function kill() {
		active = visible = false;
		super.kill();
	}
	
	var initSkin:String = Note.defaultNoteSkin + getNoteSkinPostfix();
	var playbackRate:Float;
	var correctWidth:Float;

	public function recycleNote(target:CastNote) {
		wasGoodHit = hitByOpponent = tooLate = false;
		canBeHit = missed = flipY = false; // Don't make an update call of this for the note group
		exists = true;

		isBotplay = PlayState.instance != null ? PlayState.instance.cpuControlled : false;

		strumTime = target.strumTime;
		if (!inEditor) strumTime += ClientPrefs.data.noteOffset;

		mustPress = toBool(target.noteData & (1<<8));						 // mustHit
		isSustainNote = toBool(target.noteData & (1<<9));					 // isHold
		isSustainEnds = toBool(target.noteData & (1<<10));					 // isHoldEnd
		gfNote = toBool(target.noteData & (1<<11));							 // gfNote
		animSuffix = toBool(target.noteData & (1<<12)) ? "-alt" : "";		 // altAnim
		noAnimation = noMissAnimation = toBool(target.noteData & (1<<13));	 // noAnim
		blockHit = toBool(target.noteData & (1<<14));				 		 // blockHit
		ignoreNote = toBool(target.noteData & (1<<15));				 		 // ignoreNote
		noteData = target.noteData & 3;

		hitsoundDisabled = isSustainNote;

		// Absoluty should be here, or messing pixel texture glitches...
		if (!PlayState.isPixelStage) {
			if (!CoolUtil.notBlank(chartArrowSkin)) texture = chartArrowSkin = initSkin;
			else if (chartArrowSkin != texture) texture = chartArrowSkin;
		} else reloadNote(texture);

		try {
			if (target.noteType is String) noteType = target.noteType; // applying note color on damage notes
			else noteType = DEFAULT_NOTE_TYPES[Std.parseInt(target.noteType)];
		} catch (e:Dynamic) {}

		sustainLength = target.holdLength ?? 0;

		// this.parent = parent;
		// if (this.parent != null) parent.tail = [];

		// copyAngle = !isSustainNote;

		// Juuuust in case we recycle a sustain note to a regular note
		if (PlayState.isPixelStage || !isSustainNote){
			animation.play(colArray[noteData % colArray.length] + 'Scroll', true);
			offsetX = 0;
		}

		if (isSustainNote)
		{
			flipY = ClientPrefs.data.downScroll;
			alpha = multAlpha = 0.6;

			if (PlayState.isPixelStage) {
				offsetX += pixelWidth[0] * 0.5 * PlayState.daPixelZoom;
				animation.play(colArray[noteData % colArray.length] + (isSustainEnds ? 'holdend' : 'hold'));  // isHoldEnd
				offsetX -= pixelWidth[1] * 0.5 * PlayState.daPixelZoom;

				if(!isSustainEnds) {
					// trace(pixelHeight[0], pixelHeight[1]);
					sustainScale = (PlayState.daPixelZoom / pixelHeight[1]); //Auto adjust note size
				}
			} else {
				offsetX += width * 0.5;
				animation.play(colArray[noteData % colArray.length] + (isSustainEnds ? 'holdend' : 'hold'));  // isHoldEnd
				updateHitbox();
				offsetX -= width * 0.5;

				if (!isSustainEnds) sustainScale = Note.SUSTAIN_SIZE / frameHeight;
			}
			
			// correctionOffset = 55;
		} else {
			alpha = multAlpha = sustainScale = 1;

			if (!PlayState.isPixelStage) 
			{
				scale.set(0.7, 0.7);
				width = originalWidth;
				height = originalHeight;

				centerOffsets(true);
				centerOrigin();
			} else scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		}

		if (sustainScale != 1 && !isSustainEnds)
			resizeByRatio(sustainScale);
		clipRect = null;
		x += offsetX;
		return this;
	}

	// it used on spawning hold splashes
	public function toCastNote():CastNote {
		var lmfao:Int = 
			this.noteData & 255 |
			toInt(mustPress) << 8 |
			toInt(isSustainNote) << 9 |
			toInt(isSustainEnds) << 10 |
			toInt(gfNote) << 11 |
			toInt(animSuffix != "")	<< 12 |
			toInt(noAnimation) << 13 |
			toInt(blockHit) << 14 |
			toInt(ignoreNote) << 15;
		
		var converted:CastNote = {
			strumTime: this.strumTime,
			noteData: lmfao,
			noteType: this.noteType,
			holdLength: this.sustainLength
		};

		return converted;
	}
}
