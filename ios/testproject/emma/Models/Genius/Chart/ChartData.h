//
//  ChartData.h
//  emma
//
//  Created by Xin Zhao on 13-8-3.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "ChartUtils.h"
#import "User.h"
#import <Foundation/Foundation.h>

#define NUTRITIONS_UPDATED @"nutritions_updated"
#define CALORIES_UPDATED @"calories_updated"

typedef enum {
    ChartPointTypeTemp = 0,
    ChartPointTypeCm,
    ChartPointTypeSex,
    ChartPointTypeWeight,
    ChartPointTypeCalorie,
    ChartPointTypeNutritions,
} ChartPointType;

typedef NS_ENUM(NSUInteger, TemperatureUnit) {
    Celsius,
    Fahrenheit,
};

@interface ChartData : NSObject
+ (User *)getThreadSafeUser;
+ (ChartData *)getInstance;

- (void)clearAll;
- (void)buildAllForUser:(User *)user;
- (void)rebuildNutritionAndCalorieForUser:(User *)user;
//+ (NSArray *)getKnotsAndControlPointsFrom:(NSString *)start to:(NSString *)end;
//+ (void)convertUserPredictionToPointsWithPrediction:(NSArray*)prediction;
- (NSArray *)getRawTempPointsForUser:(User *)user;
- (NSArray *)getRawWeightPointsForUser:(User *)user;
- (NSArray  *)getRawCalorieInPointsForUser:(User *)user;
- (NSArray*)getRawCalorieOutPointsForUser:(User *)user;
- (ChartPoints *)getRawSexPointsForUser:(User *)user;

- (ChartRange)calculateTempRangeWithUnit:(TemperatureUnit)unit;
- (ChartRange)calculateWeightRangeInCelsius:(BOOL)isCelsius forUser:(User *)user;
- (CGFloat)getCalorieSpaceStart;
- (CGFloat)getCalorieSpaceLength;
- (NSDictionary *)getRawNutritionPointsForUser:(User *)user;
- (NSDictionary *)getMockedRawNutritionPoint;
- (NSArray *)getMockedRawCalorieInPoints;
- (NSArray *)getMockedRawCalorieOutPoints;
- (NSArray *)getMockedRawWeightPointsInRange:(ChartRange)range;

- (NSArray *)getFertileWindowsForUser:(User *)user;
- (NSInteger)getDateIdxOffset;
- (CGFloat)interpolateTempAtDateIdx:(CGFloat)dateX;
- (CGFloat)interpolateWeightAtDateIdx:(CGFloat)dateX;
- (CGFloat)interpolateCalorieInAtDateIdx:(CGFloat)dateIdx;
- (CGFloat)interpolateCalorieOutAtDateIdx:(CGFloat)dateIdx;
- (CGFloat)getRecommendedCaloire;
- (CGFloat)getCalorieInForDateIdx:(NSInteger)dateIdx;

@end
