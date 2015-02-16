#import <UIKit/UIKit.h>
#import "UICKeyChainStore.h"
#import <GraphicsServices/GraphicsServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "TIDESettings.h"

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

void touchIdFail(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo)
{
    if (currentMonitoringField)
    {
    	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
		[animation setDuration:0.05];
		[animation setRepeatCount:4];
		[animation setAutoreverses:YES];
		[animation setFromValue:[NSValue valueWithCGPoint:CGPointMake(currentMonitoringField.center.x, currentMonitoringField.center.y - 10.0f)]];
		[animation setToValue:[NSValue valueWithCGPoint:CGPointMake(currentMonitoringField.center.x, currentMonitoringField.center.y + 10.0f)]];
		[currentMonitoringField.layer addAnimation:animation forKey:@"position"];
		currentMonitoringField.layer.borderColor = [UIColor redColor].CGColor;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((animation.duration * (animation.repeatCount * 2)) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
			currentMonitoringField.layer.borderColor = [UIColor greenColor].CGColor;
		});

    	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, CFSTR("com.efrederickson.touchideverywhere/failure"), NULL);
	}
}

%hook UITextField

- (void)layoutSubviews
{
	%orig;

	if ([TIDESettings.sharedInstance enabled] == NO)
		return;

	if (self.secureTextEntry)
	{
		if ([TIDESettings.sharedInstance fillUserName])
		{
			while (potentialUsernameFields.count > 0)
			{
				UITextField *view = [potentialUsernameFields objectAtIndex:0];
				[potentialUsernameFields removeObjectAtIndex:0];

				CGPoint myPos = [self.superview convertPoint:self.center toView:nil];
				CGPoint otherPos = [view.superview convertPoint:view.center toView:nil];
				CGFloat target = myPos.x - (otherPos.x);
				if (target <= self.frame.size.height * 2 && target >= 0)
				{
					associatedUsernameField = (UITextField*)view;
					[potentialUsernameFields removeAllObjects];
					break;
				}
			}
		}

		NSString *className = NSStringFromClass(self.superview.class);
		NSString *pass = [UICKeyChainStore stringForKey:[NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-pass", className]];
		BOOL hasStoredCode = pass != nil && pass.length > 0;
		//NSLog(@"TIDE: %@", hasStoredCode?@YES:@NO);
		if (hasStoredCode)
		{
			self.layer.borderWidth = 1;
			self.layer.borderColor = [UIColor greenColor].CGColor;
		}
		else
		{
			//NSLog(@"TIDE: RED");
			self.layer.borderWidth = 1;
			self.layer.borderColor = [UIColor redColor].CGColor;
		}
		associatedPasswordField = self;

		if (associatedUsernameField && associatedPasswordField)
		{
			NSString *className = NSStringFromClass(self.superview.class);
			NSString *username = [UICKeyChainStore stringForKey:[NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username", className]];
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
		if ([potentialUsernameFields containsObject:self] == NO && [TIDESettings.sharedInstance fillUserName])
			[potentialUsernameFields insertObject:self atIndex:0];
	}
}

- (void)_endedEditing
{
	%orig;

	if ([TIDESettings.sharedInstance enabled] == NO)
		return;
		
	currentMonitoringField = nil;
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/stopMonitoring"), nil, nil, YES);
	if (self.secureTextEntry && self.text.length > 0)
	{
		NSString *className = NSStringFromClass(self.superview.class);
		NSString *ident = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-pass", className];
		[UICKeyChainStore setString:self.text forKey:ident];
	}
	else if (self.text.length > 0)
	{
		if (associatedPasswordField && self == associatedUsernameField)
		{
			NSString *className = NSStringFromClass(self.superview.class);
			NSString *ident = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username", className];
			[UICKeyChainStore setString:self.text forKey:ident];
		}
	}
}

- (void)_becomeFirstResponder
{
	%orig;

	if ([TIDESettings.sharedInstance enabled] == NO)
		return;

	if (self == associatedUsernameField || self.secureTextEntry)
	{
		currentMonitoringField = self;
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, &touchIdSuccess, CFSTR("com.efrederickson.touchideverywhere/success"), NULL, 0);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (void*)observer, &touchIdFail, CFSTR("com.efrederickson.touchideverywhere/failure"), NULL, 0);
	    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.efrederickson.touchideverywhere/startMonitoring"), nil, nil, YES);
	}	
}

%new
-(void) TouchIDEverywhere_complete:(id)arg1
{
	NSString *className = NSStringFromClass(self.superview.class);
	NSString *pass_ = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-pass", className];
	NSString *pass = [UICKeyChainStore stringForKey:pass_];
	NSString *user_ = [NSString stringWithFormat:@"TOUCHIDEVERYWHERE-%@-username", className];
	NSString *user = [UICKeyChainStore stringForKey:user_];
	if (self == associatedUsernameField)
	{
		self.text = user;
		if ([TIDESettings.sharedInstance advancedTextSupport])
			[self keyboardInput:self shouldInsertText:user isMarkedText:NO];

		associatedPasswordField.text = pass;
		if ([TIDESettings.sharedInstance advancedTextSupport])
			[associatedPasswordField keyboardInput:associatedPasswordField shouldInsertText:pass isMarkedText:NO];

		if ([TIDESettings.sharedInstance autoEnter])
		{
			[associatedPasswordField insertText:@"\n"];
			[associatedPasswordField keyboardInput:associatedPasswordField shouldInsertText:@"\n" isMarkedText:NO];
		}
	}
	else
	{
		self.text = pass;
		if ([TIDESettings.sharedInstance advancedTextSupport])
			[self keyboardInput:self shouldInsertText:pass isMarkedText:NO];

		if (associatedUsernameField)
		{
			associatedUsernameField.text = user;
			if ([TIDESettings.sharedInstance advancedTextSupport])
				[associatedUsernameField keyboardInput:associatedUsernameField shouldInsertText:user isMarkedText:NO];
		}

		if ([TIDESettings.sharedInstance autoEnter])
		{
			[associatedPasswordField insertText:@"\n"];
			[associatedPasswordField keyboardInput:associatedPasswordField shouldInsertText:@"\n" isMarkedText:NO];
		}
	}

}

%end