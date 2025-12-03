//
//  TCSTKSmartCard.m
//  Smart Card Utility
//
//  Created by Timothy Perfitt on 11/2/25.
//  Copyright © 2025 Twocanoes Software. All rights reserved.
//

#import "TCSTKSmartCard.h"
#import <CryptoTokenKit/CryptoTokenKit.h>

NS_ASSUME_NONNULL_BEGIN

@implementation TCSTKSmartCard


- (instancetype)initFromTKSmartCard:(TKSmartCard *)smartcard {
    self = [super init];
    if (self) {
        self.tkSmartCard=smartcard;
    }
    return self;
}
- (nullable NSData *)sendIns:(UInt8)ins p1:(UInt8)p1 p2:(UInt8)p2 data:(nullable NSData *)requestData le:(nullable NSNumber *)le sw2:(UInt16 *)sw error:(NSError **)error{

    
    NSData * res = [self.tkSmartCard sendIns:ins p1:p1 p2:p2 data:requestData le:le sw:sw error:error];
    return res;

}

@end

NS_ASSUME_NONNULL_END
