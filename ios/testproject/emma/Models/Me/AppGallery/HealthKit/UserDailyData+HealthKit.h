//
//  UserDailyData+HealthKit.h
//  emma
//
//  Created by Peng Gu on 12/3/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UserDailyData.h"

@interface UserDailyData (HealthKit)

+ (void)pullFromHealthKitForDate:(NSDate *)date;

- (void)pushToHealthKit;
- (void)pushToHealthKitForKey:(NSString *)key value:(NSObject *)valueToPush;

@end
