//
//  Period.m
//  emma
//
//  Created by ltebean on 15/8/20.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "Period.h"
#import "UserDailyData.h"

@implementation Period
@dynamic pb;
@dynamic pe;
@dynamic flag;
@dynamic user;

- (NSDictionary *)attrMapper
{
    return @{
        @"pb": @"pb",
        @"pe": @"pe",
        @"flag": @"flag"
    };
}

+ (NSArray *)allPeriodsForUser:(User *)user
{
    return [user.periods sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"pb" ascending:NO]]];
}

+ (Period *)periodWithBeginDate:(NSString *)beginDate endDate:(NSString *)endDate forUser:(User *)user
{
    NSArray *periods = [self allPeriodsForUser:user];
    for (Period *period in periods) {
        if ([period.pb isEqualToString:beginDate] && [period.pe isEqualToString:endDate]) {
            return period;
        }
    }
    return nil;
}

+ (id)upsertWithDictionary:(NSDictionary *)data forUser:(User *)user;
{
    Period *period = [Period newInstance:user.dataStore];
    period.user = user;
    period.pb = data[@"pb"];
    period.pe = data[@"pe"];
    period.flag = [data[@"flag"] integerValue];
    return period;
}

+ (void)resetWithAlive:(NSArray *)alive archived:(NSArray *)archived forUser:(User *)user
{
    if (!alive && !archived) {
        return;
    }
    NSArray *periods = [self allPeriodsForUser:user];
    for (Period *period in periods) {
        [period remove];
    }
    NSArray *dailyDataWithPeriod = [UserDailyData getDailyDataWithPeriodIncludingHistoryForUser:user];
    for (UserDailyData *data in dailyDataWithPeriod) {
        if (archived) {
            data.period = 0;
        } else {
            if (data.period == LOG_VAL_PERIOD_BEGAN || data.period == LOG_VAL_PERIOD_ENDED) {
                data.period = 0;
            }
        }
    }
    for (NSDictionary *period in alive) {
        if (period[@"pe"] && ![period[@"pe"] isEqualToString:@""]) {
            [self upsertWithDictionary:period forUser:user];

            UserDailyData *pb = [UserDailyData tset:period[@"pb"] forUser:user];
            pb.period = LOG_VAL_PERIOD_BEGAN;

            UserDailyData *pe = [UserDailyData tset:period[@"pe"] forUser:user];
            pe.period = LOG_VAL_PERIOD_ENDED;
        }
        
    }
    for (NSDictionary *period in archived) {
        if (period[@"pe"] && ![period[@"pe"] isEqualToString:@""]) {
            UserDailyData *pb = [UserDailyData tset:period[@"pb"] forUser:user];
            pb.period = LOG_VAL_PERIOD_BEGAN << ARCHIVED_PERIOD_SHIFT;
            
            UserDailyData *pe = [UserDailyData tset:period[@"pe"] forUser:user];
            pe.period = LOG_VAL_PERIOD_ENDED << ARCHIVED_PERIOD_SHIFT;
        }
        
    }
    [self publish:EVENT_NEW_RULES_PULLED];
}

+ (void)persistAllPeriodsBeforeTodayWithLatestPeriod:(NSDictionary *)latestPeriod forUser:(User *)user
{
    NSArray *prediction = user.prediction;
    NSMutableArray *result = [NSMutableArray array];
    if (latestPeriod) {
        [result addObject:latestPeriod];
    }
    NSString *today = [[NSDate date] toDateLabel];
    for (NSDictionary *data in prediction) {
        NSString *pb = data[@"pb"];
        NSString *pe = data[@"pe"];
        // ignore future periods
        if ([pb compare:today] >= NSOrderedSame) {
            continue;
        }
        if (latestPeriod) {
            NSString *latestPb = latestPeriod[@"pb"];
            NSString *latestPe = latestPeriod[@"pe"];
            // ignore the one conflicts with the newly added period
            if ([pb compare:latestPb] <= NSOrderedSame && [pe compare:latestPb] >= NSOrderedSame) {
                continue;
            }
            if ([pb compare:latestPe] <= NSOrderedSame && [pe compare:latestPe] >= NSOrderedSame) {
                continue;
            }
            if ([latestPb compare:pb] <= NSOrderedSame && [latestPe compare:pb] >= NSOrderedSame) {
                continue;
            }
            if ([latestPb compare:pe] <= NSOrderedSame && [latestPe compare:pe] >= NSOrderedSame) {
                continue;
            }
        }
        NSString *oneDayAfterPe = [Utils dateLabelAfterDateLabel:pe withDays:1];
        Period *period = [self periodWithBeginDate:pb endDate:oneDayAfterPe forUser:user];
        [result addObject:@{
            @"pb": pb,
            @"pe": oneDayAfterPe,
            @"flag": @(period ? period.flag : FLAG_SOURCE_PREDICTION)
        }];
    }
    [self resetWithAlive:result archived:nil forUser:user];
}

- (void)remove
{
    [self.managedObjectContext deleteObject:self];
    [self save];
}

- (void)setAddedByUser
{
    self.flag = 1 << FLAG_ADDED_BIT | FLAG_SOURCE_USER_INPUT;
}

- (void)setModifiedByUser
{
    self.flag = 1 << FLAG_MODIFIED_BIT | self.flag;
}

- (void)setAddedByDeletion
{
    self.flag = 1 << FLAG_ADDED_BY_DELETION_BIT | self.flag;
}

- (void)setAddedByPrediction
{
    self.flag = FLAG_SOURCE_PREDICTION;
}

- (NSMutableDictionary *)createPushRequest
{
    NSMutableDictionary *request = [NSMutableDictionary dictionary];
    request[@"pb"] = self.pb;
    request[@"pe"] = self.pe;
    request[@"flag"] = @(self.flag);
    return request;
}

@end
