package ;

import com.wighawag.appengine.AppEngineLoginHttp;
import com.wighawag.utils.ConsoleInput;
import haxe.Http;
import haxe.io.Bytes;


using StringTools;

class LoginTest {

    public static function main(){


        var authUrl = "http://yoga-repo.appspot.com/authTest";
        var noAuthUrl = "http://yoga-repo.appspot.com/noAuthTest";
        var username : String = null;
        var password : String = null;

        //Sys.println("please enter your username :");
        //username = Sys.stdin().readLine();
        username = ConsoleInput.ask("username");

        //Sys.println("please enter your password :");
        //password = Sys.stdin().readLine();
        password = ConsoleInput.ask("password", true);

        Sys.println("AppEngineLoginHttp no auth required:");
        var loginRequest = new AppEngineLoginHttp(noAuthUrl, username, password);
        loginRequest.onStatus = function(status : Int){
            Sys.println("status code : " + status);
        }
        loginRequest.onError = function(e){
            Sys.println("Error : " + e);
        }
        loginRequest.onData = function(data : String){
            Sys.println(data);
        }

        loginRequest.setPostData("dd=45");
        loginRequest.request(true);


        Sys.println("AppEngineLoginHttp with auth required:");
        var loginRequest = new AppEngineLoginHttp(authUrl, username, password);
        loginRequest.onStatus = function(status : Int){
            Sys.println("status code : " + status);
        }
        loginRequest.onError = function(e){
            Sys.println("Error : " + e);
        }
        loginRequest.onData = function(data : String){
            Sys.println(data);
        }

        loginRequest.setPostData("dd=45");
        loginRequest.request(true);

        Sys.println("AppEngineLoginHttp with auth required (resuing cookie):");
        loginRequest.onStatus = function(status : Int){
            Sys.println("status code : " + status);
        }
        loginRequest.onError = function(e){
            Sys.println("Error : " + e);
        }
        loginRequest.onData = function(data : String){
            Sys.println(data);
        }

        loginRequest.setPostData("dd=45");
        loginRequest.request(true);


        Sys.println("Http :");
        var noLoginRequest = new Http(noAuthUrl);
        noLoginRequest.onStatus = function(status : Int){
            Sys.println("status code : " + status);
        }
        noLoginRequest.onError = function(e){
            Sys.println("Error : " + e);
        }
        noLoginRequest.onData = function(data : String){
            Sys.println(data);
        }

        noLoginRequest.setHeader("Content-Length", "" + 0);
        noLoginRequest.request(true);


    }



    public function new() {
    }
}
