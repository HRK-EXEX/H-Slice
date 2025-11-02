package backend;

import objects.SustainSplash;
import backend.Song;
import objects.Note;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor
{
	public static var bpm(default, set):Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;
	public static var offset:Float = 0;

	//public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	static var judgeData:Array<Rating> = [];
	public static function judgeNote(arr:Array<Rating>, diff:Float=0):Rating // die
	{
		judgeData = arr;
		for(i in 0...judgeData.length-1) //skips last window (Shit)
			if (diff <= judgeData[i].hitWindow)
				return judgeData[i];

		return judgeData[judgeData.length - 1];
	}

	static var lastChangeEvent:BPMChangeEvent;
	public static function getCrotchetAtTime(time:Float){
		lastChangeEvent = getBPMFromSeconds(time);
		return lastChangeEvent.stepCrochet*4;
	}

	public static function getBPMFromSeconds(time:Float){
		lastChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (time >= Conductor.bpmChangeMap[i].songTime)
				lastChangeEvent = Conductor.bpmChangeMap[i];
		}

		return lastChangeEvent;
	}

	public static function getBPMFromStep(step:Float){
		lastChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.bpmChangeMap[i].stepTime<=step)
				lastChangeEvent = Conductor.bpmChangeMap[i];
		}

		return lastChangeEvent;
	}

	static var step:Float;
	public static function beatToSeconds(beat:Float): Float{
		step = beat * 4;
		lastChangeEvent = getBPMFromStep(step);
		return lastChangeEvent.songTime + ((step - lastChangeEvent.stepTime) / (lastChangeEvent.bpm / 60)/4) * 1000; // TODO: make less shit and take BPM into account PROPERLY
	}

	public static function getStep(time:Float){
		lastChangeEvent = getBPMFromSeconds(time);
		return lastChangeEvent.stepTime + (time - lastChangeEvent.songTime) / lastChangeEvent.stepCrochet;
	}

	public static function getStepRounded(time:Float){
		lastChangeEvent = getBPMFromSeconds(time);
		return lastChangeEvent.stepTime + Math.floor(time - lastChangeEvent.songTime) / lastChangeEvent.stepCrochet;
	}

	public static function getBeat(time:Float){
		return getStep(time)/4;
	}

	public static function getBeatRounded(time:Float):Int{
		return Math.floor(getStepRounded(time)/4);
	}

	static var curBPM:Float;
	static var totalSteps:Int;
	static var totalPos:Float;
	static var deltaSteps:Int;
	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];

		curBPM = song.bpm;
		totalSteps = 0;
		totalPos = 0;
		
		for (i in 0...song.notes.length)
		{
			if(song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				lastChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM)/4
				};
				bpmChangeMap.push(lastChangeEvent);
			}

			deltaSteps = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		#if debug trace("new BPM map BUDDY " + bpmChangeMap); #end
	}

	static var sectionValue:Null<Float>;
	static function getSectionBeats(song:SwagSong, section:Int)
	{
		sectionValue = null;
		if(song.notes[section] != null) sectionValue = song.notes[section].sectionBeats;
		return sectionValue != null ? sectionValue : 4;
	}

	inline public static function calculateCrochet(bpm:Float){
		return (60/bpm)*1000;
	}

	public static function set_bpm(newBPM:Float):Float {
		bpm = newBPM;
		crochet = calculateCrochet(bpm);
		stepCrochet = crochet / 4;
		if (ClientPrefs.data.holdSplashAlpha != 0) {
			SustainSplash.frameRate = Math.floor(24 / 100 * bpm);
		}

		return bpm = newBPM;
	}
}