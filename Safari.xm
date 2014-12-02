#import <UIKit/UIKit.h>
#import "UICKeyChainStore.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebView.h>

@interface UIWebBrowserView : NSObject {
	WebView *_webView;
}
@property(retain, nonatomic) WebView* webView;
@end

@interface TabDocumentWebBrowserView : UIWebBrowserView
- (void)webView:(id)arg1 didFinishLoadForFrame:(id)arg2;
@end

@interface SafariWebView // : WKWebView
- (void)evaluateJavaScript:(NSString *)javaScriptString
         completionHandler:(void (^)(id,
                                     NSError *))completionHandle;
@end

@interface TabDocumentWK2
-(SafariWebView*) webView;
-(void) TIDE_complete:(id)arg1;
-(void) TIDE_storeUsername:(NSString*)u password:(NSString*)p;
@end

@interface TabDocumentWebBrowserView (touchideverywhere)
-(void) TIDE_complete:(id)arg1;
-(void) TIDE_storeUsername:(NSString*)u password:(NSString*)p;
@end

TabDocumentWebBrowserView *currentSafariView = nil;
TabDocumentWK2 *currentSafariView2 = nil;
__strong NSString *formName, *userName, *password;
extern char observer[18]; /* UITextField.xm */

void touchIdSuccess_safari(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    if (currentSafariView)
    {
    	[currentSafariView TIDE_complete:nil];
    	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, CFSTR("com.efrederickson.touchideverywhere/success"), NULL);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/stopMonitoring"), nil, nil, YES); // Should already have been done though
	    currentSafariView = nil;
    }
    else if (currentSafariView2)
    {
    	[currentSafariView2 TIDE_complete:nil];
    	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, CFSTR("com.efrederickson.touchideverywhere/success"), NULL);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/stopMonitoring"), nil, nil, YES); // Should already have been done though
	    currentSafariView2 = nil;
    }
}

/*
 Massive thanks to Tim Perrin and his project 1Tweak which he shared with me.
*/

%hook TabDocumentWebBrowserView
- (void)webView:(id)arg1 didFinishLoadForFrame:(id)arg2 {
	%orig;
	//NSLog(@"TIDE: webView:didFinishLoadForFrame:");

	NSString *js = @"var flag = 0; for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) if (\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type||\"password\"===z[x].type) { flag = 1;} flag";
	// NSString *js = [NSString stringWithFormat:@"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;)\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type?z[x].value=\"%@\":\"password\"===z[x].type&&(z[x].value=\"%@\");",username,pass];
	NSString *hasPasswordFields_ = [self.webView stringByEvaluatingJavaScriptFromString:js];
	BOOL hasPasswordFields = [hasPasswordFields_ boolValue];
	//NSLog(@"TIDE: %@ %@", hasPasswordFields_, @(hasPasswordFields));
	if (hasPasswordFields)
	{
		NSString *a = @"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) { if (\"password\"==z[x].type) z[x].parentNode.id; }";
		formName = [self.webView stringByEvaluatingJavaScriptFromString:a];
		//NSLog(@"TIDE: form %@", formName);

		NSString *keychainUserName = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username",formName];
		NSString *keychainPassword = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-password",formName];
		password = [UICKeyChainStore stringForKey:keychainPassword];
		userName = [UICKeyChainStore stringForKey:keychainUserName];

		NSString *formCatcher = [NSString stringWithFormat:@"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) {if (\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type){if (%d)		z[x].style.border = \"thin solid green\"; 	else		z[x].style.border = \"thin solid red\"; }else if (\"password\"===z[x].type){	if (%d)		z[x].style.border = \"thin solid green\"; 	else		z[x].style.border = \"thin solid red\"; }}",userName!=nil&&userName.length>0,password!=nil&&password.length>0];
		[self.webView stringByEvaluatingJavaScriptFromString:formCatcher];


		if ((userName!= nil && userName.length > 0) || (password != nil && password.length > 0))
		{
			//NSLog(@"TIDE: begin startMonitoring for safari");
			currentSafariView = self;
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, &touchIdSuccess_safari, CFSTR("com.efrederickson.touchideverywhere/success"), NULL, 0);
	    	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/startMonitoring"), nil, nil, YES);
		}
		currentSafariView = self;

		//NSString *formHook = [NSString stringWithFormat:@"var element = document.getElementById(\"%@\");var oldSub=element.submit; element.submit=function(){	var username; var password;	for (i = 0; i < element.elements.length;i++) {if (element.elements[i].type===\"password\") password = element.elements[i].value; else username=element.elements[i].value; }	window.open(str.concat(\"touchideverywhere://store?username=\",username,\"&password=\",password)); oldSub.apply(element); };",formName];
		//NSString *formHook = [NSString stringWithFormat:@"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) {if (\"button\"===z[x].type||\"submit\"===z[x].type){ z[x].style.border = \"thin solid green\"; var old=z[x].onclick; z[x].onclick=function(){ var username=\"\"; var password=\"\";	for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;){if(\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type)username=z[x].value;else if(z[x].type===\"password\")password=z[x].value;}	alert(\"touchideverywhere://store?username=\"+username+\"&password=\"+password); old.apply(z[x]); } } }"];
		//NSLog(@"TIDE: form hook '%@' %@ ", [self.webView stringByEvaluatingJavaScriptFromString:formHook], formHook);
		//[self.webView stringByEvaluatingJavaScriptFromString:formHook];

	}
}

