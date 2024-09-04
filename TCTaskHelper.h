//
//  TCTaskHelper.h
//
//  Created by Tim Perfitt on 2/20/17.
//  Copyright © 2017 Twocanoes Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCTaskHelper : NSObject

+(TCTaskHelper *)sharedTaskHelper;
-(NSString *)runCommand:(NSString *)command withOptions:(NSArray *)inOptions;

@end
