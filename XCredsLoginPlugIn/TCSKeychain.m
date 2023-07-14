//
//
//  Copyright (c) 2014 Twocanoes. All rights reserved.
//

#import "TCSKeychain.h"
#import "NSData+SHA1.h"
#import "NSData+HexString.h"
#import <CryptoTokenKit/CryptoTokenKit.h>

NSString *const TCSKeychainService = @"com.twocanoes.mds.apns";


@implementation TCSKeychain

+ (NSArray *)smartcardCertificateArrayFromKeychain
{
    
    __block BOOL verbose = [[NSUserDefaults standardUserDefaults] boolForKey:@"verboseLogging"];
    TKTokenWatcher *watcher = [[TKTokenWatcher alloc] init];
    NSArray *tokenIDs = watcher.tokenIDs;
    if (verbose == YES) NSLog(@"token IDS: %@", tokenIDs);
    __block NSMutableArray *certificateArray = [NSMutableArray array];
    [tokenIDs enumerateObjectsUsingBlock:^(NSString *currTokenID, NSUInteger idx, BOOL *_Nonnull stop) {
        NSDictionary *query = @{(id)kSecAttrTokenID : currTokenID,
                                (id)kSecClass : (id)kSecClassIdentity,
                                (id)kSecReturnAttributes : (id)kCFBooleanTrue,
                                (id)kSecReturnRef : @YES,
                                (id)kSecMatchLimit : (id)kSecMatchLimitAll
        };


        if (verbose == YES) NSLog(@"querying");
        CFTypeRef keyData = nil;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query,
                                              &keyData);

        if (verbose == YES) NSLog(@"matching with status: %i", status);
        if (status == 0) {
            NSArray *identityArray = (__bridge id)keyData;
            if (identityArray) {
                [identityArray enumerateObjectsUsingBlock:^(NSDictionary *currentIdentityInfo, NSUInteger idx, BOOL *_Nonnull stop) {
                    SecIdentityRef currentIdentity = (__bridge SecIdentityRef)([currentIdentityInfo objectForKey:(NSString *)kSecValueRef]);

                    BOOL canSign = [[currentIdentityInfo objectForKey:(NSString *)kSecAttrCanSign] boolValue];
                    BOOL canDecrypt = [[currentIdentityInfo objectForKey:(NSString *)kSecAttrCanDecrypt] boolValue];
                    BOOL canUnwrap = [[currentIdentityInfo objectForKey:(NSString *)kSecAttrCanUnwrap] boolValue];

                    SecCertificateRef cert;
                    SecIdentityCopyCertificate(currentIdentity, &cert);
                    NSData *certData = (NSData *)CFBridgingRelease(SecCertificateCopyData(cert));
                    NSData *encodedCertData = [certData base64EncodedDataWithOptions:0];
                    NSString *base64EncodedCertString = [[NSString alloc] initWithData:encodedCertData encoding:NSUTF8StringEncoding];

                    [certificateArray addObject:@{
                        @"certificate" : base64EncodedCertString,
                        @"canSign" : @(canSign),
                        @"canDecrypt" : @(canDecrypt),
                        @"canUnwrap" : @(canUnwrap)
                    }];
                }];
            }
        } else {
            NSLog(@"Issue with SecItemCopyMatching");
        }
    }];

    if (verbose == YES) {
        NSLog(@"------certificate array from keychain------");
        [certificateArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            SecIdentityRef secRef = (__bridge SecIdentityRef)obj;
            SecCertificateRef certificateRef;
            SecIdentityCopyCertificate(secRef, &certificateRef);
            NSData *data = (NSData *)CFBridgingRelease(SecCertificateCopyData(certificateRef));
            NSLog(@"certificate in keychain:%@", data);
        }];
    }
    return [NSArray arrayWithArray:certificateArray];
}

