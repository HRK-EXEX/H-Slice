package objects;

import objects.Note.CastNote;
import flixel.math.FlxRandom;

class SustainSplash extends FlxSprite
{
	public static var startCrochet:Float;
	public static var frameRate:Int;
	
	public var holding:Bool = false;
	public var note:Note;

	var rnd:FlxRandom;
	var timer:FlxTimer;

	public function new():Void
	{
		super();
		holding = false;
		note = new Note();
		note.visible = false;
		timer = new FlxTimer();

		x = -50000;
		rnd = new FlxRandom();

		frames = Paths.getSparrowAtlas('holdCovers/holdCover-' + ClientPrefs.data.holdSkin);

		animation.addByPrefix('hold', 'holdCover0', 24, true);
		animation.addByPrefix('end', 'holdCoverEnd0', 24, false);
		if(!animation.getNameList().contains("hold")) trace("Hold splash is missing 'hold' anim!");
	}

	override function update(elapsed)
	{
		super.update(elapsed);
		
		if (note.exists && note.strum != null)
		{
			setPosition(note.strum.x, note.strum.y);
			visible = note.strum.visible;
			alpha = ClientPrefs.data.holdSplashAlpha - (1 - note.strum.alpha);
		}
	}

	public function setupSusSplash(daNote:Note, ?playbackRate:Float = 1):Void
	{
		this.revive();
		var castNote:CastNote = daNote.toCastNote();
		this.note.recycleNote(castNote);
		note.strum = daNote.strum;
		// trace(note.isSustainEnds);
		timer.cancel();
		
		if (!note.isSustainEnds) {
			visible = true; holding = true;

			if (note.strum != null) setPosition(note.strum.x, note.strum.y);

			animation.play('hold', true, false, 0);
			if (animation.curAnim != null)
			{
				animation.curAnim.frameRate = frameRate;
				animation.curAnim.looped = true;
			}

			clipRect = new flixel.math.FlxRect(0, !PlayState.isPixelStage ? 0 : -210, frameWidth, frameHeight);

			if (note.shader != null && note.rgbShader.enabled)
			{
				shader = new objects.NoteSplash.PixelSplashShaderRef().shader;
				shader.data.r.value = note.shader.data.r.value;
				shader.data.g.value = note.shader.data.g.value;
				shader.data.b.value = note.shader.data.b.value;
				shader.data.mult.value = note.shader.data.mult.value;
			}

			alpha = ClientPrefs.data.holdSplashAlpha - (1 - note.strum.alpha);
			offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);
		} else if (holding && ClientPrefs.data.holdSkin != "None") {
			timer.start(startCrochet / playbackRate * 0.001, t -> showEndSplash(true));
		}
	}

	public function sendSustainEnd(anim:Bool = true) {
		if (holding) showEndSplash(anim);
	}

	public function isTimerWorking() {
		return timer.active;
	}

	function showEndSplash(anim:Bool) {
		holding = false;
		if (anim && animation != null)
		{
			alpha = ClientPrefs.data.holdSplashAlpha - (1 - note.strum.alpha);
			animation.play('end', true, false, 0);
			animation.curAnim.looped = false;
			animation.curAnim.frameRate = rnd.int(22, 26);
			clipRect = null;
			animation.finishCallback = idkEither -> kill();
			return;
		} else kill();
	}

	override function kill() {
		holding = false;
		timer.cancel();
		super.kill();
	}
}
