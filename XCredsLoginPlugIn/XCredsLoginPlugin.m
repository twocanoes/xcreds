//
//  XCredsLoginPlugin.m
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 7/2/22.
//

#import "XCredsLoginPlugin.h"
#import "XCredsLoginPlugin-Swift.h"
#import <Foundation/Foundation.h>
XCredsLoginPlugin *authorizationPlugin = nil;

//os_log_t pluginLog = nil;
XCredsLoginMechanism *loginWindowMechanism = nil;



static OSStatus PluginDestroy(AuthorizationPluginRef inPlugin) {

    TCSLog([NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__]);

    return [authorizationPlugin PluginDestroy:inPlugin];
}

static OSStatus MechanismCreate(AuthorizationPluginRef inPlugin,
                                AuthorizationEngineRef inEngine,
                                AuthorizationMechanismId mechanismId,
                                AuthorizationMechanismRef *outMechanism) {

    TCSLog([NSString stringWithFormat:@"%s %s:%d id:%s",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding] ,__LINE__,mechanismId]);

    return [authorizationPlugin MechanismCreate:inPlugin
                                      EngineRef:inEngine
                                    MechanismId:mechanismId
                                   MechanismRef:outMechanism];
}

static OSStatus MechanismInvoke(AuthorizationMechanismRef inMechanism) {
    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;

//    mechanism->fMechID = mechanismId;

    TCSLog([NSString stringWithFormat:@"%s %s:%d id:%s",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__,mechanism->fMechID]);

    return [authorizationPlugin MechanismInvoke:inMechanism];
}

static OSStatus MechanismDeactivate(AuthorizationMechanismRef inMechanism) {
    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;

    TCSLog([NSString stringWithFormat:@"%s %s:%d id:%s",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__,mechanism->fMechID]);

    return [authorizationPlugin MechanismDeactivate:inMechanism];
}

static OSStatus MechanismDestroy(AuthorizationMechanismRef inMechanism) {
    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;

    TCSLog([NSString stringWithFormat:@"%s %s:%d id:%s",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__,mechanism->fMechID]);

    return [authorizationPlugin MechanismDestroy:inMechanism];
}

static AuthorizationPluginInterface gPluginInterface = {
    kAuthorizationPluginInterfaceVersion,
    &PluginDestroy,
    &MechanismCreate,
    &MechanismInvoke,
    &MechanismDeactivate,
    &MechanismDestroy
};

extern OSStatus AuthorizationPluginCreate(const AuthorizationCallbacks *callbacks,
                                          AuthorizationPluginRef *outPlugin,
                                          const AuthorizationPluginInterface **outPluginInterface) {
    TCSLog([NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__]);

    if (authorizationPlugin == nil) {
        authorizationPlugin = [[XCredsLoginPlugin alloc] init];
    }

    return [authorizationPlugin AuthorizationPluginCreate:callbacks
                                                PluginRef:outPlugin
                                          PluginInterface:outPluginInterface];
}

// Implementation


@implementation XCredsLoginPlugin


- (OSStatus)AuthorizationPluginCreate:(const AuthorizationCallbacks *)callbacks
                            PluginRef:(AuthorizationPluginRef *)outPlugin
                      PluginInterface:(const AuthorizationPluginInterface **)outPluginInterface {
    TCSLog([NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__]);

    PluginRecord *plugin = (PluginRecord *) malloc(sizeof(*plugin));
    if (plugin == NULL) return errSecMemoryError;
    plugin->fMagic = kPluginMagic;
    plugin->fCallbacks = callbacks;
    *outPlugin = plugin;
    *outPluginInterface = &gPluginInterface;
    return errSecSuccess;
}

- (OSStatus)MechanismCreate:(AuthorizationPluginRef)inPlugin
                  EngineRef:(AuthorizationEngineRef)inEngine
                MechanismId:(AuthorizationMechanismId)mechanismId
               MechanismRef:(AuthorizationMechanismRef *)outMechanism {
    TCSLog([NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__]);

    MechanismRecord *mechanism = (MechanismRecord *)malloc(sizeof(MechanismRecord));
    if (mechanism == NULL) return errSecMemoryError;
    TCSLog([NSString stringWithFormat:@"==========> Authorization Plugin %s Mechanism created.<===========\n",mechanismId]);
    mechanism->fMagic = kMechanismMagic;
    mechanism->fEngine = inEngine;
    mechanism->fPlugin = (PluginRecord *)inPlugin;
    mechanism->fMechID = mechanismId;
    mechanism->fLoginWindow = (strcmp(mechanismId, "LoginWindow") == 0);
    mechanism->fPowerControl = (strcmp(mechanismId, "PowerControl") == 0);
    mechanism->fEnableFDE = (strcmp(mechanismId, "EnableFDE") == 0);
    mechanism->fKeychainAdd = (strcmp(mechanismId, "KeychainAdd") == 0);
    mechanism->fCreateUser = (strcmp(mechanismId, "CreateUser") == 0);
    mechanism->fLoginDone = (strcmp(mechanismId, "LoginDone") == 0);

    *outMechanism = mechanism;

    return errSecSuccess;
}

- (OSStatus)MechanismInvoke:(AuthorizationMechanismRef)inMechanism {
    TCSLog([NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__]);

    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;


    if (mechanism->fLoginWindow) {
        if (loginWindowMechanism==nil){
            loginWindowMechanism = [[XCredsLoginMechanism alloc] initWithMechanism:mechanism];
        }
        [loginWindowMechanism run];

    }
    else if (mechanism->fPowerControl){
        XCredsPowerControlMechanism *powerControl = [[XCredsPowerControlMechanism alloc] initWithMechanism:mechanism];
        [powerControl run];

    }
    else if (mechanism->fEnableFDE){
        XCredsEnableFDE *fdeMech = [[XCredsEnableFDE alloc] initWithMechanism:mechanism];
        [fdeMech run];

    }
    else if (mechanism->fKeychainAdd){
        XCredsKeychainAdd *keychainAdd = [[XCredsKeychainAdd alloc] initWithMechanism:mechanism];
        [keychainAdd run];

    }
    else if (mechanism->fCreateUser){
        XCredsCreateUser *createUser = [[XCredsCreateUser alloc] initWithMechanism:mechanism];
        [createUser run];

    }
    else if (mechanism->fLoginDone){
        XCredsLoginDone *loginDone = [[XCredsLoginDone alloc] initWithMechanism:mechanism];
        [loginDone run];

    }

    return noErr;
}

- (OSStatus)MechanismDeactivate:(AuthorizationMechanismRef)inMechanism {
    TCSLog([NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__]);

    OSStatus err;
    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;

    err = mechanism->fPlugin->fCallbacks->DidDeactivate(mechanism->fEngine);
    return err;
}

- (OSStatus)MechanismDestroy:(AuthorizationMechanismRef)inMechanism {
    TCSLog([NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__]);

    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;
    if (mechanism->fLoginWindow) {
        
        [loginWindowMechanism tearDown];
//        if (loginWindowMechanism.signIn.visible == true) {
//            [loginWindowMechanism tearDown];
//        }
    }
    free(mechanism);
    return noErr;
}

- (OSStatus)PluginDestroy:(AuthorizationPluginRef)inPlugin {
    TCSLog([NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, [[[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],__LINE__]);

    free(inPlugin);
    return noErr;
}
@end
