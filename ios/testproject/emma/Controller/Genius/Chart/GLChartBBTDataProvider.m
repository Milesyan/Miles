//
//  GLChartWeightDataProvider.m
//  kaylee
//
//  Created by Allen Hsu on 12/8/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLChartBBTDataProvider.h"
#import "User.h"
#import "Nutrition.h"
#import "UserDailyData.h"
#import "UserDailyData+CervicalPosition.h"
#import "DailyLogCellTypeMucus.h"

@interface GLChartBBTDataProvider ()
@property (copy, nonatomic) NSArray *temperatures;
@property (nonatomic, strong) NSSet* sexes;
@end

@implementation GLChartBBTDataProvider

- (NSString *)unitOfLineChart:(GLLineChartView *)lineChart
{
    BOOL isCelsius = [[Utils getDefaultsForKey:kUnitForTemp] isEqualToString:
                      UNIT_CELCIUS];
    if (isCelsius) {
        return @"°C";
    } else {
        return @"°F";
    }
}

- (NSInteger)numberOfLinesInLineChart:(GLLineChartView *)lineChart
{
    return 1;
}

- (NSArray *)lineChart:(GLLineChartView *)lineChart dotsForLineIndex:(NSInteger)lineIndex inRange:(GLLineChartRange)range
{
    return self.temperatures;
}

- (NSArray *)lineChart:(GLLineChartView *)lineChart infoKeysForDateIndex:(NSInteger)dateIndex
{
    if ([User currentUser].isSecondaryOrSingleMale) {
        return @[@"BBT", @"OPK", @"HPT", @"Sex"];
    } else {
        return @[@"BBT", @"OPK", @"HPT", @"Sex", @"CM", @"CP"];
    }
}

- (NSDictionary *)lineChart:(GLLineChartView *)lineChart infoListForDateIndex:(NSInteger)dateIndex
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    User *user = [User userOwnsPeriodInfo];
    UserDailyData *daily = [UserDailyData getUserDailyData:[Utils dateIndexToDateLabelFrom20130101:(int)dateIndex] forUser:user];
    
    // bbt
    if (daily.temperature < 30) {
        info[@"BBT"] = @"--";
    }
    else {
        BOOL isCelsius = [[Utils getDefaultsForKey:kUnitForTemp] isEqualToString:
                     UNIT_CELCIUS];
        CGFloat val = daily.temperature;
        if (!isCelsius) val = [Utils fahrenheitFromCelcius:val];
        info[@"BBT"] = catstr([Utils stringWithFloatOfTwoToZeroDecimal:
                         @"%f" float:val], (isCelsius ? @"°C" : @"°F"), nil);
    }
    
    // opk
    if (daily.ovulationTest % 10 == 0) {
         info[@"OPK"]  = @"--";
    }
    else {
        info[@"OPK"] = daily.ovulationTest % 10 == 3
        ? @"High" : (daily.ovulationTest % 10 == 1 ? @"Pos" : @"Neg");
    }

    // hpt
    if (daily.pregnancyTest % 10 == 0) {
        info[@"HPT"] = @"--";
    }
    else {
         info[@"HPT"] = daily.pregnancyTest % 10 == 1 ? @"Pos" : @"Neg";
    }

    // sex
    if (daily.intercourse == 0) {
        info[@"Sex"] = @"--";
    }
    else {
        info[@"Sex"] = daily.intercourse >= 2 ? @"Yes" : @"No";
    }

    // cm
    if (daily.cervicalMucus <= 1) {
        info[@"CM"] = @"--";
    }
    else {
        NSInteger tex = daily.cervicalMucus & 0xff;
        NSInteger amt = (daily.cervicalMucus >> 8) & 0xff;
        info[@"CM"] = catstr(capstr(amountVal2Name(amt)), @", ",
                        capstr(textureVal2Name(tex)), nil);
    }

    // cp
    if (daily.cervical == 0) {
        info[@"CP"]= @"--";
    }
    else {
        NSDictionary *status = [daily getCervicalPositionStatus];
        info[@"CP"] = [UserDailyData statusDescriptionForCervicalStatus:status seperateBy:@" & "];
    }
    return [info copy];
}

