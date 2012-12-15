package com.wighawag.utils;
class ConsoleInput {
    // taken from haxelib
    static public function ask( name : String, ?passwd: Bool = false ) {
        Sys.print(name+" : ");
        if( passwd ) {
            var s = new StringBuf();
            var c;
            while( (c = Sys.getChar(false)) != 13 )
                s.addChar(c);
            Sys.println("");
            return s.toString();
        }
        return Sys.stdin().readLine();
    }
}
