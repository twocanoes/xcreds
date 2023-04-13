//
//  NSData+HexString.h
//  Identity Manager
//
//  Created by Timothy Perfitt on 12/29/19.
//  Copyright © 2020 Twocanoes Software, Inc. All rights reserved.
//



#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (HexString)
+(id)dataWithHexString:(NSString *)hex;
- (NSString *)hexString;
@end

NS_ASSUME_NONNULL_END
