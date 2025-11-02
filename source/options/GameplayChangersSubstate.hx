package options;

import mikolka.vslice.freeplay.FreeplayState; // It has used on mobile build
import objects.AttachedText;
import objects.CheckboxThingie;
import options.Option.OptionType;

class GameplayChangersSubstate extends MusicBeatSubstate
{
	private var curSelected:Int = 0;
	private var curSelectedPartial:Float = 0;
	private var optionsArray:Array<Dynamic> = [];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var optionsCam:FlxCamera = new FlxCamera();
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var scrollOption:GameplayOption;
	private var playbackOption:GameplayOption;

	private var interpolate = CoolUtil.interpolate;

	private var curOption(get, never):GameplayOption;
	public static var fromNewFreeplayState:Bool = false;
	function get_curOption() return optionsArray[curSelected]; //shorter lol

	final ConstMax:Float = 1024;
	final MultiMax:Float = 128;

	function getOptions()
	{
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', STRING, 'multiplicative', ["multiplicative", "constant", "ignore changes"]);
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', FLOAT, 1);
		option.scrollSpeed = 1.0;
		option.minValue = 0.01;
		option.changeValue = 0.01;
		option.decimals = 2;
		if (goption.getValue() != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = MultiMax;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = ConstMax;
		}
		optionsArray.push(option);
		scrollOption = option;

		#if FLX_PITCH
		var option:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', FLOAT, 1);
		option.scrollSpeed = 1;
		option.minValue = 0.01;
		option.maxValue = MultiMax;
		option.changeValue = 0.01;
		option.displayFormat = '%vX';
		option.decimals = 3;
		optionsArray.push(option);
		playbackOption = option;
		#end

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', FLOAT, 1);
		option.scrollSpeed = 5;
		option.minValue = 0;
		option.maxValue = 10;
		option.changeValue = 0.01;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', FLOAT, 1);
		option.scrollSpeed = 5;
		option.minValue = 0;
		option.maxValue = 10;
		option.changeValue = 0.01;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		optionsArray.push(new GameplayOption('Instant kill on Miss', 'instakill', BOOL, false));
		optionsArray.push(new GameplayOption('Instant crash on Miss', 'instacrash', BOOL, false));
		optionsArray.push(new GameplayOption('Practice Mode', 'practice', BOOL, false));
		optionsArray.push(new GameplayOption('Botplay', 'botplay', BOOL, false));
	}

	public function getOptionByName(name:String)
	{
		for (i in optionsArray)
		{
			var opt:GameplayOption = i;
			if (opt.name == name)
				return opt;
		}
		return null;
	}

