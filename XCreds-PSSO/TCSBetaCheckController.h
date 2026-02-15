//
//  TCSBetaCheckController.h
//  DFU Blaster SUI
//
//  Created by Timothy Perfitt on 9/14/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TCSBetaCheckController : NSObject
-(void)checkBeta;
-(BOOL)isExpired;
@end

NS_ASSUME_NONNULL_END
