package hrk;

class Eseq {
    public static var available(get, never):Bool;
    public static function get_available() {
		try {
			Sys.stdout().writeString("");
            return true;
		} catch (e:Dynamic) return false;
    }

    public static function p(d:Dynamic = null) {
        Sys.stdout().writeString(d);
        Sys.stdout().flush();
    }
}