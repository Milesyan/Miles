//
//  ChartData.m
//  emma
//
//  Created by Xin Zhao on 13-8-3.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "ChartData.h"
#import "ChartUtils.h"
#import "ChartConstants.h"
#import "UserDailyData.h"
#import "Nutrition.h"
#import "User+Fitbit.h"

@implementation ChartData {
    BOOL dataBuilt;
    NSDictionary *rawNutritionPoints;
    dispatch_queue_t _calculationThread;
    NSNumber *minWeight;
    NSNumber *maxWeight;
    ChartPoints *bbts;
    ChartPoints *sexes;
    ChartPoints *weights;
    ChartPoints *calorieIns;
    ChartPoints *calorieOuts;
}




+ (ChartData*)getInstance {
    return [[ChartData alloc] init];

}

+ (User*)getThreadSafeUser
{
    __block User *user = nil;
    if ([NSThread isMainThread]) {
        user = [User currentUser];
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            user = (User*)[[User currentUser] makeThreadSafeCopy];
        });
    }
    return user;
}

#pragma mark - public interface
- (void)clearAll {
    dataBuilt = NO;
    
    rawNutritionPoints = nil;
    
    minWeight = nil;
    maxWeight = nil;
    
    bbts = sexes = weights = calorieIns = calorieOuts = nil;
}

- (void)buildAllForUser:(User *)user {
    if (dataBuilt) return;
    
    dataBuilt = YES;
    NSString *start = [Utils dateIndexToDateLabelFrom20130101:[self getDateIdxOffset]];
    NSString *end = [Utils dateLabelAfterDateLabel:start withDays:366];
    [self convertUserDailyDataToPointsWithPointType:ChartPointTypeTemp
                                               from:start to:end forUser:user];
    [self convertUserDailyDataToPointsWithPointType:ChartPointTypeSex
                                               from:start to:end forUser:user];
    [self convertUserDailyDataToPointsWithPointType:ChartPointTypeWeight
                                               from:start to:end forUser:user];
    [self convertUserNutritionCaloriesToPointsWithPointType:
     ChartPointTypeCalorie from:start to:end forUser:user];
    [self convertUserNutritionsToPointsWithPointType:ChartPointTypeNutritions
                                                from:start to:end forUser:user];
}

- (void)rebuildNutritionAndCalorieForUser:(User *)user
{
    [self _buildNutritionAndCalorieForUser:user];
}

- (void)_buildPointsDataType:(ChartPointType)chartPointType forUser:(User *)user {
    NSString *start = [Utils dateIndexToDateLabelFrom20130101:[self getDateIdxOffset]];
    NSString *end = [Utils dateLabelAfterDateLabel:start withDays:366];
    [self convertUserDailyDataToPointsWithPointType:chartPointType
                                               from:start to:end forUser:user];
}

- (void)_buildNutritionAndCalorieForUser:(User *)user {
    NSString *start = [Utils dateIndexToDateLabelFrom20130101:[self getDateIdxOffset]];
    NSString *end = [Utils dateLabelAfterDateLabel:start withDays:366];
    [self convertUserNutritionCaloriesToPointsWithPointType:
     ChartPointTypeCalorie from:start to:end forUser:user];
    [self convertUserNutritionsToPointsWithPointType:ChartPointTypeNutritions
                                                from:start to:end forUser:user];
}

- (NSArray *)getRawTempPointsForUser:(User *)user {
    if (!bbts) {
        [self _buildPointsDataType:ChartPointTypeTemp forUser:user];
    }
    return [bbts sortedKnots];
}

- (NSArray*)getRawWeightPointsForUser:(User *)user {
    if (!weights) {
        [self _buildPointsDataType:ChartPointTypeWeight forUser:user];
    }
    return [weights sortedKnots];
}

- (NSArray*)getRawCalorieInPointsForUser:(User *)user {
    if (!calorieIns) {
        [self _buildNutritionAndCalorieForUser:user];
    }
    return [calorieIns sortedKnots];
}

