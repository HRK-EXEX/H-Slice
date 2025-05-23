package objects;

import cpp.CastCharStar;
import objects.Note.CastNote;
import backend.animation.PsychAnimationController;

import shaders.RGBPalette;

import states.editors.NoteSplashEditorState;



private typedef RGB = {
	r:Null<Int>,
	g:Null<Int>,
	b:Null<Int>
}

private typedef NoteSplashAnim = {
	name:String,
	noteData:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef NoteSplashConfig = {
	animations:Map<String, NoteSplashAnim>,
	scale:Float,
	allowRGB:Bool,
	allowPixel:Bool,
	rgb:Array<Null<RGB>>
}

class NoteSplash extends FlxSprite
{
	public var rgbShader:PixelSplashShaderRef;
	public var skin:String;
	public var config(default, set):NoteSplashConfig;

	public static var DEFAULT_SKIN:String = "noteSplashes/noteSplashes";
	public static var configs:Map<String, NoteSplashConfig> = new Map();

	public var babyArrow:StrumNote;
	public var noteData:Int = 0;
	private var noteAnim:Int = 0;
	var noteDataMap:Map<Int, String> = new Map();

	public function new(?splash:String)
	{
		super();

        animation = new PsychAnimationController(this);
		rgbShader = new PixelSplashShaderRef();
		shader = rgbShader.shader;

		loadSplash(splash);
	}

	public function loadSplash(?splash:String)
	{
		config = null; // Reset config to the default so when reloaded it can be set properly
		skin = null;

		var skin:String = splash;
		if (skin == null || skin.length < 1) {
			skin = PlayState.SONG?.splashSkin;
		}

		if (skin == null || skin.length == 0) {
			skin = DEFAULT_SKIN + getSplashSkinPostfix();
		} else if (skin.indexOf("/") < 0) skin = "noteSplashes/" + skin;

		this.skin = skin;

		try frames = Paths.getSparrowAtlas(skin) catch (e) {
			trace("splash skin not found");
			skin = DEFAULT_SKIN; // The splash skin was not found, return to the default
			this.skin = skin;
			try frames = Paths.getSparrowAtlas(skin) catch (e) {
				active = visible = false; kill();
			}
		}

		var path:String = 'images/$skin.json';
		if (configs.exists(path)) this.config = configs.get(path);
		else if (Paths.fileExists(path, TEXT))
		{
			var config:Dynamic = haxe.Json.parse(Paths.getTextFromFile(path));
			if (config != null)
			{
				var tempConfig:NoteSplashConfig = {
					animations: new Map(),
					scale: config.scale,
					allowRGB: config.allowRGB,
					allowPixel: config.allowPixel,
					rgb: config.rgb
				}

				for (i in Reflect.fields(config.animations))
				{
					tempConfig.animations.set(i, Reflect.field(config.animations, i));
				}

				this.config = tempConfig;
				configs.set(path, tempConfig);
			}
		}
	}

	var castNote:CastNote;
	public function spawnSplashNote(note:Note, ?noteData:Null<Int>, ?randomize:Bool = true)
	{	
		if (note != null && note.noteSplashData.texture != null)
			loadSplash(note.noteSplashData.texture);

		if (note != null && note.noteSplashData.disabled)
			return;

		if (babyArrow != null)
			setPosition(babyArrow.x, babyArrow.y); // To prevent it from being misplaced for one game tick

		if (noteData == null)
			noteData = note != null ? note.noteData : 0;

		if (randomize)
		{
			var anims:Int = 0;
			var datas:Int = 0;
			var animArray:Array<Int> = [];

			while (true)
			{
				var data:Int = noteData % Note.colArray.length + (datas * Note.colArray.length); 
				if (!noteDataMap.exists(data) || !animation.exists(noteDataMap[data]))
					break;

				datas++;
				anims++;
			}

			if (anims > 1)
			{
				for (i in 0...anims)
				{
					var data = noteData % Note.colArray.length + (i * Note.colArray.length);
					if (!animArray.contains(data))
						animArray.push(data);
				}
			}

			if (animArray.length > 1)
				noteAnim = animArray[FlxG.random.int(0, animArray.length - 1)];
		}

		this.noteData = noteData;
		var anim:String = playDefaultAnim();
		
		if (note != null) {
			alpha = note.noteSplashData.a - (1 - note.strum.alpha);
			antialiasing = note.noteSplashData.antialiasing;
		} else {
			alpha = ClientPrefs.data.splashAlpha;
			antialiasing = !PlayState.isPixelStage;
		}

		if(PlayState.isPixelStage) antialiasing = false;

		var tempShader:RGBPalette = null;
		if (config.allowRGB)
		{
			if (note == null) {
				castNote = cast {
					noteData: noteData
				};
				note = new Note().recycleNote(castNote);
				note.visible = false;
			}

			Note.initializeGlobalRGBShader(noteData % Note.colArray.length);
			function useDefault()
			{
				tempShader = Note.globalRgbShaders[noteData % Note.colArray.length];
			}

			if(((cast FlxG.state) is NoteSplashEditorState) || 
				((note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB)))
			{
				// If Note RGB is enabled:
				if((!note.noteSplashData.useGlobalShader || ((cast FlxG.state) is NoteSplashEditorState)))
				{
					var colors = config.rgb;
					if (colors != null)
					{
						tempShader = new RGBPalette();
						for (i in 0...colors.length)
						{
							if (i > 2) break;

							var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData % Note.colArray.length];
							if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[noteData % Note.colArray.length];

							var rgb = colors[i];
							if (rgb == null)
							{
								if (i == 0) tempShader.r = arr[0];
								else if (i == 1) tempShader.g = arr[1];
								else if (i == 2) tempShader.b = arr[2];
								continue;
							}

							var r:Null<Int> = rgb.r; 
							var g:Null<Int> = rgb.g;
							var b:Null<Int> = rgb.b;

							if (r == null || Math.isNaN(r) || r < 0) r = arr[0];
							if (g == null || Math.isNaN(g) || g < 0) g = arr[1];
							if (b == null || Math.isNaN(b) || b < 0) b = arr[2];

							var color:FlxColor = FlxColor.fromRGB(r, g, b);
							if (i == 0) tempShader.r = color;
							else if (i == 1) tempShader.g = color;
							else if (i == 2) tempShader.b = color;
						} 
					}
					else useDefault();
				}
				else useDefault();
			}
		}
		rgbShader.copyValues(tempShader);

		if(!config.allowPixel) rgbShader.pixelAmount = 1;

		var conf = config.animations.get(anim);
		var offsets:Array<Float> = [0, 0];

		if (conf != null)
			offsets = conf.offsets;

		if (offsets != null)
		{
			centerOffsets();
			offset.set(offsets[0], offsets[1]);
		}

		animation.finishCallback = function(name:String)
		{
			PlayState.instance != null ? killLimit() : kill();
		};

		if(animation.curAnim != null && conf != null)
		{
			var minFps = conf.fps[0];
			if (minFps < 0) minFps = 0;

			var maxFps = conf.fps[1];
			if (maxFps < 0) maxFps = 0;

			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}
	
	public function playDefaultAnim()
	{
		var animation:String = noteDataMap.get(noteAnim);
		if (animation != null && this.animation.exists(animation))
			this.animation.play(animation, true);
		else
			visible = false;
		return animation;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (babyArrow != null)
		{
			//cameras = babyArrow.cameras;
			setPosition(babyArrow.x, babyArrow.y);
		}
	}

    public static function getSplashSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '-');
		return skin;
	}

	public static function createConfig():NoteSplashConfig
	{
		return {
			animations: new Map(),
			scale: 1,
			allowRGB: true,
			allowPixel: true,
			rgb: null
		}
	}

	public static function addAnimationToConfig(config:NoteSplashConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>, indices:Array<Int>, noteData:Int):NoteSplashConfig
	{
		if (config == null) config = createConfig();

		config.animations.set(name, {name: name, noteData: noteData, prefix: prefix, indices: indices, offsets: offsets, fps: fps});
		config.scale = scale;
		return config;
	}

	function set_config(value:NoteSplashConfig):NoteSplashConfig 
	{
		if (value == null) value = createConfig();

		noteDataMap.clear();

		for (i in value.animations)
		{
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0)
			{
				if (i.indices != null && i.indices.length > 0 && key != null && key.length > 0)
					animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
				else
					animation.addByPrefix(key, i.prefix, i.fps[1], false);

				noteDataMap.set(i.noteData, key);
			}
		}

		// trace(noteDataMap.toString());

		scale.set(value.scale, value.scale);
		return config = value;
	}

	var before:Int; var after:Int;
	public function killLimit(targetId:Int = -1) {
		try {
			before = PlayState.splashUsing[noteData].length;
			if (targetId != -1) PlayState.splashUsing[noteData].splice(targetId, 1);
			else PlayState.splashUsing[noteData].splice(0, 1);
			after = PlayState.splashUsing[noteData].length;
			// trace("killed: " + before + " -> " + after);
		} catch (e) { trace("something went wrong? " + e.message); }
		kill();
	}

	override function kill() {
		super.kill();
	}
}

class PixelSplashShaderRef 
{
	public var shader:PixelSplashShader = new PixelSplashShader();
	public var enabled(default, set):Bool = true;
	public var pixelAmount(default, set):Float = 1;

	public function copyValues(tempShader:RGBPalette)
	{
		if(tempShader != null)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else enabled = false;
	}

	public function set_enabled(value:Bool)
	{
		enabled = value;
		shader.mult.value = [value ? 1 : 0];
		return value;
	}

	public function set_pixelAmount(value:Float)
	{
		pixelAmount = value;
		shader.uBlocksize.value = [value, value];
		return value;
	}

	public function reset()
	{
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
	}

	public function new()
	{
		reset();
		enabled = true;

		if(!PlayState.isPixelStage) pixelAmount = 1;
		else pixelAmount = PlayState.daPixelZoom;
		//trace('Created shader ' + Conductor.songPosition);
	}
}

class PixelSplashShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header

		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if(color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;

			color = mix(color, newColor, mult);

			if(color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')

	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')

	public function new()
	{
		super();
	}
}