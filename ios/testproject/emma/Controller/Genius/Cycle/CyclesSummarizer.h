//
//  CyclesSummarizer.h
//  emma
//
//  Created by Xin Zhao on 5/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CyclesSummarizer : NSObject

+ (NSString *)summaryOfNextPb;
+ (NSArray *)summaryOfStages;
+ (NSArray *)summaryOfPastCycles;

@end
