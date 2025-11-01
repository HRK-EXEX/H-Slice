package hrk;

import mikolka.compatibility.VsliceOptions;

class Eseq {
    public static var available = true;

    public static function p(d:Dynamic = null) {
        if (!available) return;
        if (VsliceOptions.LOGGING.contains("Console")) {
            Sys.stdout().writeString('\x1b[0G$d');
            Sys.stdout().flush();
        }
        // if (VsliceOptions.LOGGING.contains("File")) {
        //     @:privateAccess
        //     var file = Logger.file;
        //     if (file != null) {
        //         file.writeString('\x1b[0G$d\n');
        //         file.flush();
        //     }
        // }
    }
}