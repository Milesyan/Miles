//
//  Activity.m
//  emma
//
//  Created by Jirong Wang on 11/29/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "Activity.h"
#import "ActivityLevel.h"
#import "User.h"
#import "UserDailyData.h"
#import "GlowFirst.h"
#import "Interpreter.h"
#import "JsInterpreter.h"
#import "DailyTodo.h"

@implementation Activity


+ (NSDictionary *)calActivityFor:(User *)user from:(NSString *)startDateLabel to:(NSString *)endDateLabel {
    if (!user.onboarded) {
        return nil;
    }
    if (!user.tutorialCompleted) {
        return nil;
    }
    
    NSArray *dailyData;
    NSArray *dailyTodos;
    @try {
        dailyData = [UserDailyData userDailyDataToDict:[UserDailyData getUserDailyDataFrom:startDateLabel to:endDateLabel ForUser:user]];
        dailyTodos = [self dailyTodoDictArrayFromDate:startDateLabel toDate:endDateLabel forUser:user];
    }
    @catch (NSException *exception) {
        dailyData = @[];
        dailyTodos = @[];
    }
    NSDictionary *activityScore = [RULES_INTERPRETER calculateActivityScoreFrom:startDateLabel to:endDateLabel withPrediction:user.prediction withDailyData:dailyData withDailyTodos:dailyTodos];
    
    return activityScore;
}

+ (NSArray *)dailyTodoDictArrayFromDate:(NSString *)startDate toDate:(NSString *)endDate forUser:(User *)user
{
    NSArray *dailyTodos = [DailyTodo todosFromDate:startDate toDate:endDate forUser:user];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (DailyTodo *todo in dailyTodos) {
        NSMutableDictionary *data = dict[todo.date];
        if (!data) {
            data = [NSMutableDictionary dictionary];
            data[@"date"] = todo.date;
            data[@"serialized_todos"] = [NSMutableArray array];
            data[@"serialized_dones"] = [NSMutableArray array];
            dict[todo.date] = data;
        }
        [data[@"serialized_todos"] addObject:@(todo.todoId)];
        if (todo.checked) {
            [data[@"serialized_dones"] addObject:@(todo.todoId)];
        }
    }
    NSArray* result = [dict allValues];
    for (NSMutableDictionary *data in result) {
        if ([data[@"serialized_todos"] count] == 0) {
            data[@"serialized_todos"] = @"[]";
        }
        else if ([data[@"serialized_todos"] count] > 0) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data[@"serialized_todos"] options:0 error:nil];
            data[@"serialized_todos"] = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        if ([data[@"serialized_dones"] count] == 0) {
            data[@"serialized_dones"] = @"[]";
        }
        else if ([data[@"serialized_dones"] count] > 0) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data[@"serialized_dones"] options:0 error:nil];
            data[@"serialized_dones"] = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    return result;
}


+ (void)calActivityForCurrentMonth:(User *)user {
//    if (!user.onboarded) {
//        return;
//    }
    if (!user.tutorialCompleted) {
        return;
    }
    NSDate *currentTime = [NSDate date];
    NSInteger y = [currentTime getYear];
    NSInteger m = [currentTime getMonth];
    NSString * startDateLabel = date2Label([Utils dateOfYear:y month:m day:1]);
    NSString * endDateLabel = date2Label(currentTime);
    
    NSArray *dailyData;
    NSArray *dailyTodos;
    
    @try {
        dailyData = [UserDailyData userDailyDataToDict:[UserDailyData getUserDailyDataFrom:startDateLabel to:endDateLabel ForUser:user]];
        dailyTodos = [self dailyTodoDictArrayFromDate:startDateLabel toDate:endDateLabel forUser:user];
    }
    @catch (NSException *exception) {
        dailyData = @[];
        dailyTodos = @[];
    }
    
    NSDictionary *activityScore = [RULES_INTERPRETER calculateActivityScoreFrom:startDateLabel to:endDateLabel withPrediction:user.prediction withDailyData:dailyData withDailyTodos:dailyTodos];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userActivity = @{
                                   @"score": [activityScore objectForKey:@"score"],
                                   @"level": [activityScore objectForKey:@"level"]
                                   };
    [defaults setObject:userActivity forKey:@"userActivity"];
    [defaults synchronize];
    
    user.activityDirty = NO;
    [user publish:EVENT_ACTIVITY_UPDATED];
    return;
}

