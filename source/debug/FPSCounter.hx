package debug;

import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import lime.ui.Window;
import cpp.vm.Gc;
import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import lime.system.System as LimeSystem;

#if flash
import openfl.Lib;
#end
import external.memory.Memory;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public static var instance:FPSCounter;
	public var currentFPS(default, null):Int;
	public var fpsFontSize:Int = 16;
	public var fpsTextLength:Int = 0;

	var fps:Int = 0;
	var curTime:Float = 0;
	var frameTime:Float = 0;
	var multipleRate:Float = 1.0;
	public var updateRate:Float = 50;

	@:noCompletion private var cacheCount:Float;
	@:noCompletion private var times:Array<Int>;

	public var os:String = '';

	var deltaTimeout:Float = 0.0;
	var delta:Int = 0;

	var nanoSecond:Float = 0.0;
	var nanoDelay:Float = 0.0;

	var sliceCnt:Int = 0;
	var sum:Int = 0;
	var avg:Float = 0;

	var defineX:Float = 0;
	var defineY:Float = 0;

	var active:Bool = true;
	var updated:Bool = false;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();
		instance = this;

		defineX = x; defineY = y;

		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = 'OS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = 'OS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';

		positionFPS(defineX, defineY, ClientPrefs.data.wideScreen);

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(Paths.font("fps.ttf"), fpsFontSize, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";
		fps = ClientPrefs.data.framerate;
		updateRate = ClientPrefs.data.fpsRate;

		cacheCount = 0;
		times = [];
		
		deltaTimeout = avg = 0.0;
		delta = sliceCnt = sum = 0;
		
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
	}

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		if (!ClientPrefs.data.showFPS || !visible || FlxG.autoPause && !stage.nativeWindow.active) return;

		if (ClientPrefs.data.nanoPosition) {
			nanoDelay = CoolUtil.getNanoTime() - nanoSecond;
			nanoSecond = CoolUtil.getNanoTime();

			deltaTime = nanoDelay * 1000;
		}
		
		sliceCnt = 0; delta = Math.round(deltaTime);
		times.push(delta); sum += delta; updated = false;
		fps = ClientPrefs.data.framerate;

		while (sum > 1000) {
			sum -= times[sliceCnt];
			++sliceCnt;
		}
		if (sliceCnt > 0) times.splice(0, sliceCnt);

		avg = times.length > 0 ? 1000 / (sum / times.length) : 0.0;
		// trace(times.length, avg);

		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		deltaTimeout += deltaTime;
		if (deltaTimeout < 1000 / updateRate) return;
		
		// Literally the stupidest thing i've done for the FPS counter but it allows it to update correctly when on 60 FPS??
		currentFPS = Math.round(avg); //Math.round((times.length + cacheCount) * 0.5) - 1;
		updateText(Math.round(1000 / deltaTime));
		deltaTimeout = 0.0;
	}

	// so people can override it in hscript
	var fpsStr:String = "";
	
	var realFPS:String = '';
	var avgFPS:String = '';
	var targetFPS:String = '';
	public dynamic function updateText(deltaTime:Float) {
		if (ClientPrefs.data.ffmpegMode) {
			targetFPS = CoolUtil.fillNumber(ClientPrefs.data.targetFPS, FlxMath.minInt(4, Std.string(ClientPrefs.data.targetFPS).length+1), 32, false);
			fpsStr = 'FPS:$targetFPS - RENDERING${MemoryUtil.isGcEnabled ? '' : " / No GC"}\n';
		} else {
			realFPS = CoolUtil.fillNumber(deltaTime, FlxMath.minInt(4, Std.string(deltaTime).length+1), 32, false);
			avgFPS = CoolUtil.fillNumber(currentFPS, FlxMath.minInt(4, Std.string(currentFPS).length+1), 32, false);
			fpsStr = 'FPS:$realFPS |$avgFPS${MemoryUtil.isGcEnabled ? '' : " / No GC"}\n';
		}
		
		if (ClientPrefs.data.showMemory) {
			fpsStr += 'RAM: ${CoolUtil.formatBytes(Memory.getCurrentUsage(), 1, true)} / ${CoolUtil.formatBytes(Gc.memInfo64(Gc.MEM_INFO_USAGE), 1, true)}';
			if (ClientPrefs.data.showPeakMemory) fpsStr += ' / ${CoolUtil.formatBytes(Memory.getPeakUsage(), 1, true)}';
			fpsStr += '\n';
		}

		if (ClientPrefs.data.showOS) fpsStr += os;

		text = fpsStr;

		if (!ClientPrefs.data.ffmpegMode)
		{
			textColor = Std.int(
				0xFFFF0000 + 
				(Std.int(CoolUtil.normalize(currentFPS, 1, fps >> 1, true) * 255) << 8) + 
				Std.int(CoolUtil.normalize(currentFPS, fps >> 1, fps, true) * 255)
			);
		} else {
			textColor = 0xFFFFFFFF;
		}

		// fpsTextLength = text.length;
		// cacheCount = times.length;
	}

	public inline function positionFPS(X:Float, Y:Float, isWide:Bool = false, ?scale:Float = 1){
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		if (isWide) {
			x = X; y = Y;
		} else {
			x = FlxG.game.x + X;
			y = FlxG.game.y + Y;
		}
	}
	
	private function onKeyPress(event:KeyboardEvent):Void {
		var eventKey:FlxKey = event.keyCode;
		if (eventKey == FlxKey.F11 && ClientPrefs.data.f11Shortcut) FlxG.fullscreen = !FlxG.fullscreen;
	}

	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}
