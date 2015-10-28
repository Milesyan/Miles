//
//  User+DailyData.m
//  emma
//
//  Created by Allen Hsu on 12/26/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "User+DailyData.h"

@implementation User (DailyData)

- (UserDailyData *)dailyDataOfDate:(NSDate *)date {
    return [UserDailyData fetchObject:@{@"user.id":self.id, @"date":[Utils dailyDataDateLabel:date]} dataStore:self.dataStore];
}

- (NSArray *)dailyDataOfMonth:(NSDate *)date {
    NSString *month = [[[Utils dailyDataDateLabel:date] substringToIndex:8] stringByAppendingFormat:@"*"];
//    GLLog(@"month: [%@]", month);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date LIKE %@", month];
//    GLLog(@"predicate:%@", predicate);
    return [[self.dailyData filteredSetUsingPredicate:predicate] allObjects];
}

- (NSArray *)dailyDataWithLogOfMonth:(NSDate *)date {
    NSArray *arr = [self dailyDataOfMonth:date];
    NSMutableArray *newArr = [NSMutableArray array];
    for (UserDailyData *d in arr) {
        if (d.hasData) {
            [newArr addObject:d];
        }
    }
    return  newArr;
}

- (NSArray *)dailyDataDateLabelsWithSexOfMonth:(NSDate *)date {
    NSArray *arr = [self dailyDataOfMonth:date];
    NSMutableArray *newArr = [NSMutableArray array];
    for (UserDailyData *d in arr) {
        if (d.hasData && d.intercourse > 1) {
            [newArr addObject:d.date];
        }
    }
    return  newArr;
}

- (NSArray *)dailyDataDateLabelsWithLogOfMonth:(NSDate *)date {
    NSArray *arr = [self dailyDataOfMonth:date];
    NSMutableArray *newArr = [NSMutableArray array];
    for (UserDailyData *d in arr) {
        if (d.hasData) {
            [newArr addObject:d.date];
        }
    }
    return  newArr;
}

- (NSArray *)dailyDataDateLabelsWithMedsOfMonth:(NSDate *)date {
    NSArray *arr = [self dailyDataOfMonth:date];
    NSMutableArray *newArr = [NSMutableArray array];
    for (UserDailyData *d in arr) {
        if (d.meds) {
            NSDictionary *data = [NSJSONSerialization JSONObjectWithData:d.meds options:0 error:NULL];
            for (NSNumber *val in data.allValues) {
                if ([val integerValue] == 1) {
                    [newArr addObject:d.date];
                    break;
                }
            }
        }
    }
    return  newArr;
}


- (UserDailyData *)tsetDailyData:(NSDate *)date {
    return [UserDailyData tset:[Utils dailyDataDateLabel:date] forUser:self];
}


- (void)archivePeriodDailyData {
    NSArray *historicalPeriodDailyData = [UserDailyData
            getDailyDataWithPeriodIncludingHistoryForUser:self];
    for (UserDailyData *daily in historicalPeriodDailyData) {
        [daily updateArchivedPeriod];
    }
    [self.settings update:@"firstPb" value:@""];
    self.firstPb = nil;
    [self cleanPrediction];
}

@end