+ (NSArray *)getGlowFirstActivityHistory:(User *)user {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *summary = [defaults objectForKey:@"userFundSummary"];
    NSDate *startMonth = nil;
    NSArray *history = nil;
    
    if (summary) {
        // give real data
        NSInteger m = [[summary objectForKey:@"start_month"] integerValue];
        NSInteger y = [[summary objectForKey:@"start_year"] integerValue];
        startMonth = [Utils dateOfYear:y month:m day:1];
        history = [summary objectForKey:@"history"];
    } else {
        // give empty data
    }
    
    /*
     *  Our server timezone is UTC
     *  The server calculate user's last month activity on 1st day of new month
     *
     *  Timezone issue - A:
     *  For user with GMT-7 (example):
     *    1. server has already set the last month's activity (user's current month)
     *    2. user will see two same months in "current" and first "previous" month
     *
     *  Timezone issue - B:
     *  For user with GMT+8:
     *    1. user has already enter a new month, but server doesn't
     *    2. user will see current month is in Oct, but first previous month is Aug.
     */
    NSDate *currentTime = [NSDate date];
    NSMutableArray *previousActive = [NSMutableArray array];
    if ((history) && (startMonth)) {
        NSDate *month = startMonth;
        for (NSInteger i=0; i < history.count; i++) {
            // fix "Timezone issue - A"
            if ([Utils date:month isSameMonthAsDate:currentTime]) {
                break;
            }
            //get real historical data
            ActivityLevel *a = [[ActivityLevel alloc] init];
            [a setMonth:month];
            a.activeScore = [[[history objectAtIndex:i] objectForKey:@"active_score"] floatValue];
            a.activeLevel = [[[history objectAtIndex:i] objectForKey:@"active_level"] intValue];
            [previousActive addObject:a];
            month = [Utils dateByAddingMonths:1 toDate:month];
        }
        // fix "Timezone issue - B"
        if (![Utils date:month isSameMonthAsDate:currentTime]) {
            NSDate * lastDate = [Utils monthLastDate:month];
            NSString * start = date2Label(month);
            NSString * end = date2Label(lastDate);
            
            NSDictionary * userActivity = [Activity calActivityFor:user from:start to:end];
            ActivityLevel *active = [[ActivityLevel alloc] init];
            [active setMonth:month];
            if (userActivity) {
                active.activeScore = [[userActivity objectForKey:@"score"] floatValue];
                active.activeLevel = [[userActivity objectForKey:@"level"] intValue];
            } else {
                active.activeScore = 0.0;
                active.activeLevel = ACTIVITY_INACTIVE;
            }
            [previousActive addObject:active];
        }
        return [[previousActive reverseObjectEnumerator] allObjects];
    }
    return previousActive;
}

+ (ActivityLevel *)getActivityFor:(User *)user year:(NSInteger)year month:(NSInteger)month {
    return [Activity getActivityFor:user year:year month:month calculate:NO];
}

+ (ActivityLevel *)getActivityFor:(User *)user year:(NSInteger)year month:(NSInteger)month calculate:(BOOL)calculate {
    NSDate * monthDate = [Utils dateOfYear:year month:month day:1];
    // check if current month
    NSDate * now = [NSDate date];
    if ([Utils date:monthDate isSameMonthAsDate:now]) {
        return [Activity getActivityForCurrentMonth:user];
    }
    
    if (calculate == NO) {
        // check if user is under a fund, so that we could use the fund summary
        if ((user.ovationStatus == OVATION_STATUS_UNDER_FUND) || (user.ovationStatus == OVATION_STATUS_UNDER_FUND_DELAY))  {
            NSArray * previousActive = [Activity getGlowFirstActivityHistory:user];
            if ((previousActive) && (previousActive.count > 0)) {
                // see if the month in under the array
                for (ActivityLevel *a in previousActive) {
                    NSDate * d = [a getMonth];
                    if ([Utils date:monthDate isSameMonthAsDate:d]) {
                        return [Activity getActivityForCurrentMonth:user];
                    }
                }
            }
        }
    }
    
    // now, we have to calculate the activity
    NSDate * lastDate = [Utils monthLastDate:monthDate];
    NSString * start = date2Label(monthDate);
    NSString * end = date2Label(lastDate);
    NSDictionary * userActivity = [Activity calActivityFor:user from:start to:end];
    ActivityLevel *active = [[ActivityLevel alloc] init];
    [active setMonth:monthDate];
    if (userActivity) {
        active.activeScore = [[userActivity objectForKey:@"score"] floatValue];
        active.activeLevel = [[userActivity objectForKey:@"level"] intValue];
    } else {
        active.activeScore = 0.0;
        active.activeLevel = ACTIVITY_INACTIVE;
    }
    return active;
}

+ (ActivityLevel *)getActivityForCurrentMonth:(User *)user {
    if (user.activityDirty) {
        [Activity calActivityForCurrentMonth:user];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userActivity = [defaults objectForKey:@"userActivity"];
    
    NSDate *currentTime = [NSDate date];
    ActivityLevel *current = [[ActivityLevel alloc] init];
    [current setMonth:currentTime];
    if (userActivity) {
        current.activeScore = [[userActivity objectForKey:@"score"] floatValue];
        current.activeLevel = [[userActivity objectForKey:@"level"] intValue];
    } else {
        current.activeScore = 0.0;
        current.activeLevel = ACTIVITY_INACTIVE;
    }
    return current;
}

+ (void)calDemoActivityHistory:(User *)user {
    /*
     * We don't store the activity level in server side, so calculate up to 3 months
     * This may take a long time, so use event
     */
    NSMutableArray *previousActive = [NSMutableArray array];
    NSDate * date = [NSDate date];
    
    for (NSInteger i=0; i<3; i++) {
        date = [Utils dateByAddingMonths:-1 toDate:date];
        NSInteger y = [date getYear];
        NSInteger m = [date getMonth];
        ActivityLevel * a = [Activity getActivityFor:user year:y month:m calculate:YES];
        if (a.activeScore == 0.0) break;
        [previousActive addObject:a];
    }
    [user publish:EVENT_ACTIVITY_GF_DEMO_UPDATED data:previousActive];
    return;
}

@end
