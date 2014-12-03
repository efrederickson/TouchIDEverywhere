#import "TIDESettings.h"

/* Thanks, http://sharedinstance.net/2014/11/settings-the-right-way/ */
#define TIDESettingsDomain   @"com.efrederickson.touchideverywhere"
#define TIDEEnabledKey       @"TIDEEnabled"
#define TIDEFillUsernameKey  @"TIDEFillUsername"
#define TIDEAutoEnterKey     @"TIDEAutoEnter"
#define TIDEATSKey           @"TIDEAdvancedTextSupport"

// Don't want this going bye-bye
__strong NSDictionary *userDefaults;

@implementation TIDESettings
+(id) sharedInstance
{
	static TIDESettings *shared = nil;
	if (!shared)
		shared = [[TIDESettings alloc] init];
	return shared;
}

-(BOOL) enabled
{
	return [[userDefaults objectForKey:TIDEEnabledKey]?:@YES boolValue];
}

-(BOOL) fillUserName
{
	return [[userDefaults objectForKey:TIDEFillUsernameKey]?:@YES boolValue];
}

-(BOOL) autoEnter
{
	return [[userDefaults objectForKey:TIDEAutoEnterKey]?:@YES boolValue];
}

-(BOOL) advancedTextSupport
{
	return [[userDefaults objectForKey:TIDEATSKey]?:@YES boolValue];
}

@end

static __attribute__((constructor)) void __tide_settings_init()
{
	userDefaults = [NSDictionary dictionaryWithContentsOfFile:@"/User/Library/Preferences/com.efrederickson.touchideverywhere.plist"];
}
