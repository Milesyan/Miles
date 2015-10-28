//
//  GLChartCaloriesDataProvider.m
//  kaylee
//
//  Created by Allen Hsu on 12/10/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLChartCaloriesDataProvider.h"
#import "Nutrition.h"
#import "User.h"
#import "UserDailyData.h"

@interface GLChartCaloriesDataProvider ()

@property (assign, nonatomic) BOOL needsReload;
@property (copy, nonatomic) NSArray *caloriesIn;
@property (copy, nonatomic) NSArray *caloriesOut;
@property (nonatomic, strong) NSSet* sexes;
@end

@implementation GLChartCaloriesDataProvider

- (instancetype)init
{
    self = [super init];
    self.needsReload = YES;
    return self;
}

- (NSString *)unitOfLineChart:(GLLineChartView *)lineChart
{
    return @"CAL";
}

- (NSInteger)numberOfLinesInLineChart:(GLLineChartView *)lineChart
{
    return 2;
}

- (NSArray *)lineChart:(GLLineChartView *)lineChart dotsForLineIndex:(NSInteger)lineIndex inRange:(GLLineChartRange)range
{
    switch (lineIndex) {
        case 0:
            return self.caloriesIn;
            break;
        case 1:
            return self.caloriesOut;
            break;
        default:
            break;
    }
    return nil;
}

- (NSArray *)lineChart:(GLLineChartView *)lineChart infoKeysForDateIndex:(NSInteger)dateIndex
{
    return @[@"Intakes", @"Burned", @"Weight", @"Exercise", @"BMI", @"Via"];
}

- (NSDictionary *)lineChart:(GLLineChartView *)lineChart infoListForDateIndex:(NSInteger)dateIndex
{
    User *user = [User currentUser];
    NSString *dateLabel = [Utils dateIndexToDateLabelFrom20130101:(int)dateIndex];
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];

    if (user.isConnectedWith3rdPartyHealthApps) {
        Nutrition *nutrition = [Nutrition nutritionForDate:dateLabel forUser:user];
        if (nutrition.calorieIn > 0) {
            info[@"Intakes"] = [NSString stringWithFormat:@"%.0f cal", nutrition.calorieIn];
        }
        if (nutrition.calorieOut > 0) {
            info[@"Burned"] = [NSString stringWithFormat:@"%.0f cal", nutrition.calorieOut];
        }
    }

    
    BOOL useMetricUnit = [[Utils getDefaultsForKey:kUnitForWeight] isEqualToString:UNIT_KG];
    
    UserDailyData *daily = [UserDailyData getUserDailyData:[Utils dateIndexToDateLabelFrom20130101:(int)dateIndex] forUser:user];
    
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
    

    return [info copy];
}

