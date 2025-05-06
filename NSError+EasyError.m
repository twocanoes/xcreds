//
//  NSError+EasyError.m
//  Winclone
//
//  Created by Timothy Perfitt on 8/14/19.
//  Copyright © 2019 Twocanoes Software, Inc. All rights reserved.
//

#import "NSError+EasyError.h"

@implementation NSError (EasyError)
+(NSError *)easyErrorWithTitle:(NSString *)title
                          body:(NSString *)body
                          line:(int)line
                          file:(NSString *)file{



    NSString *fullRecovery=body;

    BOOL extendedInfo=[[NSUserDefaults standardUserDefaults] boolForKey:@"debugging"];
    if (extendedInfo==YES) fullRecovery=[NSString stringWithFormat:@"%@\n\nAdditional Info: Error occurred at %@:%i",body,file.lastPathComponent,line];
    NSString *bundleIdentifier=[[NSBundle mainBundle] bundleIdentifier];

    NSDictionary *userInfo=@{NSLocalizedDescriptionKey:title,
                             NSLocalizedRecoverySuggestionErrorKey:fullRecovery};

    NSError *error=[NSError errorWithDomain:bundleIdentifier
                                       code:-1
                                   userInfo:userInfo];

    NSLog(@"%@: %@",title, [NSString stringWithFormat:@"%@\n\nAdditional Info: Error occurred at %@:%i",body,file.lastPathComponent,line]);
    return error;
}
@end
