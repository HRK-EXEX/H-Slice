package options;

import objects.HealthIcon;
import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;
import objects.Alphabet;
import options.Option;

import debug.FPSCounter;

class VisualsSettingsSubState extends BaseOptionsMenu
{
	public static var pauseMusics:Array<String> = ['None', 'Tea Time', 'Breakfast', 'Breakfast (Pico)', 'Breakfast (Pixel)'];
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<NoteSplash>;
	var noteY:Float = 90;
	var fpsRateOption:Option;
	var splashOption:Option;
	var bfIcon:HealthIcon;
	var iconOption:Option;
	
	var notesShown:Bool = false;
	var iconShown:Bool = false;

	public function new()
	{
		title = Language.getPhrase('visuals_menu', 'Visuals Settings');
		rpcTitle = 'Visuals Settings Menu'; //for Discord Rich Presence

		if (!OptionsState.onPlayState)
			Conductor.bpm = 102;

		// for note skins and splash skins
		notes = new FlxTypedGroup<StrumNote>();
		splashes = new FlxTypedGroup<NoteSplash>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0);
			changeNoteSkin(note);
			notes.add(note);
			
			var splash:NoteSplash = new NoteSplash();
			splash.babyArrow = note;
			splash.loadSplash();
			splash.visible = true;
			splash.alpha = ClientPrefs.data.splashAlpha;
			splash.animation.finishCallback = name -> splash.kill();
			splash.rgbShader.enabled = ClientPrefs.data.noteShaders;
			splash.kill();
			splashes.add(splash);
			
