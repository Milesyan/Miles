//
//  GLLineChartRenderView.h
//  kaylee
//
//  Created by Allen Hsu on 12/5/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define GRID_COLOR UIColorFromRGBA(0xa8a8a8b0)
#define DATE_COLOR UIColorFromRGB(0x888888)
#define LABEL_COLOR UIColorFromRGB(0x000000)
#define INDICATOR_COLOR UIColorFromRGB(0x5a62d2)

#define WEEK_VIEW_THRESHOLD 16
#define GRID_NUM_Y_AXIS     22
#define GRID_X_LABEL_HEIGHT 32.0
#define BASE_DAYS_IN_VIEW   12.0

#define CHART_LINE_WIDTH    3.0
#define INDICATOR_LINE_WIDTH 3.0
#define BUBBLE_RADIUS       8.0
#define INDICATOR_HEIGHT    5.0
#define TODAY_TRIANGLE_HEIGHT    3.0

#pragma mark - GLLineChartRange
typedef struct _GLLineChartRange {
    CGFloat location;
    CGFloat length;
} GLLineChartRange;

CG_INLINE GLLineChartRange
GLLineChartRangeMake(CGFloat location, CGFloat length)
{
    GLLineChartRange range;
    range.location = location;
    range.length = length;
    return range;
}

extern bool GLLineChartRangeEqualToRange(GLLineChartRange range1, GLLineChartRange range2);

#pragma mark - GLLineChartDot
@interface GLLineChartDot : NSObject
@property (assign, nonatomic) NSInteger dateIndex;
@property (assign, nonatomic) CGFloat value;
@end

#pragma mark - GLLineChartLineData
@interface GLLineChartLineData : NSObject
@property (strong, nonatomic) UIColor *dotColor;
@property (strong, nonatomic) UIColor *lineColor;
@property (copy, nonatomic) NSArray *dots;
@end

@interface GLLineChartRenderView : UIView
@property (assign, nonatomic) BOOL showPeriodBg;
@property (assign, nonatomic) BOOL showCycleDay;
@property (assign, nonatomic) BOOL showGrid;
@property (assign, nonatomic) BOOL showLines;
@property (assign, nonatomic) BOOL showDots;
@property (assign, nonatomic) BOOL showIndicator;
@property (assign, nonatomic) BOOL showToday;
@property (assign, nonatomic) CGFloat indicatorOffsetX;
@property (assign, nonatomic) CGFloat maxValue;
@property (assign, nonatomic) CGFloat minValue;
@property (copy, nonatomic) NSString *valueUnit;
@property (assign, nonatomic) GLLineChartRange range;
@property (copy, nonatomic) NSArray *data;
@property (strong, nonatomic) GLLineChartDot *todayDot;
@property (copy, nonatomic) NSString *todayString;
@property (strong, nonatomic) NSSet *symbols;

@end
