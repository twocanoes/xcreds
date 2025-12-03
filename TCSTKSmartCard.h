//
//  TCSTKSmartCard.h
//  Smart Card Utility
//
//  Created by Timothy Perfitt on 11/2/25.
//  Copyright © 2025 Twocanoes Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CryptoTokenKit/CryptoTokenKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface TCSTKSmartCard : TKSmartCard
@property (retain) TKSmartCard *tkSmartCard;
- (instancetype)initFromTKSmartCard:(TKSmartCard *)smartcard ;
- (nullable NSData *)sendIns:(UInt8)ins p1:(UInt8)p1 p2:(UInt8)p2 data:(nullable NSData *)requestData le:(nullable NSNumber *)le sw2:(UInt16 *)sw error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
