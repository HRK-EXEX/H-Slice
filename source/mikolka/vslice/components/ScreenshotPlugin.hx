package mikolka.vslice.components;

import mikolka.compatibility.funkin.FunkinControls;
import mikolka.vslice.components.crash.UserErrorSubstate;
import mikolka.compatibility.VsliceOptions;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import flixel.addons.util.FlxAsyncLoop;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.events.MouseEvent;
import flixel.addons.plugin.screengrab.FlxScreenGrab;

typedef ScreenshotPluginParams =
{
  ?region:Rectangle,
  flashColor:Null<FlxColor>,
};

/**
 * TODO: Contribute this upstream.
 */
class ScreenshotPlugin extends FlxBasic
{
  /**
   * Current `ScreenshotPlugin` instance
   */
  public static var instance:ScreenshotPlugin = null;

  public static final SCREENSHOT_FOLDER = 'screenshots';

  var region:Null<Rectangle>;

  /**
   * The color used for the flash
   */
  public static var flashColor(default, set):Int = 0xFFFFFFFF;

  public static function set_flashColor(v:Int):Int
  {
    flashColor = v;
    if (instance != null && instance.flashBitmap != null) instance.flashBitmap.bitmapData = new BitmapData(lastWidth, lastHeight, true, v);
    return flashColor;
  }

  /**
   * A signal fired before the screenshot is taken.
   */
  public var onPreScreenshot(default, null):FlxSignal;

  /**
   * A signal fired after the screenshot is taken.
   * @param bitmap The bitmap that was captured.
   */
  public var onPostScreenshot(default, null):FlxTypedSignal<Bitmap->Void>;

  private static var lastWidth:Int;
  private static var lastHeight:Int;
  private static var HIDE_MOUSE:Bool = false;
  private static var PREVIEW:Bool = true;
  private static var PREVIEW_ONSAVE:Bool = true;
  private static var SAVE_FORMAT:String = "png";

  var flashSprite:Sprite;
  var flashBitmap:Bitmap;
  var previewSprite:Sprite;
  var shotPreviewBitmap:Bitmap;
  var outlineBitmap:Bitmap;

  var wasMouseHidden:Bool = false; // Used for hiding and then showing the mouse
  var wasMouseShown:Bool = false; // Used for showing and then hiding the mouse
  var screenshotTakenFrame:Int = 0;

  var screenshotBeingSpammed:Bool = false;

  var screenshotSpammedTimer:FlxTimer;

  var screenshotBuffer:Array<Bitmap> = [];
  var screenshotNameBuffer:Array<String> = [];

  var unsavedScreenshotBuffer:Array<Bitmap> = [];
  var unsavedScreenshotNameBuffer:Array<String> = [];

  var stateChanging:Bool = false;
  var noSavingScreenshots:Bool = false;

  var flashTween:FlxTween;

  var previewFadeInTween:FlxTween;
  var previewFadeOutTween:FlxTween;

  var asyncLoop:FlxAsyncLoop;

  public function new(params:ScreenshotPluginParams)
  {
    super();

    if (instance != null)
    {
      destroy();
      return;
    }

    instance = this;

    lastWidth = FlxG.width;
    lastHeight = FlxG.height;

    flashSprite = new Sprite();
    flashSprite.alpha = 0;
    flashBitmap = new Bitmap(new BitmapData(lastWidth, lastHeight, true, params.flashColor));
    flashSprite.addChild(flashBitmap);

    previewSprite = new Sprite();
    previewSprite.alpha = 0;

    outlineBitmap = new Bitmap(new BitmapData(Std.int(lastWidth / 5) + 10, Std.int(lastHeight / 5) + 10, true, 0xFFFFFFFF));
    outlineBitmap.x = 5;
    outlineBitmap.y = 5;
    previewSprite.addChild(outlineBitmap);

    shotPreviewBitmap = new Bitmap();
    shotPreviewBitmap.scaleX /= 5;
    shotPreviewBitmap.scaleY /= 5;

    previewSprite.addChild(shotPreviewBitmap);
    #if !debug // I hate this sooo much
    FlxG.stage.addChild(flashSprite);
    #end

    region = params.region ?? null;
    flashColor = params.flashColor;

    onPreScreenshot = new FlxTypedSignal<Void->Void>();
    onPostScreenshot = new FlxTypedSignal<Bitmap->Void>();
    FlxG.signals.gameResized.add(this.resizeBitmap);
    FlxG.signals.preStateSwitch.add(this.saveUnsavedBufferedScreenshots);
    FlxG.signals.postStateSwitch.add(this.postStateSwitch);
    // Called when clicking the X button on the window.
    //WindowUtil.windowExit.add(onWindowClose);

    // // Called when the game crashes.
    // CrashHandler.errorSignal.add(onWindowCrash);
    // CrashHandler.criticalErrorSignal.add(onWindowCrash);
  }

