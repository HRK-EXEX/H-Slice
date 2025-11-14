package options;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import mikolka.vslice.components.crash.UserErrorSubstate;
import backend.StageData;
import flixel.FlxObject;
#if (target.threaded)
import sys.thread.Mutex;
import sys.thread.Thread;
#end

#if android
import mobile.options.MobileOptionsSubState;
#end

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		#if (desktop && !mac) 'Video Rendering', #end
		'Optimizations',
		'Graphics',
		'Visuals',
		'Gameplay',
		'P-Slice Options',
		#if (TOUCH_CONTROLS_ALLOWED || mobile) 'Mobile Options', #end
		'Export & Import Settings'
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	private static var curSelectedPartial:Float = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	var exiting:Bool = false;
	#if (target.threaded) var mutex:Mutex = new Mutex(); #end

	private var mainCam:FlxCamera;
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;
	public static var funnyCam:FlxCamera;

	function openSelectedSubstate(label:String) {
		if (label != "Adjust Delay and Combo")
			persistentUpdate = false;

		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesColorSubState());
			case 'Controls':
				if (controls.mobileC)
				{
					funnyCam.visible = persistentUpdate = true;
					UserErrorSubstate.makeMessage("Unsupported controls", 
					"You don't need to go there on mobile!\n\nIf you wish to go there anyway\nSet 'Mobile Controls Opacity' to 0%");
				}
				else
					openSubState(new options.ControlsSubState());
			#if desktop
			case 'Video Rendering':
				openSubState(new options.GameRendererSettingsSubState());
			#end
			case 'Optimizations':
				openSubState(new options.OptimizeSettingsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'P-Slice Options':
				openSubState(new BaseGameSubState());
			#if (TOUCH_CONTROLS_ALLOWED || mobile)
			case 'Mobile Options':
				openSubState(new mobile.options.MobileOptionsSubState());
			#end
			case 'Export & Import Settings':
				openSubState(new options.ShareSettingsSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		mainCam = initPsychCamera();
		funnyCam = new FlxCamera();
		funnyCam.bgColor.alpha = 0;
		FlxG.cameras.add(funnyCam, false);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		FlxG.cameras.list[FlxG.cameras.list.indexOf(funnyCam)].follow(camFollowPos);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), true);
			optionText.setScale(0.75);
			optionText.screenCenter();
			optionText.y += (60 * (num - (options.length / 2))) + 30;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>>>', true);
		selectorLeft.alignment = RIGHT;
		selectorLeft.setScale(2/3);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<<<', true);
		selectorRight.setScale(2/3);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();
		
		// Get this setting in this timing
		#if android MobileOptionsSubState.lastStorageType = ClientPrefs.data.storageType; #end

		#if (target.threaded)
		Thread.create(()->{
			mutex.acquire();

			for (music in VisualsSettingsSubState.pauseMusics)
			{
				if (music.toLowerCase() != "none")
					Paths.music(Paths.formatToSongPath(music));
			}

			mutex.release();
		});
		#end

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('UP_DOWN', 'A_B');

		var button = new TouchZone(90,270,FlxG.width,100,FlxColor.PURPLE);
		
		var scroll = new ScrollableObject(-0.01,100,0,FlxG.width-200,FlxG.height,button);
		scroll.onPartialScroll.add(delta -> changeSelection(delta,false));
		// scroll.onFullScroll.add(delta -> {
		// 	FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		// });
        scroll.onFullScrollSnap.add(() ->changeSelection(0,true));
		scroll.onTap.add(() ->{
			openSelectedSubstate(options[curSelected]);
		});
		add(scroll);
		add(button);
		#end
		
		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		controls.isInSubstate = false;
		persistentUpdate = funnyCam.visible = true;
		
		#if TOUCH_CONTROLS_ALLOWED
		removeTouchPad();
		addTouchPad('UP_DOWN', 'A_B');
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (exiting) return;

		if (controls.UI_UP_P || controls.UI_DOWN_P)
		{
			changeSelection(controls.UI_UP_P ? -1 : 1, true);
		}

		if (FlxG.mouse.wheel != 0)
		{
			changeSelection(FlxG.mouse.wheel, true, true);
		}

		// var lerpVal:Float = Math.max(0, Math.min(1, elapsed * 7.5));
		// camFollowPos.setPosition(635, FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			var thing:Float = 0;
			if (item.targetY == 0) {
				if(grpOptions.members.length > 6) {
					thing = grpOptions.members.length * 2;
				}
				// camFollow.setPosition(635, item.getGraphicMidpoint().y + 100 - thing);
			}
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), ClientPrefs.data.sfxVolume);
			exiting = false;
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(delta:Float = 0, usePrecision:Bool = false, isWheel:Bool = false)
	{
		if(usePrecision) {
			curSelected = FlxMath.wrap(curSelected + Std.int(delta), 0, options.length - 1);
			curSelectedPartial = curSelected;
		} else {
			curSelectedPartial = FlxMath.bound(curSelectedPartial + delta, 0, options.length - 1);
			curSelected = Math.round(curSelectedPartial);
		}
		
		if (usePrecision || curSelected != Math.round(curSelectedPartial)) {
			FlxG.sound.play(Paths.sound('scrollMenu'), (isWheel ? 0.4 : 1) * ClientPrefs.data.sfxVolume);
		}
		
		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelectedPartial;
			item.alpha = 0.6;
			if (num == curSelected)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 140;
				selectorLeft.y = selectorRight.y = item.y + 7;
				selectorRight.x = item.x + item.width + 35;
			}
		}
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		if (!ClientPrefs.data.disableGC && !MemoryUtil.isGcEnabled) {
			MemoryUtil.enable();
			MemoryUtil.collect(true);
			MemoryUtil.compact();
		}
		super.destroy();
	}
}
