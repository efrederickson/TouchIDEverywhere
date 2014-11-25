@protocol SBUIBiometricEventMonitorDelegate
@required
-(void)biometricEventMonitor:(id)monitor handleBiometricEvent:(unsigned)event;
@end

@interface SBUIBiometricEventMonitor : NSObject
- (void)addObserver:(id)arg1;
- (void)removeObserver:(id)arg1;
- (void)_startMatching;
- (void)_setMatchingEnabled:(BOOL)arg1;
- (BOOL)isMatchingEnabled;
@end

@interface BiometricKit : NSObject
+ (id)manager;
@end

#define TouchIDFingerDown  1
#define TouchIDFingerUp    0
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDNotMatched  10

@interface TIDEBioServer : NSObject <SBUIBiometricEventMonitorDelegate> {
	BOOL isMonitoring;
	BOOL previousMatchingSetting;
}
+(id)sharedInstance;
-(void)startMonitoring;
-(void)stopMonitoring;
-(void)setUpForMonitoring;
-(BOOL) isMonitoring;
@end