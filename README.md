Lib to connect to authenticated appengine page (login: required)
It extends haxe.Http and can be used the same way but only through Http.request (not customRequest)

var http = new AppEngineLoginHttp("jdhsjhdjshdj.appspot.com/authTest", "alfred", "secretPassword");
http.request();

the constructor accept also two more optional parameter
the first being a Bool that specify whether we should attempt to access the page without credential first (default to false)
the second is a String representing the login App (default to "NekoClient"). This is send to the google login system


This lib also contain an utility to ask for username and password from the standard input.
var username = ConsoleInput.ask("please enter your username");
var password = ConsoleInput.ask("please enter your password", true);
the second parameter being true will hide the charatcer typed