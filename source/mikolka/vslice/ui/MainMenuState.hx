package mikolka.vslice.ui;

import mikolka.vslice.ui.mainmenu.DesktopMenuState;
import mikolka.compatibility.ui.MainMenuHooks;
import mikolka.compatibility.VsliceOptions;
import mikolka.compatibility.ModsHelper;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
	#if !LEGACY_PSYCH
	public static var psychEngineVersion:String = '1.0.4'; // This is also used for Discord RPC
	#else
	public static var psychEngineVersion:String = '0.6.3'; // This is also used for Discord RPC
	#end
	public static var pSliceVersion:String = '3.3.1';
	public static var funkinVersion:String = '0.7.4'; // Version of funkin' we are emulationg
	public static var hrkVersion:String = '0.2.2'; // Version of H-Slice
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	var bg:FlxSprite;
	var magenta:FlxSprite;
	public function new(isDisplayingRank:Bool = false) {
		//TODO
		super();
	}
	
	override function create()
	{
		ModsHelper.clearStoredWithoutStickers();
		Paths.clearUnusedMemory();

		ModsHelper.resetActiveMods();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Main Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = VsliceOptions.ANTIALIASING;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = VsliceOptions.ANTIALIASING;
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		var padding:Float = 8;
		var hrkVer:FlxText = new FlxText(padding, FlxG.height - 78 - padding, FlxG.width, 'H-Slice v' + hrkVersion, 12);
		var psliceVer:FlxText = new FlxText(padding, FlxG.height - 58 - padding, FlxG.width, 'P-Slice v${pSliceVersion}', 12);
		var psychVer:FlxText = new FlxText(padding, FlxG.height - 38 - padding, FlxG.width, 'Psych Engine v' + psychEngineVersion, 12);
		var fnfVer:FlxText = new FlxText(padding, FlxG.height - 18 - padding, FlxG.width, 'Friday Night Funkin\' v${funkinVersion}', 12);

		hrkVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		psliceVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		hrkVer.scrollFactor.set();
		psliceVer.scrollFactor.set();
		psychVer.scrollFactor.set();
		fnfVer.scrollFactor.set();
		
		hrkVer.antialiasing = ClientPrefs.data.antialiasing;
		psliceVer.antialiasing = ClientPrefs.data.antialiasing;
		psychVer.antialiasing = ClientPrefs.data.antialiasing;
		fnfVer.antialiasing = ClientPrefs.data.antialiasing;

		add(hrkVer);
		add(psliceVer);
		add(psychVer);
		add(fnfVer);

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			MainMenuHooks.unlockFriday();

		#if MODS_ALLOWED
		MainMenuHooks.reloadAchievements();
		#end
		#end

		super.create();
		#if TOUCH_CONTROLS_ALLOWED
		if (controls.mobileC)
			new mobile.states.MobileMenuState(this);
		else
		#end
		new DesktopMenuState(this);
	}
	
	function goToOptions()
	{
		MusicBeatState.switchState(new OptionsState());
		#if !LEGACY_PSYCH OptionsState.onPlayState = false; #end
		if (PlayState.SONG != null)
		{
			PlayState.SONG.arrowSkin = null;
			PlayState.SONG.splashSkin = null;
			#if !LEGACY_PSYCH PlayState.stageUI = 'normal'; #end
		}
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;
		super.update(elapsed);
	}
}