			if (splash.rgbShader.enabled) {
				Note.initializeGlobalRGBShader(i % Note.colArray.length);
				splash.rgbShader.copyValues(Note.globalRgbShaders[i % Note.colArray.length]);
			}
		}

		// options
		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if(noteSkins.length > 0)
		{
			if(!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; //Reset to default if saved noteskin couldnt be found

			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin); //Default skin always comes first
			var option:Option = new Option('Note Skins:',
				"Select your preferred Note skin.",
				'noteSkin',
				STRING,
				noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			splashOption = option;
			noteOptionID = optionsArray.length - 1;
		}
		
		if (PlayState.SONG != null) PlayState.SONG.splashSkin = null; // Fix this component not working when entering from a song!
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if(noteSplashes.length > 0)
		{
			if(!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin; //Reset to default if saved splashskin couldnt be found

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin); //Default skin always comes first
			var option:Option = new Option('Note Splashes:',
				"Select your preferred Note Splash variation or turn it off.",
				'splashSkin',
				STRING,
				noteSplashes);
			addOption(option);
			option.onChange = onChangeSplashSkin;
		}

		// HealthIcon for Bopping
		bfIcon = new HealthIcon("bf", true);
		bfIcon.x = FlxG.width + 100;
		bfIcon.y = FlxG.height / 3;

		var option:Option = new Option('Note Splash Opacity',
			'How transparent should the Note Splashes be?',
			'splashAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.01;
		option.decimals = 2;
		addOption(option);
		option.onChange = playNoteSplashes;

		var option:Option = new Option('Note Splash Count:',
			'How many Note Splashes should spawn every note hit?\n0 = No Limit.',
			'splashCount',
			INT);
		option.scrollSpeed = 30;
		option.minValue = 0;
		option.maxValue = 15;
		option.changeValue = 1;
		addOption(option);
		option.onChange = playNoteSplashes;

		var holdSkins:Array<String> = Mods.mergeAllTextsNamed('images/holdCovers/list.txt');
		if(holdSkins.length > 0)
		{
			if(!holdSkins.contains(ClientPrefs.data.holdSkin))
				ClientPrefs.data.holdSkin = ClientPrefs.defaultData.holdSkin; //Reset to default if saved splashskin couldnt be found
			holdSkins.remove(ClientPrefs.defaultData.holdSkin);
			holdSkins.insert(0, ClientPrefs.defaultData.holdSkin); //Default skin always comes first
			var option:Option = new Option('Hold Splashes:',
				"Select your preferred Hold Splash variation or turn it off.",
				'holdSkin',
				STRING,
				holdSkins);
			addOption(option);
		}

		var option:Option = new Option('Note Hold Splash Opacity',
			'How transparent should the Note Hold Splash be?\n0% = = Disabled.',
			'holdSplashAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.01;
		option.decimals = 2;
		addOption(option);

		var option:Option = new Option('Opponent Note Splash',
			'If checked, Note Splash appears in Opponent Strum.',
			'splashOpponent',
			BOOL);
		addOption(option);

		var option:Option = new Option('Strum Animation',
			'If checked, the light-up animation of the strums will play every time a note is hit.',
			'strumAnim',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Play Animation on Sustain Hit',
			"If unchecked, the animaiton when sustain notes are hit will not play.",
			'holdAnim',
			BOOL);
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			BOOL);
		addOption(option);

		var option:Option = new Option('Three Digits Delimiter',
			'If checked, it will improves the visibility of large numbers, such as 1000 or more.',
			'numberFormat',
			BOOL);
		addOption(option);

		var option:Option = new Option('Show Info:',
			"If checked, the game will show the selected infomation on screen.\nMainly for Debug.",
			'showInfoType',
			STRING,
			[
				'None',
				'Notes Per Second',
				'Rendered Notes',
				'NPS & Rendered',
				'Note Splash Counter',
				'Note Spawn Time',
				'Video Info',
				'Note Info',
				'Strums Info',
				'Song Info',
				'Music Sync Info',
				'Debug Info',
			]);
		addOption(option);
		
		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType',
			STRING,
			[
				'Time Left',
				'Time Elapsed',
				'Song Name',
				'Disabled'
			]);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			BOOL);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			BOOL);
		addOption(option);

		var option:Option = new Option('Score Text Grow on Hit',
			"If unchecked, disables the Score text growing\neverytime you hit a note.",
			'scoreZoom',
			BOOL);
		addOption(option);

		var option:Option = new Option('Health Bar Opacity',
			'How transparent should the Health Bar and icons be?',
			'healthBarAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.01;
		option.decimals = 2;
		addOption(option);

		var option:Option = new Option('Icon Bop Type:',
			'Select icon bop animation on a beat hit.',
			'iconBopType',
			STRING,
			[
				'Default',
				'Horizontal',
				'Vertical',
				'Drill',
				'HRK Style',
				'None'
			]);
		iconOption = option;
		addOption(option);
			
		var option:Option = new Option('Icon Strength on HP',
			'If checked, Icon bopping depends current HP.',
			'iconStrength',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			BOOL);
		addOption(option);
		option.onChange = onChangeFPSCounter;
		
		var option:Option = new Option('- Memory Usage',
			'If checked, shows Memory Usage, From Left to Right,\nOverall usage, Garbage Collector Usage, Maximum usage.',
			'showMemory',
			BOOL);
		addOption(option);
		option.onChange = onChangeFPSCounterHeight;
		
		var option:Option = new Option('- Maximum Memory Usage',
			'If checked, shows Maximum Memory Usage.',
			'showPeakMemory',
			BOOL);
		addOption(option);
		option.onChange = onChangeFPSCounterHeight;
		
		var option:Option = new Option('- OS Infomation',
			'If checked, shows OS Infomation.',
			'showOS',
			BOOL);
		addOption(option);
		option.onChange = onChangeFPSCounterHeight;
		
		var option:Option = new Option('FC - Update Rate',
			"How fast will the FPS Counter Update?",
			'fpsRate',
			INT);
		option.defaultValue = 1;
		option.scrollSpeed = 30;
		option.minValue = 1;
		option.maxValue = 1000;
		option.changeValue = 1;
		option.decimals = 0;
		option.onChange = onChangeFPSRate;
		addOption(option);
		fpsRateOption = option;

		var option:Option = new Option('Pause Music:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			STRING,
			pauseMusics);
		addOption(option);
		option.onChange = onChangePauseMusic;

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord",
			'discordRPC',
			BOOL);
		addOption(option);
		#end

		var option:Option = new Option('Time Text Precisions',
			"You can set the decimal places to be displayed.\nMin to Second, Max to Microsecond.",
			'timePrec',
			INT);
		option.defaultValue = 1;
		option.scrollSpeed = 20;
		option.minValue = 0;
		option.maxValue = 6;
		option.changeValue = 1;
		option.decimals = 0;
		addOption(option);

        var option:Option = new Option('Show Rating Pop-Up',
			"If checked, \"Rating Pop-Up\" shows up every time you hit notes.\nUnchecking reduces a little bit of memory usage.",
			'showRating',
			BOOL);
		addOption(option);

		var option:Option = new Option('Show Combo Number Pop-Up',
			"If checked, \"Combo Number Pop-Up\" shows up every time you hit notes.\nUnchecking reduces a little bit of memory usage.",
			'showComboNum',
			BOOL);
		addOption(option);

		var option:Option = new Option('Show Combo Pop-Up',
			"If checked, \"Combo Pop-Up\" shows up every time you hit notes.\n(I don't think anyone checks this option)",
			'showCombo',
			BOOL);
		addOption(option);

		var option:Option = new Option('Pop-Up Stacking',
			"If unchecked, score pop-ups won't stack,\nbut the game now uses a recycling system,\nso it doesn't have a huge effect anymore.",
			'comboStacking',
			BOOL);
		addOption(option);

		var option:Option = new Option('Combo <-> Notes',
			"If checked, the score pop-up become a note counter instead combo.\nIt counts both opponent and player note hits.",
			'changeNotes',
			BOOL);
		addOption(option);

		super();
		add(notes);
		add(splashes);
		add(bfIcon);
	}

	var lastSelected:Int = -1;
	override function changeSelection(change:Float,usePrecision:Bool = false)
	{
		super.changeSelection(change,usePrecision);
		if(lastSelected == curSelected) return;
		else lastSelected = curSelected;

		switch(curOption.variable)
		{
			case 'noteSkin', 'splashSkin', 'splashAlpha', 'splashCount':
				if (!notesShown)
				{
					for (note in notes.members)
					{
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = true;
				if(curOption.variable.startsWith('splash') && Math.abs(notes.members[0].y - noteY) < 25) playNoteSplashes();

			case 'iconBopType':
				if (!iconShown)
				{
					FlxTween.cancelTweensOf(bfIcon);
					FlxTween.tween(bfIcon, {x: FlxG.width - 250}, 0.25, {ease: FlxEase.quadInOut});
				}
				iconShown = true;

			default:
				if (notesShown) 
				{
					for (note in notes.members)
					{
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = false;
				
				if (iconShown)
				{
					FlxTween.cancelTweensOf(bfIcon);
					FlxTween.tween(bfIcon, {x: FlxG.width + 100}, 0.125, {ease: FlxEase.quadInOut});
				}
				iconShown = false;
		}
	}

	override function beatHit() {
		super.beatHit();
		if (iconOption.getValue() == "None") return;

		var multX:Float = 0;
		var multY:Float = 0;
		var angle:Float = 0;

		bfIcon.angle = 0;
		switch (iconOption.getValue()) {
			case 'Default':
				multX = multY = 1.2;
			case 'Horizontal':
				multX = 1.2;
				multY = 0.6;
			case 'Vertical':
				multX = 0.6;
				multY = 1.2;
			case 'Drill':
				multX = 1.6;
				multY = 0.8;
				angle = 25;
			case 'HRK Style':
				if (curBeat % 2 == 1) {
					multX = 1.2;
					multY = 1.2;
					angle = -20;
				} else {
					multX = 1.5;
					multY = 1.2;
					angle = 30;
				}
		}
		
		bfIcon.scale.set(multX, multY);
		bfIcon.angle = -angle;
	}

	var iconBopTime:Float;
	var iconAngleTime:Float;
	var iconBopMultX:Float;
	var iconBopMultY:Float;
	var iconBopAngle:Float;
	override function update(elapsed:Float) {
		iconBopTime = Math.exp(-Conductor.bpm / 24 * elapsed);
		iconAngleTime = Math.exp(-Conductor.bpm / 12 * elapsed);

		iconBopMultX = FlxMath.lerp(1, bfIcon.scale.x, iconBopTime);
		iconBopMultY = FlxMath.lerp(1, bfIcon.scale.y, iconBopTime);
		iconBopAngle = FlxMath.lerp(0, bfIcon.angle, iconAngleTime);

		bfIcon.scale.set(iconBopMultX, iconBopMultY);
		bfIcon.angle = iconBopAngle;
		bfIcon.updateHitbox();
		
		Conductor.songPosition += elapsed;
		if (Math.abs(FlxG.sound.music.time - Conductor.songPosition) > 20)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), ClientPrefs.data.bgmVolume);

		changedMusic = true;
	}

	function onChangeNoteSkin()
	{
		notes.forEachAlive(function(note:StrumNote) {
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
		});
	}

	function changeNoteSkin(note:StrumNote)
	{
		var skin:String = Note.DEFAULT_NOTE_SKIN;
		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		note.texture = skin; //Load texture and anims
		note.reloadNote();
		note.playAnim('static');
	}

	function onChangeSplashSkin()
	{
		var skin:String = NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
		for (splash in splashes)
			splash.loadSplash(skin);

		playNoteSplashes();
	}
	
	function playNoteSplashes()
	{
		var rand:Int = 0;
		if (splashes.members[0] != null && splashes.members[0].maxAnims > 1)
			rand = FlxG.random.int(0, splashes.members[0].maxAnims - 1); // For playing the same random animation on all 4 splashes

		for (index => splash in splashes)
		{
			splash.revive();
			var anim:String = splash.playDefaultAnim(splash.texture.toLowerCase().contains('classic') ? index : 0);
			var conf = splash.config.animations.get(anim);
			var offsets:Array<Float> = [0, 0];

			var minFps:Int = 22;
			var maxFps:Int = 26;
			if (conf != null)
			{
				offsets = conf.offsets;

				minFps = conf.fps[0];
				if (minFps < 0) minFps = 0;

				maxFps = conf.fps[1];
				if (maxFps < 0) maxFps = 0;
			}

			splash.offset.set(10, 10);
			if (offsets != null)
			{
				splash.offset.x += offsets[0];
				splash.offset.y += offsets[1];
			}

			if (splash.animation.curAnim != null)
				splash.animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}

	override function destroy()
	{
		if(changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music('freakyMenu'), ClientPrefs.data.bgmVolume, true);
		super.destroy();
	}

	function onChangeFPSCounter()
	{
		if (Main.fpsVar != null) Main.fpsVar.visible = ClientPrefs.data.showFPS;
		if (Main.fpsBg != null) Main.fpsBg.visible = ClientPrefs.data.showFPS;
	}
	
	function onChangeFPSCounterHeight()
	{
		Main.fpsBg.relocate(0, 0, ClientPrefs.data.wideScreen);
	}

	function onChangeFPSRate()
	{
		var rate:Null<Float> = fpsRateOption.getValue();
		fpsRateOption.scrollSpeed = interpolate(30, 50000, (holdTime - 0.5) / 10, 3);
		if (rate != null) FPSCounter.instance.updateRate = rate;
		else FPSCounter.instance.updateRate = 1;
	}
}
