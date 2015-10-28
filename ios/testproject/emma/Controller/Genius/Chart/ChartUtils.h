//
//  Chart.h
//  emma
//
//  Created by Xin Zhao on 13-7-4.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    CmDescVeryWatery = 0,
} CmDesc;

typedef enum {
    ChartGestureLockNone = 0xff,
    ChartGestureLockPinch = 0x01,
    ChartGestureLockPan = 0x02
} ChartGestureLock;

//struct ChartPointerInfo {
//    NSInteger cm;
//    CGFloat temp;
//    BOOL sex;
//    NSInteger year;
//    NSInteger month;
//    NSInteger day;
//    CGFloat snappedX;
//    CGFloat screenY;
//};
//typedef struct ChartPointerInfo ChartPointerInfo;

@interface ChartPointerInfo : NSObject
@property NSInteger cm;
@property CGFloat temp;
@property BOOL sex;
@property CGFloat weight;
@property CGFloat height;
@property CGFloat calorieIn;
@property CGFloat calorieOut;
@property CGFloat calorieRecommended;
@property NSInteger dateIdx;
@property CGFloat snappedX;
@property CGFloat interpolatedTemp;
@property CGFloat interpolatedWeight;
@property CGFloat interpolatedCalorieIn;
@property CGFloat interpolatedCalorieOut;
@property NSString *calorieSrc;
@property NSString *carb;
@property NSString *fat;
@property NSString *protein;
@property NSString *dateString;
@property NSAttributedString *attrTempString;
@property NSAttributedString *attrCmString;
@property NSAttributedString *attrSexString;
@property NSAttributedString *attrTempStringBig;
@property NSAttributedString *attrWetnessString;
@property NSAttributedString *attrTextureString;
@property NSAttributedString *attrWeightString;
@property NSAttributedString *attrCalorieString;

//+ (CpInfo*)makeCpInfoFromChartPointerInfo:(ChartPointerInfo)cpInfo;
@end

struct ChartRange {
    CGFloat start;
    CGFloat length;
};
typedef struct ChartRange ChartRange;

CG_INLINE ChartRange
ChartRangeMake(CGFloat start, CGFloat length)
{
    ChartRange cr;
    cr.start = start;
    cr.length = length;
    return cr;
}

CG_INLINE ChartPointerInfo*
chartPointerInfoMake(NSInteger dateIdx, NSInteger cm, CGFloat temp, BOOL sex,
                     CGFloat weight, CGFloat calorieIn, CGFloat calorieOut, CGFloat x, CGFloat y, NSString *calorieSrc)
{
    ChartPointerInfo *cpInfo = [[ChartPointerInfo alloc] init];
    cpInfo.dateIdx = dateIdx;
    cpInfo.cm = cm;
    cpInfo.temp = temp;
    cpInfo.sex = sex;
    cpInfo.snappedX = x;
    cpInfo.interpolatedTemp = y;
    cpInfo.weight = weight;
    cpInfo.calorieIn = calorieIn;
    cpInfo.calorieOut = calorieOut;
    cpInfo.calorieSrc = calorieSrc;
    return cpInfo;
}

@interface ScrollAnimationDisplayLink : NSObject
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) CGFloat targetOffsetX;
@property (nonatomic) CGFloat startOffsetX;
@property (nonatomic) CGFloat currentOffsetX;
@property (nonatomic) CFTimeInterval duration;
@property (nonatomic) BOOL scrollAnimationStarted;
@property (nonatomic) CFTimeInterval startTimestamp;
@property (nonatomic) CFTimeInterval timeElapsed;
@property (nonatomic) NSMutableDictionary *startStates;

- (ScrollAnimationDisplayLink*)init;
- (void)startWithTarget:(CGFloat)target start:(CGFloat)start duration:(CFTimeInterval)duration;
- (void)comeIntoLoopFor1stTime;
- (BOOL)scrollCanEnd;
- (void)animationEnd;
- (void)updateCurrentOffsetX:(CGFloat)newCurrent;
- (void)storeStartStatesValue:(id)obj forKey:(id)key;
- (id)getStartStatesForKey:(id)key;
@end

@interface ChartPoint : NSObject
@property CGFloat x;
@property CGFloat y;
@property CGFloat alpha;

+ (NSArray *)chartPointsWithArray:(NSArray *)coordinates;
+ (ChartPoint *)chartPointWithX:(CGFloat)x y:(CGFloat)y;
+ (ChartPoint *)chartPointWithX:(CGFloat)x y:(CGFloat)y alpha:(CGFloat)a;
@end


@interface ChartPoints : NSObject
@property (nonatomic, readonly, weak) ChartPoint *lowestPoint;
@property (nonatomic, readonly, weak) ChartPoint *highestPoint;
@property (nonatomic, readonly) NSUInteger count;

- (void)putKnot:(ChartPoint *)knot;
- (NSArray *)sortedKnots;
- (ChartPoint *)for:(NSInteger)dateIdx;
@end


@interface ChartUtils : NSObject
@end

