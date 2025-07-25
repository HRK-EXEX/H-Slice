package options;

import objects.Character;
import objects.Bar;
import flixel.addons.display.shapes.FlxShapeCircle;

import mikolka.stages.erect.MainStageErect as BackgroundStage;

class NoteOffsetState extends MusicBeatState
{
	var stageDirectory:String = 'week1';
	var boyfriend:Character;
	var gf:Character;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	var coolText:FlxText;
	var rating:FlxSprite;
	var comboNums:FlxSpriteGroup;
	var comboSprite:FlxSprite;
	var dumbTexts:FlxTypedGroup<FlxText>;

	var barPercent:Float = 0;
	var delayMin:Int = -500;
	var delayMax:Int = 500;
	var timeBar:Bar;
	var timeTxt:FlxText;
	var timingTxt:FlxText;
	var timingTween:FlxTween;
	var beatText:Alphabet;
	var beatTween:FlxTween;

	var changeModeText:FlxText;
	var holdTimeText:FlxText;

	var controllerPointer:FlxSprite;
	var _lastControllerMode:Bool = false;

	override public function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Delay/Combo Offset Menu", null);
		#end

		// Cameras
		camGame = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);

		FlxG.camera.scroll.set(120, 130);

		persistentUpdate = true;
		FlxG.sound.pause();

		// Stage
		Paths.setCurrentLevel(stageDirectory);
		var stage = new BackgroundStage();
		stage.create();
		add(stage);

		// Characters
		gf = new Character(400, 130, 'gf');
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(0.95, 0.95);
		boyfriend = new Character(770, 100, 'bf', true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(gf);
		add(boyfriend);

		// Combo stuff
		coolText = new FlxText(0, 0, 0, '', 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		coolText.antialiasing = ClientPrefs.data.antialiasing;

		rating = new FlxSprite().loadGraphic(Paths.image('sick'));
		rating.cameras = [camHUD];
		rating.antialiasing = ClientPrefs.data.antialiasing;
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		
		add(rating);

		comboNums = new FlxSpriteGroup();
		comboNums.cameras = [camHUD];
		add(comboNums);

		comboSprite = new FlxSprite().loadGraphic(Paths.image('combo'));
		comboSprite.antialiasing = ClientPrefs.data.antialiasing;
		comboSprite.setGraphicSize(Std.int(comboSprite.width * 0.55));
		comboSprite.cameras = [camHUD];
		add(comboSprite);

		var seperatedScore:Array<Int> = [];
		for (i in 0...3)
		{
			seperatedScore.push(FlxG.random.int(0, 9));
		}

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite(43 * daLoop).loadGraphic(Paths.image('num' + i));
			numScore.cameras = [camHUD];
			numScore.antialiasing = ClientPrefs.data.antialiasing;
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			comboNums.add(numScore);
			daLoop++;
		}

		dumbTexts = new FlxTypedGroup<FlxText>();
		dumbTexts.cameras = [camHUD];
		add(dumbTexts);
		createTexts();

		repositionCombo();

		// Note delay stuff
		beatText = new Alphabet(0, 0, Language.getPhrase('delay_beat_hit', 'Beat Hit!'), true);
		beatText.setScale(0.6, 0.6);
		beatText.x += 260;
		beatText.alpha = 0;
		beatText.acceleration.y = 250;
		beatText.visible = false;
		add(beatText);
		
		timeTxt = new FlxText(0, 600, FlxG.width, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 2;
		timeTxt.visible = false;
		timeTxt.cameras = [camHUD];
		timeTxt.antialiasing = ClientPrefs.data.antialiasing;
		
		timingTxt = new FlxText(0, timeTxt.y - 50, FlxG.width, "", 32);
		timingTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timingTxt.scrollFactor.set();
		timingTxt.borderSize = 2;
		timingTxt.visible = false;
		timingTxt.cameras = [camHUD];
		timingTxt.antialiasing = ClientPrefs.data.antialiasing;

		barPercent = ClientPrefs.data.noteOffset;
		updateNoteDelay();
		
		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 3), 'healthBar', function() return barPercent, delayMin, delayMax);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.visible = false;
		timeBar.cameras = [camHUD];
		timeBar.leftBar.color = FlxColor.LIME;

		add(timeBar);
		add(timeTxt);
		add(timingTxt);

		///////////////////////

		var blackBox:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 40, FlxColor.BLACK);
		blackBox.scrollFactor.set();
		blackBox.alpha = 0.6;
		blackBox.cameras = [camHUD];
		add(blackBox);

		changeModeText = new FlxText(0, 4, FlxG.width, "", 32);
		changeModeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		changeModeText.scrollFactor.set();
		changeModeText.cameras = [camHUD];
		changeModeText.antialiasing = ClientPrefs.data.antialiasing;
		add(changeModeText);

		holdTimeText = new FlxText(0, 500, FlxG.width, "", 32);
		holdTimeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		holdTimeText.scrollFactor.set();
		holdTimeText.cameras = [camHUD];
		holdTimeText.antialiasing = ClientPrefs.data.antialiasing;
		#if !debug holdTimeText.visible = false; #end
		add(holdTimeText);
		
		controllerPointer = new FlxShapeCircle(0, 0, 20, {thickness: 0}, FlxColor.WHITE);
		controllerPointer.offset.set(20, 20);
		controllerPointer.screenCenter();
		controllerPointer.alpha = 0.6;
		controllerPointer.cameras = [camHUD];
		add(controllerPointer);
		
		updateMode();
		_lastControllerMode = true;

		Conductor.bpm = 128.0;
		FlxG.sound.playMusic(Paths.music('offsetSong'), ClientPrefs.data.bgmVolume, true);
		Conductor.songPosition = 0;

		#if TOUCH_CONTROLS_ALLOWED controls.controllerMode = controls.mobileC; #end

		super.create();
	}

	var holdTime:Float = 0;
	var onComboMenu:Bool = true;
	var holdingObjectType:Null<Int> = null;

	var startMousePos:FlxPoint = FlxPoint.get();
	var startComboOffset:FlxPoint = FlxPoint.get();

	override public function update(elapsed:Float)
	{
		var addNum:Int = 1;
		if(FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER))
		{
			if(onComboMenu)
				addNum = 10;
			else
				addNum = 3;
		}

		if(FlxG.gamepads.anyJustPressed(ANY)) controls.controllerMode = true;
		else if(FlxG.mouse.justPressed) controls.controllerMode = false;

		if(controls.controllerMode != _lastControllerMode)
		{
			//trace('changed controller mode');
			FlxG.mouse.visible = !controls.controllerMode;
			controllerPointer.visible = controls.controllerMode;

			// changed to controller mid state
			if(controls.controllerMode)
			{
				var mousePos = FlxG.mouse.getScreenPosition(camHUD);
				controllerPointer.x = mousePos.x;
				controllerPointer.y = mousePos.y;
			}
			updateMode();
			_lastControllerMode = controls.controllerMode;
		}

		if(onComboMenu)
		{
			if(FlxG.keys.justPressed.ANY || FlxG.gamepads.anyJustPressed(ANY))
			{
				var controlArray:Array<Bool> = null;
				if(!controls.controllerMode)
				{
					controlArray = [
						FlxG.keys.justPressed.LEFT,
						FlxG.keys.justPressed.RIGHT,
						FlxG.keys.justPressed.UP,
						FlxG.keys.justPressed.DOWN,
					
						FlxG.keys.justPressed.A,
						FlxG.keys.justPressed.D,
						FlxG.keys.justPressed.W,
						FlxG.keys.justPressed.S,
					
						FlxG.keys.justPressed.F,
						FlxG.keys.justPressed.H,
						FlxG.keys.justPressed.T,
						FlxG.keys.justPressed.G
					];
				}
				else
				{
					controlArray = [
						FlxG.gamepads.anyJustPressed(DPAD_LEFT),
						FlxG.gamepads.anyJustPressed(DPAD_RIGHT),
						FlxG.gamepads.anyJustPressed(DPAD_UP),
						FlxG.gamepads.anyJustPressed(DPAD_DOWN),
					
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_LEFT),
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_RIGHT),
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_UP),
						FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_DOWN),
					
						FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_LEFT),
						FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_RIGHT),
						FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_UP),
						FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_DOWN)
					];
				}

				if(controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if(controlArray[i])
						{
							switch(i)
							{
								case 0: ClientPrefs.data.comboOffset[0] -= addNum;
								case 1: ClientPrefs.data.comboOffset[0] += addNum;
								case 2: ClientPrefs.data.comboOffset[1] += addNum;
								case 3: ClientPrefs.data.comboOffset[1] -= addNum;
								case 4: ClientPrefs.data.comboOffset[2] -= addNum;
								case 5: ClientPrefs.data.comboOffset[2] += addNum;
								case 6: ClientPrefs.data.comboOffset[3] += addNum;
								case 7: ClientPrefs.data.comboOffset[3] -= addNum;
								case 8: ClientPrefs.data.comboOffset[4] -= addNum;
								case 9: ClientPrefs.data.comboOffset[4] += addNum;
								case 10: ClientPrefs.data.comboOffset[5] += addNum;
								case 11: ClientPrefs.data.comboOffset[5] -= addNum;
							}
						}
					}
					repositionCombo();
				}
			}
			
			// controller things
			var analogX:Float = 0;
			var analogY:Float = 0;
			var analogMoved:Bool = false;
			var gamepadPressed:Bool = false;
			var gamepadReleased:Bool = false;
			if(controls.controllerMode)
			{
				for (gamepad in FlxG.gamepads.getActiveGamepads())
				{
					analogX = gamepad.getXAxis(LEFT_ANALOG_STICK);
					analogY = gamepad.getYAxis(LEFT_ANALOG_STICK);
					analogMoved = (analogX != 0 || analogY != 0);
					if(analogMoved) break;
				}
				controllerPointer.x = Math.max(0, Math.min(FlxG.width, controllerPointer.x + analogX * 1000 * elapsed));
				controllerPointer.y = Math.max(0, Math.min(FlxG.height, controllerPointer.y + analogY * 1000 * elapsed));
				gamepadPressed = !FlxG.gamepads.anyJustPressed(START) && controls.ACCEPT;
				gamepadReleased = !FlxG.gamepads.anyJustReleased(START) && controls.justReleased('accept');
			}

			// probably there's a better way to do this but, oh well.
			if (FlxG.mouse.justPressed || gamepadPressed)
			{
				holdingObjectType = null;
				if(!controls.controllerMode)
					FlxG.mouse.getScreenPosition(camHUD, startMousePos);
				else
					controllerPointer.getScreenPosition(startMousePos, camHUD);

				if (startMousePos.x - comboNums.x >= 0 && startMousePos.x - comboNums.x <= comboNums.width &&
					startMousePos.y - comboNums.y >= 0 && startMousePos.y - comboNums.y <= comboNums.height)
				{
					holdingObjectType = 1;
					startComboOffset.x = ClientPrefs.data.comboOffset[2];
					startComboOffset.y = ClientPrefs.data.comboOffset[3];
					//trace('yo bro');
				}
				else if (startMousePos.x - rating.x >= 0 && startMousePos.x - rating.x <= rating.width &&
						 startMousePos.y - rating.y >= 0 && startMousePos.y - rating.y <= rating.height)
				{
					holdingObjectType = 0;
					startComboOffset.x = ClientPrefs.data.comboOffset[0];
					startComboOffset.y = ClientPrefs.data.comboOffset[1];
					//trace('heya');
				}
				else if (startMousePos.x - comboSprite.x >= 0 && startMousePos.x - comboSprite.x <= comboSprite.width &&
						 startMousePos.y - comboSprite.y >= 0 && startMousePos.y - comboSprite.y <= comboSprite.height)
				{
					holdingObjectType = 2;
					startComboOffset.x = ClientPrefs.data.comboOffset[4];
					startComboOffset.y = ClientPrefs.data.comboOffset[5];
					//trace('howdy');
				}
			}
			if(FlxG.mouse.justReleased || gamepadReleased) {
				holdingObjectType = null;
				//trace('dead');
			}

			if(holdingObjectType != null)
			{
				if(FlxG.mouse.justMoved || analogMoved)
				{
					var mousePos:FlxPoint = null;
					if(!controls.controllerMode)
						mousePos = FlxG.mouse.getScreenPosition(camHUD);
					else
						mousePos = controllerPointer.getScreenPosition(camHUD);

					var addNum:Int = holdingObjectType * 2;
					ClientPrefs.data.comboOffset[addNum + 0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
					ClientPrefs.data.comboOffset[addNum + 1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
					repositionCombo();
				}
			}

			if(controls.RESET #if TOUCH_CONTROLS_ALLOWED || touchPad.buttonC.justPressed #end)
			{
				for (i in 0...ClientPrefs.data.comboOffset.length)
				{
					ClientPrefs.data.comboOffset[i] = 0;
				}
				repositionCombo();
			}
		}
		else
		{
			timingTxt.alpha -= elapsed / 3;

			if(controls.UI_LEFT_P)
			{
				holdTime = 0;
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.data.noteOffset - 1, delayMax));
				updateNoteDelay();
			}
			else if(controls.UI_RIGHT_P)
			{
				holdTime = 0;
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.data.noteOffset + 1, delayMax));
				updateNoteDelay();
			}

			if (FlxG.keys.justPressed.ANY || TouchUtil.justPressed) {
				timingTxt.alpha = 1;
				var delay:Float = (Conductor.songPosition * Conductor.bpm / 120) % 2000 - 1000;
				
				timingTxt.text = '${delay > 0 ? "+" : ""}${CoolUtil.floatToStringPrecision(delay, 3)} ms';
				timingTxt.scale.set(1.2, 1.2);

				if (timingTween != null) timingTween.cancel();
				timingTween = FlxTween.tween(timingTxt.scale, {x: 1, y: 1}, 1, {
					type: ONESHOT,
					ease: FlxEase.cubeOut,
					onComplete: twn -> timingTween = null
				});
			}

			if(controls.UI_LEFT || controls.UI_RIGHT)
			{
				var mult:Int = 1;
				holdTime += elapsed;
				if(controls.UI_LEFT) mult = -1;

				if(holdTime > 0.5)
				{
					barPercent += 100 * addNum * elapsed * mult;
					barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
					updateNoteDelay();
				}
			}

			if(controls.RESET #if TOUCH_CONTROLS_ALLOWED || touchPad.buttonC.justPressed #end)
			{
				holdTime = 0;
				barPercent = 0;
				updateNoteDelay();
			}
		}

		if((!controls.controllerMode && controls.ACCEPT) ||
		(controls.controllerMode && FlxG.gamepads.anyJustPressed(START)))
		{
			onComboMenu = !onComboMenu;
			updateMode();
		}

		if(controls.BACK)
		{
			if(zoomTween != null) zoomTween.cancel();
			if(beatTween != null) beatTween.cancel();

			persistentUpdate = false;
			MusicBeatState.switchState(new options.OptionsState());
			if(OptionsState.onPlayState)
			{
				if(ClientPrefs.data.pauseMusic != 'None')
					FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), ClientPrefs.data.bgmVolume);
				else
					FlxG.sound.music.volume = 0;
			}
			else FlxG.sound.playMusic(Paths.music('freakyMenu'), ClientPrefs.data.bgmVolume);
			FlxG.mouse.visible = false;
		}
	
		holdTimeText.text = Std.string(holdTime);
		Conductor.songPosition += elapsed;
		if (Math.abs(FlxG.sound.music.time - Conductor.songPosition) > 20)
			Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);
	}

	var zoomTween:FlxTween;
	var lastBeatHit:Float = -1;
	override public function beatHit()
	{
		super.beatHit();

		if(lastBeatHit == curBeat)
		{
			return;
		}

		if(curBeat % 2 == 0)
		{
			boyfriend.dance();
			gf.dance();
		}
		
		if(curBeat % 4 == 2)
		{
			FlxG.camera.zoom = 1.15;

			if(zoomTween != null) zoomTween.cancel();
			zoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {ease: FlxEase.circOut, onComplete: function(twn:FlxTween)
				{
					zoomTween = null;
				}
			});

			beatText.alpha = 1;
			beatText.y = 320;
			beatText.velocity.y = -150;
			if(beatTween != null) beatTween.cancel();
			beatTween = FlxTween.tween(beatText, {alpha: 0}, 1, {ease: FlxEase.sineIn, onComplete: function(twn:FlxTween)
				{
					beatTween = null;
				}
			});
		}

		lastBeatHit = curBeat;
	}

	function repositionCombo()
	{
		rating.screenCenter();
		rating.x = coolText.x - 40 + ClientPrefs.data.comboOffset[0];
		rating.y -= 60 + ClientPrefs.data.comboOffset[1];
		rating.alpha = ClientPrefs.data.showRating ? 1 : 0.75;

		comboSprite.screenCenter();
		comboSprite.x = coolText.x + ClientPrefs.data.comboOffset[4];
		comboSprite.y += 60 - ClientPrefs.data.comboOffset[5];
		comboSprite.alpha = ClientPrefs.data.showCombo ? 1 : 0.75;

		comboNums.screenCenter();
		comboNums.x = coolText.x - 90 + ClientPrefs.data.comboOffset[2];
		comboNums.y += 75 - ClientPrefs.data.comboOffset[3];
		comboNums.alpha = ClientPrefs.data.showComboNum ? 1 : 0.75;

		reloadTexts();
	}

	var textOffset:Float = 48;
	function createTexts()
	{
		textOffset = 48;
		for (i in 0...6)
		{
			var text:FlxText = new FlxText(10, (i * 30) + textOffset, 0, '', 24);
			text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 2;
			dumbTexts.add(text);
			text.cameras = [camHUD];
			text.antialiasing = ClientPrefs.data.antialiasing;

			if(i%2 == 1)
			{
				textOffset += 24;
			}
		}
	}

	function reloadTexts()
	{
		for (i in 0...dumbTexts.length)
		{
			switch(i)
			{
				case 0: dumbTexts.members[i].text = Language.getPhrase('combo_rating_offset', 'Rating Offset:');
				case 1: dumbTexts.members[i].text = '[' + ClientPrefs.data.comboOffset[0] + ', ' + ClientPrefs.data.comboOffset[1] + ']';
				case 2: dumbTexts.members[i].text = Language.getPhrase('combo_numbers_offset', 'Numbers Offset:');
				case 3: dumbTexts.members[i].text = '[' + ClientPrefs.data.comboOffset[2] + ', ' + ClientPrefs.data.comboOffset[3] + ']';
				case 4: dumbTexts.members[i].text = Language.getPhrase('combo_combo_offset', 'Combo Offset:');
				case 5: dumbTexts.members[i].text = '[' + ClientPrefs.data.comboOffset[4] + ', ' + ClientPrefs.data.comboOffset[5] + ']';
			}
		}
	}

	function updateNoteDelay()
	{
		ClientPrefs.data.noteOffset = Math.round(barPercent);
		timeTxt.text = Language.getPhrase('delay_current_offset', 'Current offset: {1} ms', [Math.floor(barPercent)]);
	}

	function updateMode()
	{
		rating.visible = onComboMenu;
		comboNums.visible = onComboMenu;
		comboSprite.visible = onComboMenu;
		dumbTexts.visible = onComboMenu;
		
		timeBar.visible = !onComboMenu;
		timeTxt.visible = !onComboMenu;
		timingTxt.visible = !onComboMenu;
		beatText.visible = !onComboMenu;

		controllerPointer.visible = false;
		FlxG.mouse.visible = false;
		if(onComboMenu)
		{
			FlxG.mouse.visible = !controls.controllerMode;
			controllerPointer.visible = controls.controllerMode;
		}

		#if TOUCH_CONTROLS_ALLOWED
        removeTouchPad();
		#end

		var str:String;
		var str2:String;
		final accept:String = (controls.mobileC) ? "A" : (!controls.controllerMode) ? "ACCEPT" : "Start";
		if(onComboMenu)
		{
			str = Language.getPhrase('combo_offset', 'Combo Offset');
			#if TOUCH_CONTROLS_ALLOWED
			addTouchPad('NONE', 'A_B_C');
			addTouchPadCamera(false);
			#end
		} else {
			str = Language.getPhrase('note_delay', 'Note/Beat Delay');
			#if TOUCH_CONTROLS_ALLOWED
			addTouchPad('LEFT_FULL', 'A_B_C');
			addTouchPadCamera(false);
			#end
		}

		str2 = Language.getPhrase('switch_on_button', '(Press {1} to Switch)', [accept]);

		changeModeText.text = '< ${str.toUpperCase()} ${str2.toUpperCase()} >';
	}

	override function destroy(){
		startMousePos.put();
		startComboOffset.put();
		super.destroy();
	}
}