- (NSArray*)getRawCalorieOutPointsForUser:(User *)user {
    if (!calorieOuts) {
        [self _buildNutritionAndCalorieForUser:user];
    }
    return [calorieOuts sortedKnots];
}

- (NSDictionary *)getRawNutritionPointsForUser:(User *)user {
    //    GLLog(@"nutritionsL %@", rawNutritionPoints);
    if (!rawNutritionPoints) {
        [self _buildNutritionAndCalorieForUser:user];
    }
    return rawNutritionPoints;
}

- (ChartPoints *)getRawSexPointsForUser:(User *)user {
    if (!sexes) {
        [self _buildPointsDataType:ChartPointTypeSex forUser:user];
    }
    return sexes;
}

- (CGFloat)getWeightSpaceStartForUser:(User *)user {
    if (!minWeight) {
        [self buildAllForUser:user];
    }
    return [minWeight floatValue];
}

- (CGFloat)getWeightSpaceLengthForUser:(User *)user {
    if (!minWeight || !maxWeight) {
        [self buildAllForUser:user];
    }
    return [maxWeight floatValue] - [minWeight floatValue];
}

- (ChartRange)calculateWeightRangeInCelsius:(BOOL)isCelsius forUser:(User *)user {
    if (!isCelsius) {
        float start = [Utils precisePoundsFromKg:[self getWeightSpaceStartForUser:user]];
        float length = [Utils precisePoundsFromKg:[self getWeightSpaceLengthForUser:user]];
        float mid = roundf((start + length / 2.f) / 10.f) * 10.f;
        float interval = MAX(mid - start, start + length - mid) / 5.f;
        interval = (NSInteger)(ceilf(interval / 5) * 5);
        interval = MAX(5.f, interval);
        return ChartRangeMake([Utils preciseKgFromPounds:mid - 5.5f * interval],
                              [Utils preciseKgFromPounds:11.f * interval]);
    }
    float start = [self getWeightSpaceStartForUser:user];
    float length = [self getWeightSpaceLengthForUser:user];
    float mid = roundf((start + length / 2.f) / 10.f) * 10.f;
    float interval = 1.f;
    for (NSInteger i = 0; i <= 6; i++) {
        interval = i <= 1 ? (i + 1) : 5 * (i - 1);
        if (mid - 5.f * interval <= start &&
            mid + 5.f * interval >= start + length) {
            break;
        }
    }
    return ChartRangeMake(mid - 5.5f * interval, 11.f * interval);
}

- (ChartRange)calculateTempRangeWithUnit:(TemperatureUnit)unit
{
    if (bbts.count == 0) {
        return NORMAL_BBT_VALUE_RANGE;
    }
    
    NSUInteger lowest, highest;
    if (unit == Celsius) {
        lowest = (NSUInteger)roundf(bbts.lowestPoint.y * 10);
        highest = (NSUInteger)roundf(bbts.highestPoint.y * 10);
    } else {
        lowest = (NSUInteger)roundf([Utils fahrenheitFromCelcius:bbts.lowestPoint.y] * 10);
        highest = (NSUInteger)roundf([Utils fahrenheitFromCelcius:bbts.highestPoint.y] * 10);
    }

    CGFloat mid = (highest + lowest) / 2;
    mid = roundf(mid / 10) * 10;
    CGFloat interval;
//    NSUInteger length = MAX(highest - mid, mid - lowest);
//    if (length < GRID_DIVIDER * TEMP_INTERVAL_SMALL * 10 / 2) {             // interval: 0.05, length: 5.5
//        interval = TEMP_INTERVAL_SMALL;
//    }
//    else if (length < GRID_DIVIDER * TEMP_INTERVAL_MEDIUM * 10 / 2) {     // interval: 0.1, length: 11
//        interval = TEMP_INTERVAL_MEDIUM;
//    }
//    else if (length < GRID_DIVIDER * TEMP_INTERVAL_LARGE * 10 / 2){       // interval: 0.25, length: 27.5
//        interval = TEMP_INTERVAL_LARGE;
//    }
//    else {                                                                // interval: 0.5, length: 55
//        interval = TEMP_INTERVAL_EVEN_LARGER;
//    }
    
    interval = TEMP_INTERVAL_MEDIUM;
    
    CGFloat rangeLength = GRID_DIVIDER * interval;
    CGFloat rangeStart = mid / 10 - rangeLength / 2;
    if (interval == TEMP_INTERVAL_LARGE) {
        rangeStart = roundf(rangeStart);
    }
    
    // make sure intergers will be shown
    if ((NSInteger)fmodf(rangeStart/interval, 2) == 0) {
        rangeStart -= interval;
    }
    
    // if Fahrenheit, we need to convert range back to celcius
    if (unit == Fahrenheit) {
        CGFloat rangeEnd = [Utils celciusFromFahrenheit:(rangeStart + rangeLength)];
        rangeStart = [Utils celciusFromFahrenheit:rangeStart];
        return ChartRangeMake(rangeStart, rangeEnd - rangeStart);
    }
    return ChartRangeMake(rangeStart, rangeLength);
}

