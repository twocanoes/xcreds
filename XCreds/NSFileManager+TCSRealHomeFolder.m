//
//  NSFileManager+TCSRealHomeFolder.m
//  Signing Manager
//
//  Created by Timothy Perfitt on 2/15/21.
//  Copyright © 2021 Twocanoes Software, Inc. All rights reserved.
//

#import "NSFileManager+TCSRealHomeFolder.h"
#include <pwd.h>


@implementation NSFileManager (TCSRealHomeFolder)
- (NSString *)realHomeFolder
{
    struct passwd *pw = getpwuid(getuid());
    assert(pw);
    return [NSString stringWithUTF8String:pw->pw_dir];
}

@end
