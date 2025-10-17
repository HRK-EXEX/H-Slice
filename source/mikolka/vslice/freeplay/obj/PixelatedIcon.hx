package mikolka.vslice.freeplay.obj;

import mikolka.compatibility.funkin.FunkinPath;
import mikolka.compatibility.ModsHelper;
import mikolka.compatibility.freeplay.FreeplayHelpers;
import flixel.FlxSprite;
import mikolka.funkin.FlxFilteredSprite;

/**
 * The icon that gets used for Freeplay capsules and char select
 * NOT to be confused with the CharIcon class, which is for the in-game icons
 */
class PixelatedIcon extends FlxFilteredSprite
{
	private inline static final ICON_FRAMERATE = 10;
	public var type:IconType;
	public var thirdIcon:Bool;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		this.makeGraphic(32, 32, 0x00000000);
		this.antialiasing = false;
		this.active = false;
	}


	public function setCharacter(char:String):Void
	{
		// ? rewrote this to allow for cuistom character icons
		// 60, 10
		// trace(char);
		if (char.startsWith("icon-")) char = char.replace("icon-", "");
		type = IconType.LEGACY;
		if (FunkinPath.exists('images/freeplay/icons/${char}pixel.png'))
		{
			if (FunkinPath.exists('images/freeplay/icons/${char}pixel.xml'))
				type = ANIMATED;
			else
				type = PIXEL;
		}
		switch (type)
		{
			case LEGACY:
				// Legacy FNF icon (no freeplay one)
				var charPath:String = "icons/";
				charPath += "icon-";
				charPath += '${char}';
				
				var image = Paths.image(charPath, ClientPrefs.data.cacheOnGPU);
				if (image == null) // TODO
				{
					#if debug trace('[WARN] Character ${char} has no freeplay icon.'); #end
					image = Paths.image("icons/icon-face");
					// healthIcon = true;
				}
				var iSize:Float = Math.max(Math.round(image.width / image.height), 1);
				// trace(iSize, image.width, Math.round(image.width / iSize));
				this.loadGraphic(image, true, Math.round(image.width / iSize), Math.round(image.height));
				animation.add("idle", [0]);
				animation.add("confirm", [1]);
				if (iSize > 2) animation.add("favorite", [2]);

				thirdIcon = iSize > 2;

				this.scale.x = this.scale.y = 0.58;
				this.updateHitbox();
				this.origin.x = 100;
				this.antialiasing = ClientPrefs.data.antialiasing;
			case PIXEL:
				// legacy P-Slice freeplay icons
				var image = Paths.image('freeplay/icons/${char}pixel');
				this.loadGraphic(image);
				this.scale.x = this.scale.y = 2;
				this.updateHitbox();
				animation.add("idle", [0]);
				animation.add("confirm", [0]);
				this.origin.x = 25;
				if (char == "parents")
					this.origin.x = 55;
			case ANIMATED:
				// NEW freeplay animated icon
				frames = FunkinPath.getSparrowAtlas('freeplay/icons/${char}pixel');
				this.active = true;
				this.scale.x = this.scale.y = 2;
				this.updateHitbox();
				this.animation.addByPrefix('idle', 'idle', 10, true);
				this.animation.addByPrefix('confirm', 'confirm', 10, false);
				this.animation.addByPrefix('confirm-hold', 'confirm-hold', 10, true);

				this.animation.finishCallback = function(name:String):Void
				{
					trace('Finish pixel animation: ${name}');
					if (name == 'confirm')
						this.animation.play('confirm-hold');
				};
				this.origin.x = 25;
				if (char == "parents")
					this.origin.x = 55;
		}
		favoriteAnim();
	}

	public function favoriteAnim(isFavorited:Bool = false) {
		if (isFavorited && thirdIcon)
			animation.play("favorite");
		else
			animation.play("idle");
	}
}

enum IconType
{
	LEGACY;
	PIXEL;
	ANIMATED;
}