  public override function update(elapsed:Float):Void
  {
    if (asyncLoop != null)
    {
      // If the loop hasn't started yet, start it
      if (!asyncLoop.started)
      {
        asyncLoop.start();
      }
      else
      {
        // if the loop has been started, and is finished, then we kill. it
        if (asyncLoop.finished)
        {
          if (screenshotBuffer != [])
          {
            trace("finished processing screenshot buffer");
            screenshotBuffer = [];
            screenshotNameBuffer = [];
          }
          // your honor, league of legends
          asyncLoop.kill();
          asyncLoop.destroy();
          asyncLoop = null;
        }
      }
      // Examples ftw!
    }
    super.update(elapsed);

    /**
     * This looks scary, oh no I pressed the button but no screenshot because screenshotTakenFrame != 0!
     * But if you're crazy enough to have a macro that bumps into this
     * then you're probably also going to hit 100 screenshots real fast
     */
    if (hasPressedScreenshot() && screenshotTakenFrame == 0)
    {
      if (FlxG.keys.pressed.SHIFT)
      {
        openScreenshotsFolder();
        return; // We're only opening the screenshots folder (we don't want to accidentally take a screenshot after this)
      }
      if (HIDE_MOUSE && !wasMouseHidden && FlxG.mouse.visible)
      {
        wasMouseHidden = true;
        FlxG.mouse.visible = false;
      }
      for (sprite in [flashSprite, previewSprite])
      {
        FlxTween.cancelTweensOf(sprite);
        sprite.alpha = 0;
      }
      // screenshot spamming timer
      if (screenshotSpammedTimer == null || screenshotSpammedTimer.finished == true)
      {
        screenshotSpammedTimer = new FlxTimer().start(1, function(_) {
          // The player's stopped spamming shots, so we can stop the screenshot spam mode too
          screenshotBeingSpammed = false;
          if (screenshotBuffer[0] != null) saveBufferedScreenshots(screenshotBuffer, screenshotNameBuffer);
          if (!PREVIEW && wasMouseHidden && !FlxG.mouse.visible)
          {
            wasMouseHidden = false;
            FlxG.mouse.visible = true;
          }
        });
      }
      else // Pressing the screenshot key more than once every second enables the screenshot spam mode and resets the timer
      {
        screenshotBeingSpammed = true;
        screenshotSpammedTimer.reset(1);
      }
      FlxG.stage.removeChild(previewSprite);
      screenshotTakenFrame++;
    }
    else if (screenshotTakenFrame > 1)
    {
      screenshotTakenFrame = 0;
      capture(); // After all these checks and waiting a frame, we finally try taking a screenshot
    }
    else if (screenshotTakenFrame > 0)
    {
      screenshotTakenFrame++;
    }
  }

  /**
   * Initialize the screenshot plugin.
   */
  public static function initialize():Void
  {
    #if LEGACY_PSYCH FlxG.plugins.add
    #else FlxG.plugins.addPlugin
    #end 
    (new ScreenshotPlugin(
      {
        flashColor: VsliceOptions.FLASHBANG ? FlxColor.WHITE : null, // Was originally a black flash.
      }));
    
  }

