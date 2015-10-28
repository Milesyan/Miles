//
//  GLChartWeightDataProvider.m
//  kaylee
//
//  Created by Allen Hsu on 12/8/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLChartWeightDataProvider.h"
#import "User.h"
#import "Nutrition.h"
#import "UserDailyData.h"
#import "UserDailyData+Symptom.h"

@interface GLChartWeightDataProvider ()
@property (copy, nonatomic) NSArray *weights;
@property (nonatomic, strong) NSSet* sexes;
@end

@implementation GLChartWeightDataProvider


- (NSString *)unitOfLineChart:(GLLineChartView *)lineChart
{
    NSString *unit = [Utils getDefaultsForKey:kUnitForWeight];
    if ([unit isEqualToString:UNIT_KG]) {
        return @"KG";
    } else {
        return @"LB";
    }
}

- (NSInteger)numberOfLinesInLineChart:(GLLineChartView *)lineChart
{
    return 1;
}

- (NSArray *)lineChart:(GLLineChartView *)lineChart dotsForLineIndex:(NSInteger)lineIndex inRange:(GLLineChartRange)range
{
    return self.weights;
}

- (NSArray *)lineChart:(GLLineChartView *)lineChart infoKeysForDateIndex:(NSInteger)dateIndex
{
    return @[@"Weight", @"Exercise", @"BMI", @"Sex", @"Physical", @"Emotional"];
}

- (NSDictionary *)lineChart:(GLLineChartView *)lineChart infoListForDateIndex:(NSInteger)dateIndex
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    BOOL useMetricUnit = [[Utils getDefaultsForKey:kUnitForWeight] isEqualToString:UNIT_KG];
    
    UserDailyData *daily = [UserDailyData getUserDailyData:[Utils dateIndexToDateLabelFrom20130101:(int)dateIndex] forUser:[User currentUser]];
    
    // weight
    if (daily.weight <= 10) {
        info[@"Weight"] = @"--";
    } else {
        CGFloat val = daily.weight;
        if (!useMetricUnit) val = [Utils poundsFromKg:val];
        info[@"Weight"] = catstr([Utils stringWithFloatOfOneOrZeroDecimal:
                         @"%f" float:val], (useMetricUnit ? @"KG" : @"LB"), nil);
    }
    
    // excercise
    if (daily.exercise == 0) {
         info[@"Exercise"] = @"--";
    }
    else {
        if (daily.exercise & 4) {
            info[@"Exercise"] = @"15-30 mins";
        } else if (daily.exercise & 8) {
            info[@"Exercise"] = @"30-60 mins";
        } else if (daily.exercise & 16) {
            info[@"Exercise"] = @"60+ mins";
        }
    }
    
    // bmi
    CGFloat userHeight = [User currentUser].settings.height;
    if (daily.weight <= 10 || userHeight <= 10) {
        info[@"BMI"] = @"--";
    }
    else {
        info[@"BMI"] = [Utils stringWithFloatOfOneOrZeroDecimal:@"%f" float:
                  [Utils calculateBmiWithHeightInCm:userHeight weightInKg:
                   daily.weight]];
    }

    // intercource
    if (daily.intercourse == 0) {
        info[@"Sex"] = @"--";
    }
    else {
        info[@"Sex"] = daily.intercourse >= 2 ? @"Yes" : @"No";
    }
    
    // physical
    NSDictionary *physicalSymptoms = [daily getPhysicalSymptoms];
    if (physicalSymptoms.count == 0) {
        info[@"Physical"] = @"--";
    }
    else {
        NSNumber *symp = [physicalSymptoms.allKeys firstObject];
        NSMutableDictionary *physicalMapping = [PhysicalSymptomNames mutableCopy];
        [physicalMapping addEntriesFromDictionary:PhysicalSymptomNamesForMale];
        info[@"Physical"] = [physicalMapping objectForKey:symp];
    }
    
    if (physicalSymptoms.count > 1) {
        info[@"Physical"] = catstr(info[@"Physical"], @" ...", nil);
    }

    // emotional
    NSDictionary *emotionalSymptoms = [daily getEmotionalSymptoms];
    if (emotionalSymptoms.count == 0) {
        info[@"Emotional"] = @"--";
    }
    else {
        NSNumber *symp = [emotionalSymptoms.allKeys firstObject];
        info[@"Emotional"] = [EmotionalSymptomNames objectForKey:symp];
    }
    
    if (emotionalSymptoms.count > 1) {
        info[@"Emotional"] = catstr(info[@"Emotional"], @" ...", nil);
    }

    return [info copy];
}

