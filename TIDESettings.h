@interface TIDESettings : NSObject
+(id) sharedInstance;

-(BOOL) enabled;
-(BOOL) fillUserName;
-(BOOL) autoEnter;
-(BOOL) advancedTextSupport; 
-(BOOL) useAppellancy;
@end