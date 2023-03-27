//
//  NSData+SHA1.m
//  TCSToken
//
//  Created by Timothy Perfitt on 12/29/19.
//  Copyright © 2019 Twocanoes Software, Inc. All rights reserved.
//

#import "NSData+SHA1.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>


@implementation NSData (SHA1)
- (NSData *)sha1
{
    CC_SHA1_CTX ctx;
    uint8_t *hashBytes = NULL;
    NSData *hash = nil;

    // Malloc a buffer to hold hash.
    hashBytes = malloc(CC_SHA1_DIGEST_LENGTH * sizeof(uint8_t));
    memset((void *)hashBytes, 0x0, CC_SHA1_DIGEST_LENGTH);

    // Initialize the context.
    CC_SHA1_Init(&ctx);
    // Perform the hash.
    CC_SHA1_Update(&ctx, (void *)[self bytes], (CC_LONG)[self length]);
    // Finalize the output.
    CC_SHA1_Final(hashBytes, &ctx);

    // Build up the SHA1 blob.
    hash = [NSData dataWithBytes:(const void *)hashBytes length:(NSUInteger)CC_SHA1_DIGEST_LENGTH];

    if (hashBytes) free(hashBytes);

    return hash;
}

@end
