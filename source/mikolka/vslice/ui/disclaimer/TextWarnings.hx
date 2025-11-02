package mikolka.vslice.ui.disclaimer;

import flixel.FlxState;

class OutdatedState extends WarningState
{
	public function new(newVersion:String, nextState:FlxState)
	{
		final bro:String = #if mobile 'kiddo' #else 'bro' #end;
		final escape:String = (controls.mobileC) ? 'B' : 'ESCAPE';

		var guh:StringBuf = new StringBuf();

		guh.add('Sup $bro, looks like you\'re running an\n');
		guh.add('outdated version of H-Slice Engine (${MainMenuState.hrkVersion}),\n');
		guh.add('please update to $newVersion!\n');
		guh.add('Press $escape to proceed anyway.\n\n');
		guh.add('Thank you for using the Engine!\n');

		super(guh.toString(), () ->
		{
			CoolUtil.browserLoad("https://github.com/HRK-EXEX/H-Slice/releases");
			if (onExit != null)
				onExit();
		}, onExit, nextState);
	}
}

class FlashingState extends WarningState
{
	public function new(nextState:FlxState)
	{
		final enter:String = controls.mobileC ? 'A' : 'ENTER';
		final escape:String = controls.mobileC ? 'B' : 'ESCAPE';

		var text:StringBuf = new StringBuf();
		
		text.add("Hey, watch out!\n");
		text.add("This Mod contains some flashing lights!\n");
		text.add('Press $enter to disable them now or go to Options Menu.\n');
		text.add('Press $escape to ignore this message.\n\n');
		text.add("You've been warned!");

		super(text.toString(), () ->
		{
			#if LEGACY_PSYCH
			ClientPrefs.flashing = false;
			#else
			ClientPrefs.data.flashing = false;
			#end
			ClientPrefs.saveSettings();
		}, () -> {}, nextState);
	}
}