- (void)reloadData
{

    if (![User currentUser].isConnectedWith3rdPartyHealthApps) {
        [self setupDemoData];
        self.chartViewController.demoMode = YES;
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *caloriesIn = [NSMutableArray array];
        NSMutableArray *caloriesOut = [NSMutableArray array];
        NSMutableSet *sexes = [NSMutableSet set];
        NSNumber *minValue = nil;
        NSNumber *maxValue = nil;
        NSNumber *minDateIndex = nil;
        NSNumber *maxDateIndex = nil;
        GLLineChartDot *todayInDot = nil;
        GLLineChartDot *todayOutDot = nil;
        
        int todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
        NSString *end = [Utils dateIndexToDateLabelFrom20130101:todayIndex];
        NSString *start = [Utils dateLabelAfterDateLabel:end withDays:-365];
        User *user = [User currentUser];
        
        NSArray *userDailyData = [UserDailyData getUserDailyDataFrom:start to:end ForUser:user];
        for (UserDailyData *d in userDailyData) {
            if (d.intercourse >= 2) {
                [sexes addObject:d.date];
            }
        }
        
        NSArray *nutritions = [Nutrition nutritonsWithCalorieFromDate:start toDate:end forUser:user];
        for (Nutrition *d in nutritions) {
            int date = [Utils dateLabelToIntFrom20130101:d.date];

            if (d.calorieIn > 0) {
                float value = d.calorieIn;
                GLLineChartDot *dot = [[GLLineChartDot alloc] init];
                dot.dateIndex = date;
                dot.value = value;
                [caloriesIn addObject:dot];
                if (date == todayIndex) {
                    todayInDot = dot;
                }
                
                if (!minValue || value < [minValue floatValue]) {
                    minValue = @(value);
                }
                if (!maxValue || value > [maxValue floatValue]) {
                    maxValue = @(value);
                }
                if (!minDateIndex || date < [minDateIndex integerValue]) {
                    minDateIndex = @(date);
                }
                if (!maxDateIndex || date > [maxDateIndex integerValue]) {
                    maxDateIndex = @(date);
                }
            }
            if (d.calorieOut > 0) {
                float value = d.calorieOut;
                GLLineChartDot *dot = [[GLLineChartDot alloc] init];
                dot.dateIndex = date;
                dot.value = value;
                [caloriesOut addObject:dot];
                if (date == todayIndex) {
                    todayOutDot = dot;
                }
         
                if (!minValue || value < [minValue floatValue]) {
                    minValue = @(value);
                }
                if (!maxValue || value > [maxValue floatValue]) {
                    maxValue = @(value);
                }
                if (!minDateIndex || date < [minDateIndex integerValue]) {
                    minDateIndex = @(date);
                }
                if (!maxDateIndex || date > [maxDateIndex integerValue]) {
                    maxDateIndex = @(date);
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (caloriesIn.count + caloriesOut.count == 0) {
                self.chartViewController.demoMode = YES;
                [self setupDemoData];
            } else {
                self.chartViewController.demoMode = NO;
                self.caloriesIn = caloriesIn;
                self.caloriesOut= caloriesOut;
                self.sexes = sexes;

                self.minDateIndex = minDateIndex;
                self.latestDateIndex = maxDateIndex;
                self.maxDateIndex = @(todayIndex);
                
                self.todayDot = todayInDot ?: todayOutDot;
                NSString *inToday = todayInDot ? [NSString stringWithFormat:@"%.0f cal", todayInDot.value] : @"--";
                NSString *outToday = todayOutDot ? [NSString stringWithFormat:@"%.0f cal", todayOutDot.value] : @"--";
                self.todayString = [NSString stringWithFormat:@"**Intakes: **%@\n**Burned: **%@", inToday, outToday];
                
                if (minValue && maxValue) {
                    CGFloat min = [minValue floatValue];
                    CGFloat max = [maxValue floatValue];
                    
                    CGFloat mid = roundf((min + max) / 2.f / 10.f) * 10.f;
                    CGFloat interval = 1.f;
                    for (int i = 0; i <= 6; i++) {
                        interval = i <= 1 ? (i + 1) : 5 * (i - 1);
                        if (mid - 5.f * interval <= min && mid + 5.f * interval >= max) {
                            break;
                        }
                    }
                    
                    self.minValue = @(MAX(0, floor(minValue.integerValue / 100) * 100));
                    self.maxValue = @(floor(maxValue.integerValue / 100) * 100 + 100);
                }
            }
            [self.chartViewController reloadChartView];
        });
    });
}

- (void)setupDemoData
{
    int todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    int minDateIndex = todayIndex - 15.0;
    int maxDateIndex = todayIndex;
    
    static NSMutableArray *demoCaloriesIn = nil;
    static NSMutableArray *demoCaloriesOut = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        demoCaloriesIn = [NSMutableArray array];
        demoCaloriesOut = [NSMutableArray array];
        
        for (int i = minDateIndex; i <= maxDateIndex; i += 3) {
            float inVal = 2600 + arc4random() % 200;
            float outVal = 2000 + arc4random() % 200;
            GLLineChartDot *inDot = [[GLLineChartDot alloc] init];
            inDot.dateIndex = i;
            inDot.value = inVal;
            [demoCaloriesIn addObject:inDot];
            GLLineChartDot *outDot = [[GLLineChartDot alloc] init];
            outDot.dateIndex = i;
            outDot.value = outVal;
            [demoCaloriesOut addObject:outDot];
        }
    });
    
    self.minValue = @(2000);
    self.maxValue = @(3000);
    
    self.minDateIndex = @(minDateIndex);
    self.latestDateIndex = @(maxDateIndex);
    self.maxDateIndex = @(todayIndex);
    
    self.caloriesIn = demoCaloriesIn;;
    self.caloriesOut = demoCaloriesOut;
    
    self.todayDot = nil;
    self.todayString = [NSString stringWithFormat:@"**Intakes: **--\n**Burned: **--"];
}

- (NSString *)placeholderStringOfLineChart:(GLLineChartView *)lineChart
{
    return @"In order to see your calories chart,\n you must connect with your \n**MyFitnessPal**, **Fitbit**, **Jawbone UP**, \nor **Misfit** account in your Me page!";
}

- (NSString *)placeholderButtonTitleOfLineChart:(GLLineChartView *)lineChart
{
    return @"Connect now";
}

- (NSSet *)symbolsOfLineChart:(GLLineChartView *)lineChart
{
    return self.sexes;
}

- (NSString *)targetEventOfLineChart:(GLLineChartView *)lineChart
{
    return EVENT_GO_CONNECTING_3RD_PARTY;
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