  public function hasPressedScreenshot():Bool
  {
    return FunkinControls.SCREENSHOT && !noSavingScreenshots;
  }

  public function updateFlashColor():Void
  {
    VsliceOptions.FLASHBANG ? set_flashColor(FlxColor.WHITE) : null;
  }

  private function resizeBitmap(width:Int, height:Int)
  {
    lastWidth = width;
    lastHeight = height;
    flashBitmap.bitmapData = new BitmapData(lastWidth, lastHeight, true, flashColor);
    outlineBitmap.bitmapData = new BitmapData(Std.int(lastWidth / 5) + 10, Std.int(lastHeight / 5) + 10, true, 0xFFFFFFFF);
  }

  /**
   * Capture the game screen as a bitmap.
   */
  public function capture():Void
  {
    onPreScreenshot.dispatch();

    var shot = new Bitmap(BitmapData.fromImage(FlxG.stage.window.readPixels()));
    if (screenshotBeingSpammed == true)
    {
      // Save the screenshots to the buffer instead
      if (screenshotBuffer.length < 15)
      {
        screenshotBuffer.push(shot);
        screenshotNameBuffer.push('screenshot-${DateUtil.generateTimestamp()}');

        unsavedScreenshotBuffer.push(shot);
        unsavedScreenshotNameBuffer.push('screenshot-${DateUtil.generateTimestamp()}');
      }
      else
      {
        noSavingScreenshots = true;
        screenshotBuffer = [];
        screenshotNameBuffer = [];
        UserErrorSubstate.makeMessage("Too many screenshots!",
          "You've tried taking more than 15 screenshots at a time. Give the game a funkin break! Jeez.\n\n\nIf you wanted those screenshots, well too bad!");
        FlxG.state.subStateClosed.addOnce(state -> {
            noSavingScreenshots = false;
        });

      }
      showCaptureFeedback();
      if (wasMouseHidden && !FlxG.mouse.visible && VsliceOptions.FLASHBANG) // Just in case
      {
        wasMouseHidden = false;
        FlxG.mouse.visible = true;
      }
      if (!PREVIEW_ONSAVE) showFancyPreview(shot);
    }
    else
    {
      // Save the screenshot immediately, so it doesn't get lost by a state change
      saveScreenshot(shot, 'screenshot-${DateUtil.generateTimestamp()}', 1, false);
      // Show some feedback.
      showCaptureFeedback();
      if (wasMouseHidden && !FlxG.mouse.visible)
      {
        wasMouseHidden = false;
        FlxG.mouse.visible = true;
      }
      if (!PREVIEW_ONSAVE) showFancyPreview(shot);
    }
    onPostScreenshot.dispatch(shot);
  }

  final CAMERA_FLASH_DURATION = 0.25;

  /**
   * Visual and audio feedback when a screenshot is taken.
   */
  function showCaptureFeedback():Void
  {
    if (stateChanging) return; // Flash off!
    flashSprite.alpha = 1;
    FlxTween.tween(flashSprite, {alpha: 0}, 0.15);

    FlxG.sound.play(Paths.sound('screenshot'), ClientPrefs.data.sfxVolume);
  }

  static final PREVIEW_INITIAL_DELAY = 0.25; // How long before the preview starts fading in.
  static final PREVIEW_FADE_IN_DURATION = 0.3; // How long the preview takes to fade in.
  static final PREVIEW_FADE_OUT_DELAY = 1.25; // How long the preview stays on screen.
  static final PREVIEW_FADE_OUT_DURATION = 0.3; // How long the preview takes to fade out.

