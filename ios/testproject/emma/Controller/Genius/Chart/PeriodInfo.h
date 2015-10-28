//
//  PeriodInfo.h
//  emma
//
//  Created by ltebean on 15-4-8.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
@interface PeriodInfo : NSObject
+ (id)sharedInstance;
- (void)reloadData;
- (NSInteger)cycleDayForDateIndex:(NSInteger)dateIndex;
- (NSInteger)ovulationDayForDateIndex:(NSInteger)dateIndex;
- (NSArray *)fertileWindows;
@end
