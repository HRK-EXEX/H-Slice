package mikolka.compatibility.freeplay;

import hrk.Eseq;
import haxe.Json;
import haxe.Exception;
import backend.StageData;
import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import mikolka.vslice.components.crash.UserErrorSubstate;
import openfl.utils.AssetType;
import mikolka.vslice.freeplay.pslice.BPMCache;
import mikolka.vslice.freeplay.FreeplayState;
import backend.Song;
import backend.Highscore;

import backend.WeekData;

class FreeplayHelpers {
	public static var BPM(get,set):Float;
	public static function set_BPM(value:Float) {
		Conductor.bpm = value;
		return value;
	}
	public static function get_BPM() {
		return Conductor.bpm;
	}

	static var songs = [];
	static var leWeek:WeekData;
	static var colors:Array<Int>;
	static var sngCard:FreeplaySongData;
	static var offset:Int;
	static var songCount:Int;
    public static function loadSongs(){
		var noCache:Bool = false;
		songs = []; 
        songCount = offset = 0;
        WeekData.reloadWeekFiles(false);

		var bpmList:Dynamic = null;
		try {
			bpmList = Json.parse(File.getContent("assets/bpmList.json"));
		} catch (e) {trace('Bpm list file not found'); noCache = true;}

		// programmatically adds the songs via LevelRegistry and SongRegistry
		var songName:String = null;
		for (week in WeekData.weeksList) songCount += WeekData.weeksLoaded.get(week).songs.length;

		if (!noCache) {
			if (bpmList != null) {
				for (key in Reflect.fields(bpmList)) {
					if (!BPMCache.freeplayBPMs.exists(key)) {
						BPMCache.freeplayBPMs.set(key, Reflect.field(bpmList, key));
						songName = Paths.formatToSongPath(key.substring(key.lastIndexOf("/")+1));
					}
				}
			}
		}

		trace(songCount, BPMCache.count());
		if (songCount < BPMCache.count() || noCache) {
			BPMCache.clearCache(); // for good measure
		}

		for (i => week in WeekData.weeksList)
		{
			if (weekIsLocked(week))
				continue;

			leWeek = WeekData.weeksLoaded.get(week); // TODO tweak this
			if(leWeek == null) continue;
			
			WeekData.setDirectoryFromWeek(leWeek);
			for (j => song in leWeek.songs)
			{
				if (Main.isConsoleAvailable) {
					if (ClientPrefs.data.numberFormat)
						Eseq.p('\x1b[0GLoading Song (${CoolUtil.formatMoney(j+offset+1)}/${CoolUtil.formatMoney(songCount)})');
					else Eseq.p('\x1b[0GLoading Song (${j+offset+1}/$songCount)');
				}
			
				colors = song[2];
				if (colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				sngCard = new FreeplaySongData(i, song[0], song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				// songName, weekNum, songCharacter, color
				if (sngCard.songDifficulties.length == 0)
					continue;

				songs.push(sngCard);
			}
			offset += leWeek.songs.length;
		}
		Sys.print("\n");
		
		// for mobile compability
		#if mobile
		if (!NativeFileSystem.exists('assets'))
			NativeFileSystem.createDirectory('assets');
		#end

		File.saveContent("assets/bpmList.json", Json.stringify(BPMCache.freeplayBPMs));

        return songs;
    }

    public static function moveToPlaystate(state:FreeplayState,cap:FreeplaySongData,currentDifficulty:String,?targetInstId:String){
        // FunkinSound.emptyPartialQueue();

		LoadingState.loadAndSwitchState(new PlayState());
		FlxG.sound.music.volume = 0;

		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
    }

    public static function weekIsLocked(name:String):Bool
        {
            var leWeek:WeekData = WeekData.weeksLoaded.get(name);
            return (!leWeek.startUnlocked
                && leWeek.weekBefore != null
                && leWeek.weekBefore.length > 0
                && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
        }
	public static function exitFreeplay() {
		// bpmCache.clearCache();
		Mods.loadTopMod();
		FlxG.signals.postStateSwitch.dispatch(); //? for the screenshot plugin to clean itself	
	}
	public inline static function openResetScoreState(state:FreeplayState,sng:FreeplaySongData,onScoreReset:() -> Void = null) {

		state.openSubState(new ResetScoreSubState(sng.songName, sng.loadAndGetDiffId(), sng.songCharacter,-1,onScoreReset));
	}
	public inline static function openGameplayChanges(state:FreeplayState) {
		state.openSubState(new GameplayChangersSubstate());
	}
	public static function loadDiffsFromWeek(songData:FreeplaySongData){
		Mods.currentModDirectory = songData.folder;
		PlayState.storyWeek = songData.levelId; // TODO
		Difficulty.loadFromWeek();
	}
	public static function getDifficultyName() {
		return Difficulty.list[PlayState.storyDifficulty].toUpperCase();
	}

	public static function updateConductorSongTime(time:Float) {
		Conductor.songPosition = time;
	}
}