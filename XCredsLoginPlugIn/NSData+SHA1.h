//
//  NSData+SHA1.h
//  TCSToken
//
//  Created by Timothy Perfitt on 12/29/19.
//  Copyright © 2019 Twocanoes Software, Inc. All rights reserved.
//



#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSData (SHA1)
- (NSData *)sha1;
@end

NS_ASSUME_NONNULL_END
