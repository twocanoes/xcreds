//
//  NSData+HexString.m
//  Identity Manager
//
//  Created by Timothy Perfitt on 12/29/19.
//  Copyright © 2019 Twocanoes Software, Inc. All rights reserved.
//

#import "NSData+HexString.h"

@implementation NSData (HexString)
- (NSString *)hexString {

    NSUInteger capacity = self.length * 2;
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *dataBuffer = self.bytes;

    for (NSInteger i = 0; i < self.length; i++) {
        [stringBuffer appendFormat:@"%02lX", (unsigned long)dataBuffer[i]];
    }

    return stringBuffer;
}
+(id)dataWithHexString:(NSString *)hex
{
    char buf[3];
    buf[2] = '\0';

    NSString *currHex=hex;
    if ([hex hasPrefix:@"0x"] || [hex hasPrefix:@"0X"] ) {
        currHex=[hex substringFromIndex:2];
    }
    if ([currHex length] % 2 !=0) {
        return nil;
    }

    unsigned char *bytes = malloc([currHex length]/2);
    unsigned char *bp = bytes;
    for (CFIndex i = 0; i < [currHex length]; i += 2) {
        buf[0] = [currHex characterAtIndex:i];
        buf[1] = [currHex characterAtIndex:i+1];
        char *b2 = NULL;
        *bp++ = strtol(buf, &b2, 16);
        if (b2 != buf + 2) {
            NSLog(@"String should be all hex digits: %@ (bad digit around %ld)", currHex, i);
            return nil;
        }
    }

    return [NSData dataWithBytesNoCopy:bytes length:[currHex length]/2 freeWhenDone:YES];
}

@end