+ (SecIdentityRef)findIdentityWithSubject:(NSString *)inSubject
{
    NSArray *returnIdentityArray;
    OSStatus sanityCheck;
    sanityCheck = SecItemCopyMatching((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         (id)kSecClassIdentity, kSecClass,
                                                                         kSecMatchLimitAll, kSecMatchLimit,
                                                                         kCFBooleanFalse, kSecReturnRef,
                                                                         kCFBooleanFalse, kSecReturnAttributes,
                                                                         inSubject, kSecMatchSubjectContains,

                                                                         nil],
                                      (void *)&returnIdentityArray);


    if (returnIdentityArray.count == 1) return (SecIdentityRef)CFBridgingRetain(returnIdentityArray[0]);

    return nil;
}
+ (void)findIdentityWithSHA1Hash:(NSData *)inHash returnIdentity:(SecIdentityRef *)returnIdentity
{
    NSArray *returnIdentityArray;
    OSStatus sanityCheck;
    *returnIdentity = nil;
    sanityCheck = SecItemCopyMatching((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         (id)kSecClassIdentity, kSecClass,
                                                                         kSecMatchLimitAll, kSecMatchLimit,
                                                                         kCFBooleanFalse, kSecReturnRef,
                                                                         kCFBooleanFalse, kSecReturnAttributes,

                                                                         nil],
                                      (void *)&returnIdentityArray);


    if (sanityCheck != noErr) {
        NSLog(@"SecIdentityCopyCertificate error");
        return;
    }

    [returnIdentityArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *_Nonnull stop) {
        SecCertificateRef cert;
        SecIdentityCopyCertificate((SecIdentityRef)obj, &cert);
        NSData *certData = (NSData *)CFBridgingRelease(SecCertificateCopyData(cert));
        if ([inHash isEqualToData:[certData sha1]]) {
            *stop = YES;
            *returnIdentity = (__bridge_retained SecIdentityRef)(obj);
        }
    }];
}
+ (NSArray *)keychainIdentities
{
    NSArray *returnIdentityArray;
    OSStatus sanityCheck;
    sanityCheck = SecItemCopyMatching((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
        (id)kSecClassIdentity, kSecClass,
         kSecMatchLimitAll, kSecMatchLimit,
            kCFBooleanTrue, kSecReturnRef,
         kCFBooleanFalse, kSecReturnAttributes,

         nil],
                                      (void *)&returnIdentityArray);


    if (sanityCheck != noErr) {
         return nil;
    }

    return returnIdentityArray;
}
+ (NSArray *)availableIdentityInfo
{
    NSArray *identities = [TCSKeychain keychainIdentities];

    __block NSMutableArray *identityArray = [NSMutableArray array];
    [identities enumerateObjectsUsingBlock:^(id _Nonnull currIdentity, NSUInteger idx, BOOL *_Nonnull stop) {
        SecIdentityRef currIDRef = (__bridge SecIdentityRef)currIdentity;
        CFStringRef cn;
        SecCertificateRef certRef;
        if (SecIdentityCopyCertificate(currIDRef, &certRef) == errSecSuccess) {
            if (SecCertificateCopyCommonName(certRef, &cn) == errSecSuccess) {
                NSData *certData = (NSData *)CFBridgingRelease(SecCertificateCopyData(certRef));
                NSString *sha1Hash = [[certData sha1] hexString];

                [identityArray addObject:@{@"cn" : (NSString *)CFBridgingRelease(cn), @"sha1_fingerprint" : sha1Hash}];
            }
        }
    }];

    return [NSArray arrayWithArray:identityArray];
}


+ (NSString *)randomPasswordLength:(NSUInteger)length
{
    NSMutableString *password = [NSMutableString stringWithString:@""];
    for (int i = 0; i < length; i++) {
        [password appendString:[NSString stringWithFormat:@"%c", arc4random_uniform(94) + '!']];
    }
    return [NSString stringWithString:password];
}
+ (NSString *)randomPassword
{
    return [[self class] randomPasswordLength:15];
}

+ (NSString *)passwordForService:(NSString *)service account:(NSString *)account accessGroup:(NSString *)accessGroup error:(NSError **)err
{
    NSDictionary *attributes = [TCSKeychain attributesForService:service account:account accessGroup:accessGroup error:err];

    if (attributes && [attributes objectForKey:@"password"]) return [attributes objectForKey:@"password"];
    return nil;
}
+ (NSDictionary *)attributesForService:(NSString *)service account:(NSString *)account accessGroup:(NSString *)accessGroup error:(NSError **)err
{
    NSDictionary *itemQuery;
    if (accessGroup) {
        itemQuery = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                      (__bridge id)kSecAttrAccount : account,
                      (__bridge id)kSecAttrService : service,
                      (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
                      (__bridge id)kSecAttrSynchronizable : @YES,
                      (__bridge id)kSecAttrAccessGroup : accessGroup,
                      (__bridge id)kSecReturnAttributes : @YES,
                      (__bridge id)kSecReturnData : @YES};
    } else {
        itemQuery = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                      (__bridge id)kSecAttrAccount : account,
                      (__bridge id)kSecAttrService : service,
                      (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
                      (__bridge id)kSecReturnAttributes : @YES,
                      (__bridge id)kSecReturnData : @YES};
    }

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)itemQuery, &result);
    if (status == noErr) {
        CFDataRef data = CFDictionaryGetValue(result, kSecValueData);
        NSDate *modifiedDate = (NSDate *)CFDictionaryGetValue(result, kSecAttrModificationDate);
        NSString *password = [[NSString alloc] initWithData:(__bridge NSData *)data encoding:NSASCIIStringEncoding];

        if (password && modifiedDate) {
            return @{@"password" : password, @"modifiedDate" : modifiedDate};
        } else
            return nil;
    }
    //nil without error means not found
    if (status == errSecItemNotFound) {
        return nil;
    }
    *err = [NSError errorWithDomain:@"TCS" code:-128 userInfo:nil];
    return nil;
}
+ (NSString *)passwordForAccount:(NSString *)account accessGroup:(NSString *)accessGroup error:(NSError **)err
{
    return [[self class] passwordForService:TCSKeychainService account:account accessGroup:accessGroup error:err];
}