- (void)reloadData
{
    self.chartViewController.demoMode = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *temperatures = [NSMutableArray array];
        NSMutableSet *sexes = [NSMutableSet set];
        NSNumber *minTemperature = nil;
        NSNumber *maxTemperature = nil;
        NSNumber *minDateIndex = nil;
        NSNumber *maxDateIndex = nil;
        GLLineChartDot *todayDot = nil;
        
        int todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
        NSString *end = [Utils dateIndexToDateLabelFrom20130101:todayIndex];
        NSString *start = [Utils dateLabelAfterDateLabel:end withDays:-365];
        User *user = [User userOwnsPeriodInfo];
        
        BOOL isCelsius = [[Utils getDefaultsForKey:kUnitForTemp] isEqualToString:
                          UNIT_CELCIUS];

        NSArray *userDailyData = [UserDailyData getUserDailyDataFrom:start to:end ForUser:user];
        for (UserDailyData *d in userDailyData) {
            int date = [Utils dateLabelToIntFrom20130101:d.date];
            
            if (d.intercourse >=2) {
                [sexes addObject:d.date];
            }

            if (!minDateIndex || date < [minDateIndex integerValue]) {
                minDateIndex = @(date);
            }
            if (!maxDateIndex || date > [maxDateIndex integerValue]) {
                maxDateIndex = @(date);
            }
            
            float temperature = d.temperature;
            if (temperature < 30) {
                continue;
            }
            if (!isCelsius) {
                temperature = [Utils fahrenheitFromCelcius:temperature];
            }
            GLLineChartDot *dot = [[GLLineChartDot alloc] init];
            dot.dateIndex = date;
            dot.value = temperature;
            [temperatures addObject:dot];
            if (date == todayIndex && !todayDot) {
                todayDot = dot;
            }
            
            if (!minTemperature || temperature < [minTemperature floatValue]) {
                minTemperature = @(temperature);
            }
            if (!maxTemperature || temperature > [maxTemperature floatValue]) {
                maxTemperature= @(temperature);
            }
            
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (temperatures.count == 0) {

                self.temperatures = temperatures;
                self.todayString = @"**Today: **--";
                
                self.minDateIndex = minDateIndex;
                self.latestDateIndex = maxDateIndex;
                self.maxDateIndex = @(todayIndex);
                self.sexes = sexes;

            } else {
                self.chartViewController.demoMode = NO;
                self.temperatures = temperatures;
                self.sexes = sexes;
                self.minDateIndex = minDateIndex;
                self.latestDateIndex = maxDateIndex;
                self.maxDateIndex = @(todayIndex);
                
                self.todayDot = todayDot;
                if (todayDot) {
                    self.todayString = [NSString stringWithFormat:@"**Today: **%@ %@",
                                        [Utils stringWithFloatOfOneOrZeroDecimal:@"%f" float:todayDot.value],
                                        isCelsius ? @"°C" : @"°F"];
                } else {
                    self.todayString = @"**Today: **--";
                }
                
                if (minTemperature && maxTemperature) {
                    CGFloat min = [minTemperature floatValue];
                    CGFloat max = [maxTemperature floatValue];
                    
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
    self.temperatures = demoWeights;
    self.todayDot = nil;
    self.todayString = @"**Today: **--";
}

- (NSString *)placeholderStringOfLineChart:(GLLineChartView *)lineChart
{
    return @"In order to see your weight trends, \nbegin entering weight data in your daily log!";
}

- (NSString *)placeholderButtonTitleOfLineChart:(GLLineChartView *)lineChart
{
    return @"Take me to my daily logs";
}

- (NSString *)targetEventOfLineChart:(GLLineChartView *)lineChart
{
    return nil;
}

- (UIColor *)lineChart:(GLLineChartView *)lineChart lineColorForLineIndex:(NSInteger)lineIndex
{
    return [UIColor redColor];
}

- (UIColor *)lineChart:(GLLineChartView *)lineChart dotColorForLineIndex:(NSInteger)lineIndex
{
    return [UIColor redColor];
}

- (NSSet *)symbolsOfLineChart:(GLLineChartView *)lineChart
{
    return self.sexes;
}

- (BOOL)needsShowPeriodBg
{
    return YES;
}

- (BOOL)needsShowCycleDay
{
    return YES;
}

@end
