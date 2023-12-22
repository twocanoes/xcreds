//
//  KerbUtil.m
//  NoMAD
//
//  Created by Joel Rennich on 4/26/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

#import "KerbUtil.h"
#import <GSS/GSS.h>
#import <krb5/krb5.h>
#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#import <DirectoryService/DirectoryService.h>
#import <OpenDirectory/OpenDirectory.h>

@interface KerbUtil ()

@property (nonatomic, assign, readwrite) BOOL				finished;

@end

@implementation KerbUtil


//we declare the private function SecKeychainChangePassword
//this is private... so keep that in mind

extern OSStatus SecKeychainChangePassword(SecKeychainRef keychainRef, UInt32 oldPasswordLength, const void* oldPassword, UInt32 newPasswordLength, const void* newPassword);

extern OSStatus SecKeychainResetLogin(UInt32 passwordLength, const void* password, Boolean resetSearchList);

- (void)getKerberosCredentials:(NSString *)password :(NSString *)userPrincipal completion:(void(^)(NSString *))callback {
    OM_uint32 maj_stat;
    gss_name_t gname = GSS_C_NO_NAME;
    gss_cred_id_t cred = NULL;
    CFErrorRef error = NULL;

    // preflight for spaces in the userPrincipal
    gname = GSSCreateName((__bridge CFTypeRef _Nonnull)(userPrincipal), GSS_C_NT_USER_NAME, NULL);
    if (gname == NULL) {
        callback(@"error: failed to create GSS name");
        return;
    }

    NSDictionary *attrs = @{ (id)kGSSICPassword : password };
    maj_stat = gss_aapl_initial_cred(gname, GSS_KRB5_MECHANISM, (__bridge CFDictionaryRef)attrs, &cred, &error);

    CFRelease(gname);
    if (maj_stat) {
        NSLog(@"error: %d %@", (int)maj_stat, error);
        NSDictionary *errorDict = CFBridgingRelease(CFErrorCopyUserInfo(error));
        NSString *errorMessage = [errorDict valueForKey:(@"NSDescription")];
        callback(errorMessage);
        return;
    }

    CFRelease(cred);
    callback(nil);
}

- (NSString *)getKerbCredentials:(NSString *)password :(NSString *)userPrincipal {

    self.finished = NO;

    OM_uint32 maj_stat;
    gss_name_t gname = GSS_C_NO_NAME;
    gss_cred_id_t cred = NULL;
    CFErrorRef error = NULL;

    // preflight for spaces in the userPrincipal

    gname = GSSCreateName((__bridge CFTypeRef _Nonnull)(userPrincipal), GSS_C_NT_USER_NAME, NULL);
    if (gname == NULL)
        return @"error: creating GSS name";

    NSDictionary *attrs = @{
                            (id)kGSSICPassword : password
                            };


    maj_stat = gss_aapl_initial_cred(gname, GSS_KRB5_MECHANISM, (__bridge CFDictionaryRef)attrs, &cred, &error);

    CFRelease(gname);
    if (maj_stat) {
        NSLog(@"error: %d %@", (int)maj_stat, error);
        NSDictionary *errorDict = CFBridgingRelease(CFErrorCopyUserInfo(error)) ;
        self.finished = YES;
        return [ errorDict valueForKey:(@"NSDescription")];
    }

    CFRelease(cred);
    self.finished = YES;
    return nil ;
}

- (void)changeKerberosPassword:(NSString *)oldPassword :(NSString *)newPassword :(NSString *)userPrincipal completion:(void(^)(NSString *))callback {
    OM_uint32 maj_stat;
    gss_name_t gname = GSS_C_NO_NAME;
    CFErrorRef error = NULL;

    gname = GSSCreateName((__bridge CFTypeRef _Nonnull)(userPrincipal), GSS_C_NT_USER_NAME, NULL);
    if (gname == NULL) {
        callback(@"error: failed to create GSS name");
        return;
    }
    NSDictionary *attrs = @{ (id)kGSSChangePasswordOldPassword: oldPassword,
                             (id)kGSSChangePasswordNewPassword: newPassword };

    maj_stat = gss_aapl_change_password(gname, GSS_KRB5_MECHANISM, (__bridge CFDictionaryRef)attrs, &error);

    CFRelease(gname);
    if (maj_stat) {
        NSLog(@"error: %d %@", (int)maj_stat, error);
        NSDictionary *errorDict = CFBridgingRelease(CFErrorCopyUserInfo(error));
        NSString *errorMessage = [errorDict valueForKey:(@"NSDescription")];
        callback(errorMessage);
        return;
    }
    callback(nil);
}

