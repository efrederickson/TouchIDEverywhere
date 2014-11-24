#import <UIKit/UIKit.h>
#import "UICKeyChainStore.h"
/*
%hook DOMHTMLInputElement
- (void)setDefaultValue:(id)arg1
{
	NSLog(@"TouchIDEverywhere: %@", arg1);
	%orig;
}
%end

%ctor
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
   		%init;
	});
}
*/