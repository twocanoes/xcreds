//
//  XCredsLoginPlugin.m
//  XCredsLoginPlugin
//
//  Created by Timothy Perfitt on 7/2/22.
//

#import "XCredsLoginPlugin.h"
#import "XCredsLoginPlugin-Swift.h"
XCredsLoginPlugin *authorizationPlugin = nil;

//os_log_t pluginLog = nil;
XCredsLoginMechanism *loginWindowMechanism = nil;



static OSStatus PluginDestroy(AuthorizationPluginRef inPlugin) {
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

    return [authorizationPlugin PluginDestroy:inPlugin];
}

static OSStatus MechanismCreate(AuthorizationPluginRef inPlugin,
                                AuthorizationEngineRef inEngine,
                                AuthorizationMechanismId mechanismId,
                                AuthorizationMechanismRef *outMechanism) {
    [[TCSUnifiedLogger sharedLogger] setLogFileURL:[NSURL fileURLWithPath:@"/tmp/xcreds.log"]];
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

    return [authorizationPlugin MechanismCreate:inPlugin
                                      EngineRef:inEngine
                                    MechanismId:mechanismId
                                   MechanismRef:outMechanism];
}

static OSStatus MechanismInvoke(AuthorizationMechanismRef inMechanism) {
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

    return [authorizationPlugin MechanismInvoke:inMechanism];
}

static OSStatus MechanismDeactivate(AuthorizationMechanismRef inMechanism) {
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

    return [authorizationPlugin MechanismDeactivate:inMechanism];
}

static OSStatus MechanismDestroy(AuthorizationMechanismRef inMechanism) {
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

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
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

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
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

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
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

    MechanismRecord *mechanism = (MechanismRecord *)malloc(sizeof(MechanismRecord));
    if (mechanism == NULL) return errSecMemoryError;
    mechanism->fMagic = kMechanismMagic;
    mechanism->fEngine = inEngine;
    mechanism->fPlugin = (PluginRecord *)inPlugin;
    mechanism->fMechID = mechanismId;
    mechanism->fLoginWindow = (strcmp(mechanismId, "LoginWindow") == 0);
    mechanism->fPowerControl = (strcmp(mechanismId, "PowerControl") == 0);
    mechanism->fKeychainAdd = (strcmp(mechanismId, "KeychainAdd") == 0);
    mechanism->fCreateUser = (strcmp(mechanismId, "CreateUser") == 0);
    *outMechanism = mechanism;

    return errSecSuccess;
}

- (OSStatus)MechanismInvoke:(AuthorizationMechanismRef)inMechanism {
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;


    if (mechanism->fLoginWindow) {
        loginWindowMechanism = [[XCredsLoginMechanism alloc] initWithMechanism:mechanism];
        [loginWindowMechanism run];

    }
    else if (mechanism->fPowerControl){
        NSLog(@"Calling PowerControl");
        XCredsPowerControlMechanism *powerControl = [[XCredsPowerControlMechanism alloc] initWithMechanism:mechanism];
        [powerControl run];

    }
    else if (mechanism->fKeychainAdd){
        NSLog(@"Calling fKeychainAdd");
        XCredsKeychainAdd *keychainAdd = [[XCredsKeychainAdd alloc] initWithMechanism:mechanism];
        [keychainAdd run];

    }
    else if (mechanism->fCreateUser){
        NSLog(@"Calling CreateUser");
        XCredsCreateUser *createUser = [[XCredsCreateUser alloc] initWithMechanism:mechanism];
        [createUser run];

    }
    return noErr;
}

- (OSStatus)MechanismDeactivate:(AuthorizationMechanismRef)inMechanism {
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

    OSStatus err;
    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;

    err = mechanism->fPlugin->fCallbacks->DidDeactivate(mechanism->fEngine);
    return err;
}

- (OSStatus)MechanismDestroy:(AuthorizationMechanismRef)inMechanism {
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;
    if (mechanism->fLoginWindow) {
//        if (loginWindowMechanism.signIn.visible == true) {
//            [loginWindowMechanism tearDown];
//        }
    }
    free(mechanism);
    return noErr;
}

- (OSStatus)PluginDestroy:(AuthorizationPluginRef)inPlugin {
    [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:@"%s %s:%d",__FUNCTION__, __FILE__,__LINE__] level:LOGLEVELDEBUG];

    free(inPlugin);
    return noErr;
}

@end
