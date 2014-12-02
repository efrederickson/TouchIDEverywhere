#import <UIKit/UIKit.h>
#import "UICKeyChainStore.h"
#import <GraphicsServices/GraphicsServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

char observer[18] = "touchideverywhere";

@interface UITextField (TouchIDEverywhere)
-(void) TouchIDEverywhere_complete:(id)arg1;
- (BOOL)keyboardInput:(id)arg1 shouldInsertText:(id)arg2 isMarkedText:(BOOL)arg3;
@end

UITextField *currentMonitoringField = nil;
UITextField *associatedUsernameField = nil;
UITextField *associatedPasswordField = nil;
NSMutableArray *potentialUsernameFields = [NSMutableArray array];

void touchIdSuccess(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    if (currentMonitoringField)
    {
    	[currentMonitoringField TouchIDEverywhere_complete:nil];
    	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, CFSTR("com.efrederickson.touchideverywhere/success"), NULL);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/stopMonitoring"), nil, nil, YES); // Should already have been done though
    }
}

%hook UITextField
//-(BOOL) secureTextEntry

- (void)layoutSubviews
{
	%orig;

	if (self.secureTextEntry)
	{
		while (potentialUsernameFields.count > 0)
		{
			UITextField *view = [potentialUsernameFields objectAtIndex:0];
			[potentialUsernameFields removeObjectAtIndex:0];

			CGPoint myPos = [self.superview convertPoint:self.center toView:nil];
			CGPoint otherPos = [view.superview convertPoint:view.center toView:nil];
			CGFloat target = myPos.x - (otherPos.x + 0);
			if (target <= self.frame.size.height * 2 && target >= 0)
			{
				associatedUsernameField = (UITextField*)view;
				[potentialUsernameFields removeAllObjects];
				break;
			}
		}

		NSString *className = NSStringFromClass(self.superview.class);
		NSString *pass = [UICKeyChainStore stringForKey:[NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-pass-%ld", className, (long)self.tag]];
		BOOL hasStoredCode = pass != nil && pass.length > 0;
		if (hasStoredCode)
		{
			self.layer.borderWidth = 1;
			self.layer.borderColor = [UIColor greenColor].CGColor;
		}
		else
		{
			self.layer.borderWidth = 1;
			self.layer.borderColor = [UIColor redColor].CGColor;
		}
		associatedPasswordField = self;

		if (associatedUsernameField && associatedPasswordField)
		{
			NSString *className = NSStringFromClass(self.superview.class);
			NSString *username = [UICKeyChainStore stringForKey:[NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username-%ld", className, (long)self.tag]];
			BOOL hasStoredCode = username != nil && username.length > 0;
			if (hasStoredCode)
			{
				associatedUsernameField.layer.borderWidth = 1;
				associatedUsernameField.layer.borderColor = [UIColor greenColor].CGColor;
			}
			else
			{
				associatedUsernameField.layer.borderWidth = 1;
				associatedUsernameField.layer.borderColor = [UIColor redColor].CGColor;
			}
		}
	}
	else
	{
		if ([potentialUsernameFields containsObject:self] == NO)
			[potentialUsernameFields insertObject:self atIndex:0];
	}
}

- (void)_endedEditing
{
	%orig;

	currentMonitoringField = nil;
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/stopMonitoring"), nil, nil, YES);
	if (self.secureTextEntry && self.text.length > 0)
	{
		NSString *className = NSStringFromClass(self.superview.class);
		NSString *ident = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-pass-%ld", className, (long)self.tag];
		[UICKeyChainStore setString:self.text forKey:ident];
	}
	else if (self.text.length > 0)
	{
		if (associatedPasswordField && self == associatedUsernameField)
		{
			NSString *className = NSStringFromClass(self.superview.class);
			NSString *ident = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username-%ld", className, (long)self.tag];
			[UICKeyChainStore setString:self.text forKey:ident];
		}
	}
}

- (void)_becomeFirstResponder
{
	%orig;

	if (self == associatedUsernameField || self.secureTextEntry)
	{
		currentMonitoringField = self;
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, &touchIdSuccess, CFSTR("com.efrederickson.touchideverywhere/success"), NULL, 0);
	    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/startMonitoring"), nil, nil, YES);
	}	
}

%new
-(void) TouchIDEverywhere_complete:(id)arg1
{
	NSString *className = NSStringFromClass(self.superview.class);
	NSString *pass_ = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-pass-%ld", className, (long)self.tag];
	NSString *pass = [UICKeyChainStore stringForKey:pass_];
	NSString *user_ = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username-%ld", className, (long)self.tag];
	NSString *user = [UICKeyChainStore stringForKey:user_];
	if (self == associatedUsernameField)
	{
		self.text = user;
		[self keyboardInput:self shouldInsertText:user isMarkedText:NO];
		associatedPasswordField.text = pass;
		[associatedPasswordField keyboardInput:associatedPasswordField shouldInsertText:pass isMarkedText:NO];
		[associatedPasswordField keyboardInput:associatedPasswordField shouldInsertText:@"\n" isMarkedText:NO]; // Auto-enter
	}
	else
	{
		self.text = pass;
		[self keyboardInput:self shouldInsertText:pass isMarkedText:NO];
		[self keyboardInput:self shouldInsertText:@"\n" isMarkedText:NO]; // Auto-enter

		if (associatedUsernameField)
		{
			associatedUsernameField.text = user;
			[associatedUsernameField keyboardInput:associatedUsernameField shouldInsertText:user isMarkedText:NO];
		}
	}

}

%end