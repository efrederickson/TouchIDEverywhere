#import <UIKit/UIKit.h>
#import "UICKeyChainStore.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebView.h>

@interface UIWebBrowserView : NSObject {
	WebView *_webView;
}
@property(retain, nonatomic) WebView* webView;
@end

@interface UIWebBrowserView (touchideverywhere)
-(void) TIDE_complete:(id)arg1;
-(void) TIDE_storeUsername:(NSString*)u password:(NSString*)p;
@end

UIWebBrowserView *currentWebView = nil;
extern NSString *formName, *userName, *password;
extern char observer[18]; /* UITextField.xm */

void touchIdSuccess_webview(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    if (currentWebView)
    {
    	[currentWebView TIDE_complete:nil];
    	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, CFSTR("com.efrederickson.touchideverywhere/success"), NULL);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/stopMonitoring"), nil, nil, YES); // Should already have been done though
	    currentWebView = nil;
    }
}

%hook UIWebBrowserView
- (void)webView:(id)arg1 didFinishLoadForFrame:(id)arg2 
{
	%orig;

	NSString *js = @"var flag = 0; for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) if (\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type||\"password\"===z[x].type) { flag = 1;} flag";
	NSString *hasPasswordFields_ = [self.webView stringByEvaluatingJavaScriptFromString:js];
	BOOL hasPasswordFields = [hasPasswordFields_ boolValue];
	if (hasPasswordFields)
	{
		NSString *a = @"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) { if (\"password\"==z[x].type) z[x].parentNode.id; }";
		formName = [self.webView stringByEvaluatingJavaScriptFromString:a];

		NSString *keychainUserName = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username",formName];
		NSString *keychainPassword = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-password",formName];
		password = [UICKeyChainStore stringForKey:keychainPassword];
		userName = [UICKeyChainStore stringForKey:keychainUserName];

		NSString *formCatcher = [NSString stringWithFormat:@"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;) {if (\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type){if (%d)		z[x].style.border = \"thin solid green\"; 	else		z[x].style.border = \"thin solid red\"; }else if (\"password\"===z[x].type){	if (%d)		z[x].style.border = \"thin solid green\"; 	else		z[x].style.border = \"thin solid red\"; }}",userName!=nil&&userName.length>0,password!=nil&&password.length>0];
		[self.webView stringByEvaluatingJavaScriptFromString:formCatcher];

		if ((userName!= nil && userName.length > 0) || (password != nil && password.length > 0))
		{
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, &touchIdSuccess_webview, CFSTR("com.efrederickson.touchideverywhere/success"), NULL, 0);
	    	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/startMonitoring"), nil, nil, YES);
		}
		currentWebView = self;
	}
}

- (void)webView:(id)arg1 willCloseFrame:(id)arg2
{
	if (currentWebView)
	{
		NSString *usernameJs = @"var username=\"\"; var password=\"\";	for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;){if(\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type)username=z[x].value;else if(z[x].type===\"password\")password=z[x].value;} username; ";
		NSString *passwordJs = @"var username=\"\"; var password=\"\";	for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;){if(\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type)username=z[x].value;else if(z[x].type===\"password\")password=z[x].value;} password; ";
		NSString *username = [self.webView stringByEvaluatingJavaScriptFromString:usernameJs];
		NSString *password = [self.webView stringByEvaluatingJavaScriptFromString:passwordJs];
		[self TIDE_storeUsername:username password:password];
		currentWebView = nil;
	}
	
	%orig; 
}

%new
-(void) TIDE_complete:(id)arg1
{
  	NSString *filler = [NSString stringWithFormat:@"for(var z=document.getElementsByTagName(\"input\"),x=z.length;x--;)\"username\"===z[x].type||\"username\"===z[x].name||\"email\"===z[x].type||\"email\"===z[x].name||\"user\"===z[x].name||\"user\"===z[x].type?z[x].value=\"%@\":\"password\"===z[x].type&&(z[x].value=\"%@\");",userName,password];
	[self.webView stringByEvaluatingJavaScriptFromString:filler];

	NSString *submitter = [NSString stringWithFormat:@"document.getElementById(\"%@\").submit();", formName];
	[self.webView stringByEvaluatingJavaScriptFromString:submitter];

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

%ctor
{
	// Assert not in Safari.
	// We have special hooks for that.
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.mobilesafari"])
		return;
	%init;
}
