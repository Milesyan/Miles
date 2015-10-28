
//  Chart.m
//  emma
//
//  Created by Xin Zhao on 13-7-4.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import "ChartUtils.h"

@implementation ChartPointerInfo
@end

@implementation ScrollAnimationDisplayLink
@synthesize timeElapsed;

- (ScrollAnimationDisplayLink*)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        _displayLink = nil;
        _targetOffsetX = -1;
        _startOffsetX = -1;
        _currentOffsetX = -1;
        _scrollAnimationStarted = NO;
        _startTimestamp = -1;
    }
    return self;
}

- (CFTimeInterval)timeElapsed
{
    return self.displayLink.timestamp - self.startTimestamp;
}

- (void)startWithTarget:(CGFloat)target start:(CGFloat)start duration:(CFTimeInterval)duration
{
    _targetOffsetX = target;
    _startOffsetX = start;
    _duration = duration;
    _currentOffsetX = -1;
    _scrollAnimationStarted = NO;
    _startTimestamp = -1;
    self.startStates = [NSMutableDictionary dictionary];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)comeIntoLoopFor1stTime
{
    _scrollAnimationStarted = YES;
    _startTimestamp = self.displayLink.timestamp;
}

- (BOOL)scrollCanEnd
{
    return fabsf(self.currentOffsetX - self.targetOffsetX) < 0.01f;
}

- (void)animationEnd
{
    [self.displayLink invalidate];
    _displayLink = nil;
    _targetOffsetX = -1;
    _startOffsetX = -1;
    _currentOffsetX = -1;
    _scrollAnimationStarted = NO;
    _startTimestamp = -1;
    _startStates = nil;
}

- (void)updateCurrentOffsetX:(CGFloat)newCurrent
{
    _currentOffsetX = newCurrent;
}

- (void)storeStartStatesValue:(id)obj forKey:(id)key
{
    self.startStates[key] = obj;
}

- (id)getStartStatesForKey:(id)key
{
    return self.startStates[key];
}

@end

@implementation ChartPoint

- (NSString *)description
{
    return [NSString stringWithFormat:@"{x: %f, y: %f}", self.x, self.y];
}

+ (ChartPoint *)chartPointWithX:(CGFloat)x y:(CGFloat)y {
    ChartPoint *result = [[ChartPoint alloc] init];
    result.x = x;
    result.y = y;
    result.alpha = -1;
    return result;
}

+ (ChartPoint *)chartPointWithX:(CGFloat)x y:(CGFloat)y alpha:(CGFloat)a {
    ChartPoint *result = [[ChartPoint alloc] init];
    result.x = x;
    result.y = y;
    result.alpha = a;
    return result;
}

+ (NSArray *)chartPointsWithArray:(NSArray *)coordinates {
    NSMutableArray *result = [NSMutableArray array];
    NSInteger endIdx = [coordinates count] % 2 == 0 ? [coordinates count] : [coordinates count] - 1;
    for (NSInteger i = 0; i < endIdx; i += 2) {
        [result addObject:[ChartPoint chartPointWithX:[[coordinates objectAtIndex:i] floatValue] y:[[coordinates objectAtIndex:i+1] floatValue]]];
    }
    return result;
}

@end

@interface ChartPoints() {}

@property (nonatomic, readwrite, weak) ChartPoint *lowestPoint;
@property (nonatomic, readwrite, weak) ChartPoint *highestPoint;

@property NSMutableArray *knots;
@property NSMutableDictionary *xToKnot;
@property BOOL sorted;
@end

@implementation ChartPoints

- (id)init {
    self = [super init];
    if (self) {
        self.sorted = NO;
        self.knots = [@[] mutableCopy];
        self.xToKnot = [@{} mutableCopy];
    }
    return self;
}

- (NSString *)description {
    return self.knots.description;
}

- (NSUInteger)count {
    return self.knots.count;
}

- (ChartPoint *)lowestPoint {
    if (!_lowestPoint) {
        [self setupLowestAndHighestPoints];
    }
    return _lowestPoint;
}

- (ChartPoint *)highestPoint {
    if (!_highestPoint) {
        [self setupLowestAndHighestPoints];
    }
    return _highestPoint;
}

- (void)setupLowestAndHighestPoints {
    if (self.knots.count == 0) {
        return;
    } else if (self.knots.count == 1) {
        _lowestPoint = _highestPoint = self.knots[0];
        return;
    }
    
    _lowestPoint = self.knots[0];
    _highestPoint = self.knots[1];
    
    for (ChartPoint *point in self.knots) {
        if (point.y < _lowestPoint.y) {
            _lowestPoint = point;
        }
        if (point.y > _highestPoint.y) {
            _highestPoint = point;
        }
    }
}

- (void)putKnot:(ChartPoint *)knot {
    self.sorted = NO;
    [self.knots addObject:knot];
    self.xToKnot[@(roundf(knot.x))] = knot;
}

- (NSArray *)sortedKnots {
    if (!self.sorted) {
        self.knots = [[self.knots sortedArrayUsingComparator:
                       ^NSComparisonResult(ChartPoint *a, ChartPoint *b){
                           if (a.x < b.x) {
                               return NSOrderedAscending;
                           }
                           else if (a.x > b.x){
                               return NSOrderedDescending;
                           }
                           return NSOrderedSame;
                       }] mutableCopy];
        self.sorted = YES;
    }
    return (NSArray *)self.knots;
}

- (ChartPoint *)for:(NSInteger)dateIdx {
    return self.xToKnot[@(dateIdx)];
}

@end

@implementation ChartUtils
@end


