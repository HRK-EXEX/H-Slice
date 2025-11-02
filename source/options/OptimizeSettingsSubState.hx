package options;

class OptimizeSettingsSubState extends BaseOptionsMenu
{
	var limitCount:Option;
	var cacheCount:Option;

	public static final SORT_PATTERN:Array<String> = [
		'Never',
		'After Note Spawned',
		'After Note Processed',
		'After Note Finalized',
		'Reversed',
		'Chaotic',
		'Random',
		'Shuffle',
	];

	public function new()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Optimizations Menu", null);
		#end
		
		title = 'Optimizations';
		rpcTitle = 'Optimization Settings Menu'; //for Discord Rich Presence

		//Working in Progress!
        var option:Option = new Option('Work in Progress', //Name
			"Make changes at your own risk.", //Description
			'openDoor', //Save data variable name
			STRING,
			['!']); //Variable type
		addOption(option);

        var option:Option = new Option('Show Notes',
			"If unchecked, appearTime sets to 0.\nAll notes will be processed as skipped notes.\nBotplay is force-enabled.",
			'showNotes',
			BOOL);
		addOption(option);

        var option:Option = new Option('Show Notes again after Skip',
			"If checked, it tries preventing notes from showing only halfway through.",
			'showAfter',
			BOOL);
		addOption(option);

        var option:Option = new Option('Keep Notes in Screen',
		 	"If checked, notes will display from top to bottom, even if they are skippable.\nIf unchecked, it improves performance, especially if a lot of notes are displayed.",
		 	'keepNotes',
		 	BOOL);
		addOption(option);
		
        var option:Option = new Option('Sort Notes:',
			"If checked, the notes array is sorted every frame when notes are added.\nUnchecking improves performance, especially if a lot of notes are displayed.\nDefault: \"After Note Finalized\"",
			'sortNotes',
			STRING,
			SORT_PATTERN); //Variable type
		addOption(option);

        var option:Option = new Option('Faster Sort',
			"If checked, It sorts only visible objects.",
			'fastSort',
			BOOL);
		addOption(option);

		var option:Option = new Option('Better Recycling',
			"If checked, the game will use NoteGroup's recycle system.\nIt boosts game performance massively.",
			'betterRecycle',
			BOOL);
		addOption(option);

		var option:Option = new Option('Max Notes Shown:',
			"How many notes do you wanna display? To unlimited, set the value to 0.",
			'limitNotes',
			INT);
		option.scrollSpeed = 30;
		option.minValue = 0;
		option.maxValue = 99999;
		option.changeValue = 1;
		option.decimals = 0;
		option.onChange = onChangeLimitCount;
		limitCount = option;
		addOption(option);

		var option:Option = new Option('Invisible overlapped notes:',
			"I thought It would be nice because I implemented skipping feature\nI won't care about cheating anymore",
			'hideOverlapped',
			FLOAT);
		option.displayFormat = "%v pixel";
		option.scrollSpeed = 10.0;
		option.minValue = 0.0;
		option.maxValue = 10.0;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

        var option:Option = new Option('Process Notes before Spawning',
			"If checked, it process notes before they spawn.\nIt boosts game performance massively.\nIt is recommended to enable this option.",
			'processFirst',
			BOOL);
		addOption(option);

        var option:Option = new Option('Skip Process for Spawned Note',
			"If checked, enables Skip Note Function.\nIt boosts game performance massively, but it only works in specific situations.\nIf you don't understand, enable this.",
			'skipSpawnNote',
			BOOL);
		addOption(option);

        var option:Option = new Option(' - Break on Time Limit Exceeded',
			"If checked, breaks from note spawn loop if the time limit is exceeded.\nIt may have good performance on some scenes.",
			'breakTimeLimit',
			BOOL);
		addOption(option);

        var option:Option = new Option('Optimize Process for Spawned Note',
			"If checked, it judges whether or not to do hit process\nimmediately when a note spawned. It boosts game performance massively,\nbut it only works in specific situations. If you don't understand, enable this.",
			'optimizeSpawnNote',
			BOOL);
		addOption(option);

        var option:Option = new Option('noteHitPreEvent',
			"If unchecked, the game will not send any noteHitPreEvent on Lua/HScript.",
			'noteHitPreEvent',
			BOOL);
		addOption(option);

        var option:Option = new Option('noteHitEvent',
			"If unchecked, the game will not send any noteHitEvent on Lua/HScript.\nNot recommended to disable this option.",
			'noteHitEvent',
			BOOL);
		addOption(option);

		var option:Option = new Option('spawnNoteEvent',
			"If unchecked, the game will not send spawn event\non Lua/HScript for spawned notes. Improves performance.",
			'spawnNoteEvent',
			BOOL);
		addOption(option);

        var option:Option = new Option('noteHitEvent for stages',
			"If unchecked, the game will not send any noteHitEvent on stage.\nNot recommended to disable this option for vanilla stages.",
			'noteHitStage',
			BOOL);
		addOption(option);

		var option:Option = new Option('noteHitEvents for Skipped Notes',
			"If unchecked, the game will not send any hit event\non Lua/HScript for skipped notes. Improves performance.",
			'skipNoteEvent',
			BOOL);
		addOption(option);

        var option:Option = new Option('Disable Garbage Collector',
			"If checked, You can play the main game without GC lag.\nIt only works on loading/playing charts.",
			'disableGC',
			BOOL);
		addOption(option);

        super();
    }

	function onChangeLimitCount(){
		limitCount.scrollSpeed = interpolate(30, 50000, (holdTime - 0.5) / 10, 3);
	}

	function onChangeCacheCount(){
		cacheCount.scrollSpeed = interpolate(30, 50000, (holdTime - 0.5) / 10, 3);
	}
}
