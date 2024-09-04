//
//  Header.h
//  NoMAD
//
//  Created by Joel Rennich on 4/26/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GSS/GSS.h>
#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#import <DirectoryService/DirectoryService.h>
#import <OpenDirectory/OpenDirectory.h>

extern OSStatus SecKeychainItemSetAccessWithPassword(SecKeychainItemRef item, SecAccessRef access, UInt32 passLength, const void* password);

@interface KerbUtil : NSObject
@property (nonatomic, assign, readonly) BOOL						finished;   // observable

- (NSDictionary *)getKerbCredentialWithPassword:password userPrincipal:(NSString *)userPrincipal;
- (void)getKerberosCredentials:(NSString *)password :(NSString *)userPrincipal completion:(void(^)(NSDictionary *))callback;
- (NSString *)getKerbCredentials:(NSString *)password :(NSString *)userPrincipal;
- (void)changeKerberosPassword:(NSString *)oldPassword :(NSString *)newPassword :(NSString *)userPrincipal completion:(void(^)(NSString *))callback;
- (NSString *)changeKerbPassword:(NSString *)oldPassword :(NSString *)newPassword :(NSString *)userPrincipal;
- (int)checkPassword:(NSString *)myPassword;
- (int)changeKeychainPassword:(NSString *)oldPassword :(NSString *)newPassword;
- (OSStatus)resetKeychain:(NSString *)password;

@end