	public function new()
	{
		controls.isInSubstate = true;
		super();
		FlxG.cameras.add(optionsCam, false);
		optionsCam.bgColor = FlxColor.TRANSPARENT;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.camera = optionsCam;
		add(bg);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		grpOptions.camera = optionsCam;
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		grpTexts.camera = optionsCam;
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		checkboxGroup.camera = optionsCam;
		add(checkboxGroup);

		getOptions();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(150, 360, optionsArray[i].name, true);
			optionText.isMenuItem = true;
			optionText.setScale(0.8);
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (optionsArray[i].type == BOOL)
			{
				optionText.x += 60;
				optionText.startPosition.x += 60;
				optionText.snapToPosition();
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.offsetX -= 20;
				checkbox.offsetY = -52;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.snapToPosition();
				var valueText:AttachedText = new AttachedText(Std.string(optionsArray[i].getValue()), optionText.width + 40, 0, true, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}
			updateTextFrom(optionsArray[i]);
		}
		#if TOUCH_CONTROLS_ALLOWED
		var button = new TouchZone(90, 335, 1050, 100, FlxColor.PURPLE);
		button.camera = optionsCam;
		var scroll = new ScrollableObject(-0.008, 100, 0, FlxG.width - 200, FlxG.height, button);
		scroll.camera = optionsCam;
		scroll.onPartialScroll.add(delta -> changeSelection(delta, false));
		scroll.onFullScroll.add(delta ->
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		});
		scroll.onFullScrollSnap.add(() -> changeSelection(0, true));
		scroll.onTap.add(() ->
		{
			// copy paste because I am stupid.
			if (curOption.type != BOOL)
				return;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			curOption.setValue((curOption.getValue() == true) ? false : true);
			curOption.change();
			reloadCheckboxes();
		});
		add(scroll);
		add(button);
		addTouchPad('LEFT_FULL', 'A_B_C');
		addTouchPadCamera(false);
		#end
		changeSelection(0, true);
		reloadCheckboxes();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeSelection(-1, true);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1, true);
		}

		if (controls.BACK)
		{
			close();
			ClientPrefs.saveSettings();

			if (fromNewFreeplayState) {
				FreeplayState.configReturned = true;
			}
			
			controls.isInSubstate = fromNewFreeplayState;
			fromNewFreeplayState = false;

			FlxG.cameras.remove(optionsCam);
			FlxG.sound.play(Paths.sound('cancelMenu'), ClientPrefs.data.sfxVolume);
		}

		if (nextAccept <= 0)
		{
			var usesCheckbox:Bool = (curOption.type == BOOL);
			if (usesCheckbox)
			{
				if (controls.ACCEPT)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), ClientPrefs.data.sfxVolume);
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			}
			else
			{
				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if (holdTime > 0.5 || pressed)
					{
						scrollOption.scrollSpeed = interpolate(1.5, 1000, (holdTime - 0.5) / 8, 3);
						playbackOption.scrollSpeed = interpolate(1, 1000, (holdTime - 0.5) / 8, 3);
						if (pressed)
						{
							var add:Dynamic = null;
							if (curOption.type != STRING)
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;

							switch (curOption.type)
							{
								case INT, FLOAT, PERCENT:
									holdValue = curOption.getValue() + add;
									if (holdValue < curOption.minValue)
										holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue)
										holdValue = curOption.maxValue;

									switch (curOption.type)
									{
										case INT:
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case FLOAT, PERCENT:
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);

										default:
									}

								case STRING:
									var num:Int = curOption.curOption; // lol
									if (controls.UI_LEFT_P)
										--num;
									else
										num++;

									if (num < 0)
										num = curOption.options.length - 1;
									else if (num >= curOption.options.length)
										num = 0;

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); // lol

									if (curOption.name == "Scroll Type")
									{
										var oOption:GameplayOption = getOptionByName("Scroll Speed");
										if (oOption != null)
										{
											if (curOption.getValue() == "constant")
											{
												oOption.displayFormat = "%v";
												oOption.maxValue = ConstMax;
												oOption.setValue(Math.min(oOption.getValue(), ConstMax));
											}
											else
											{
												oOption.displayFormat = "%vX";
												oOption.maxValue = MultiMax;
												oOption.setValue(Math.min(oOption.getValue(), MultiMax));
											}
											updateTextFrom(oOption);
										}
									}
								// trace(curOption.options[num]);

								default:
							}
							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'), ClientPrefs.data.sfxVolume);
						}
						else if (curOption.type != STRING)
						{
							holdValue = Math.max(curOption.minValue,
								Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));

							switch (curOption.type)
							{
								case INT:
									curOption.setValue(Math.round(holdValue));

								case FLOAT, PERCENT:
									var blah:Float = Math.max(curOption.minValue,
										Math.min(curOption.maxValue, holdValue + curOption.changeValue - (holdValue % curOption.changeValue)));
									curOption.setValue(FlxMath.roundDecimal(blah, curOption.decimals));

								default:
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if (curOption.type != STRING)
						holdTime += elapsed;
				}
				else if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
					clearHold();
			}
			
			if(controls.RESET #if TOUCH_CONTROLS_ALLOWED || touchPad.buttonC.justPressed #end)			
			{
				if (!FlxG.keys.pressed.SHIFT) {
					curOption.setValue(curOption.defaultValue);
					if(curOption.type != BOOL)
					{
						if(curOption.type == STRING)
							curOption.curOption = curOption.options.indexOf(curOption.getValue());

						updateTextFrom(curOption);
					}

					if (curSelected < 2)
					{
						optionsArray[1].displayFormat = (optionsArray[0].getValue() == "constant") ? "%v" : "%vX";
						curOption.maxValue = MultiMax;
						if(curOption.getValue() > MultiMax)
							curOption.setValue(MultiMax);

						updateTextFrom(curOption);
					}
					curOption.change();
					
					FlxG.sound.play(Paths.sound('cancelMenu'), ClientPrefs.data.sfxVolume);
					reloadCheckboxes();
				} else {
					for (i in 0...optionsArray.length)
					{
						var leOption:GameplayOption = optionsArray[i];
						leOption.setValue(leOption.defaultValue);
						if(leOption.type != BOOL)
						{
							if(leOption.type == STRING)
								leOption.curOption = leOption.options.indexOf(leOption.getValue());

							updateTextFrom(leOption);
						}

						if(leOption.name == 'Scroll Speed')
						{
							leOption.displayFormat = "%vX";
							leOption.maxValue = MultiMax;
							if(leOption.getValue() > MultiMax)
								leOption.setValue(MultiMax);

							updateTextFrom(leOption);
						}
						leOption.change();
					}
					FlxG.sound.play(Paths.sound('cancelMenu'), ClientPrefs.data.sfxVolume);
					reloadCheckboxes();
				}
			}
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}

		#if TOUCH_CONTROLS_ALLOWED
		if (touchPad == null)
		{ // sometimes it dosent add the vpad, hopefully this fixes it
			addTouchPad('LEFT_FULL', 'A_B_C');
			addTouchPadCamera(false);
		}
		#end

		super.update(elapsed);
	}

	function updateTextFrom(option:GameplayOption)
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if (option.type == PERCENT)
			val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if (holdTime > 0.5) {
			FlxG.sound.play(Paths.sound('scrollMenu'), ClientPrefs.data.sfxVolume);
			scrollOption.setValue(CoolUtil.floorDecimal(scrollOption.getValue(), scrollOption.decimals));
			playbackOption.setValue(CoolUtil.floorDecimal(playbackOption.getValue(), playbackOption.decimals));
		}

		holdTime = 0;
	}

	function changeSelection(delta:Float, usePrecision:Bool = false)
	{
		if (usePrecision)
		{
			if (delta != 0)
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curSelected = FlxMath.wrap(curSelected + Std.int(delta), 0, optionsArray.length - 1);
			curSelectedPartial = curSelected;
		}
		else
		{
			curSelectedPartial = FlxMath.bound(curSelectedPartial + delta, 0, optionsArray.length - 1);
			if (curSelected != Math.round(curSelectedPartial))
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			curSelected = Math.round(curSelectedPartial);
		}
		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelectedPartial;
			item.alpha = 0.6;
			if (num == curSelected)
				item.alpha = 1;
		}
		for (text in grpTexts)
		{
			text.alpha = 0.6;
			if (text.ID == curSelected)
				text.alpha = 1;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), ClientPrefs.data.sfxVolume);
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
		{
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}
}

