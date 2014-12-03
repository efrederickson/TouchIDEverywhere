#import <UIKit/UIKit.h>
#import "TIDEBioServer.h"

%ctor
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
	{
		[[TIDEBioServer sharedInstance] setUpForMonitoring];
	}
}

@interface SBLockStateAggregator : NSObject
+ (id)sharedInstance;
- (void)_updateLockState;
- (_Bool)hasAnyLockState;
@end

// Dunno if I even need this... 
/*
BOOL wasMonitoring = NO;
%hook SBLockStateAggregator
-(void)_updateLockState
{
	%orig;

	if ([self hasAnyLockState])
	{
		wasMonitoring = [[TIDEBioServer sharedInstance] isMonitoring];
		if (wasMonitoring)
			[[TIDEBioServer sharedInstance] stopMonitoring];
	}
	else
	{
		if (wasMonitoring)
			[[TIDEBioServer sharedInstance] startMonitoring];
	}
}
%end
*/