- (void)webView:(id)arg1 willCloseFrame:(id)arg2
{
	%orig;

	if (currentSafariView)
	{
		NSString *usernameJs = @"var username=\"\"; var password=\"\";	for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;){if(\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type)username=z[x].value;else if(z[x].type===\"password\")password=z[x].value;} username; ";
		NSString *passwordJs = @"var username=\"\"; var password=\"\";	for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;){if(\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type)username=z[x].value;else if(z[x].type===\"password\")password=z[x].value;} password; ";
		NSString *username = [self.webView stringByEvaluatingJavaScriptFromString:usernameJs];
		NSString *password = [self.webView stringByEvaluatingJavaScriptFromString:passwordJs];
		[self TIDE_storeUsername:username password:password];
		//NSLog(@"TIDE: %@", [self.webView stringByEvaluatingJavaScriptFromString:hax]);
	}
	currentSafariView = nil;
}

%new
-(void) TIDE_complete:(id)arg1
{
  	NSString *filler = [NSString stringWithFormat:@"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;)\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type?z[x].value=\"%@\":\"password\"===z[x].type&&(z[x].value=\"%@\");",userName,password];
	[self.webView stringByEvaluatingJavaScriptFromString:filler];

	NSString *submitter = [NSString stringWithFormat:@"document.getElementById(\"%@\").submit();", formName];
	[self.webView stringByEvaluatingJavaScriptFromString:submitter];
	//NSLog(@"TIDE: %@", [self.webView stringByEvaluatingJavaScriptFromString:submitter]);

}

%new
-(void) TIDE_storeUsername:(NSString*)u password:(NSString*)p
{
	//NSLog(@"TIDE: store data: %@ %@", u, p);
	NSString *keychainUserName = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username",formName];
	NSString *keychainPassword = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-password",formName];
	if (u.length > 0)
		[UICKeyChainStore setString:u forKey:keychainUserName];
	if (p.length > 0)
		[UICKeyChainStore setString:p forKey:keychainPassword];

}
%end

