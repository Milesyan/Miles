//
//  CyclesSummarizer.m
//  emma
//
//  Created by Xin Zhao on 5/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "User.h"
#import "CyclesSummarizer.h"

@implementation CyclesSummarizer



+ (NSString *)summaryOfNextPb {
    NSArray *prediction = [User userOwnsPeriodInfo].prediction;
    if (!prediction) {
        return nil;
    }
    
    NSInteger todayIndex = [[NSDate date] toDateIndex];
    for (NSDictionary *p in prediction) {
        NSInteger pbIndex = [Utils dateLabelToIntFrom20130101:p[@"pb"]];
        if (pbIndex > todayIndex) {
            NSDate *nextPb = [Utils dateWithDateLabel:p[@"pb"]];
            return [Utils formatedWithFormat:@"EEE, MMM d" date:nextPb];
        }
    }
    return nil;
}

+ (NSArray *)summaryOfStages {
    NSArray *prediction = [User userOwnsPeriodInfo].prediction;
    if (!prediction) {
        return @[@0, @0, @0, @0];
    }

    NSInteger cycleDaysSum = 0, periodDaysSum = 0,
        lutealPhaseSum = 0, cycleDaysCount = 0, periodDaysCount = 0,
        lutealPhaseCount = 0, i = 0;
    NSInteger todayIndex = [[NSDate date] toDateIndex];
    for (i = 0; i < [prediction count]; i++) {
        NSDictionary* p = prediction[i];
        NSInteger pbIndex = [Utils dateLabelToIntFrom20130101:p[@"pb"]];
        if (pbIndex > todayIndex) {
            break;
        }
        int cl = [p[@"cl"] intValue], pl = [p[@"pl"] intValue] + 1,
            ol = [p[@"ol"] intValue];
        if (cl > 0) {
            cycleDaysSum += cl;
            cycleDaysCount++;
        }
        if (cl > 0) {
            periodDaysSum += pl;
            periodDaysCount++;
        }
        if (ol > 0) {
            lutealPhaseSum += ol;
            lutealPhaseCount++;
        }
    }
    NSInteger avgCl = cycleDaysCount > 0 ? round((float)cycleDaysSum / cycleDaysCount)
        : 0;
    NSInteger avgPl = periodDaysCount > 0 ?
        round((float)periodDaysSum / periodDaysCount) : 0;
    NSInteger avgLuteal = lutealPhaseCount > 0
        ? round((float)lutealPhaseSum / lutealPhaseCount) : 0;
    NSInteger avgFollicular = avgCl - avgLuteal;
    return @[@(avgCl), @(avgPl), @(avgFollicular), @(avgLuteal)];
}

+ (NSArray *)summaryOfPastCycles {
    NSArray *prediction = [User userOwnsPeriodInfo].prediction;
    if (!prediction) {
        return nil;
    }
    
    NSInteger todayIndex = [[NSDate date] toDateIndex];
    NSMutableArray *result = [@[] mutableCopy];
    for (NSDictionary* p in prediction) {
        NSInteger pbIndex = [Utils dateLabelToIntFrom20130101:p[@"pb"]];
        if (pbIndex > todayIndex) {
            break;
        }
        NSDate *pb = [Utils dateWithDateLabel:p[@"pb"]];
        NSDate *pe = [Utils dateWithDateLabel:p[@"pe"]];
        NSString *periodDates = @"--";
        if ([pb getMonth] != [pe getMonth]) {
            periodDates = [Utils catstr:
                [Utils formatedWithFormat:@"MMM d" date:pb], @" - ",
                [Utils formatedWithFormat:@"MMM d" date:pe], nil];
        }
        else {
            periodDates = [Utils catstr:
                [Utils formatedWithFormat:@"MMM d" date:pb],
                @" - ",
                [@([pe getDay]) stringValue], nil];
        }
        int pl = [p[@"pl"] intValue] + 1;
        [result addObject:@[periodDates, @(pl), p[@"cl"]]];
    }
    return result;
}

@end
