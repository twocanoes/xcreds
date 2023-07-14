//
//  TCSLoginWindowUtilities.m
//  XCreds
//
//  Created by Timothy Perfitt on 5/11/23.
//
#import <Foundation/Foundation.h>

#import "TCSLoginWindowUtilities.h"
@protocol LFSessionAgentListenerInterface <NSObject>
- (void)SACLOFinishDelayedLogout:(NSDictionary *)arg1 reply:(void (^)(int))arg2;
- (void)SACLORegisterLogoutStatusCallacks:(NSDictionary *)arg1 reply:(void (^)(int))arg2;
- (void)SACLOStartLogoutWithOptions:(int)arg1 subType:(int)arg2 showConfirmation:(BOOL)arg3 countDownTime:(int)arg4 talOptions:(int)arg5 logoutOptions:(NSDictionary *)arg6 reply:(void (^)(int))arg7;
- (void)SACLOStartLogout:(int)arg1 subType:(int)arg2 showConfirmation:(BOOL)arg3 talOptions:(int)arg4 reply:(void (^)(int))arg5;
- (void)SACLogoutComplete:(NSDictionary *)arg1 reply:(void (^)(int))arg2;
- (void)SACNewSessionSignalReady:(void (^)(int))arg1;
- (void)SACStartSessionForUser:(unsigned int)arg1 reply:(void (^)(int))arg2;
- (void)SACStopSessionForLoginWindow:(void (^)(int))arg1;
- (void)SACStartSessionForLoginWindow:(void (^)(int))arg1;
- (void)SACSaveSetupUserScreenShots:(void (^)(int))arg1;
- (void)SACMiniBuddySignalFinishedStage1WithOptions:(NSDictionary *)arg1 reply:(void (^)(int))arg2;
- (void)SACMiniBuddyCopyUpgradeDictionary:(void (^)(int, NSDictionary *))arg1;
- (void)SACSetFinalSnapshot:(BOOL)arg1 reply:(void (^)(int))arg2;
- (void)SACStopProgressIndicator:(void (^)(int))arg1;
- (void)SACStartProgressIndicator:(NSDictionary *)arg1 reply:(void (^)(int))arg2;
- (void)SACBeginLoginTransition:(NSDictionary *)arg1 reply:(void (^)(int))arg2;
- (void)SACSwitchToLoginWindow:(void (^)(int))arg1;
- (void)SACSwitchToUser:(NSDictionary *)arg1 reply:(void (^)(int))arg2;
- (void)SACSetKeyboardType:(int)arg1 productID:(int)arg2 vendorID:(int)arg3 countryCode:(int)arg4 reply:(void (^)(int))arg5;
- (void)SACSetAutologinPassword:(NSString *)arg1 reply:(void (^)(int))arg2;
- (void)SACSetAppleIDForUser:(NSString *)arg1 verified:(BOOL)arg2 reply:(void (^)(int))arg3;
- (void)SACUpdateAppleIDUserLogin:(NSString *)arg1 reply:(void (^)(int))arg2;
- (void)SACRestartForUser:(NSString *)arg1 reply:(void (^)(int))arg2;
- (void)SACScreenSaverDidFadeInBackground:(BOOL)arg1 psnHi:(unsigned int)arg2 psnLow:(unsigned int)arg3 reply:(void (^)(int))arg4;
- (void)SACScreenSaverIsRunningInBackground:(void (^)(int, BOOL))arg1;
- (void)SACScreenSaverTimeRemaining:(void (^)(int, double))arg1;
- (void)SACScreenSaverStopNowWithOptions:(NSDictionary *)arg1 reply:(void (^)(int))arg2;
- (void)SACScreenSaverStopNow:(void (^)(int))arg1;
- (void)SACScreenSaverStartNow:(void (^)(int))arg1;
- (void)SACSetScreenSaverCanRun:(BOOL)arg1 reply:(void (^)(int))arg2;
- (void)SACScreenSaverCanRun:(void (^)(int, BOOL))arg1;
- (void)SACScreenSaverIsRunning:(void (^)(int, BOOL))arg1;
- (void)SACShieldWindowShowing:(void (^)(int, BOOL))arg1;
- (void)SACScreenLockEnabled:(void (^)(int, BOOL))arg1;
- (void)SACLockScreenImmediate:(void (^)(int))arg1;
- (void)SACScreenLockPreferencesChanged:(void (^)(int))arg1;
- (void)SACFaceTimeCallRingStop:(void (^)(int))arg1;
- (void)SACFaceTimeCallRingStart:(void (^)(int))arg1;
@end

@protocol LFLogindListenerLookupInterface <NSObject>
- (void)SMMoveSessionToConsoleTemporaryBridge:(NSDictionary *)arg1 reply:(void (^)(int))arg2;
- (void)SMReleaseSessionTemporaryBridge:(NSDictionary *)arg1 reply:(void (^)(int))arg2;
- (void)SMCreateSessionTemporaryBridge:(NSDictionary *)arg1 reply:(void (^)(int, unsigned int))arg2;
- (void)SMGetSessionAgentConnection:(void (^)(int, NSXPCListenerEndpoint *))arg1;
@end

static NSString* XPCHelperMachServiceName = @"com.apple.logind";


@implementation TCSLoginWindowUtilities


-(void)switchToLoginWindow:(id)sender{

    NSString*  service_name = XPCHelperMachServiceName;

    NSXPCConnection* connection = [[NSXPCConnection alloc] initWithMachServiceName:service_name options:0x1000];

    NSXPCInterface* interface = [NSXPCInterface interfaceWithProtocol:@protocol(LFLogindListenerLookupInterface)];

    [connection setRemoteObjectInterface:interface];

    [connection resume];

    id obj = [connection remoteObjectProxyWithErrorHandler:^(NSError* error)
    {
    NSLog(@"[-] Something went wrong");
    NSLog(@"[-] Error: %@", error);
    }];

    NSLog(@"obj: %@", obj);
    NSLog(@"conn: %@", connection);

    [obj SMGetSessionAgentConnection:^(int b, NSXPCListenerEndpoint * endpoint){
        NSLog(@"SMGetSessionAgentConnection Response: %d", b);

        NSXPCConnection* SAConnection = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
        [SAConnection setRemoteObjectInterface:[NSXPCInterface interfaceWithProtocol:@protocol(LFSessionAgentListenerInterface)]];
        [SAConnection resume];

        id login_window = [SAConnection remoteObjectProxy];


        [login_window SACSwitchToLoginWindow:^(int val) {

        }];

    }];

    [NSThread sleepForTimeInterval:10.0f];

    NSLog(@"Done");

}
@end
