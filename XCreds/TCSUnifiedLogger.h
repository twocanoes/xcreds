//
//  TCSUnifiedLogger.h
//
//  Created by Timothy Perfitt on 8/15/19.
//  Copyright © 2019 Twocanoes Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum : NSUInteger {
    LOGLEVELERROR,
    LOGLEVELINFO,
    LOGLEVELDEBUG,
} LogLevel;

#undef os_log_debug
#undef os_log_info
#undef os_log_error

#define os_log_debug(log, ...)                                                                                      \
    ;                                                                                                               \
    {                                                                                                               \
        char *log_string = malloc(1024);                                                                            \
        snprintf(log_string, 1024, ##__VA_ARGS__);                                                                  \
        [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithUTF8String:log_string] level:LOGLEVELDEBUG]; \
        free(log_string);                                                                                           \
    }
#define os_log_info(log, ...)                                                                                      \
    ;                                                                                                              \
    {                                                                                                              \
        char *log_string = malloc(1024);                                                                           \
        snprintf(log_string, 1024, ##__VA_ARGS__);                                                                 \
        [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithUTF8String:log_string] level:LOGLEVELINFO]; \
        free(log_string);                                                                                          \
    }
#define os_log_error(log, ...)                                                                                      \
    ;                                                                                                               \
    {                                                                                                               \
        char *log_string = malloc(1024);                                                                            \
        snprintf(log_string, 1024, ##__VA_ARGS__);                                                                  \
        [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithUTF8String:log_string] level:LOGLEVELERROR]; \
        free(log_string);                                                                                           \
    }
#define NSLog(fmt, ...)                                                                                                 \
    ;                                                                                                                   \
    {                                                                                                                   \
        [[TCSUnifiedLogger sharedLogger] logString:[NSString stringWithFormat:fmt, ##__VA_ARGS__] level:LOGLEVELDEBUG]; \
    }


NS_ASSUME_NONNULL_BEGIN
#undef TCSLog
void TCSLog(NSString *str);


@interface TCSUnifiedLogger : NSObject
+ (TCSUnifiedLogger *)sharedLogger;
@property (strong, readwrite) NSURL *logFileURL;
@property (strong, readwrite) NSString *logFolderName;
@property (strong, readwrite) NSString *logFileName;
- (void)logString:(NSString *)inStr level:(LogLevel)level;

@end

NS_ASSUME_NONNULL_END
