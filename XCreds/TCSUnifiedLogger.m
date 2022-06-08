//
//  TCSUnifiedLogger.m
//
//  Created by Timothy Perfitt on 8/15/19.
//  Copyright © 2019 Twocanoes Software, Inc. All rights reserved.
//

#import "TCSUnifiedLogger.h"
#include <unistd.h>
#import "NSFileManager+TCSRealHomeFolder.h"


@interface TCSUnifiedLogger ()

@property NSString *lastLine;
@property NSDate *lastLoggedDate;
@property NSInteger repeated;
@end


@implementation TCSUnifiedLogger

void TCSLog(NSString *string)
{
    [[TCSUnifiedLogger sharedLogger] logString:string level:LOGLEVELINFO];
}


+ (TCSUnifiedLogger *)sharedLogger
{
    static TCSUnifiedLogger *sharedLogger;
    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *logFolderPath = [[[NSUserDefaults standardUserDefaults] objectForKey:@"LogFolderPath"] stringByExpandingTildeInPath];
    NSURL *logFolderURL;

    if (!logFolderPath || logFolderPath.length == 0 || [fm fileExistsAtPath:logFolderPath] == NO) {
        if (getuid() == 0) {
            logFolderURL = [NSURL fileURLWithPath:@"/Library/Logs"];

            if ([fm isWritableFileAtPath:logFolderURL.path] == NO || [fm fileExistsAtPath:logFolderURL.path]) {
                logFolderURL = [NSURL fileURLWithPath:@"/var/log"];
                if (![fm fileExistsAtPath:logFolderURL.path] || [fm isWritableFileAtPath:logFolderURL.path] == NO) {
                    logFolderURL = [NSURL fileURLWithPath:@"/tmp"];
                }
            }
        } else {
            NSString *homePath = [[NSFileManager defaultManager] realHomeFolder];
            logFolderURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Library/Logs", homePath]];
            if (![fm fileExistsAtPath:logFolderURL.path]) {
                logFolderURL = [NSURL fileURLWithPath:@"/tmp"];
            }
        }
    }

    else {
        logFolderURL = [NSURL fileURLWithPath:[logFolderPath stringByExpandingTildeInPath]];
    }

    NSString *logFileName = [[NSUserDefaults standardUserDefaults] objectForKey:@"LogFileName"];
    if (!logFileName || logFileName.length == 0) {
        logFileName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"LogFileName"];
        if (!logFileName || logFileName.length == 0) {
            logFileName = @"generic.log";
        }
    }


    if (sharedLogger == nil) {
        sharedLogger = [[TCSUnifiedLogger alloc] init];
        sharedLogger.lastLoggedDate = [NSDate distantPast];

        sharedLogger.logFileURL = [logFolderURL URLByAppendingPathComponent:logFileName];
        if (![fm fileExistsAtPath:[sharedLogger.logFileURL.path stringByDeletingLastPathComponent]]) {
            if ([fm createDirectoryAtPath:[sharedLogger.logFileURL.path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil] == NO) {
            }
        }
    }
    return sharedLogger;
}
- (void)logString:(NSString *)inStr level:(LogLevel)level
{
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];

    NSString *processName = [processInfo processName];
    int processID = [processInfo processIdentifier];
    NSString *processInfoString = [NSString stringWithFormat:@"%@(%d)", processName, processID];

    fprintf(stderr, "%s\n", inStr.UTF8String);
    if (([[NSDate date] timeIntervalSinceDate:self.lastLoggedDate]) > 2 || ![inStr isEqualToString:self.lastLine]) {
        NSFileManager *fm = [NSFileManager defaultManager];

        if (![fm fileExistsAtPath:self.logFileURL.path]) {
            [[NSFileManager defaultManager] createFileAtPath:self.logFileURL.path contents:nil attributes:nil];
        }


        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:self.logFileURL.path];
        [fh seekToEndOfFile];
        NSString *dateString = [NSISO8601DateFormatter stringFromDate:[NSDate date] timeZone:[NSTimeZone localTimeZone] formatOptions:NSISO8601DateFormatWithInternetDateTime];

        if (self.repeated > 0) {
            [fh writeData:[[NSString stringWithFormat:@"%@:Last message repeated %li times\n", dateString, self.repeated] dataUsingEncoding:NSUTF8StringEncoding]];


            self.repeated = 0;
            self.lastLine = @"";
        }
        [fh writeData:[[NSString stringWithFormat:@"%@ %@: %@", dateString, processInfoString, [inStr stringByAppendingString:@"\n"]] dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
        self.lastLoggedDate = [NSDate date];

    } else {
        if (self.repeated > 1000) {
            printf("%s\n", inStr.UTF8String);
        }
        self.repeated++;
    }
    self.lastLine = inStr;
}

@end
