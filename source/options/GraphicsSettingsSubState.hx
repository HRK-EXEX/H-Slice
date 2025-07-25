package options;

import objects.Character;
import options.Option;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	var fpsOption:Option;
	var syncOption:Option;

	public function new()
	{
		title = Language.getPhrase('graphics_menu', 'Graphics Settings');
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function (name:String) boyfriend.dance();
		boyfriend.visible = false;

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			BOOL); //Variable type
		addOption(option);

		var option:Option = new Option('Anti-Aliasing', //Name
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.', //Description
			'antialiasing',
			BOOL);
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);
		antialiasingOption = optionsArray.length-1;

		var option:Option = new Option('Shaders', //Name
			"If unchecked, disables shaders.\nIt's used for some visual effects, and also CPU intensive for weaker " + Main.platform + ").", //Description
			'shaders',
			BOOL);
		addOption(option);

		var option:Option = new Option('Note Shaders', //Name
			"If unchecked, disables note shaders.\nPlease use the noteSkin older than psych v0.6.x!", //Description
			'noteShaders',
			BOOL);
		addOption(option);

		var option:Option = new Option('Multithreaded Caching', //Name
		"If checked, enables multithreaded loading, which improves loading times but with a low chance for the game to freeze while loading a song.", //Description
		'cacheOnCPU',
		BOOL);
		addOption(option);
		
		var option:Option = new Option('GPU Caching', //Name
			"If checked, allows the GPU to be used for caching textures,\ndecreasing RAM usage. Don't turn this on if you have a shitty Graphics Card.", //Description
			'cacheOnGPU',
			BOOL);
		addOption(option);

		#if sys
		var option:Option = new Option('VSync', //Name
			'If checked, it enables VSync, fixing any screen tearing\nat the cost of capping the FPS to screen refresh rate.',
			'vsync',
			BOOL);
		option.onChange = onChangeVSync;
		addOption(option);
		syncOption = option;
		#end

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			INT);
		addOption(option);

		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 10;
		option.maxValue = 1000;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		fpsOption = option;
		#end

		super();
		insert(1, boyfriend);
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:FlxSprite = cast sprite;
			if(sprite != null && (sprite is FlxSprite)) {
				sprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	function onChangeFramerate()
	{
		fpsOption.scrollSpeed = interpolate(30, 1000, (holdTime - 0.5) / 5, 3);
		if(ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}
	
	#if sys
	function onChangeVSync()
	{
		// #if linux
		var file:String = StorageUtil.rootDir + "vsync.txt";
		if(FileSystem.exists(file))
			FileSystem.deleteFile(file);
		File.saveContent(file, Std.string(ClientPrefs.data.vsync));
		// #else
		FlxG.stage.application.window.vsync = syncOption.getValue();
		// #end
	}
	#end

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		boyfriend.visible = (antialiasingOption == curSelected);
	}
}