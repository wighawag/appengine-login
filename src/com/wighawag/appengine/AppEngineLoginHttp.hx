package com.wighawag.appengine;
import haxe.Http;
import haxe.io.Bytes;
using StringTools;

//TODO deal with duplication among AppEngineClientLogin and this class
//AppEngineClientLogin attempts unauthenticated access first, do we want that in this too ?
class AppEngineLoginHttp extends Http{

    private var username : String;
    private var password : String;
    private var source : String;

    private var gotError : Bool;

    public function new(url : String, username : String, password : String, ?source : String = "nekoClient") {
        super(url);
        this.username = username;
        this.password = password;
        this.source = source;
        gotError = false;
    }

    override public function request(post:Bool):Void {
        var result : String = null;
        gotError = false;
        var gotData : Bool = false;

        // attempts unauenticated acces:
        var redirectedForGoogleLogin : Bool = false;

        var unautenticatedRequestAttempt = new haxe.Http(url);
        unautenticatedRequestAttempt.onStatus = function(status : Int){
            if (status == 302)
            {
                var newLocation = unautenticatedRequestAttempt.responseHeaders.get("Location");
                if (newLocation.startsWith("https://www.google.com/accounts/ServiceLogin")){
                    redirectedForGoogleLogin = true;
                }
            }
            // dispatch status only if not from the google login as this will be handled internally here
            if(!redirectedForGoogleLogin){
                onStatus(status);
            }

        }
        unautenticatedRequestAttempt.onError = function(e){
            dealWithError(e);
        }
        unautenticatedRequestAttempt.onData = function(data : String){
            if (!redirectedForGoogleLogin){
                onData(data);
                gotData = true;
            }
        }
        unautenticatedRequestAttempt.request(false);


        if (gotError || gotData){
            return;
        }

        var protocolLessUrl = url;
        var protocolIndex = url.indexOf("://");
        if (protocolIndex >= 0) {
            protocolLessUrl = url.substr(protocolIndex + 3);
        }

        var baseUrl : String = null;
        var slashIndex = protocolLessUrl.indexOf("/");
        if (slashIndex >= 0){
            baseUrl = protocolLessUrl.substr(0,slashIndex+1);
        }
        else
        {
            baseUrl = url + "/";
        }
        var appLoginUrl = baseUrl + "_ah/login";



        // connect to google login service to get an auth token

        var googleLoginUrl = "https://www.google.com/accounts/ClientLogin";
        var authToken : String = null;
        var loginRequest = new Http(googleLoginUrl);
        var loginPostData : String =
        "Email=" + StringTools.urlEncode(username) + "&" +
        "Passwd=" + StringTools.urlEncode(password) + "&" +
        "service=" + StringTools.urlEncode("ah") + "&" +
        "source=" + StringTools.urlEncode(source) + "&" +
        "accountType=" + StringTools.urlEncode("HOSTED_OR_GOOGLE");

        loginRequest.setPostData(loginPostData);
        loginRequest.setHeader("Content-Type","application/x-www-form-urlencoded");
        loginRequest.setHeader("Content-Length","" + Bytes.ofString(loginPostData).length);

        loginRequest.onError = function(e) {
            dealWithError("googleLogin : " +  e);
        };
        loginRequest.onData = function(data : String)
        {
            var lines : Array<String> = data.split("\n");
            for (line in lines)
            {
                if (line.startsWith("Auth="))
                {
                    authToken = line.substr(5);
                }
            }
        }
        loginRequest.request(true);  // POST request


        if (gotError){
            return;
        }

        // get the cookie :

        var cookie : String = null;
        var cookieReqUrl = appLoginUrl + "?" +
        "continue=" + StringTools.urlEncode(url) + "&" +
        "auth=" + StringTools.urlEncode(authToken);

        var cookieRequest = new Http(cookieReqUrl);
        cookieRequest.onError = function(e)
        {
            dealWithError("cookieRequest : " + e);
        }
        cookieRequest.onData = function(data : String)
        {
            cookie = cookieRequest.responseHeaders.get("Set-Cookie");
        }
        cookieRequest.request(false); // GET request


        if(gotError){
            return;
        }

        // execute tha actual request with the cookie

        setHeader("Cookie", cookie);
        if (post){
            //add Content-Length as appengine require it for POST request
            var contentLength : Int = 0;
            if (postData != null){
                contentLength = Bytes.ofString(postData).length;
            }
            setHeader("Content-Length", "" + contentLength);
        }
        super.request(post);
    }

    private function dealWithError(e:String) : Void{
        onError(e);
        gotError = true;
    }

}
