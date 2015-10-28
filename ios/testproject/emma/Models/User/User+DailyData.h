//
//  User+DailyData.h
//  emma
//
//  Created by Allen Hsu on 12/26/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "User.h"

@interface User (DailyData)

- (UserDailyData *)dailyDataOfDate:(NSDate *)date;
- (NSArray *)dailyDataOfMonth:(NSDate *)date;
- (NSArray *)dailyDataWithLogOfMonth:(NSDate *)date;
- (NSArray *)dailyDataDateLabelsWithSexOfMonth:(NSDate *)date;
- (NSArray *)dailyDataDateLabelsWithLogOfMonth:(NSDate *)date;
- (NSArray *)dailyDataDateLabelsWithMedsOfMonth:(NSDate *)date;
- (UserDailyData *)tsetDailyData:(NSDate *)date;
- (void)archivePeriodDailyData;

@end
