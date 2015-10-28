//
//  Activity.h
//  emma
//
//  Created by Jirong Wang on 11/29/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "ActivityLevel.h"

@interface Activity : NSObject

+ (NSDictionary *)calActivityFor:(User *)user from:(NSString *)startDateLabel to:(NSString *)endDateLabel;
+ (NSArray *)getGlowFirstActivityHistory:(User *)user;
+ (ActivityLevel *)getActivityFor:(User *)user year:(NSInteger)year month:(NSInteger)month;
+ (ActivityLevel *)getActivityForCurrentMonth:(User *)user;
+ (void)calActivityForCurrentMonth:(User *)user;
+ (void)calDemoActivityHistory:(User *)user;
+ (NSArray *)dailyTodoDictArrayFromDate:(NSString *)startDate toDate:(NSString *)endDate forUser:(User *)user;

@end