  /**
   * Show a fancy preview for the screenshot
   */
  function showFancyPreview(shot:Bitmap):Void
  {
    if (!PREVIEW || screenshotBeingSpammed && !VsliceOptions.FLASHBANG || stateChanging) return; // Sorry, the previews' been cancelled
    shotPreviewBitmap.bitmapData = shot.bitmapData;
    shotPreviewBitmap.x = outlineBitmap.x + 5;
    shotPreviewBitmap.y = outlineBitmap.y + 5;

    shotPreviewBitmap.width = outlineBitmap.width - 10;
    shotPreviewBitmap.height = outlineBitmap.height - 10;

    // Remove the existing preview
    FlxG.stage.removeChild(previewSprite);

    // ermmm stealing this??

    if (!wasMouseShown && !wasMouseHidden && !FlxG.mouse.visible)
    {
      wasMouseShown = true;
      FlxG.mouse.visible = true;
    }

    // so that it doesnt change the alpha when tweening in/out
    var changingAlpha:Bool = false;
    var targetAlpha:Float = 1;

    // fuck it, cursed locally scoped functions, purely because im lazy
    // (and so we can check changingAlpha, which is locally scoped.... because I'm lazy...)
    var onHover = function(e:MouseEvent) {
      if (!changingAlpha) e.target.alpha = 0.6;
      targetAlpha = 0.6;
    };

    var onHoverOut = function(e:MouseEvent) {
      if (!changingAlpha) e.target.alpha = 1;
      targetAlpha = 1;
    }

    // used for movement + button stuff
    previewSprite.buttonMode = true;
    previewSprite.addEventListener(MouseEvent.MOUSE_DOWN, previewSpriteOpenScreenshotsFolder);
    previewSprite.addEventListener(MouseEvent.MOUSE_MOVE, onHover);
    previewSprite.addEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

    FlxTween.cancelTweensOf(previewSprite); // Reset the tweens
    FlxG.stage.addChild(previewSprite);
    previewSprite.alpha = 0.0;
    previewSprite.y -= 10;
    // set the alpha to 0.6 if the mouse is already over the preview sprite
    if (previewSprite.hitTestPoint(previewSprite.mouseX, previewSprite.mouseY)) targetAlpha = 0.6;
    // Wait to fade in.
    new FlxTimer().start(PREVIEW_INITIAL_DELAY, function(_) {
      // Fade in.
      changingAlpha = true;
      FlxTween.tween(previewSprite, {alpha: targetAlpha, y: 0}, PREVIEW_FADE_IN_DURATION,
        {
          ease: FlxEase.quartOut,
          onComplete: function(_) {
            changingAlpha = false;
            // Wait to fade out.
            new FlxTimer().start(PREVIEW_FADE_OUT_DELAY, function(_) {
              changingAlpha = true;
              // Fade out.
              FlxTween.tween(previewSprite, {alpha: 0.0, y: 10}, PREVIEW_FADE_OUT_DURATION,
                {
                  ease: FlxEase.quartInOut,
                  onComplete: function(_) {
                    if (wasMouseShown && FlxG.mouse.visible)
                    {
                      wasMouseShown = false;
                      FlxG.mouse.visible = false;
                    }
                    else if (wasMouseHidden && !FlxG.mouse.visible)
                    {
                      wasMouseHidden = false;
                      FlxG.mouse.visible = true;
                    }

                    previewSprite.removeEventListener(MouseEvent.MOUSE_DOWN, previewSpriteOpenScreenshotsFolder);
                    previewSprite.removeEventListener(MouseEvent.MOUSE_OVER, onHover);
                    previewSprite.removeEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

                    FlxG.stage.removeChild(previewSprite);
                  }
                });
            });
          }
        });
    });
  }

  /**
   * This is a separate function, as running the previewsprite check
   * in the other one would mean you can't open the folder when the preview's hidden, lol
   * That, and it needs a mouse event as a parameter to work.
   */
  function previewSpriteOpenScreenshotsFolder(e:MouseEvent):Void
  {
    if (previewSprite.alpha <= 0) return;
    openScreenshotsFolder();
  }

  function openScreenshotsFolder():Void
  {
    FileUtil.openFolder(SCREENSHOT_FOLDER);
  }

