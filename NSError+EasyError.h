//
//  NSError+EasyError.h
//  Winclone
//
//  Created by Timothy Perfitt on 8/14/19.
//  Copyright © 2019 Twocanoes Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (EasyError)
+(NSError *)easyErrorWithTitle:(NSString *)title
                          body:(NSString *)body
                          line:(int)line
                          file:(NSString *)file;
@end

NS_ASSUME_NONNULL_END
