//
//  TCSBetaCheckController.m
//  DFU Blaster SUI
//
//  Created by Timothy Perfitt on 9/14/24.
//

#import "TCSBetaCheckController.h"
#import <AppKit/AppKit.h>
@implementation TCSBetaCheckController
#define SUPPORTURLS [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Support URLs"]

-(void)checkBeta {

     NSString *compileDate = [NSString stringWithUTF8String:__DATE__];
     NSDateFormatter *df = [[NSDateFormatter alloc] init];
     [df setDateFormat:@"MMM d yyyy"];
     NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
     [df setLocale:usLocale];
     NSDate *betaExpireDate = [[df dateFromString:compileDate] dateByAddingTimeInterval:60*60*24*30];
         NSTimeInterval ti=[betaExpireDate timeIntervalSinceNow];
         NSInteger res;
         if ([self isExpired]==YES) {
             res=NSRunAlertPanel(NSLocalizedString(@"Beta Period Ended",@"Title for alert panel that beta expired"),NSLocalizedString(@"This beta has expired.  Please visit twocanoes.com to download the release version.",@"body for alert panel that beta expired"), NSLocalizedString(@"Visit",@"button alert panel that beta expired"),NSLocalizedString(@"Quit", @"button for alert panel that beta expired"),nil);
             if (res==NSAlertDefaultReturn) {
                 ;
                 NSURL *url=[NSURL URLWithString:@"https://twocanoes.com"];
                 [[NSWorkspace sharedWorkspace]  openURL:url];
             }
             [NSApp terminate:self];
         }
         else {

             dispatch_async(dispatch_get_main_queue(), ^{


             NSAlert *alert=[NSAlert alertWithMessageText:@"WARNING" defaultButton:@"I Agree" alternateButton:@"Quit" otherButton:nil informativeTextWithFormat:@"THIS IS A PRE-RELEASE SOFTWARE AND THIS SOFTWARE IS OFFERED WITHOUT SUPPORT OR WARRANTY. BY CLICKING OK, YOU ACCEPT AND AGREE.\n\nThis build will expire on %@",[betaExpireDate description]];
     
             NSInteger res=[alert runModal];
             if (res==NSAlertAlternateReturn){
                 [NSApp terminate:self];
             }
             });

     
         }

     
}
-(BOOL)isExpired{
    NSString *compileDate = [NSString stringWithUTF8String:__DATE__];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MMM d yyyy"];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [df setLocale:usLocale];
    NSDate *betaExpireDate = [[df dateFromString:compileDate] dateByAddingTimeInterval:60*60*24*30];
        NSTimeInterval ti=[betaExpireDate timeIntervalSinceNow];
        if (ti<0) {
            return YES;
        }
    return NO;


    
}
@end
