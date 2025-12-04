#if desktop
package backend;

import lime.math.Rectangle;
import haxe.io.Bytes;
import haxe.ds.Vector;
import lime.app.Application;
import lime.graphics.Image;
import flixel.FlxG;
import lime.ui.Window;
import sys.FileSystem;
import options.GameRendererSettingsSubState;

class FFMpeg {
    var x:Int;
    var y:Int;
    var width:Int;
    var height:Int;
    var image:Image;
    var bytes:Bytes;
    var window:Window;
    var buffer:Rectangle;

    public var target = "render_video";
    public var fileName = '';
    public var fileExts = '.mp4';
    public var wentPreview:String;
    public var process:Process;

    public static var instance:FFMpeg;

    public function new() {}

    public function init() {
        if (NativeFileSystem.exists(target)) {
            if (!NativeFileSystem.isDirectory(target)) {
                NativeFileSystem.deleteFile(target);
                NativeFileSystem.createDirectory(target);
            }
        } else NativeFileSystem.createDirectory(target);

        window = FlxG.stage.application.window;

        x = window.width;
        y = window.height;
    }

    public function setup(testMode:Bool = false) {
        var executable:String = #if windows 'ffmpeg.exe' #else 'ffmpeg' #end;
        if (!FileSystem.exists(executable)) {
            if (testMode) {
                throw "not found ffmpeg";
            } else {
                trace('"$executable" not found, turning on preview mode...');
                ClientPrefs.data.previewRender = true;

                FlxG.sound.play(Paths.sound('cancelMenu'), ClientPrefs.data.sfxVolume);
                wentPreview = executable + " was not found";
                return;
            }
        }
        var curCodec:String = ClientPrefs.data.codec;

        var isGPU:Bool = CoolUtil.searchFromStrings(curCodec, ['QSV', 'NVENC', 'AMF' ,'VAAPI']);
        if (CoolUtil.searchFromString(curCodec, 'VP')) fileExts = ".webm";

        if (!testMode) {
            fileName = target + '/' + Paths.formatToSongPath(testMode ? "test" : PlayState.SONG.song);
            if (FileSystem.exists(fileName + fileExts)) {
                var millis = CoolUtil.fillNumber(Std.int(haxe.Timer.stamp() * 1000.0) % 1000, 3, 48);
                fileName += "-" + DateTools.format(Date.now(), "%Y-%m-%d_%H-%M-%S-") + millis;
            }
        } else {
            fileName = target + '/test-codec-' + curCodec;
        }

        var arguments:Array<String> = [
            '-v', 'quiet', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba',
            '-s', x + 'x' + y, '-r', Std.string(ClientPrefs.data.targetFPS), '-i', '-',
            '-c:v', GameRendererSettingsSubState.codecMap[curCodec]
        ];
        switch (ClientPrefs.data.encodeMode) {
            case "CRF/CQP":
                arguments.push('-b:v');
                arguments.push('0');
                arguments.push(isGPU ? '-qp' : '-crf');
                arguments.push(Std.string(ClientPrefs.data.constantQuality));
            case 'VBR', 'CBR':
                arguments.push('-b:v');
                arguments.push(Std.string(ClientPrefs.data.bitrate * 1_000_000));
                if (ClientPrefs.data.encodeMode == 'CBR') {
                    arguments.push('-maxrate');
                    arguments.push(Std.string(ClientPrefs.data.bitrate * 1_000_000));
                    arguments.push('-minrate');
                    arguments.push(Std.string(ClientPrefs.data.bitrate * 1_000_000));
                }
        }
        arguments.push(fileName + fileExts);
        
        if (!ClientPrefs.data.previewRender && !testMode) trace("running " + arguments);
        process = new Process('ffmpeg', arguments);

        buffer = new Rectangle(0, 0, x, y);
        FlxG.autoPause = false;
        
        // ready to render video
        if (!testMode) FlxG.sound.play(Paths.sound('confirmMenu'), ClientPrefs.data.sfxVolume);
    }

    public function pipeFrame():Void
    {
        image = window.readPixels();
        bytes = image.getPixels(buffer);
        process.stdin.write(bytes);
    }

    public function destroy():Void
    {
        if (process != null){
            if (process.stdin != null)
                process.stdin.close();
            process.close();
            process.kill();
        }

        FlxG.autoPause = ClientPrefs.data.autoPause;
    }
}
#end