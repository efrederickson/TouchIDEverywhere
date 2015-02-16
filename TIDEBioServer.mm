#import "TIDEBioServer.h"
#import <objc/runtime.h>
#import <notify.h>
#import <substrate.h>
#import <UIKit/UIKit.h>
#import <libactivator/libactivator.h>

@interface UIApplication (SpringBoard)
-(BOOL) isLocked;
@end

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
	static TIDEBioServer* sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
		sharedInstance->oldObservers = [NSHashTable new];
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
			[self notifyClientsOfFailure];
			break;
		default:
			break;
	}
}

-(void)startMonitoring
{
	if(isMonitoring || [[UIApplication sharedApplication] isLocked]) 
		return;
	//notify_post(DISABLE_VH);
	activatorListenerNames = nil;
	id activator = [objc_getClass("LAActivator") sharedInstance];
	if (activator)
    {
		id event = [objc_getClass("LAEvent") eventWithName:@"libactivator.fingerprint-sensor.press.single" mode:@"application"]; // LAEventNameFingerprintSensorPressSingle
		if (event)
        {
			activatorListenerNames = [activator assignedListenerNamesForEvent:event];
			if (activatorListenerNames)
				for (NSString *listenerName in activatorListenerNames)
					[activator removeListenerAssignment:listenerName fromEvent:event];
		}
	}
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
	if(!isMonitoring || [[UIApplication sharedApplication] isLocked]) 
		return;
	
	isMonitoring = NO;
	SBUIBiometricEventMonitor* monitor = [[objc_getClass("BiometricKit") manager] delegate];
	NSHashTable *observers = MSHookIvar<NSHashTable*>(monitor, "_observers");
	if (observers && [observers containsObject:self])
		[monitor removeObserver:self];
	if (oldObservers && observers)
		for (id observer in oldObservers)
			[monitor addObserver:observer];
	oldObservers = nil;
	[monitor _setMatchingEnabled:previousMatchingSetting];
	//notify_post(ENABLE_VH);
    id activator = [objc_getClass("LAActivator") sharedInstance];
    if (activator && activatorListenerNames)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
           id event = [objc_getClass("LAEvent") eventWithName:@"libactivator.fingerprint-sensor.press.single" mode:@"application"]; // LAEventNameFingerprintSensorPressSingle
           if (event)
               for (NSString *listenerName in activatorListenerNames)
                   [activator addListenerAssignment:listenerName toEvent:event];
        });
    }
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

-(void) notifyClientsOfFailure
{
	// TODO: implement into clients
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/failure"), nil, nil, YES);
}

-(BOOL) isMonitoring
{
	return isMonitoring;
}
@end
