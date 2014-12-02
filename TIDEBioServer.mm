#import "TIDEBioServer.h"
#import <objc/runtime.h>
#import <notify.h>
#import <substrate.h>

#define ENABLE_VH "virtualhome.enable"
#define DISABLE_VH "virtualhome.disable"

void startMonitoring_(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    [[TIDEBioServer sharedInstance] startMonitoring];
}

void stopMonitoring_(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    [[TIDEBioServer sharedInstance] stopMonitoring];
}

@implementation TIDEBioServer

+(id)sharedInstance {
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event 
{
	switch(event) 
	{
		case TouchIDMatched:
			[self notifyClientsOfSuccess];
			[self stopMonitoring];
			break;
		case TouchIDNotMatched:
			// TODO: notify client of failure so it can alert user somehow (label color change?)
		default:
			break;
	}
}

-(void)startMonitoring
{
	if(isMonitoring) 
		return;
	//notify_post(DISABLE_VH);
	isMonitoring = YES;

	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	previousMatchingSetting = [monitor isMatchingEnabled];


	oldObservers = [MSHookIvar<NSHashTable*>(monitor, "_observers") copy];
	for (id observer in oldObservers)
		[monitor removeObserver:observer];

	[monitor addObserver:self];
	[monitor _setMatchingEnabled:YES];
	[monitor _startMatching];
}

-(void)stopMonitoring 
{
	if(!isMonitoring) 
		return;
	isMonitoring = NO;
	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	[monitor removeObserver:self];
	for (id observer in oldObservers)
		[monitor addObserver:observer];
	oldObservers = nil;
	[monitor _setMatchingEnabled:previousMatchingSetting];
	//notify_post(ENABLE_VH);
}

-(void) setUpForMonitoring
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &startMonitoring_, CFSTR("com.efrederickson.touchideverywhere/startMonitoring"), NULL, 0);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &stopMonitoring_, CFSTR("com.efrederickson.touchideverywhere/stopMonitoring"), NULL, 0);
}

-(void) notifyClientsOfSuccess
{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/success"), nil, nil, YES);
}

-(BOOL) isMonitoring
{
	return isMonitoring;
}
@end