- (CGFloat)getCalorieSpaceStart {
    return 3000.f - 500.f * 5.5f;
}
- (CGFloat)getCalorieSpaceLength {
    return 500.f * 11.f;
}

- (CGFloat)getRecommendedCaloire {
    User *u = [User currentUser];
    if (u.mfpId) {
        GLLog(@"mfp goal: %d", u.settings.mfpDailyCalorieGoal);
        return u.settings.mfpDailyCalorieGoal;
    }
    if (u.fitbitId) {
        GLLog(@"fitbit goal: %@", [Utils getDefaultsForKey:UDK_FITBIT_CALORIE_GOAL] );
        return [[Utils getDefaultsForKey:UDK_FITBIT_CALORIE_GOAL] integerValue];
    }
    
    return -3000;
}

- (CGFloat)getCalorieInForDateIdx:(NSInteger)dateIdx {
    if (calorieIns && [calorieIns for:dateIdx]) {
        return [calorieIns for:dateIdx].y;
    } else
        return 0;
}

- (NSArray *)getFertileWindowsForUser:(User *)user
{
    NSMutableArray *allFertileWindows = [NSMutableArray array];
    if (!user.prediction) {
        return @[];
    }
    
    BOOL hasFertile = user.shouldHaveFertileScore;
    for (NSDictionary *p in user.prediction) {
        [allFertileWindows addObject:@{
            @"pb": @([Utils dateLabelToIntFrom20130101:p[@"pb"]]),
            @"pe": @([Utils dateLabelToIntFrom20130101:p[@"pe"]]),
            @"fb": @([Utils dateLabelToIntFrom20130101:p[@"fb"]]),
            @"ov": @([Utils dateLabelToIntFrom20130101:p[@"ov"]]),
            @"fe": @([Utils dateLabelToIntFrom20130101:p[@"fe"]]),
            @"cl": p[@"cl"],
            @"cover_line": p[@"cover_line"] ? p[@"cover_line"] : @0,
            @"hasFertile": @(hasFertile),
        }];
    }
    return allFertileWindows;
}
- (NSInteger)getDateIdxOffset {
    NSInteger currentMonth = [[NSDate date] getMonth];
    NSInteger currentYear = [[NSDate date] getYear];
    NSInteger startMonth = currentMonth + 2;
    startMonth = startMonth - (NSInteger)(startMonth / 12) * 12 + 1;
    NSInteger startYear = startMonth > currentMonth ? currentYear - 1 : currentYear;
    NSDate *start = [Utils dateOfYear:startYear month:startMonth day:1];
    return [Utils dateToIntFrom20130101:start];
}

