package objects;

import haxe.ds.ArraySort;

class PopupGroup extends FlxTypedGroup<Popup>
{
    var pool:Array<Popup> = [];
    var _ecyc_e:Popup;

    public function push(p:Popup) {
        pool.push(p);
    }

    public function spawn() {
        if (pool.length > 0) {
            _ecyc_e = pool.pop();
            _ecyc_e.revive();
        } else {
            _ecyc_e = new Popup();
            members.push(_ecyc_e);
            ++length;
        }
        // Sys.print('\x1b[0G${countLiving()}, ${pool.length}, ${members.length}   ');
        return _ecyc_e;
    }

    public function stableSort() {
        ArraySort.sort(members, (a, b) -> compare(a.popUpTime, b.popUpTime));
    }

    function compare(a:Float, b:Float):Int {
        return a > b ? a == b ? 1 : 0 : -1;
    }
}