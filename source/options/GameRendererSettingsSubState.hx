package options;

import flixel.system.ui.FlxSoundTray;
import backend.FFMpeg;
import flixel.input.gamepad.FlxGamepad;

class GameRendererSettingsSubState extends BaseOptionsMenu
{
	var fpsOption:Option;
	var bitOption:Option;
	var gcRateOption:Option;
	var testOption:Option;
	
	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	
	public static final codecList:Array<String> = [
		'H.264',
		'H.264 (QSV)',
		'H.264 (NVENC)',
		'H.264 (AMF)',
		'H.264 (VAAPI)',
		'H.265',
		'H.265 (QSV)',
		'H.265 (NVENC)',
		'H.265 (AMF)',
		'H.265 (VAAPI)',
		'VP8',
		'VP8 (VAAPI)',
		'VP9',
		'VP9 (VAAPI)',
		'AV1',
		'AV1 (NVENC for RTX40)'
	];
	
    public static final codecMap:Map<String, String> = [
        'H.264' => 'libx264',
        'H.264 (QSV)' => 'h264_qsv',
        'H.264 (NVENC)' => 'h264_nvenc',
        'H.264 (AMF)' => 'h264_amf',
        'H.264 (VAAPI)' => 'h264_vaapi',
        'H.265' => 'libx265',
        'H.265 (QSV)' => 'hevc_qsv',
        'H.265 (NVENC)' => 'hevc_nvenc',
        'H.265 (AMF)' => 'hevc_amf',
        'H.265 (VAAPI)' => 'hevc_vaapi',
        'VP8' => 'libvpx',
        'VP8 (VAAPI)' => 'libvpx_vaapi',
        'VP9' => 'libvp9',
        'VP9 (VAAPI)' => 'libvp9_vaapi',
        'AV1' => 'libsvtav1',
        'AV1 (NVENC for RTX40)' => 'av1_nvenc'
    ];

	public function new()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Game Renderer", null);
		#end
		
		title = 'Game Renderer';
		rpcTitle = 'Game Renderer Settings Menu'; //for Discord Rich Presence

		//Working in Progress!
        var option:Option = new Option('Working in Progress', //Name
			"Make changes at your own risk.", //Description
			'openDoor', //Save data variable name
			STRING,
			['!']); //Variable type
		addOption(option);

        var option:Option = new Option('Use Game Renderer',
			"If checked, It renders a video.\nAnd It forces turn on Botplay and disable debug menu key.",
			'ffmpegMode',
			BOOL);
		option.onChange = resetTimeScale;
		addOption(option);

        var option:Option = new Option('Garbage Collection Rate',
			"Have GC run automatically based on this option.\nSpecified by Frame and It turn on GC forcely.\n0 means disabled. Beware of memory leaks!",
			'gcRate',
			INT);
		addOption(option);
		
		option.minValue = 0;
		option.maxValue = 10000;
		option.scrollSpeed = 60;
		option.decimals = 0;
		option.onChange = onChangeGCRate;
		gcRateOption = option;

		var option:Option = new Option('Run Major Garbage Collection',
			"Increase the GC range and reduce memory usage.\nIt's for upper option.",
			'gcMain',
			BOOL);
		addOption(option);

        var option:Option = new Option('Video Framerate',
			"How much do you need fps in your video?",
			'targetFPS',
			INT);
		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 1;
		option.maxValue = 1000;
		option.scrollSpeed = 30;
		option.decimals = 0;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		fpsOption = option;
		addOption(option);

		var option:Option = new Option('Video Codec',
			"It's advanced Option. If you don't know, leave this 'H.264'.",
			'codec',
			STRING,
			codecList);
		addOption(option);

		var option:Option = new Option('Encode Mode',
			"It's advanced Option.\nSelect the mode of rendering you want.",
			'encodeMode',
			STRING,
			['CRF/CQP', 'VBR', 'CBR']);
		option.onChange = resetTimeScale;
		addOption(option);

		var option:Option = new Option('Video Bitrate',
			"Set bitrate in here.",
			'bitrate',
			FLOAT);
		option.minValue = 0.01;
		option.maxValue = 100;
		option.changeValue = 0.01;
		option.scrollSpeed = 3;
		option.decimals = 2;
		option.displayFormat = '%v Mbps';
		bitOption = option;
		option.onChange = onChangeBitrate;

		addOption(option);

		var option:Option = new Option('Video Quality',
			"The quality which set here is constant.",
			'constantQuality',
			FLOAT);
		addOption(option);