- (void)reloadData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *weights = [NSMutableArray array];
        NSMutableSet *sexes = [NSMutableSet set];
        NSNumber *minWeight = nil;
        NSNumber *maxWeight = nil;
        NSNumber *minDateIndex = nil;
        NSNumber *maxDateIndex = nil;
        GLLineChartDot *todayDot = nil;
        
        int todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
        NSString *end = [Utils dateIndexToDateLabelFrom20130101:todayIndex];
        NSString *start = [Utils dateLabelAfterDateLabel:end withDays:-365];
        User *user = [User currentUser];
        
        BOOL useMetricUnit = [[Utils getDefaultsForKey:kUnitForWeight] isEqualToString:UNIT_KG];
        NSArray *userDailyData = [UserDailyData getUserDailyDataFrom:start to:end ForUser:user];
        for (UserDailyData *d in userDailyData) {
            int date = [Utils dateLabelToIntFrom20130101:d.date];
            
            if (d.intercourse >= 2) {
                [sexes addObject:d.date];
            }
            
            float weight = d.weight;
            if (weight < 10) {
                continue;
            }
            if (!useMetricUnit) {
                weight = [Utils precisePoundsFromKg:weight];
            }
            GLLineChartDot *dot = [[GLLineChartDot alloc] init];
            dot.dateIndex = date;
            dot.value = weight;
            [weights addObject:dot];
            if (date == todayIndex && !todayDot) {
                todayDot = dot;
            }
            
            if (!minWeight || weight < [minWeight floatValue]) {
                minWeight = @(weight);
            }
            if (!maxWeight || weight > [maxWeight floatValue]) {
                maxWeight = @(weight);
            }
            if (!minDateIndex || date < [minDateIndex integerValue]) {
                minDateIndex = @(date);
            }
            if (!maxDateIndex || date > [maxDateIndex integerValue]) {
                maxDateIndex = @(date);
            }

        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weights.count == 0) {
                self.chartViewController.demoMode = YES;
                [self setupDemoData];
            } else {
                self.chartViewController.demoMode = NO;
                self.weights = weights;
                self.sexes = sexes;
                
                self.minDateIndex = minDateIndex;
                self.latestDateIndex = maxDateIndex;
                self.maxDateIndex = @(todayIndex);
                
                self.todayDot = todayDot;
                if (todayDot) {
                    self.todayString = [NSString stringWithFormat:@"**Today: **%@ %@",
                                        [Utils stringWithFloatOfOneOrZeroDecimal:@"%f" float:todayDot.value],
                                        useMetricUnit ? @"KG" : @"LB"];
                } else {
                    self.todayString = @"**Today: **--";
                }
                
                if (minWeight && maxWeight) {
                    CGFloat min = [minWeight floatValue];
                    CGFloat max = [maxWeight floatValue];
                    
                    CGFloat mid = roundf((min + max) / 2.f / 10.f) * 10.f;
                    CGFloat interval = 1.f;
                    for (int i = 0; i <= 6; i++) {
                        interval = i <= 1 ? (i + 1) : 5 * (i - 1);
                        if (mid - 5.f * interval <= min && mid + 5.f * interval >= max) {
                            break;
                        }
                    }
                    
                    self.minValue = @(mid - 5 * interval);
                    self.maxValue = @(mid + 5 * interval);
                }
            }
            [self.chartViewController reloadChartView];
        });
    });
}

- (void)setupDemoData
{
    static NSMutableArray *demoWeights = nil;
    
    int todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    int minDateIndex = todayIndex - 15.0;
    int maxDateIndex = todayIndex;
    
    BOOL useMetricUnit = [[Utils getDefaultsForKey:kUnitForWeight] isEqualToString:UNIT_KG];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        demoWeights = [NSMutableArray array];
        
        float weight = 72.0;
        for (int i = minDateIndex; i <= maxDateIndex; i += 3) {
            weight += (arc4random() % 10 / 10.0);
            GLLineChartDot *dot = [[GLLineChartDot alloc] init];
            dot.dateIndex = i;
            if (useMetricUnit) {
                dot.value = weight;
            } else {
                dot.value = [Utils precisePoundsFromKg:weight];
            }
            [demoWeights addObject:dot];
        }
    });
    
    if (useMetricUnit) {
        self.minValue = @(70.0);
        self.maxValue = @(80.0);
    } else {
        self.minValue = @(160.0);
        self.maxValue = @(180.0);
    }
    
    self.minDateIndex = @(minDateIndex);
    self.latestDateIndex = @(maxDateIndex);
    self.maxDateIndex = @(todayIndex);
    self.weights = demoWeights;
    self.todayDot = nil;
    self.todayString = @"**Today: **--";
}

- (NSSet *)symbolsOfLineChart:(GLLineChartView *)lineChart
{
    return self.sexes;
}

- (NSString *)placeholderStringOfLineChart:(GLLineChartView *)lineChart
{
    return @"In order to see your weight trends, \nbegin entering weight data in your daily log!";
}

- (NSString *)placeholderButtonTitleOfLineChart:(GLLineChartView *)lineChart
{
    return @"Enter my weight now";
}


- (NSString *)targetEventOfLineChart:(GLLineChartView *)lineChart
{
    return EVENT_GO_DAILYLOG_WEIGHT;
}

- (BOOL)needsShowPeriodBg
{
    return [[User currentUser].id isEqualToNumber: [User userOwnsPeriodInfo].id];
}

- (BOOL)needsShowCycleDay
{
    return [[User currentUser].id isEqualToNumber: [User userOwnsPeriodInfo].id];
}

@end