- (NSDictionary *)getMockedRawNutritionPoint {
    return @{
             NUTRITION_SRC_NAME: @"MyFitnessPal",
             NUTRITION_FAT: @9,
             NUTRITION_PROTEIN: @24,
             NUTRITION_CARBOHYDRATE: @39
             };
}

- (NSArray *)getMockedRawCalorieInPoints {
    NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    return @[
        [ChartPoint chartPointWithX:todayIndex - 12 y:3155],
        [ChartPoint chartPointWithX:todayIndex - 8 y:2600],
        [ChartPoint chartPointWithX:todayIndex - 4 y:2967],
        [ChartPoint chartPointWithX:todayIndex y:2799]
    ];
}

- (NSArray *)getMockedRawCalorieOutPoints {
    NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    return @[
        [ChartPoint chartPointWithX:todayIndex - 12 y:2465],
        [ChartPoint chartPointWithX:todayIndex - 8 y:1600],
        [ChartPoint chartPointWithX:todayIndex - 4 y:2400],
        [ChartPoint chartPointWithX:todayIndex y:1800]
    ];
}

- (NSArray *)getMockedRawWeightPointsInRange:(ChartRange)range
{
    NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    return @[
        [ChartPoint chartPointWithX:todayIndex - 12 y:(range.start + range.length * 0.5)],
        [ChartPoint chartPointWithX:todayIndex - 8 y:(range.start + range.length * 0.4)],
        [ChartPoint chartPointWithX:todayIndex - 4 y:(range.start + range.length * 0.6)],
        [ChartPoint chartPointWithX:todayIndex y:(range.start + range.length * 0.5)]
    ];
}

- (dispatch_queue_t)calculationThread {
    if (!_calculationThread) {
        _calculationThread = dispatch_queue_create("com.emma.chartcalculation", NULL);
    }
    return _calculationThread;
}

- (void)convertUserNutritionCaloriesToPointsWithPointType:(ChartPointType)pointType from:(NSString *)start to:(NSString *)end forUser:(User *)user {
    calorieIns = [[ChartPoints alloc] init];
    calorieOuts = [[ChartPoints alloc] init];
    
    NSArray *nutritions = [Nutrition nutritonsWithCalorieFromDate:start toDate:end forUser:user];
    for (Nutrition *d in nutritions) {
        if (d.calorieIn  > 0) {
            [calorieIns putKnot:[ChartPoint chartPointWithX:[Utils dateLabelToIntFrom20130101:d.date] y:d.calorieIn]];
        }
        if (d.calorieOut  > 0) {
            [calorieOuts putKnot:[ChartPoint chartPointWithX:[Utils dateLabelToIntFrom20130101:d.date] y:d.calorieOut]];
        }
    }
    
    [user publish:CALORIES_UPDATED];
}

- (void)convertUserNutritionsToPointsWithPointType:(ChartPointType)pointType from:(NSString *)start to:(NSString *)end forUser:(User *)user {
    NSMutableDictionary *nutritionsOutResult = [NSMutableDictionary dictionary];
    
    NSArray *nutritions = [Nutrition nutritonsWithNutritionFromDate:start toDate:end forUser:user];
    for (Nutrition *d in nutritions) {
        [nutritionsOutResult setObject:[d nutritionsDict] forKey:@([Utils dateLabelToIntFrom20130101:d.date])];
    }
    
    rawNutritionPoints = nutritionsOutResult;
    [user publish:NUTRITIONS_UPDATED];
}