class GameplayOption
{
	private var child:Alphabet;

	public var text(get, set):String;
	public var onChange:Void->Void = null; // Pressed enter (on Bool type options) or pressed/held left/right (on other types)
	public var type:OptionType = BOOL;

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50; // Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; // Variable from ClientPrefs.hx's gameplaySettings

	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; // Don't change this
	public var options:Array<String> = null; // Only used in string type
	public var changeValue:Dynamic = 1; // Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; // Only used in int/float/percent type
	public var maxValue:Dynamic = null; // Only used in int/float/percent type
	public var decimals:Int = 1; // Only used in float/percent type

	public var displayFormat:String = '%v'; // How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:OptionType, defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		_name = name;
		this.name = Language.getPhrase('setting_$name', name);
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case BOOL:
					defaultValue = false;
				case INT, FLOAT:
					defaultValue = 0;
				case PERCENT:
					defaultValue = 1;
				case STRING:
					defaultValue = '';
					if (options.length > 0)
						defaultValue = options[0];

				default:
			}
		}

		if (getValue() == null)
			setValue(defaultValue);

		switch (type)
		{
			case STRING:
				var num:Int = options.indexOf(getValue());
				if (num > -1)
					curOption = num;

			case PERCENT:
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;

			default:
		}
	}

	public function change()
	{
		// nothing lol
		if (onChange != null)
			onChange();
	}

	public function getValue():Dynamic
		return ClientPrefs.data.gameplaySettings.get(variable);

	public function setValue(value:Dynamic)
		ClientPrefs.data.gameplaySettings.set(variable, value);

	public function setChild(child:Alphabet)
		this.child = child;

	var _name:String = null;
	var _text:String = null;

	private function get_text()
		return _text;

	private function set_text(newValue:String = '')
	{
		if (child != null)
		{
			_text = newValue;
			child.text = Language.getPhrase('setting_$_name-$_text', _text);
			return _text;
		}
		return null;
	}
}