- (NSString *)changeKerbPassword:(NSString *)oldPassword :(NSString *)newPassword :(NSString *)userPrincipal {

    self.finished = NO;

    OM_uint32 maj_stat ;
    gss_name_t gname = GSS_C_NO_NAME;
    CFErrorRef error = NULL;

    gname = GSSCreateName((__bridge CFTypeRef _Nonnull)(userPrincipal), GSS_C_NT_USER_NAME, NULL);
    if (gname == NULL)
        return @"Error creating the GSS name.";

    // now change the password

    NSDictionary *attrs2 = @{
                             (id)kGSSChangePasswordOldPassword : oldPassword,
                             (id)kGSSChangePasswordNewPassword : newPassword,
                             };


    maj_stat = gss_aapl_change_password(gname, GSS_KRB5_MECHANISM, (__bridge CFDictionaryRef)attrs2, &error);
    CFRelease(gname);
    if (maj_stat) {
        NSLog(@"error: %d %@", (int)maj_stat, error);
        NSDictionary *errorDict = CFBridgingRelease(CFErrorCopyUserInfo(error)) ;
        self.finished = YES;
        return [ errorDict valueForKey:(@"NSDescription")];
    }
    //   CFRelease(error);
    self.finished = YES;
    return nil;
}

- (int) checkPassword:(NSString *)myPassword {

    //there's a lot of setup here to check a password
    //we create an Authorization Right and then test it

    AuthorizationItem myAuthRight;
    myAuthRight.name = "system.login.tty";
    myAuthRight.value = NULL;
    myAuthRight.valueLength = 0;
    myAuthRight.flags = 0;
    AuthorizationRights authRights;
    authRights.count = 1;
    authRights.items = &myAuthRight;

    //now to setup the authorization environment

    AuthorizationItem authEnvironmentItems[2];
    authEnvironmentItems[0].name = kAuthorizationEnvironmentUsername;
    authEnvironmentItems[0].valueLength = NSUserName().length;
    authEnvironmentItems[0].value = (void *)[NSUserName() UTF8String];
    authEnvironmentItems[0].flags = 0;
    authEnvironmentItems[1].name = kAuthorizationEnvironmentPassword;
    authEnvironmentItems[1].valueLength = myPassword.length;
    authEnvironmentItems[1].value = (void *)[myPassword UTF8String];
    authEnvironmentItems[1].flags = 0;
    AuthorizationEnvironment authEnvironment;
    authEnvironment.count = 2;
    authEnvironment.items = authEnvironmentItems;


    //and now to actually do the auth

    OSStatus authStatus = AuthorizationCreate(&authRights, &authEnvironment, kAuthorizationFlagExtendRights, NULL);
    return (authStatus == errAuthorizationSuccess);

}

- (int) changeKeychainPassword:(NSString *)oldPassword :(NSString *)newPassword {

    // Set up some variables
    SecKeychainRef myDefaultKeychain;
    OSErr err;

    // Get the default keychain path, then attempt to change the password on it
    SecKeychainCopyDefault(&myDefaultKeychain);

    // Cast to proper types before function call
    UInt32 oldLength = (UInt32)oldPassword.length;
    UInt32 newLength = (UInt32)newPassword.length;
    const char *cStyleOldPassword = [oldPassword UTF8String];
    const char *cStyleNewPassword = [newPassword UTF8String];

    NSLog(@"Changing keychain password");
    err = SecKeychainChangePassword(myDefaultKeychain,
                                    oldLength,
                                    cStyleOldPassword,
                                    newLength,
                                    cStyleNewPassword);

    if (err == noErr) {
        NSLog(@"Password changed successfully");
        return 1;
    }
    else if (err == -25293) {
        // Let's try again because sometimes it returns -25293 error, but password is changed.
        // No public function that does the same, we need to stick with it.
        err = SecKeychainChangePassword(myDefaultKeychain,
                                        oldLength,
                                        cStyleOldPassword,
                                        newLength,
                                        cStyleNewPassword);
        if (err == noErr) {
            NSLog(@"Password changed successfully");
            return 1;
        } else {
            NSLog(@"Bad password. Keychain change was not successful.");
            return 0;
        }
    }
    else {
        NSLog(@"Keychain change error.");
        return 0;
    }
}

- (OSStatus)resetKeychain:(NSString *)password {
    return SecKeychainResetLogin((UInt32)password.length, [password UTF8String], YES);
}

@end
