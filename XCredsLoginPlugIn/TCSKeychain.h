//
//
//  Copyright (c) 2014 Twocanoes. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TCSKeychain : NSObject
+ (NSArray *)keychainIdentities;
+ (SecIdentityRef)findIdentityWithSubject:(NSString *)inSubject;
+ (NSString *)randomPasswordLength:(NSUInteger)length;
+ (NSString *)randomPassword;

+ (NSDictionary *)attributesForService:(NSString *)service account:(NSString *)account accessGroup:(NSString *)accessGroup error:(NSError **)err;
+ (NSString *)passwordForService:(NSString *)service account:(NSString *)account accessGroup:(NSString *)accessGroup error:(NSError **)err;

+ (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account accessGroup:(NSString *)accessGroup;
+ (BOOL)setPassword:(NSString *)password forAccount:(NSString *)account accessGroup:(NSString *)accessGroup;
+ (NSString *)passwordForAccount:(NSString *)account accessGroup:(NSString *)accessGroup error:(NSError **)err;
+ (void)findIdentityWithSHA1Hash:(NSData *)inHash returnIdentity:(SecIdentityRef *)returnIdentity;
+ (NSArray *)availableIdentityInfo;
+ (NSArray *)smartcardCertificateArrayFromKeychain;
@end


@interface TCSPassword : NSObject

@property (nonatomic, copy) NSString *service;
@property (nonatomic, copy) NSString *accessGroup;
@property (nonatomic, copy) NSString *password;

- (instancetype)initWithService:(NSString *)service account:(NSString *)account group:(NSString *)group;

@end
