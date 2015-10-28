//
//  ChartSegmentView.h
//  emma
//
//  Created by Xin Zhao on 13-9-9.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChartUtils.h"

CG_INLINE CGFloat
xValueToScreen(CGFloat value, CGRect screen, ChartRange range)
{
    return (CGFloat)(value - range.start) / range.length * screen.size.width;
}
CG_INLINE CGFloat
yValueToScreen(CGFloat value, CGRect screen, ChartRange range)
{
    return (1.0f - (value - range.start) / range.length) * screen.size.height + screen.origin.y;
}

typedef enum {
    ChartSegmentStateNormal = 0,
    ChartSegmentStateThumb,
    ChartSegmentStateTransition,
    ChartSegmentStateScaling
} ChartSegmentState;

@interface ChartSegmentView : UIView

//@property (readonly) NSArray *bgBbtKnots;
@property (readonly) NSArray *bbtKnots;
@property (readonly) NSArray *weightKnots;
@property (readonly) NSArray *calorieInKnots;
@property (readonly) NSArray *calorieOutKnots;
@property (readonly) NSDictionary *cms;
@property (readonly) ChartPoints *sexes;
@property (readonly) NSArray *bg;
@property (readonly) ChartRange rangeX;
@property (readonly) ChartRange weightRangeY;
@property (readonly) ChartRange calorieRangeY;
@property (readonly) ChartPoint *todayPointInThumb;
@property CGPoint curveAndDotSize;
@property ChartSegmentState state;
@property NSInteger chartDataType;
//@property NSInteger _drawnCount;
@property (nonatomic) BOOL isTtc;
@property (nonatomic) float recommendedIntake;

@property (assign, nonatomic) ChartRange temperatureRangeY;
@property (assign, nonatomic) CGFloat tempOffset;
@property (assign, nonatomic) CGFloat intervalY;
@property (assign, nonatomic) BOOL isMockData;
//- (void)setBgBbtFromParent:(NSArray *)bbtKnots;
- (void)setBbtFromParent:(NSArray *)bbtKnots;
- (void)setWeightFromParent:(NSArray *)weightKnots;
- (void)setCalorieInFromParent:(NSArray *)calorieInKnots;
- (void)setCalorieOutFromParent:(NSArray *)calorieOutKnots;
//- (void)setCmsFromParent:(NSDictionary *)cms;
- (void)setSexesFromParent:(ChartPoints *)sexes;
- (void)setBgFromParent:(NSArray *)bg;
- (void)setRangeXFromParent:(ChartRange)rangeX;
- (void)setWeightRangeYFromParent:(ChartRange)rangeY;
- (void)setCalorieRangeYFromParent:(ChartRange)rangeY;
- (void)setTodayPointFromParent:(ChartPoint*)todayPoint;
- (void)setInCelsiusFromParent:(BOOL)inCelsius;

- (NSNumber *)getPbBetweenStart:(NSInteger)start toEnd:(NSInteger)end;
- (NSInteger)getCdForDateIdx:(NSInteger)dateIdx;
- (NSInteger)getOvulationForDateIndex:(NSInteger)dateIndex;
- (CGRect)getBaseLineNameRect;


@end