- (void)convertUserDailyDataToPointsWithPointType:(ChartPointType)pointType from:(NSString *)start to:(NSString *)end forUser:(User *)user {
    if (ChartPointTypeTemp == pointType) {
        bbts = [[ChartPoints alloc] init];
    }
    if (ChartPointTypeSex == pointType) {
        sexes = [[ChartPoints alloc] init];
    }
    if (ChartPointTypeWeight == pointType) {
        weights = [[ChartPoints alloc] init];
    }
    NSMutableArray *allOvs = [@[] mutableCopy];
    
    if (user.prediction) {
        for (NSInteger i = 0; i < [user.prediction count]; i++) {
            NSDictionary *p = user.prediction[i];
            NSDictionary *a = i < [user.a count] ? user.a[i] : nil;
            if (a && a[@"ov_lv"] && !isNSNull(a[@"ov_lv"]) &&
                [a[@"ov_lv"] isKindOfClass:[NSNumber class]] &&
                ([a[@"ov_lv"] intValue] == 1 || [a[@"ov_lv"] intValue] == 3)) {
                
                [allOvs addObject:@([Utils dateLabelToIntFrom20130101:
                                     p[@"ov"]])];
            }
        }
    }
    
    NSArray *userDailyData = [UserDailyData getUserDailyDataFrom:start to:end ForUser:user];
    if (ChartPointTypeWeight == pointType) {
        minWeight = @999;
        maxWeight = @0;
    }
    for (UserDailyData *d in userDailyData) {
        NSInteger date = [Utils dateLabelToIntFrom20130101:d.date];
        if (ChartPointTypeTemp == pointType && d.temperature && d.temperature > 30) {
            ChartPoint *cp;
            if ([allOvs containsObject:@(date)]) {
                cp = [ChartPoint chartPointWithX:date y:d.temperature alpha:1];
            }
            else {
                cp = [ChartPoint chartPointWithX:date y:d.temperature alpha:-1];
            }
            [bbts putKnot:cp];
        }
        if (ChartPointTypeWeight == pointType && d.weight && d.weight > 20) {
            ChartPoint *cp = [ChartPoint chartPointWithX:date y:d.weight];
            [weights putKnot:cp];
            if (d.weight < [minWeight floatValue]) {
                minWeight = @(d.weight);
            }
            if (d.weight > [maxWeight floatValue]) {
                maxWeight = @(d.weight);
            }
        }
        if (ChartPointTypeSex == pointType && d.intercourse > 1) {
            ChartPoint *cp = [ChartPoint chartPointWithX:
                              [Utils dateLabelToIntFrom20130101:d.date] y:1];
            [sexes putKnot:cp];
        }
    }
    switch (pointType) {
        case ChartPointTypeWeight:
            if ([minWeight floatValue] > [maxWeight floatValue]) {
                minWeight = @([Utils preciseKgFromPounds:125.f]);
                maxWeight = @([Utils preciseKgFromPounds:175.f]);
            }
            break;
        default:
            break;
    }
}

- (CGFloat)interpolateTempAtDateIdx:(CGFloat)dateIdx {
    return [self _interpolateKnots:[bbts sortedKnots]
                        forDateIdx:dateIdx];
}

- (CGFloat)interpolateWeightAtDateIdx:(CGFloat)dateIdx {
    return [self _interpolateKnots:[weights sortedKnots] forDateIdx:dateIdx];
}

- (CGFloat)interpolateCalorieInAtDateIdx:(CGFloat)dateIdx {
    return [self _interpolateKnots:[calorieIns sortedKnots] forDateIdx:dateIdx];
}

- (CGFloat)interpolateCalorieOutAtDateIdx:(CGFloat)dateIdx {
    return [self _interpolateKnots:[calorieOuts sortedKnots] forDateIdx:dateIdx];
}

- (CGFloat)_interpolateKnots:(NSArray *)knots forDateIdx:(CGFloat)dateIdx {
    for (NSInteger i = 0; i < [knots count]; i++) {
        ChartPoint *p = knots[i];
        if (fabs(p.x - dateIdx) < 0.05f) return p.y;
        if (i + 1 >= [knots count]) return -1;
        ChartPoint *nextP = knots[i+1];
        if (p.x <= dateIdx + 0.05f && nextP.x >= dateIdx - 0.05f) {
            return nextP.y - (nextP.x - dateIdx) / (nextP.x - p.x) * (nextP.y - p.y);
        }
    }
    return -1;
}
@end