+ (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account accessGroup:(NSString *)accessGroup
{
    NSDictionary *query;

    if (accessGroup) {
        query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                  (__bridge id)kSecAttrAccount : account,
                  (__bridge id)kSecAttrService : service,
                  (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
                  (__bridge id)kSecAttrSynchronizable : @YES,
                  (__bridge id)kSecAttrAccessGroup : accessGroup,
                  (__bridge id)kSecReturnAttributes : @YES};
    } else {
        query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                  (__bridge id)kSecAttrAccount : account,
                  (__bridge id)kSecAttrService : service,
                  (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
                  (__bridge id)kSecReturnAttributes : @YES};
    }

    if (password) {
        NSData *passwordData = [password dataUsingEncoding:NSASCIIStringEncoding];

        CFTypeRef result = NULL;
        OSStatus queryStatus = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        switch (queryStatus) {
            case noErr: {
                NSDictionary *updateQuery;
                if (accessGroup) {
                    updateQuery = @{
                        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                        (__bridge id)kSecAttrAccount : account,
                        (__bridge id)kSecAttrService : service,
                        (__bridge id)kSecAttrSynchronizable : @YES,
                        (__bridge id)kSecAttrAccessGroup : accessGroup,

                    };
                } else {
                    updateQuery = @{
                        (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                        (__bridge id)kSecAttrAccount : account,
                        (__bridge id)kSecAttrService : service,

                    };
                }

                NSDictionary *updateItem = @{(__bridge id)kSecValueData : passwordData};

                OSStatus updateStatus = SecItemUpdate((__bridge CFDictionaryRef)(updateQuery), (__bridge CFDictionaryRef)updateItem);
                if (updateStatus != noErr) {
                    NSLog(@"Update Error: %i", (int)updateStatus);
                    return NO;
                }

                break;
            }
            case errSecItemNotFound: {
                NSDictionary *newItem;
                if (accessGroup) {
                    newItem = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecAttrAccount : account,
                                (__bridge id)kSecAttrService : service,
                                (__bridge id)kSecAttrSynchronizable : @YES,
                                (__bridge id)kSecAttrAccessGroup : accessGroup,


                                (__bridge id)kSecValueData : passwordData};
                } else {
                    newItem = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecAttrAccount : account,
                                (__bridge id)kSecAttrService : service,

                                (__bridge id)kSecValueData : passwordData};
                }

                CFTypeRef result = NULL;
                OSStatus addStatus = SecItemAdd((__bridge CFDictionaryRef)newItem, &result);
                if (addStatus != noErr) {
                    NSLog(@"%@", result);
                    return NO;
                }
                break;
            }
            default: {
                NSLog(@"unknown result :%i", queryStatus);
                return NO;
                break;
            }
        }
    } else {
        NSDictionary *deleteQuery;
        if (accessGroup) {
            deleteQuery = @{
                (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                (__bridge id)kSecAttrAccount : account,
                (__bridge id)kSecAttrService : service,

            };
        } else {
            deleteQuery = @{
                (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                (__bridge id)kSecAttrAccount : account,
                (__bridge id)kSecAttrService : service,
                (__bridge id)kSecAttrSynchronizable : @YES,
                (__bridge id)kSecAttrAccessGroup : accessGroup,

            };
        }

        OSStatus deleteStatus = SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
        if (deleteStatus != noErr) {
            NSLog(@"Error removing keychain %@: %i", account, (int)deleteStatus);
            return NO;
        }
    }
    return YES;
}

+ (BOOL)setPassword:(NSString *)password forAccount:(NSString *)account accessGroup:(NSString *)accessGroup
{
    return [[self class] setPassword:password forService:TCSKeychainService account:account accessGroup:accessGroup];
}
+ (void)deletePasswordForService:(NSString *)service account:(NSString *)account accessGroup:(NSString *)accessGroup
{
    [[self class] setPassword:nil forService:service account:account accessGroup:accessGroup];
}
+ (void)deletePasswordForAccount:(NSString *)account accessGroup:(NSString *)accessGroup
{
    [[self class] setPassword:nil forAccount:account accessGroup:accessGroup];
}

@end


@interface TCSPassword ()
@property (nonatomic, strong) NSMutableDictionary *keychainInfo;
@end


@implementation TCSPassword

- (instancetype)initWithService:(NSString *)service account:(NSString *)account group:(NSString *)group
{
    self = [super init];
    if (self) {
        _keychainInfo = [NSMutableDictionary dictionary];
        if (service) {
            _keychainInfo[(__bridge NSString *)kSecAttrService] = service;
        }
        if (account) {
            _keychainInfo[(__bridge NSString *)kSecAttrAccount] = account;
        }
        if (group) {
            _keychainInfo[(__bridge NSString *)kSecAttrAccessGroup] = group;
        }
    }
    return self;
}

- (void)setPassword:(NSString *)password
{
    NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
    self.keychainInfo[(__bridge NSString *)kSecValueData] = data;
}

- (NSString *)password
{
    NSData *data = self.keychainInfo[(__bridge NSString *)kSecValueData];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)query
{
}

@end
