package states.editors.content;

import states.editors.content.MetaNote;
import objects.Note.CastNote;

class MetaNoteGroup extends FlxTypedGroup<MetaNote>
{
    var pool:Array<MetaNote> = [];
    var poolAvail:Array<Bool> = [];
    var _ecyc_e:MetaNote;
    var recycleData:CastNote;
    var living:Int = 0;

    public function new() {
        super();
    }

    public function push(n:MetaNote) {
        pool.push(n);
    }

    public function spawnNote(chartNote:Array<Dynamic>) {
        if (pool.length > 0) {
            _ecyc_e = pool.pop();
            _ecyc_e.exists = true;
        } else {
            _ecyc_e = null;
            _ecyc_e = new MetaNote(chartNote[0], chartNote[1], chartNote);
            members.push(_ecyc_e);
            ++length;
        }
        recycleData = {
            strumTime: chartNote[0],
            noteData: chartNote[1],
            holdLength: chartNote[2],
            noteType: chartNote[3] ?? null,
        };
        return _ecyc_e.recycleNote(recycleData);
    }

    public function debugInfo():Array<Float> {
        living = 0;
        for (obj in pool) if (obj != null) ++living;

        return [living, length, living * 100.0 / Math.max(length, 1), poolAvail.length];
    }
}