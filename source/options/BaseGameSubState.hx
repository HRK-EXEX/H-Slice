package options;
import mikolka.vslice.components.crash.Logger;
import options.Option;

class BaseGameSubState extends BaseOptionsMenu {
	var logOption:Option;
	var cursorOption:Option;

    public function new() {
        title = Language.getPhrase("vslice_menu","P-Slice settings");
        rpcTitle = "P-Slice settings menu";

        var option:Option = new Option('Use New Freeplay State',
			"If disabled, it uses Psych Engine's Freeplay State instead of the new one.",
			'vsliceFreeplay',
			BOOL);
		addOption(option);

        var option:Option = new Option('Freeplay Dynamic Coloring',
			'Enables dynamic freeplay background colors. Disable this if you prefer the original V-Slice freeplay menu colors.',
			'vsliceFreeplayColors',
			BOOL);
		addOption(option);
		#if sys
		var option:Option = new Option('Logging Type',
			"Controls verbosity of the game's logs.",
			'loggingType',
			STRING,
			["None", "Console", "File", "Console & File"]);
		option.onChange = Logger.updateLogType;
		addOption(option);
		logOption = option;
		#end
		var option:Option = new Option('Naughtyness',
			'If disabled, some "raunchy content" (such as swearing, etc.) will be disabled.',
			'vsliceNaughtyness',
			BOOL);
		addOption(option);
		var option:Option = new Option('Use Results Screen',
			'If disabled, the game will skip showing the result screen.',
			'vsliceResults',
			BOOL);
		addOption(option);

		var option:Option = new Option('Smooth Song Position',
			'If enabled, it reduces stuttering in gameplay,\nin exchange for possibly causing problems with scripts.',
			'vsliceSongPosition',
			BOOL);
		addOption(option);

		var option:Option = new Option('Smooth Health Bar',
			'If enabled, the health bar will move smoothly.',
			'vsliceSmoothBar',
			BOOL);
		addOption(option);

		var option:Option = new Option('Use legacy bar',
			'Makes the health bar and score text much simpler.',
			'vsliceLegacyBar',
			BOOL);
		addOption(option);

		var option:Option = new Option('Use P-Slice cursor',
			'If enabled, the game will use the designated cursor for P-Slice instead of the one for V-Slice.',
			'vsliceSystemCursor',
			BOOL);
		option.onChange = changeCursor;
		cursorOption = option;
		addOption(option);

		var option:Option = new Option('- Smoothness Speed',
			'Change the speed of the Health Bar smoothness.\n0 = Disabled.',
			'vsliceSmoothNess',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1.0;
		option.changeValue = 0.01;
		option.decimals = 2;
		addOption(option);

		var option:Option = new Option('Special Freeplay Cards',
			"If disabled, it will force every character to use BF's card. (including pico)",
			'vsliceSpecialCards',
			BOOL);
		addOption(option);

		var option:Option = new Option('Preview Whole Song in New Freeplay',
			'If enabled, it will load the ENTIRE instrumental of every song in the new Freeplay State.\nVery CPU Intensive.',
			'vsliceLoadInstAll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Botplay Text Location: ',
			'Changes the location of the Botplay text.',
			'vsliceBotPlayPlace',
			STRING,
			[
				"Time Bar",
				"Health Bar",
			]);
		addOption(option);
		
		var option:Option = new Option('Force "New" tag',
			'If enabled, it will force every uncompleted song to show a "new" tag even if it\'s disabled',
			'vsliceForceNewTag',
			BOOL);
		addOption(option);
        super();
    }

	function changeCursor() {
		FlxG.mouse.useSystemCursor = !cursorOption.getValue();
	}

	function updateLogType() {
		ClientPrefs.data.loggingType = logOption.getValue();
		Logger.updateLogType();
	}
}