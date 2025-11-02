package substates;

import mikolka.vslice.freeplay.FreeplayState as NewFreeplayState;
import states.FreeplayState;
import mikolka.funkin.custom.mobile.MobileScaleMode;
#if TOUCH_CONTROLS_ALLOWED
import mobile.objects.TouchZone;
import mobile.objects.ScrollableObject;
#end
import backend.WeekData;
import backend.Highscore;
import backend.Song;
import flixel.util.FlxStringUtil;
import flixel.addons.transition.FlxTransitionableState;
import mikolka.vslice.StickerSubState;
import options.OptionsState;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = [
		'Resume',
		'Restart Song',
		#if TOUCH_CONTROLS_ALLOWED 'Chart Editor', #end
		'Change Difficulty',
		'Options',
		'Exit to menu'
	];
	var difficultyChoices = [];
	var curSelected:Int = 0;
	var curSelectedPartial:Float = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var inVid:Bool;

	public var cutscene_allowSkipping = true;
	public var cutscene_hardReset = true;
	public var cutscene_type = true;
	public var specialAction:PauseSpecialAction = PauseSpecialAction.NOTHING;

	var cutscene_branding:String = 'lol';
	var cutscene_resetTxt:String = 'lol';
	var cutscene_skipTxt:String = 'lol';

	public static var songName:String = null;
	var pSte:PlayState;

	public function new(inCutscene:Bool = false, type:PauseType = PauseType.CUTSCENE)
	{
		super();
		cutscene_branding = switch (type)
		{
			case VIDEO: Language.getPhrase("pause_branding_video", "Video");
			case CUTSCENE: Language.getPhrase("pause_branding_cutscene", "Cutscene");
			case DIALOGUE: Language.getPhrase("pause_branding_dialogue", "Dialogue");
		};
		cutscene_resetTxt = Language.getPhrase("pause_branding_restart", 'Restart {1}', [cutscene_branding]);
		cutscene_skipTxt = Language.getPhrase("pause_branding_skip", 'Skip {1}', [cutscene_branding]);
		this.inVid = inCutscene;
	}

	override function create()
	{
		pSte = PlayState.instance;
		controls.isInSubstate = true;
		if (Difficulty.list.length < 2)
			menuItemsOG.remove('Change Difficulty'); // No need to change difficulty if there is only one!

		var num:Int = 0;
		if(!pSte.startingSong)
		{
			num = 1;
			menuItemsOG.insert(PlayState.chartingMode ? 3 : 2, 'Skip Time');
		}

		if(PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
			
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}

		if (inVid)
		{
			menuItems = ['Resume', cutscene_resetTxt, cutscene_skipTxt, 'Options', 'Exit to menu'];
			if (!cutscene_allowSkipping) menuItems.remove(cutscene_skipTxt);
		} else menuItems = menuItemsOG;

		for (i in 0...Difficulty.list.length)
		{
			var diff:String = Difficulty.getString(i);
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if (pauseSong != null)
				pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		catch (e:Dynamic)
		{
			trace("No pause music!");
		}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.SONG.song, 32);
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		levelInfo.antialiasing = ClientPrefs.data.antialiasing;
		levelInfo.alpha = 0;
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, Language.getPhrase("pause_difficulty", "Difficulty: {1}", [CoolUtil.capitalize(Difficulty.getString())]), 32);
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		levelDifficulty.antialiasing = ClientPrefs.data.antialiasing;
		levelDifficulty.alpha = 0;
		add(levelDifficulty);
		
		var ballsTxt = inVid ? Language.getPhrase("pause_branding", '{1} Paused', [cutscene_branding]) : 
			Language.getPhrase("blueballed", "{1} Blue Balls", [PlayState.deathCounter]);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, ballsTxt, 32);
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		blueballedTxt.antialiasing = ClientPrefs.data.antialiasing;
		blueballedTxt.alpha = 0;
		add(blueballedTxt);

		practiceText = new FlxText(20, 15 + 101, 0, Language.getPhrase("Practice Mode").toUpperCase(), 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.visible = pSte.practiceMode;
		practiceText.antialiasing = ClientPrefs.data.antialiasing;
		practiceText.alpha = 0;
		add(practiceText);

		var chartingText:FlxText = new FlxText(20, 15 + 101, 0, Language.getPhrase("Charting Mode").toUpperCase(), 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.font('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 20);
		chartingText.updateHitbox();
		chartingText.visible = PlayState.chartingMode;
		chartingText.antialiasing = ClientPrefs.data.antialiasing;
		chartingText.alpha = 0;
		add(chartingText);

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		if (chartingText.visible) {
			FlxTween.tween(chartingText, {alpha: 1, y: chartingText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});
		}

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		missingTextBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		missingTextBG.scale.set(FlxG.width, FlxG.height);
		missingTextBG.updateHitbox();
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		missingText.antialiasing = ClientPrefs.data.antialiasing;
		add(missingText);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad(menuItems.contains('Skip Time') ? 'LEFT_FULL' : 'UP_DOWN', 'A');
		addTouchPadCamera();

		var button = new TouchZone(85, 300, 1000, 100, FlxColor.PURPLE);
		button.cameras = cameras;
		var scroll = new ScrollableObject(-0.008, 100, 0, FlxG.width - 200, FlxG.height, button);
		scroll.cameras = cameras;
		scroll.onPartialScroll.add(delta -> changeSelection(delta, false));
		scroll.onFullScrollSnap.add(() -> changeSelection(0, true));
		scroll.onTap.add(() ->
		{
			var daSelected:String = menuItems[curSelected];
			onAccept(daSelected);
		});
		add(scroll);
		add(button);
		#end

		super.create();
	}

	function getPauseSong()
	{
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
		if (formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none'))
			return null;

		return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;

	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		if (controls.BACK)
		{
			specialAction = RESUME;
			close();
			return;
		}

		if (FlxG.keys.justPressed.F5)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			PlayState.nextReloadAll = true;
			MusicBeatState.resetState();
		}

		updateSkipTextStuff();
		if (controls.UI_UP_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			changeSelection(-1, true);
		}
		if (controls.UI_DOWN_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			changeSelection(1, true);
		}

		var daSelected:String = menuItems[curSelected];

		switch (daSelected)
		{
			case 'Skip Time':
				skipTimeText.visible = true;
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.sfxVolume);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.sfxVolume);
					curTime += 1000;
					holdTime = 0;
				}
				if (controls.ACCEPT)
					onAccept(daSelected);

				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if (holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if (curTime >= FlxG.sound.music.length)
						curTime -= FlxG.sound.music.length;
					else if (curTime < 0)
						curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
			default:
				if (skipTimeText != null) skipTimeText.visible = false;
				if (controls.ACCEPT)
					onAccept(daSelected);
		}

		#if TOUCH_CONTROLS_ALLOWED
		if (touchPad == null) // sometimes it dosent add the tpad, hopefully this fixes it
		{
			addTouchPad(PlayState.chartingMode ? 'LEFT_FULL' : 'UP_DOWN', 'A');
			addTouchPadCamera();
		}
		#end
	}

	function onAccept(selectedOption:String)
	{
		if (cantUnpause <= 0)
		{
			if (menuItems == difficultyChoices)
			{
				var songLowercase:String = Paths.formatToSongPath(PlayState.SONG.song);
				var useErect = FreeplayMeta.getMeta(songLowercase).allowErectVariants;
				if(useErect){
					var curDiffText = selectedOption;
					if(songLowercase.endsWith("-erect") && curDiffText != "Erect" && curDiffText != "Nightmare"){
						//not nightmare anymore
						songLowercase = songLowercase.substring(0,songLowercase.length-"-erect".length);
					}
					else if(!songLowercase.endsWith("-erect") && (curDiffText == "Erect" || curDiffText == "Nightmare")){
						//now it's nightmare
						songLowercase = songLowercase+"-erect";
					}
				}
				var poop:String = Highscore.formatSong(songLowercase, curSelected);
				try
				{
					if (menuItems.length - 1 != curSelected && difficultyChoices.contains(selectedOption))
					{
						Song.loadFromJson(poop, false, songLowercase);
						PlayState.storyDifficulty = curSelected;
						MusicBeatState.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
						PlayState.unspawnNotes = [];
						return;
					}
				}
				catch (e:haxe.Exception)
				{
					trace('ERROR! ${e.message}');

					var errorStr:String = e.message;
					if (errorStr.startsWith('[lime.utils.Assets] ERROR:'))
						errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length - 1); // Missing chart
					else
						errorStr += '\n\n' + e.stack;

					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'), ClientPrefs.data.sfxVolume);

					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}
			PlayState.canResync = false;
			
			switch (selectedOption)
			{
				case "Resume":
					Paths.clearUnusedMemory();
					specialAction = RESUME;
					PlayState.canResync = true;
					close();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					deleteSkipTimeText();
					regenMenu();
				case 'Toggle Practice Mode':
					pSte.practiceMode = !pSte.practiceMode;
					PlayState.changedDifficulty = true;
					practiceText.visible = pSte.practiceMode;
					if (practiceText.visible) {
						FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});
					}
				case "Restart Song":
					restartSong();
				case 'Chart Editor':
					PlayState.instance.openChartEditor();
					PlayState.unspawnNotes = [];
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				case 'Skip Time':
					PlayState.startOnTime = curTime;
					restartSong(true);
				case 'End Song':
					close();
					pSte.notes.clear();
					PlayState.unspawnNotes = [];
					pSte.finishSong(true);
				case 'Toggle Botplay':
					pSte.cpuControlled = !pSte.cpuControlled;
					PlayState.changedDifficulty = true;
					pSte.botplayTxt.visible = pSte.cpuControlled;
					pSte.botplayTxt.alpha = 1;
					pSte.botplaySine = 0;
				case 'Options':
					pSte.paused = true; // For lua
					
					if (pSte.bfVocal) pSte.vocals.volume = 0;
					if (pSte.opVocal) pSte.opponentVocals.volume = 0;

					MusicBeatState.switchState(new OptionsState());
					if (ClientPrefs.data.pauseMusic != 'None')
					{
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: ClientPrefs.data.bgmVolume}, 0.8);
						FlxG.sound.music.time = pauseMusic.time;

						Conductor.bpm = switch (ClientPrefs.data.pauseMusic) {
							case 'Tea Time': 105.0;
							case 'Breakfast': 160.0;
							case 'Breakfast (Pico)': 88.0;
							case 'Breakfast (Pixel)': 160.0;
							default: Conductor.bpm;
						}
					} else {
						FlxG.sound.music.resume();
						FlxTween.tween(FlxG.sound.music, {volume: ClientPrefs.data.bgmVolume}, 0.8);
						FlxG.sound.music.looped = true;
					}
					OptionsState.onPlayState = true;
				case "Exit to menu":
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					//! not yet
					Mods.loadTopMod();
					if (PlayState.isStoryMode)
					{
						PlayState.storyPlaylist = [];
						openSubState(new StickerSubState(null, (sticker) -> new StoryMenuState(sticker)));
					}
					else
					{
						if (ClientPrefs.data.vsliceFreeplay) {
							FlxTransitionableState.skipNextTransIn = true;
							FlxTransitionableState.skipNextTransOut = true;
							openSubState(new StickerSubState(null, (sticker) -> NewFreeplayState.build(null, sticker)));
						} else {
							FlxTransitionableState.skipNextTransIn = false;
							FlxTransitionableState.skipNextTransOut = false;
							MusicBeatState.switchState(new FreeplayState());
							FlxG.sound.playMusic(Paths.music('freakyMenu'), ClientPrefs.data.bgmVolume);
						}
					}
					
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
					PlayState.unspawnNotes = [];
				default:
					if (selectedOption == cutscene_skipTxt)
					{
						specialAction = SKIP;
						close();
					}
					else if (selectedOption == cutscene_resetTxt)
					{
						if (cutscene_hardReset)
							restartSong();
						else
						{
							specialAction = RESTART;
							close();
						}
					}
			}
		}
		
		if (ClientPrefs.data.nanoPosition) PlayState.nanoTime = CoolUtil.getNanoTime();
		
		#if TOUCH_CONTROLS_ALLOWED
		if (touchPad == null) //sometimes it dosent add the tpad, hopefully this fixes it
		{
			addTouchPad(PlayState.chartingMode ? 'LEFT_FULL' : 'UP_DOWN', 'A');
			addTouchPadCamera();
		}
		#end
	}

	function deleteSkipTimeText()
	{
		if (skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false)
	{
		var pSte = PlayState.instance;
		pSte.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		if (pSte.bfVocal) pSte.vocals.volume = 0;
		if (pSte.opVocal) pSte.opponentVocals.volume = 0;

		if (noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

	override function destroy()
	{
		controls.isInSubstate = false;
		pauseMusic.destroy();
		super.destroy();
	}

	function changeSelection(delta:Float, usePrecision:Bool = false)
	{
		if (usePrecision)
		{
			if(delta != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curSelected = FlxMath.wrap(curSelected + Std.int(delta), 0, menuItems.length - 1);
			curSelectedPartial = curSelected;
		}
		else
		{
			curSelectedPartial = FlxMath.bound(curSelectedPartial + delta, 0, menuItems.length - 1);
			if(curSelected != Math.round(curSelectedPartial)) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curSelected = Math.round(curSelectedPartial);
		}
		for (num => item in grpMenuShit.members)
		{
			item.targetY = num - curSelectedPartial;
			item.alpha = 0.6;
			if (num == curSelected)
			{
				item.alpha = 1;
				if (item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
		missingText.visible = false;
		missingTextBG.visible = false;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4 * ClientPrefs.data.sfxVolume);
	}

	function regenMenu():Void
	{
		for (i in 0...grpMenuShit.members.length)
		{
			var obj:Alphabet = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}
		var cutoutSize = MobileScaleMode.gameCutoutSize.x / 2;
		for (num => str in menuItems)
		{
			var item = new Alphabet(cutoutSize+90, 320, Language.getPhrase('pause_$str', str), true);
			item.isMenuItem = true;
			item.targetY = num;
			grpMenuShit.add(item);

			if (str == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeText.antialiasing = ClientPrefs.data.antialiasing;
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		curSelected = 0;
		changeSelection(0, true);
	}

	function updateSkipTextStuff()
	{
		if (skipTimeText == null || skipTimeTracker == null)
			return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
	}

	function updateSkipTimeText() {
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false)
			 + ' / '
			 + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}

enum PauseSpecialAction
{
	NOTHING;
	RESTART;
	SKIP;
	RESUME;
}

enum PauseType
{
	VIDEO;
	CUTSCENE;
	DIALOGUE;
}
