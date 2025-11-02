package options;
import mikolka.vslice.components.crash.Logger;
import options.Option;

class BaseGameSubState extends BaseOptionsMenu {
	var logOption:Option;

    public function new() {
        title = Language.getPhrase("vslice_menu","P-Slice settings");
        rpcTitle = "P-Slice settings menu";

        var option:Option = new Option('Use New Freeplay State',
			'If disabled, it uses the Freeplay State of Psych Engine instead new one.',
			'vsliceFreeplay',
			BOOL);
		addOption(option);

        var option:Option = new Option('Freeplay Dynamic Coloring',
			'Enables dynamic freeplay background color. Disable this if you prefer original V-slice freeplay menu colors',
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
			'If disabled, some "raunchy content" (such as swearing, etc.) will be disabled',
			'vsliceNaughtyness',
			BOOL);
		addOption(option);
		var option:Option = new Option('Use Results Screen',
			'If disabled will skip showing the result screen',
			'vsliceResults',
			BOOL);
		addOption(option);

		var option:Option = new Option('Smooth Song Position',
			'If enabled, it reduces the stuttering whole gameplay,\nin exchange for maybe cause problems with scripts.',
			'vsliceSongPosition',
			BOOL);
		addOption(option);

		var option:Option = new Option('Smooth Health Bar',
			'If enabled, makes health bar move move smoothly.',
			'vsliceSmoothBar',
			BOOL);
		addOption(option);

		var option:Option = new Option('Use legacy bar',
			'Makes health bar and score text much simpler',
			'vsliceLegacyBar',
			BOOL);
		addOption(option);

		var option:Option = new Option('- Smoothness Speed',
			'Change the speed of the Health Bar smoothness.\n0 = Disabled, 1 = No Smoothness.',
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
			'If enabled, it will load every song in New Freeplay State,\nVery CPU Intensive.',
			'vsliceLoadInstAll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Botplay Text Location: ',
			'Change the Botplay Text Location.',
			'vsliceBotPlayPlace',
			STRING,
			[
				"Time Bar",
				"Health Bar",
			]);
		addOption(option);
		
		var option:Option = new Option('Force "New" tag',
			'If enabled will force every uncompleted song to show "new" tag even if it\'s disabled',
			'vsliceForceNewTag',
			BOOL);
		addOption(option);
        super();
    }

	function updateLogType() {
		ClientPrefs.data.loggingType = logOption.getValue();
		Logger.updateLogType();
	}
}