		option.minValue = 0;
		option.maxValue = 51;
		option.scrollSpeed = 20;
		option.decimals = 1;
		option.displayFormat = '%v';
		bitOption = option;

        var option:Option = new Option('Unlock Framerate',
			"If checked, fps limit goes 1000 in rendering.",
			'unlockFPS',
			BOOL);
		addOption(option);

        var option:Option = new Option('Pre Rendering',
			"If checked, Render current screen in the first of update method.\nIf unchecked, It does in the last of it.",
			'preshot',
			BOOL);
		addOption(option);

        var option:Option = new Option('Preview Mode',
			"If checked, Skip rendering.\nIf ffmpeg not found, force enabling this.\nIt's for a function for debug too.",
			'previewRender',
			BOOL);
		addOption(option);

        var option:Option = new Option('Test Rendering Each Encoders',
			"Try to test which is encoder available!",
			'dummy',
			BOOL);
		option.onChange = testRender;
		addOption(option);

        super();
		
		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		missingText.antialiasing = ClientPrefs.data.antialiasing;
		add(missingText);
    }

	function onChangeGCRate()
	{
		gcRateOption.scrollSpeed = interpolate(30, 1000, (holdTime - 0.5) / 5, 3);
	}

	function onChangeFramerate()
	{
		fpsOption.scrollSpeed = interpolate(30, 1000, (holdTime - 0.5) / 5, 3);
	}

	function onChangeBitrate()
	{
		bitOption.scrollSpeed = interpolate(1, 100, (holdTime - 0.5) / 5, 3);
	}

	function resetTimeScale()
	{
		FlxG.timeScale = 1;
	}

	function testRender()
	{
		var video:FFMpeg = new FFMpeg();
		var backupCodec = ClientPrefs.data.codec;
		var result:Bool = true;
		var output:String = 'FPS: ${ClientPrefs.data.targetFPS}, Mode: ${ClientPrefs.data.encodeMode}\n';
		var noFFMpeg:Bool = false;
		var message:String = "";

		video.target = "render_test";
		video.init();

		var cnt:Int = 0;
		var maxLength:Int = 0;
		var space:String;

		for (codec in codecList) {
			maxLength = FlxMath.maxInt(codec.length, maxLength);
		}

		for (codec in codecList) {
			space = "";
			ClientPrefs.data.codec = codec;
			// trace(codec);
			try {
				video.setup(true);
				video.pipeFrame();
				video.destroy();
				
				result = FileSystem.stat(video.fileName + video.fileExts).size != 0;
			} catch (e) {
				result = false;
				trace(e.message);
				message = e.message;
				if (message == "not found ffmpeg") {
					noFFMpeg = true; break;
				}
			}

			if (result) {
				++cnt;
				FlxG.sound.play(Paths.sound('soundtray/Volup'), ClientPrefs.data.sfxVolume);
			} else {
				FlxG.sound.play(Paths.sound('soundtray/Voldown'), ClientPrefs.data.sfxVolume);
			}

			for (i in 0...(maxLength - codec.length)) {
				space += " ";
			}

			output += 'Codec: ${ClientPrefs.data.codec},$space Result: ${result ? "PASS" : "fail"} $message\n';
		}

		output = output.substring(0, output.length - 1);

		missingText.visible = true;
		missingTextBG.visible = true;

		if (noFFMpeg) {
			missingText.text = "ERROR WHILE TESTING FFMPEG FEATURE:\nYou don't have 'FFMpeg.exe' in same Folder as H-Slice.";
			
			FlxG.sound.play(Paths.sound('cancelMenu'), ClientPrefs.data.sfxVolume);
		} else {
			missingText.text = 'Test simple result: $cnt/$maxLength codecs passed.\n\n' + output;
			// Sys.println('Test simple result: $cnt/$maxLength codecs passed.');
			// if (cnt != maxLength) 
			// 	Sys.println('Check avail_codecs.txt for details.');
		}

		missingText.screenCenter(Y);

		// CoolUtil.deleteDirectoryWithFiles(video.target);
		// File.saveContent("avail_codecs.txt", output);
		FlxG.sound.play(Paths.sound('soundtray/VolMAX'), ClientPrefs.data.sfxVolume);
		ClientPrefs.data.codec = backupCodec;
	}

	override function changeSelection(delta:Float, usePrecision:Bool = false) {
		super.changeSelection(delta, usePrecision);
		
		if (missingText != null) {
			missingText.visible = false;
			missingTextBG.visible = false;
		}
	}
}