#import <UIKit/UIKit.h>
#import "TIDEBioServer.h"

%ctor
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
	{
		[[TIDEBioServer sharedInstance] setUpForMonitoring];
	}
}