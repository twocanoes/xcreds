//
//  TCSUnifiedLogger.m
//
//  Created by Timothy Perfitt on 8/15/19.
//  Copyright © 2019 Twocanoes Software, Inc. All rights reserved.
//

#import "TCSUnifiedLogger.h"
#include <unistd.h>
#import "NSFileManager+TCSRealHomeFolder.h"
#import <os/log.h>


@interface TCSUnifiedLogger ()

@property NSString *lastLine;
@property NSDate *lastLoggedDate;
@property NSInteger repeated;
@end


@implementation TCSUnifiedLogger

void TCSLog(NSString *string)
{

    os_log(OS_LOG_DEFAULT, "XCREDS_LOG:%{public}s",[string stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"].UTF8String);
    [[TCSUnifiedLogger sharedLogger] logString:string level:LOGLEVELDEBUG];
}

void TCSLogInfo(NSString *string)
{
    os_log(OS_LOG_DEFAULT, "XCREDS_LOG:%{public}s",[string stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"].UTF8String);

    [[TCSUnifiedLogger sharedLogger] logString:string level:LOGLEVELINFO];
    
}
void TCSLogError(NSString *string)
{
    os_log(OS_LOG_DEFAULT, "XCREDS_LOG:%{public}s",[string stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"].UTF8String);

    [[TCSUnifiedLogger sharedLogger] logString:string level:LOGLEVELERROR];
}
+ (TCSUnifiedLogger *)sharedLogger
{
    static TCSUnifiedLogger *sharedLogger;


    if (sharedLogger !=nil){
        return sharedLogger;
    }

 
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *logFolderPath = [[[NSUserDefaults standardUserDefaults] objectForKey:@"LogFolderPath"] stringByExpandingTildeInPath];
    NSURL *logFolderURL;
//log file not defined.
    if (!logFolderPath || logFolderPath.length == 0 || [fm fileExistsAtPath:logFolderPath] == NO) {
        //root
        if (getuid() == 0 || getuid() == 92) { //root or security agent

            logFolderURL = [NSURL fileURLWithPath:@"/tmp/xcreds"];


        //not root
        } else {
            system("/usr/bin/touch /tmp/xcd");
            NSString *homePath = [[NSFileManager defaultManager] realHomeFolder];
            logFolderURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/Library/Logs", homePath]];
            if (![fm fileExistsAtPath:logFolderURL.path]) {
                char template[]="/tmp/xcreds-XXXXXX";

                char *dirPath=mkdtemp(template);
                if (dirPath) {
                    logFolderURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:dirPath]];
                }

            }
        }
    }
//define based on prefs.
    else {
        logFolderURL = [NSURL fileURLWithPath:[logFolderPath stringByExpandingTildeInPath]];
    }

    //get name from prefs. if not set, use generic.log
    NSString *logFileName = [[NSUserDefaults standardUserDefaults] objectForKey:@"LogFileName"];
    if (!logFileName || logFileName.length == 0) {

        logFileName = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"LogFileName"];
        if (!logFileName || logFileName.length == 0) {
            logFileName = @"generic.log";
        }
    }


    if (sharedLogger == nil) {
        sharedLogger = [[TCSUnifiedLogger alloc] init];
    }
    sharedLogger.lastLoggedDate = [NSDate distantPast];

    sharedLogger.logFileURL = [logFolderURL URLByAppendingPathComponent:logFileName];
    if (![fm fileExistsAtPath:[sharedLogger.logFileURL.path stringByDeletingLastPathComponent]]) {
        if ([fm createDirectoryAtPath:[sharedLogger.logFileURL.path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil] == NO) {
        }
    }
    return sharedLogger;
}
//os_log("Unable to get home directory path.", log: "", type: .error)
//- (void)os_log:(NSString *)inStr log:(NSString *)level type:(id)type{
//
//}


- (void)logString:(NSString *)inStr level:(LogLevel)level
{

    if (level==LOGLEVELDEBUG && [[NSUserDefaults standardUserDefaults] boolForKey:@"showDebug"]==NO){

        return;
    }
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