  // Save them, save the screenshots
  function onWindowClose(exitCode:Int):Void
  {
    if (noSavingScreenshots) return; // sike
    saveUnsavedBufferedScreenshots();
  }

  function onWindowCrash(message:String):Void
  {
    if (noSavingScreenshots) return;
    saveUnsavedBufferedScreenshots();
  }

  static function getCurrentState():FlxState
  {
    var state = FlxG.state;
    while (state.subState != null)
    {
      state = state.subState;
    }
    return state;
  }

  static function getScreenshotPath():String
  {
    return '$SCREENSHOT_FOLDER/';
  }

  static function makeScreenshotPath():Void
  {
    FileUtil.createDirIfNotExists(SCREENSHOT_FOLDER);
  }

  /**
   * Convert a Bitmap to a PNG or JPEG ByteArray to save to a file.
   */
  function encode(bitmap:Bitmap):ByteArray
  {
    var compressor = returnEncoder(SAVE_FORMAT);
    return bitmap.bitmapData.encode(bitmap.bitmapData.rect, compressor);
  }

  var previousScreenshotName:String;
  var previousScreenshotCopyNum:Int;

  /**
   * Save the generated bitmap to a file.
   * @param bitmap The bitmap to save.
   * @param targetPath The name of the screenshot.
   * @param screenShotNum Used for the delay save option, to space out the saving of the images.
   * @param delaySave If true, the image gets saved with the screenShotNum as the delay.
   */
  function saveScreenshot(bitmap:Bitmap, targetPath = "image", screenShotNum:Int = 0, delaySave:Bool = true)
  {
    makeScreenshotPath();
    // Check that we're not overriding a previous image, and keep making a unique path until we can
    if (previousScreenshotName != targetPath && previousScreenshotName != (targetPath + ' (${previousScreenshotCopyNum})'))
    {
      previousScreenshotName = targetPath;
      targetPath = getScreenshotPath() + targetPath + '.' + Std.string(SAVE_FORMAT).toLowerCase();
      previousScreenshotCopyNum = 2;
    }
    else
    {
      var newTargetPath:String = targetPath + ' (${previousScreenshotCopyNum})';
      while (previousScreenshotName == newTargetPath)
      {
        previousScreenshotCopyNum++;
        newTargetPath = targetPath + ' (${previousScreenshotCopyNum})';
      }
      previousScreenshotName = newTargetPath;
      targetPath = getScreenshotPath() + newTargetPath + '.' + Std.string(SAVE_FORMAT).toLowerCase();
    }

    // TODO: Make this work on browser.
    // Maybe save the images into a buffer that you can download as a zip or something? That'd work
    // Shouldn't be too hard to do something similar to the chart editor saving

    if (delaySave) // Save the images with a delay (a timer)
      new FlxTimer().start(screenShotNum, function(_) {
        var pngData = encode(bitmap);

        if (pngData == null)
        {
          trace('[WARN] Failed to encode ${SAVE_FORMAT} data');
          previousScreenshotName = null;
          // Just in case
          unsavedScreenshotBuffer.shift();
          unsavedScreenshotNameBuffer.shift();
          return;
        }
        else
        {
          trace('Saving screenshot to: ' + targetPath);
          FileUtil.writeBytesToPath(targetPath, pngData);
          // Remove the screenshot from the unsaved buffer because we literally just saved it
          unsavedScreenshotBuffer.shift();
          unsavedScreenshotNameBuffer.shift();
          if (PREVIEW_ONSAVE) showFancyPreview(bitmap); // Only show the preview after a screenshot is saved
        }
      });
    else // Save the screenshot immediately
    {
      var pngData = encode(bitmap);

      if (pngData == null)
      {
        trace('[WARN] Failed to encode ${SAVE_FORMAT} data');
        previousScreenshotName = null;
        return;
      }
      else
      {
        trace('Saving screenshot to: ' + targetPath);
        FileUtil.writeBytesToPath(targetPath, pngData);
        if (PREVIEW_ONSAVE) showFancyPreview(bitmap); // Only show the preview after a screenshot is saved
      }
    }
  }

