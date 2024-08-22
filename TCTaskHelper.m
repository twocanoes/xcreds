//
//  TCTaskHelper.m
//
//  Created by Tim Perfitt on 2/20/17.
//  Copyright © 2017 Twocanoes Software, Inc. All rights reserved.
//

#import "TCTaskHelper.h"

@implementation TCTaskHelper
+(TCTaskHelper *)sharedTaskHelper{
    static TCTaskHelper *sharedTaskHelper;
    
    if(sharedTaskHelper==nil){
        sharedTaskHelper=[[TCTaskHelper alloc] init];
    }
    return sharedTaskHelper;
    
}



-(NSString *)runCommand:(NSString *)command withOptions:(NSArray *)inOptions{
    NSLog(@"running %@ %@",command, [inOptions componentsJoinedByString:@" "]);
    NSPipe *pipe = [NSPipe pipe];
    
    NSMutableString *outputString=[NSMutableString string];
    NSTask *task = [NSTask new];
    [task setLaunchPath:command];
    [task setArguments:inOptions];
    
    
    [task setStandardOutput:pipe];
    
    [task launch];
    
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    
   // [task waitUntilExit];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *lines=[string componentsSeparatedByString:@"\n"];
    
    for (NSString *line in lines) {
        [outputString appendString:line];
    }
    
    return [NSString stringWithString:outputString];
}

@end
