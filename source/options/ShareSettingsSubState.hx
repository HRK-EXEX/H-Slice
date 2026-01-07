package options;

import lime.system.Clipboard;
import mikolka.vslice.components.crash.UserErrorSubstate;
import states.editors.content.FileDialogHandler;
import states.editors.content.PsychJsonPrinter;
import haxe.Json;

class ShareSettingsSubState extends BaseOptionsMenu {
    static var fileDialog:FileDialogHandler = new FileDialogHandler();
	var messageTextBG:FlxSprite;
	var messageText:FlxText;

    var offTimer:FlxTimer = new FlxTimer();

    public function new() {
		// Working in Progress!
        // var option:Option = new Option('Working in Progress', //Name
		// 	"Make changes at your own risk.", //Description
		// 	'openDoor', //Save data variable name
		// 	STRING,
		// 	['!']); //Variable type
		// addOption(option);
        
        // I chose the word "Settings" from among of [Configuration, Settings, Preferences, Options].
        // Thank you for answering the youtube survey!
        var option:Option = new Option('Export Settings',
			"Press ACCEPT Key to export settings.\nIt will be saved in JSON format."
            #if mobile + "\nThis device only supports using the clipboard." #end,
			'doExport',
			BOOL);
		option.onChange = exportJSON;
        option.setValue(false);
		addOption(option);

        var option:Option = new Option('Import Settings',
			"Press ACCEPT Key to import settings.\nWARNING! It overwrites your current settings if the loading is completed."
            #if mobile + "\nThis device only supports using the clipboard." #end,
			'doImport',
			BOOL);
		option.onChange = importJSON;
        option.setValue(false);
		addOption(option);
        
        var option:Option = new Option('Formatted JSON',
			"If checked, you can more easily view and edit the exported JSON.",
			'formatJS',
			BOOL);
		addOption(option);
        
        #if !mobile
        var option:Option = new Option('Use Clipboard Instead File',
			"If checked, it copies the json data into your clipboard instead of a json file.",
			'clipboard',
			BOOL);
		addOption(option);
        #end

        super();
        
		messageTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		messageTextBG.alpha = 0.6;
		messageTextBG.visible = false;
		add(messageTextBG);
		
		messageText = new FlxText(50, 0, FlxG.width - 100);
		messageText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		messageText.scrollFactor.set();
		messageText.visible = false;
		messageText.antialiasing = ClientPrefs.data.antialiasing;
		add(messageText);
    }

	override function changeSelection(delta:Float, usePrecision:Bool = false) {
		super.changeSelection(delta, usePrecision);
		
		if (messageText != null) {
			if (messageText.visible || messageTextBG.visible) {
				messageText.visible = false;
				messageTextBG.visible = false;
			}
		}
	}

    function turnOFF(playSnd:String = "") {
        if (CoolUtil.notBlank(playSnd)) FlxG.sound.play(Paths.sound(playSnd), ClientPrefs.data.sfxVolume);
        
        var o = curOption; // prevent to overwrite other configs
        o.setValue(true);
        reloadCheckboxes();

        if (offTimer.active) offTimer.cancel();
        offTimer.start(t -> {
            o.setValue(false);
            reloadCheckboxes();
        });
    }

    function showMsg(msg:String) {
        messageText.visible = true;
        messageTextBG.visible = true;

        messageText.text = msg;
		messageText.screenCenter(Y);
    }

    // export settings
    function exportJSON() {
        curOption.setValue(false); // it's not even a bug but it's for preventing to confuse
        var str = ClientPrefs.data.formatJS ? PsychJsonPrinter.print(ClientPrefs.data) : Json.stringify(ClientPrefs.data);
        if (#if mobile true #else ClientPrefs.data.clipboard #end) {
            Clipboard.text = str;
            turnOFF('confirmMenu');
            showMsg('Copied the json string on your clipboard!');
        } else {
            fileDialog.save('settings.json', str, 
                () -> { // succeed
                    turnOFF('confirmMenu');
                    showMsg('Exporting settings was completed successfully!\nCheck the saved file in ${fileDialog.path}');
                },
                () -> turnOFF('cancelMenu'), // cancelled
                () -> turnOFF('cancelMenu'), // failed, but it happened when cancelled or closed the window too
            );
        }
    }

    // import settings
    function importJSON() {
        curOption.setValue(false);
        try {
            if (#if mobile true #else ClientPrefs.data.clipboard #end) {
                if (!doImporting(Clipboard.text)) {
                    turnOFF('soundtray/VolMAX');
                    showMsg("Importing settings was failed.\nThe JSON format is incorrect on clipboard.");
                }
            } else {
                fileDialog.open('settings.json', 'Select the jsonified setting file.', null, 
                    () -> { // succeed
                        if (!doImporting(fileDialog.data)) {
                            turnOFF('soundtray/VolMAX');
                            showMsg("Importing settings was failed.\nThe JSON format is incorrect on file.");
                        }
                    }, 
                    () -> turnOFF('cancelMenu'), // cancelled
                    () -> turnOFF('cancelMenu'), // failed, but it happened when cancelled or closed the window too
                );
            }
        } catch (x) {
            turnOFF('soundtray/VolMAX');
            showMsg('Importing settings was failed by error: ${x.message}\n\n${x.stack}');
        }
		Main.fpsBg.relocate(0, 0, ClientPrefs.data.wideScreen);
    }

    function doImporting(str) {
        var data = null;
        if (str is String) data = Json.parse(str);
        else {
            trace('Given value isn\'t String type. Actual type is: ${Type.getClassName(Type.getClass(data))}');
            return false;
        }
        var skipCnt:Int = 0;

        var fields = Reflect.fields(data);
        var realFields = Type.getInstanceFields(Type.getClass(ClientPrefs.data));

        if (fields == null || fields.length == 0) {
            trace(fields == null ? "Null object" : "No length array");
            return false;
        }

        ClientPrefs.saveSettings();
        ClientPrefs.loadPrefs();
        for (key in fields) {
            if (!realFields.contains(key)) {
                trace('The $key field doesn\'t exist.');
                return false;
            }
        }
        
        for (key in fields) {
            if (key != 'gameplaySettings')
                Reflect.setField(ClientPrefs.data, key, Reflect.field(data, key));
        }

        var fields = skipCnt > 1 ? 'fields' : 'field';
        ClientPrefs.saveSettings();
        ClientPrefs.loadPrefs();
        turnOFF('confirmMenu');
        showMsg('Importing was completed successfully!');
        return true;
    }
}