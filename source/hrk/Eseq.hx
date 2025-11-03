package hrk;

import mikolka.vslice.components.crash.Logger;
import mikolka.compatibility.VsliceOptions;

class Eseq {
    public static var available = true;
    static final Escape = '\x1b[0G';

    public static function p(d:Dynamic = null) {
        if (!available) return;
        if (Logger.logType & 1 > 0) {
            Sys.stdout().writeString('$Escape$d');
            Sys.stdout().flush();
        }
        if (Logger.logType & 2 > 0) {
            @:privateAccess
            var file = Logger.file;
            if (file != null) {
                file.writeString('$Escape$d\n');
                file.flush();
            }
        }
    }

    public static function pln(d:Dynamic = null) { p('$d\n'); }
}