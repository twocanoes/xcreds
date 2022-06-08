//
//  NSFileManager+TCSRealHomeFolder.h
//  Signing Manager
//
//  Created by Timothy Perfitt on 2/15/21.
//  Copyright © 2021 Twocanoes Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSFileManager (TCSRealHomeFolder)
- (NSString *)realHomeFolder;
@end

NS_ASSUME_NONNULL_END