%hook TabDocumentWK2
- (void)_webView:(id)arg1 navigationDidFinishDocumentLoad:(id)arg2
{
	%orig;

	NSString *js = @"var flag = 0; for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) if (\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type||\"password\"===z[x].type) { flag = 1;} flag";
	// NSString *js = [NSString stringWithFormat:@"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;)\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type?z[x].value=\"%@\":\"password\"===z[x].type&&(z[x].value=\"%@\");",username,pass];
	[self.webView evaluateJavaScript:js completionHandler:^(id result,
                                     NSError *error){
		BOOL hasPasswordFields = [result boolValue];
		//NSLog(@"TIDE: %@ %@", hasPasswordFields_, @(hasPasswordFields));
		if (hasPasswordFields)
		{
			NSString *a = @"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) { if (\"password\"==z[x].type) z[x].parentNode.id; }";
			[self.webView evaluateJavaScript:a completionHandler:^(id result,
                                     NSError *error){
				formName = result; 
				NSLog(@"TIDE: form %@", formName);
				//NSLog(@"TIDE: form %@", formName);

				NSString *keychainUserName = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username",formName];
				NSString *keychainPassword = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-password",formName];
				password = [UICKeyChainStore stringForKey:keychainPassword];
				userName = [UICKeyChainStore stringForKey:keychainUserName];
				currentSafariView2 = self;

				NSString *formCatcher = [NSString stringWithFormat:@"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) {if (\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type){if (%d)		z[x].style.border = \"thin solid green\"; 	else		z[x].style.border = \"thin solid red\"; }else if (\"password\"===z[x].type){	if (%d)		z[x].style.border = \"thin solid green\"; 	else		z[x].style.border = \"thin solid red\"; }}",userName!=nil&&userName.length>0,password!=nil&&password.length>0];
				[self.webView evaluateJavaScript:formCatcher completionHandler:^(id result,
                                     NSError *error){


					if ((userName!= nil && userName.length > 0) || (password != nil && password.length > 0))
					{
						//NSLog(@"TIDE: begin startMonitoring for safari");
						CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, &touchIdSuccess_safari, CFSTR("com.efrederickson.touchideverywhere/success"), NULL, 0);
				    	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/startMonitoring"), nil, nil, YES);
					}

					//NSString *formHook = [NSString stringWithFormat:@"var element = document.getElementById(\"%@\");var oldSub=element.submit; element.submit=function(){	var username; var password;	for (i = 0; i < element.elements.length;i++) {if (element.elements[i].type===\"password\") password = element.elements[i].value; else username=element.elements[i].value; }	window.open(str.concat(\"touchideverywhere://store?username=\",username,\"&password=\",password)); oldSub.apply(element); };",formName];
					//NSString *formHook = [NSString stringWithFormat:@"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) {if (\"button\"===z[x].type||\"submit\"===z[x].type){ z[x].style.border = \"thin solid green\"; var old=z[x].onclick; z[x].onclick=function(){ var username=\"\"; var password=\"\";	for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;){if(\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type)username=z[x].value;else if(z[x].type===\"password\")password=z[x].value;}	alert(\"touchideverywhere://store?username=\"+username+\"&password=\"+password); old.apply(z[x]); } } }"];
					//NSLog(@"TIDE: form hook '%@' %@ ", [self.webView stringByEvaluatingJavaScriptFromString:formHook], formHook);
					//[self.webView stringByEvaluatingJavaScriptFromString:formHook];
				}];
			}];

		}
	}];
	
}

- (void)_loadingControllerDidStartLoading
{
	if (currentSafariView2)
	{
		NSString *usernameJs = @"var username=\"\"; var password=\"\";	for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;){if(\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type)username=z[x].value;else if(z[x].type===\"password\")password=z[x].value;} username; ";
		NSString *passwordJs = @"var username=\"\"; var password=\"\";	for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;){if(\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type)username=z[x].value;else if(z[x].type===\"password\")password=z[x].value;} password; ";
		
		[self.webView evaluateJavaScript:usernameJs completionHandler:^(id result, NSError*error) {
			NSString *username = result;
			[self.webView evaluateJavaScript:passwordJs completionHandler:^(id result2, NSError*e) {
				NSString *password = result2;
				//NSLog(@"TIDE: %@ %@ %@", username, password, formName);
				[self TIDE_storeUsername:username password:password];
			}];
		}];

		//NSString *username = [self.webView stringByEvaluatingJavaScriptFromString:usernameJs];
		//NSString *password = [self.webView stringByEvaluatingJavaScriptFromString:passwordJs];
		//[self TIDE_storeUsername:username password:password];
		//NSLog(@"TIDE: %@", [self.webView stringByEvaluatingJavaScriptFromString:hax]);
	}
	currentSafariView2 = nil;

	%orig;

}

%new
-(void) TIDE_complete:(id)arg1
{
	// - (void)performAutoFillAction;

  	NSString *filler = [NSString stringWithFormat:@"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;)\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type?z[x].value=\"%@\":\"password\"===z[x].type&&(z[x].value=\"%@\");",userName,password];
	//[self.webView stringByEvaluatingJavaScriptFromString:filler];

	NSString *submitter = [NSString stringWithFormat:@"document.getElementById(\"%@\").submit();", formName];
	//[self.webView stringByEvaluatingJavaScriptFromString:submitter];

	[self.webView evaluateJavaScript:filler completionHandler:^(id a, id b) {
		[self.webView evaluateJavaScript:submitter completionHandler:nil];
	}];

	//NSLog(@"TIDE: %@", [self.webView stringByEvaluatingJavaScriptFromString:submitter]);

}

%new
-(void) TIDE_storeUsername:(NSString*)u password:(NSString*)p
{
	//NSLog(@"TIDE: store data: %@ %@", u, p);
	NSString *keychainUserName = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username",formName];
	NSString *keychainPassword = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-password",formName];
	if (u.length > 0)
		[UICKeyChainStore setString:u forKey:keychainUserName];
	if (p.length > 0)
		[UICKeyChainStore setString:p forKey:keychainPassword];

}
%end