  // I' m very happy with this code, all of it just works
  function saveBufferedScreenshots(screenshots:Array<Bitmap>, screenshotNames)
  {
    trace('Saving screenshot buffer');
    var i:Int = 0;

    asyncLoop = new FlxAsyncLoop(screenshots.length, () -> {
      if (screenshots[i] != null)
      {
        saveScreenshot(screenshots[i], screenshotNames[i], i);
      }
      i++;
    }, 1);
    getCurrentState().add(asyncLoop);
    if (!VsliceOptions.FLASHBANG && !PREVIEW_ONSAVE)
      showFancyPreview(screenshots[screenshots.length - 1]); // show the preview for the last screenshot
  }

  /**
   * Similar to the above function, but cancels the tweens, undos the mouse
   * and doesn't have the async loop because this is called before the state changes
   */
  function saveUnsavedBufferedScreenshots()
  {
    stateChanging = true;
    // Cancel the tweens of the capture feedback if they're running
    if (flashSprite.alpha != 0 || previewSprite.alpha != 0)
    {
      for (sprite in [flashSprite, previewSprite])
      {
        FlxTween.cancelTweensOf(sprite);
        sprite.alpha = 0;
      }
    }

    // Undo the mouse stuff - we don't know what the next state will do with it
    if (wasMouseShown && FlxG.mouse.visible)
    {
      wasMouseShown = false;
      FlxG.mouse.visible = false;
    }
    else if (wasMouseHidden && !FlxG.mouse.visible)
    {
      wasMouseHidden = false;
      FlxG.mouse.visible = true;
    }

    if (unsavedScreenshotBuffer[0] == null) return;
    // There's unsaved screenshots, let's save them! (haha, get it?)

    trace('Saving unsaved screenshots in buffer!');

    for (i in 0...unsavedScreenshotBuffer.length)
    {
      if (unsavedScreenshotBuffer[i] != null) saveScreenshot(unsavedScreenshotBuffer[i], unsavedScreenshotNameBuffer[i], i, false);
    }

    unsavedScreenshotBuffer = [];
    unsavedScreenshotNameBuffer = [];
  }

  public function returnEncoder(saveFormat:String):Any
  {
    return switch (saveFormat)
    {
      // JPEG encoder causes the game to crash?????
      // case "JPEG": new openfl.display.JPEGEncoderOptions(Preferences.jpegQuality);
      default: new openfl.display.PNGEncoderOptions();
    }
  }

  function postStateSwitch()
  {
    stateChanging = false;
    screenshotBeingSpammed = false;
    FlxG.stage.removeChild(previewSprite);
  }

  override public function destroy():Void
  {
    if (instance == this) instance = null;

    if (FlxG.plugins.list.contains(this)) FlxG.plugins.remove(this);

    FlxG.signals.gameResized.remove(this.resizeBitmap);
    FlxG.signals.preStateSwitch.remove(this.saveUnsavedBufferedScreenshots);
    FlxG.signals.postStateSwitch.remove(this.postStateSwitch);
    FlxG.stage.removeChild(previewSprite);
    FlxG.stage.removeChild(flashSprite);
    // WindowUtil.windowExit.remove(onWindowClose);
    // CrashHandler.errorSignal.remove(onWindowCrash);
    // CrashHandler.criticalErrorSignal.remove(onWindowCrash);

    super.destroy();

    try{

      @:privateAccess
      for (parent in [flashSprite, previewSprite])
        for (child in parent.__children)
          parent.removeChild(child);
    }
    catch(x:Dynamic){
      trace("We caught an exception while trying to remove the screenshot plugin!");
    }

    flashSprite = null;
    flashBitmap = null;
    previewSprite = null;
    shotPreviewBitmap = null;
    outlineBitmap = null;
  }
}
