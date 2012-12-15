package com.wighawag.appengine;
import haxe.Http;
import haxe.io.Bytes;
using StringTools;

class AppEngineLoginHttp extends Http{

    private var username : String;
    private var password : String;
    private var source : String;

    private var attemptUnauthenticatedRequest : Bool;

    private var cookie : String;

    private var gotError : Bool;

    public function new(url : String, username : String, password : String, ?attemptUnauthenticatedRequest : Bool = false, ?source : String = "nekoClient") {
        super(url);
        this.username = username;
        this.password = password;
        this.source = source;
        this.attemptUnauthenticatedRequest = attemptUnauthenticatedRequest;
        this.cookie = null;
        gotError = false;
    }

    override public function request(post:Bool):Void {

        if (cookie != null){
            finalRequest(cookie, post);
            return;
        }

        var result : String = null;
        gotError = false;
        var gotData : Bool = false;

        if(attemptUnauthenticatedRequest){
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


            if (gotError || gotData || !redirectedForGoogleLogin){
                return;
            }

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
//        loginRequest.onStatus = function(status : Int){
//            Sys.println("status " + status);
//        };
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
        var cookieReqUrl = appLoginUrl + "?" +
        "continue=" + StringTools.urlEncode(url) + "&" +
        "auth=" + StringTools.urlEncode(authToken);

        var cookieRequest = new Http(cookieReqUrl);
        cookieRequest.onError = function(e)
        {
            dealWithError("cookieRequest : " + e);
        }
//        cookieRequest.onStatus = function(status : Int){
//            Sys.println("status " + status);   // if successful : 302 but do not follow
//        };
        cookieRequest.onData = function(data : String)
        {
            cookie = cookieRequest.responseHeaders.get("Set-Cookie");
        }
        cookieRequest.request(false); // GET request


        if(gotError){
            return;
        }

        // execute tha actual request with the cookie
        finalRequest(cookie, post);
    }

    private function finalRequest(cookie : String, post : Bool) : Void{
        setHeader("Cookie", cookie);
        if (post){
            //add Content-Length as appengine require it for POST request
            var contentLength : Int = 0;
            if (postData != null){
                contentLength = Bytes.ofString(postData).length;
                setHeader("Content-Length", "" + contentLength);
            }
        }
        super.request(post);
    }

    private function dealWithError(e:String) : Void{
        onError(e);
        gotError = true;
    }

}
