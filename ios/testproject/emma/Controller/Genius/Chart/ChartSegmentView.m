//
//  ChartSegmentView.m
//  emma
//
//  Created by Xin Zhao on 13-9-9.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "ChartSegmentView.h"
#import "ChartConstants.h"
#import "ChartUtils.h"
#import <GLFoundation/UIColor+Utils.h>
#import "User.h"

#define THUMBVIEW_BBT_VALUE_RANGE ChartRangeMake(TEMP_VALUE_SPACE_START, TEMP_VALUE_UPBOUND - TEMP_VALUE_SPACE_START)
#define NORMAL_CM_VALUE_RANGE ChartRangeMake(CM_VALUE_SPACE_START, CM_VALUE_SPACE_LENGTH)

@interface ChartSegmentView(){
    CGFloat dotRaius;
    CGFloat curveW;
    CGRect baseLineNameRect;
}

@property BOOL inCelsius;
@property (nonatomic, strong) NSMutableArray *scaleLabels;

@end

@implementation ChartSegmentView

static UIFont *small;
static UIFont *italicSmall;
static NSMutableArray *allCls;
static NSMutableArray *allPbs;
static NSMutableArray *allOvulationDates;
static UIImage *sexSymbol;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        small = [Utils defaultFont:9];
        italicSmall = [UIFont fontWithName:@"HelveticaNeue-Italic" size:9];
        if (nil == italicSmall) {
            italicSmall = [Utils defaultFont:9];
        }
        sexSymbol = [UIImage imageNamed:@"calendar-sex"];
        self.recommendedIntake = -1;
        baseLineNameRect = CGRectZero;
        
        self.clipsToBounds = YES;
        self.isMockData = NO;
    }
    return self;
}

#pragma mark - Setters
//- (void)setBgBbtFromParent:(NSArray *)bbtKnots
//{
//    _bgBbtKnots = bbtKnots;
//}

- (void)setBbtFromParent:(NSArray *)bbtKnots
{
    _bbtKnots = bbtKnots;
}

- (void)setWeightFromParent:(NSArray *)weightKnots
{
    _weightKnots = weightKnots;
}

- (void)setCalorieInFromParent:(NSArray *)calorieInKnots
{
    _calorieInKnots = calorieInKnots;
}

- (void)setCalorieOutFromParent:(NSArray *)calorieOutKnots
{
    _calorieOutKnots = calorieOutKnots;
}

- (void)setSexesFromParent:(ChartPoints *)sexes
{
    _sexes = sexes;
}

- (void)setRangeXFromParent:(ChartRange)rangeX
{
    _rangeX = rangeX;
}

- (void)setWeightRangeYFromParent:(ChartRange)rangeY
{
    _weightRangeY = rangeY;
}
- (void)setCalorieRangeYFromParent:(ChartRange)rangeY
{
    _calorieRangeY = rangeY;
}
- (void)setBgFromParent:(NSArray *)bg
{
    _bg = bg;
    allPbs = [@[] mutableCopy];
    allCls = [@[] mutableCopy];
    allOvulationDates = [NSMutableArray array];
    for (NSDictionary *p in bg) {
        [allPbs addObject:p[@"pb"]];
        [allCls addObject:p[@"cl"]];
        [allOvulationDates addObject:p[@"ov"]];
    }
}

- (void)setTodayPointFromParent:(ChartPoint*)todayPoint
{
    _todayPointInThumb = todayPoint;
}

- (void)setInCelsiusFromParent:(BOOL)inCelsius
{
    _inCelsius = inCelsius;
}

- (void)setFrame:(CGRect)frame
{
//    if ((self.chartDataType & CHART_DATA_TYPE_TEMP) && self.bbtKnots.count > 0) {
//        CGFloat offset = self.temperatureRangeY.length - GRID_DIVIDER * 0.1;
//        if (offset > 0) {
//            CGFloat height = frame.size.height * offset;
//            frame.size.height += height;
//        }
//    }
    [super setFrame:frame];
//    NSLog(@"set frame: %@", NSStringFromCGRect(frame));    
}

- (CGFloat)intervalY
{
    return self.height * GRID_AREA_HEIGHT_2_WHOLE / GRID_DIVIDER;
}

#pragma mark - View drawers
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
// static NSInteger drawnCount = 0;
- (void)drawRect:(CGRect)rect
{
    CGRect gridRect = setRectHeight(rect, rect.size.height * GRID_AREA_HEIGHT_2_WHOLE);
    if (self.state == ChartSegmentStateThumb) {
//        self.state == ChartSegmentStateTransition) {
        dotRaius = DOT_RADIUS / 2;
        curveW = CURVE_W / 2;
    }
    else {
        dotRaius = DOT_RADIUS;
        curveW = CURVE_W;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);

    if ((self.state == ChartSegmentStateNormal || self.state == ChartSegmentStateTransition) &&
        self.chartDataType != CHART_DATA_TYPE_NUTRITION) {
        [self drawBgInContext:context inRect:gridRect withBg:self.bg inRange:self.rangeX];
    }
   
    if (self.chartDataType & CHART_DATA_TYPE_TEMP) {
        [self drawBbtInContext:context inRect:gridRect withKnots:self.bbtKnots
            inRangeX:self.rangeX rangeY:self.temperatureRangeY];
    }
    if (self.chartDataType & CHART_DATA_TYPE_WEIGHT) {
        [self drawWeightInContext:context inRect:gridRect withKnots:
            self.weightKnots inRangeX:self.rangeX rangeY:self.weightRangeY];
    }
    if (self.chartDataType & CHART_DATA_TYPE_CALORIE) {
        [self drawCalorieInContext:context inRect:gridRect withInKnots:
            self.calorieInKnots andOutKnots:self.calorieOutKnots
            inRangeX:self.rangeX rangeY:self.calorieRangeY];
    }
    
    if (self.state == ChartSegmentStateNormal && self.chartDataType != CHART_DATA_TYPE_NUTRITION) {
        [self drawDatesInContext:context inRect:rect inRangeX:self.rangeX rangeY:self.temperatureRangeY];
        [self drawSexBubblesInContext:context inRect:rect withSex:self.sexes inRangeX:self.rangeX];
    }
    
    if (self.state == ChartSegmentStateThumb) {
        
        if (self.chartDataType == CHART_DATA_TYPE_NUTRITION) {
            return;
        }
        
        CGFloat thumbBubbleScreenX = xValueToScreen(self.todayPointInThumb.x,
            rect, self.rangeX);
        CGFloat thumbBubbleScreenY = rect.origin.y + rect.size.height * 0.382f;
        if (self.chartDataType == CHART_DATA_TYPE_TEMP) {
            if (self.todayPointInThumb.y > 0) {
                thumbBubbleScreenY = yValueToScreen(self.todayPointInThumb.y,
                    rect, self.temperatureRangeY);
            }
        }
        else {
            if (self.todayPointInThumb.y > 0) {
                thumbBubbleScreenY = yValueToScreen(self.todayPointInThumb.y,
                    rect, self.weightRangeY);
            }
        }

        CGRect bubbleRect;
        if (thumbBubbleScreenY - BUBBLE_GAP - BUBBLE_ARROW -
            THUMB_BUBBLE_HEIGHT > 2) {
            thumbBubbleScreenY -= BUBBLE_GAP;
            bubbleRect = (CGRect){
                {thumbBubbleScreenX - THUMB_BUBBLE_WIDTH * 0.85f,
                thumbBubbleScreenY - BUBBLE_ARROW - THUMB_BUBBLE_HEIGHT},
                {THUMB_BUBBLE_WIDTH, THUMB_BUBBLE_HEIGHT}};
        }
        else {
            thumbBubbleScreenY = thumbBubbleScreenY + BUBBLE_GAP +
                BUBBLE_ARROW < 2 ? 2 : thumbBubbleScreenY;
            thumbBubbleScreenY += BUBBLE_GAP;
            bubbleRect = (CGRect){
                {thumbBubbleScreenX - THUMB_BUBBLE_WIDTH * 0.85f,
                thumbBubbleScreenY + BUBBLE_ARROW},
                {THUMB_BUBBLE_WIDTH, THUMB_BUBBLE_HEIGHT}};
        }
        
        
        // if mock data or calorie chart or today's data not exist, draw bubble in up-right corner
        if (self.isMockData || self.chartDataType == CHART_DATA_TYPE_CALORIE || self.todayPointInThumb.y < 0) {
            bubbleRect = (CGRect){
                {self.width - THUMB_BUBBLE_WIDTH - 10, 10},
                {THUMB_BUBBLE_WIDTH, THUMB_BUBBLE_HEIGHT}};
            // set bubble height in calorie chart
            if (self.chartDataType == CHART_DATA_TYPE_CALORIE) {
                bubbleRect.size.height = 30;
            }
            [self drawThumbBubbleInContext:context inRect:bubbleRect pointAt:
             (CGPoint){self.width - THUMB_BUBBLE_WIDTH - 10,10}];
        } else {
            [self drawThumbBubbleInContext:context inRect:bubbleRect pointAt:
             (CGPoint){thumbBubbleScreenX, thumbBubbleScreenY}];
        }

    }
}

- (void)_drawCurveWithColor:(CGColorRef)curveColor andKnots:(NSArray *)knots
    withColor:(CGColorRef)knotColor inRect:(CGRect)rect
    inRangeX:(ChartRange)rangeX rangeY:(ChartRange)rangeY
    inContext:(CGContextRef)context{
    
//    NSLog(@"draw rect in: %@", NSStringFromCGRect(rect));
//    NSLog(@"range: (%f, %f), (%f, %f)", rangeX.start, rangeX.length, rangeY.start, rangeY.length);
//    NSLog(@"points: %@", [knots componentsJoinedByString:@", "]);
    
    if (self.isMockData && self.state == ChartSegmentStateThumb) {
//        curveColor = UIColorFromRGB(0xe2f1d5).CGColor;
//        knotColor = UIColorFromRGB(0xe2f1d5).CGColor;
    }
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, curveW);
    CGContextSetStrokeColorWithColor(context, curveColor);
    CGMutablePathRef curve = CGPathCreateMutable();
   
    NSInteger startIdx = -1;
    for (NSInteger i = 0; i < [knots count]; i++) {
        ChartPoint *knot = (ChartPoint*)knots[i];
        if (knot.x < self.rangeX.start) {
            continue;
        }
        if (knot.x >= self.rangeX.start) {
            startIdx = i;
            break;
        }
        else if (knot.x > self.rangeX.start + self.rangeX.length) {
            break;
        }

    }
    if (startIdx > 0) {
        startIdx--;
    }
    if (startIdx <= -1) {
        return;
    }
    
    CGFloat offsetY = 0;
    if (self.chartDataType & CHART_DATA_TYPE_TEMP) {
        offsetY = self.tempOffset;
    }
    
    for (NSInteger i = startIdx; i < [knots count] - 1; i++) {
        ChartPoint *lastKnot = knots[i];
        ChartPoint *knot = knots[i+1];
        CGFloat lastScreenX = xValueToScreen(lastKnot.x, rect, rangeX);
        CGFloat lastScreenY = yValueToScreen(lastKnot.y, rect, rangeY) + offsetY;
        CGFloat screenX = xValueToScreen(knot.x, rect, rangeX);
        CGFloat screenY = yValueToScreen(knot.y, rect, rangeY) + offsetY;
        
        CGPathMoveToPoint(curve, 0, lastScreenX, lastScreenY);
        CGPathAddLineToPoint(curve, nil, screenX, screenY);
        if (knot.x > self.rangeX.start + self.rangeX.length) {
            break;
        }
    }
    CGContextAddPath(context, curve);
    CGContextStrokePath(context);
    CGPathRelease(curve);
    
    for (NSInteger i = startIdx; i < [knots count]; i++) {
        CGContextSetFillColorWithColor(context, knotColor);
        ChartPoint *knot = knots[i];
        if (knot.x > self.rangeX.start + self.rangeX.length) {
            break;
        }
        CGFloat screenX = xValueToScreen(knot.x, rect, rangeX);
        CGFloat screenY = yValueToScreen(knot.y, rect, rangeY) + offsetY;
        CGContextFillEllipseInRect(context, CGRectMake(
            screenX - dotRaius, screenY - dotRaius,
            dotRaius * 2, dotRaius * 2));
        if (knot.alpha <= 0) {
            continue;
        }
        CGRect bubbleRect = CGRectMake(screenX - 24, screenY + 15,
            48, 15);
        
        [self _drawBubbleInContext:context inRect:
            bubbleRect pointAt:CGPointMake(screenX, screenY + 10)
            withColor:OV_BUBBLE_COLOR];
        
        NSDictionary *attrs = @{NSFontAttributeName:small,
            NSForegroundColorAttributeName:[UIColor whiteColor]};
        CGSize size = [OV_BUBBLE_TEXT sizeWithAttributes:attrs];
        [OV_BUBBLE_TEXT drawAtPoint:CGPointMake(screenX - roundf(size.width) / 2, screenY + 17)
                     withAttributes:attrs];
    }
    CGContextRestoreGState(context);
}

- (void)drawBbtInContext:(CGContextRef)context inRect:(CGRect)rect
    withKnots:(NSArray*)knots inRangeX:(ChartRange)rangeX
    rangeY:(ChartRange)rangeY {
    
    CGColorRef color = TEMP_CURVE_COLOR.CGColor;
    [self _drawCurveWithColor:color andKnots:knots
        withColor:color inRect:rect
        inRangeX:rangeX rangeY:rangeY inContext:context];
}

- (void)drawWeightInContext:(CGContextRef)context inRect:(CGRect)rect
    withKnots:(NSArray*)knots inRangeX:(ChartRange)rangeX
    rangeY:(ChartRange)rangeY {
    
    BOOL isMockThumb = self.isMockData && self.state == ChartSegmentStateThumb;
    CGColorRef color = isMockThumb ? UIColorFromRGB(0xe2f1d5).CGColor : WEIGHT_CURVE_COLOR.CGColor;
    
    [self _drawCurveWithColor:color andKnots:knots
        withColor:color inRect:rect
        inRangeX:rangeX rangeY:rangeY inContext:context];
}

- (void)drawCalorieInContext:(CGContextRef)context inRect:(CGRect)rect
    withKnots:(NSArray*)knots inRangeX:(ChartRange)rangeX
    rangeY:(ChartRange)rangeY withColor:(UIColor *)color {

    [self _drawCurveWithColor:color.CGColor andKnots:knots
        withColor:color.CGColor inRect:rect
        inRangeX:rangeX rangeY:rangeY inContext:context];
}


- (void)drawCalorieInContext:(CGContextRef)context inRect:(CGRect)rect
    withInKnots:(NSArray*)iKnots andOutKnots:(NSArray *)oKnots
    inRangeX:(ChartRange)rangeX rangeY:(ChartRange)rangeY {
    
    BOOL isMockThumb = self.isMockData && self.state == ChartSegmentStateThumb;
    UIColor *inColor = isMockThumb ? UIColorFromRGB(0xfee8cd) : CALORIE_IN_CURVE_COLOR;
    UIColor *outColor = isMockThumb ? UIColorFromRGB(0xe2f1d5) : CALORIE_OUT_CURVE_COLOR;
    
    [self drawCalorieInContext:context inRect:rect withKnots:iKnots
        inRangeX:rangeX rangeY:rangeY withColor:inColor];
    [self drawCalorieInContext:context inRect:rect withKnots:oKnots
        inRangeX:rangeX rangeY:rangeY withColor:outColor];
    
}

- (void)_baseLineNameTestInRect:(CGRect)rect withBg:(NSArray *)bg
    inRange:(ChartRange)rangeX{
    baseLineNameRect = CGRectZero;
//    baseLineNameLeft = baseLineNameRight = baseLineNameY = -9999;
    float gridH = rect.size.height / GRID_DIVIDER;
    if (CHART_DATA_TYPE_TEMP == self.chartDataType) {
        NSRange screenR = NSMakeRange(rangeX.start, rangeX.length - 2);
        for (NSInteger i = 0; i < [bg count]; i++) {
            NSRange cycleR = NSMakeRange([bg[i][@"pb"] intValue],
                [bg[i][@"cl"] intValue]);
            NSRange intersect = NSIntersectionRange(cycleR, screenR);
            if (intersect.length <= 0) {
                continue;
            }
            if (cycleR.location > screenR.location + screenR.length) {
                break;
            }
            CGFloat coverLine = [bg[i][@"cover_line"] floatValue];
            if (coverLine > 0) {
                float r = MIN(xValueToScreen(cycleR.location + cycleR.length,
                    rect, rangeX), rect.size.width) - 2;
                float y = yValueToScreen([bg[i][@"cover_line"] floatValue],
                    rect, self.temperatureRangeY);
                baseLineNameRect.origin = (CGPoint){r - 55, y - gridH / 2.f};
                baseLineNameRect.size = (CGSize){55, gridH};
            }
        }
    }
    else if (CHART_DATA_TYPE_CALORIE == self.chartDataType) {
        if (self.recommendedIntake < 0) {
            return;
        }
        float y = yValueToScreen(self.recommendedIntake, rect,
            self.calorieRangeY);
        float r = rect.size.width;
        baseLineNameRect.origin = (CGPoint){r - 108, y - gridH / 2.f};
        baseLineNameRect.size = (CGSize){108, gridH};
    }
}

- (void)_drawBaseLineInContext:(CGContextRef)context inRect:(CGRect)rect
    withBg:(NSArray *)bg inRangeX:(ChartRange)rangeX RangeY:(ChartRange)rangY
{
    if (baseLineNameRect.size.width <= 0 || baseLineNameRect.size.height <= 0) {
        return;
    }
    
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, PERIOD_TEXT_COLOR.CGColor);
    if (CHART_DATA_TYPE_TEMP == self.chartDataType) {
        NSRange screenR = NSMakeRange(rangeX.start, rangeX.length - 2);
        for (NSInteger i = 0; i < [bg count]; i++) {
            NSRange cycleR = NSMakeRange([bg[i][@"pb"] intValue],
                [bg[i][@"cl"] intValue]);
            NSRange intersect = NSIntersectionRange(cycleR, screenR);
            if (intersect.length <= 0) {
                continue;
            }
            if (cycleR.location > screenR.location + screenR.length) {
                break;
            }
            CGFloat coverLine = [bg[i][@"cover_line"] floatValue];
            if (coverLine > 0) {
                CGFloat screenL = xValueToScreen(intersect.location, rect,
                    rangeX);
                CGFloat screenW = MIN(baseLineNameRect.origin.x,
                    xValueToScreen(cycleR.location + cycleR.length,
                    rect, rangeX)) - screenL;
                CGContextFillRect(context, (CGRect){{screenL,
                    yValueToScreen([bg[i][@"cover_line"] floatValue], rect,
                    self.temperatureRangeY)},
                    {screenW, 1}});
            }
        }
        
        NSDictionary *attrs = [self italicFontAttrWithColor:PERIOD_TEXT_COLOR];
        CGSize size = [COVER_LINE_TEXT sizeWithAttributes:attrs];
        CGPoint point = CGPointMake(baseLineNameRect.origin.x + baseLineNameRect.size.width / 2 - size.width / 2,
                                    baseLineNameRect.origin.y + baseLineNameRect.size.height / 2 - size.height / 2);
        [COVER_LINE_TEXT drawAtPoint:point withAttributes:attrs];
    }
    else if (CHART_DATA_TYPE_CALORIE == self.chartDataType) {
        CGContextFillRect(context, (CGRect){
            {0, baseLineNameRect.origin.y + baseLineNameRect.size.height / 2},
            {baseLineNameRect.origin.x, 1}});
        
        NSDictionary *attrs = [self italicFontAttrWithColor:PERIOD_TEXT_COLOR];
        CGSize size = [RECOMMENDED_INTAKE_TEXT sizeWithAttributes:attrs];
        CGPoint point = CGPointMake(baseLineNameRect.origin.x + baseLineNameRect.size.width / 2 - size.width / 2,
                                    baseLineNameRect.origin.y + baseLineNameRect.size.height / 2 - size.height / 2);
        [RECOMMENDED_INTAKE_TEXT drawAtPoint:point withAttributes:attrs];
    }
    CGContextRestoreGState(context);
}

- (void)drawBgInContext:(CGContextRef)context inRect:(CGRect)rect
    withBg:(NSArray*)bg inRange:(ChartRange)rangeX
{
    CGContextSaveGState(context);
    
    [self _baseLineNameTestInRect:rect withBg:bg inRange:rangeX];
    
    
    // draw fertile window
    if (self.chartDataType == CHART_DATA_TYPE_TEMP || [User currentUser].isPrimaryOrSingle) {
        NSInteger count = [bg count];
        CGFloat rangeLeft = rangeX.start;
        CGFloat rangeRight = rangeX.start + rangeX.length;

        for (NSInteger i = 0; i < count; i++) {
            NSInteger l = [bg[i][@"fb"] integerValue];
            NSInteger r = [bg[i][@"fe"] integerValue];
            BOOL hasFertile = [bg[i][@"hasFertile"] boolValue];
            if (hasFertile &&
                ((l >= rangeLeft && l < rangeRight) ||
                 (r > rangeLeft && r <= rangeRight) ||
                 (rangeLeft >= l && rangeLeft < r) ||
                 (rangeRight > l && rangeRight <= r))) {
                    
                    CGFloat screenX = xValueToScreen(l, rect, rangeX);
                    CGFloat screenW = xValueToScreen(r, rect, rangeX) - screenX;
                    CGContextSetFillColorWithColor(context,
                                                   FERTILE_WINDOW_COLOR.CGColor);
                    CGContextFillRect(context, CGRectMake(screenX, rect.origin.y,
                                                          screenW, rect.size.height));
                    
                    NSString *text = FERTILE_WINDOW_TEXT;
                    NSDictionary *attrs = [self italicFontAttrWithColor:FERTILE_WINDOW_TEXT_COLOR];
                    CGSize size = [text sizeWithAttributes:attrs];
                    CGPoint point = CGPointMake(screenX + 0.5f * (screenW - size.width),
                                                rect.origin.y + BG_TEXT_SPACER - size.height / 2);
                    [text drawAtPoint:point withAttributes:attrs];
                }
            
            l = [bg[i][@"pb"] integerValue];
            r = [bg[i][@"pe"] integerValue];
            
            if ((l >= rangeLeft && l < rangeRight) ||
                (r > rangeLeft && r <= rangeRight) ||
                (rangeLeft >= l && rangeLeft < r) ||
                (rangeRight > l && rangeRight <= r)) {
                
                CGFloat screenX = xValueToScreen(l, rect, rangeX);
                CGFloat screenW = xValueToScreen(r, rect, rangeX) - screenX;
                CGContextSetFillColorWithColor(context, PERIOD_COLOR.CGColor);
                CGContextFillRect(context, CGRectMake(screenX, rect.origin.y,
                                                      screenW, rect.size.height));
                
                NSDictionary *attrs = [self italicFontAttrWithColor:PERIOD_TEXT_COLOR];
                CGSize size = [PERIOD_TEXT sizeWithAttributes:attrs];
                CGPoint point = CGPointMake(screenX + 0.5f * (screenW - size.width),
                                            rect.origin.y + BG_TEXT_SPACER - size.height / 2);
                [PERIOD_TEXT drawAtPoint:point withAttributes:attrs];
            }
            
            if (CHART_DATA_TYPE_TEMP == self.chartDataType) {
                r = [bg[i][@"pb"] intValue] + [bg[i][@"cl"] intValue];
                if (((l >= rangeLeft && l < rangeRight - 3) ||
                     (r > rangeLeft && r <= rangeRight - 3) ||
                     (rangeLeft >= l && rangeLeft < r) ||
                     (rangeRight - 3 > l && rangeRight - 3 <= r)) &&
                    [bg[i][@"cover_line"] floatValue] > 0) {
                    
                }
            }
        }

    }
    
 
    CGContextSetFillColorWithColor(context, GRID_COLOR.CGColor);
    CGFloat startY = rect.origin.y;
    CGFloat intervalY = rect.size.height / GRID_DIVIDER;
    CGFloat startX = xValueToScreen(floor(rangeX.start), rect, rangeX);
    CGFloat intervalX =xValueToScreen(floor(rangeX.start) + 1, rect, rangeX) -
        startX;
    CGPoint noGridArea = [self noGridAreaInRect:rect];
    CGFloat noGridT = noGridArea.x;
    CGFloat noGridB = noGridArea.y;
    CGFloat firstCutX = 9999, lastCutX = -9999;
    for (NSInteger j = 0; j < self.rangeX.length + 1; j++) {
        CGFloat screenX = startX + intervalX * j;
        if (screenX < baseLineNameRect.origin.x ||
            screenX > baseLineNameRect.origin.x + baseLineNameRect.size.width) {
            CGContextFillRect(context, CGRectMake(screenX, rect.origin.y,
                1, rect.size.height));
        }
        else {
            if (firstCutX > rect.size.width) {
                firstCutX = screenX - intervalX;
            }
            lastCutX = screenX + intervalX;
            CGContextFillRect(context, CGRectMake(screenX, rect.origin.y,
                1, noGridT));
            CGContextFillRect(context, CGRectMake(screenX, noGridB,
                1, rect.size.height - noGridB));
        }
    }
    
    // draw horizontal lines with offset
    CGFloat offsetY = floor(fmodf(self.tempOffset, intervalY));
    for (NSInteger i = 0; i <= GRID_DIVIDER; i++) {
        CGFloat y = startY + i * intervalY + offsetY;
        if (y > noGridT && y < noGridB) {
            CGContextFillRect(context, (CGRect){{0, y}, {firstCutX, 1}});
            CGContextFillRect(context, (CGRect){{lastCutX, y}, {rect.size.width - lastCutX, 1}});
        }
        else {
            CGContextFillRect(context, (CGRect){{0, y}, {rect.size.width, 1}});
        }
    }
    
    [self _drawBaseLineInContext:context inRect:rect withBg:self.bg
        inRangeX:rangeX RangeY:self.temperatureRangeY];
    
    CGContextRestoreGState(context);
}

- (void)drawSexBubblesInContext:(CGContextRef)context inRect:(CGRect)rect
    withSex:(ChartPoints *)sexes inRangeX:(ChartRange)rangeX{
    for (NSInteger i = rangeX.start - 1; i < rangeX.start + rangeX.length + 1; i++) {
        ChartPoint *sexCp = [sexes for:i];
        if (!sexCp || sexCp.y < 1) {
            continue;
        }
        CGFloat screenX = xValueToScreen(i, rect, rangeX);
        CGRect sexRect = CGRectMake(screenX - 6,
            rect.origin.y + rect.size.height * (11.f / 12.f) - 8, 13, 13);
        [sexSymbol drawInRect:sexRect];
    }

}

- (void)_drawBubbleInContext:(CGContextRef)context inRect:(CGRect)rect
    pointAt:(CGPoint)pointer withColor:(UIColor*)color{
    CGContextSaveGState(context);
    CGFloat l = rect.origin.x;
    CGFloat t = rect.origin.y;
    CGFloat r = l + rect.size.width;
    CGFloat b = t + rect.size.height;
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGFloat radius = rect.size.height / 5.;
    CGContextMoveToPoint(context, l, t + radius);
    //left
    CGContextAddLineToPoint(context, l, b - radius);
    //bottom left
    CGContextAddArc(context, l + radius, b - radius, radius, M_PI, M_PI / 2, 1);
    //bottom
    CGContextAddLineToPoint(context, r - radius, b);
    //bottom right
    CGContextAddArc(context, r - radius, b - radius, radius, M_PI / 2, 0.0f, 1);
    //right
    CGContextAddLineToPoint(context, r, t + radius);
    //top right
    CGContextAddArc(context, r - radius, t + radius, radius, 0.0f, -M_PI / 2, 1);
    //top
    CGContextAddLineToPoint(context, l + radius, t);
    //top left
    CGContextAddArc(context, l + radius, t + radius, radius, -M_PI / 2, M_PI, 1);
    CGContextFillPath(context);
    
    CGFloat pX = pointer.x;
    CGFloat pY = pointer.y;
    if (pY < t) {
        CGContextMoveToPoint(context, pX, pY);
        CGContextAddLineToPoint(context, pX - (pY - t), t + 1);
        CGContextAddLineToPoint(context, pX + (pY - t), t + 1);
        CGContextAddLineToPoint(context, pX, pY);
    }
    else if (pY > b) {
        CGContextMoveToPoint(context, pX, pY);
        CGContextAddLineToPoint(context, pX - (pY - b), b - 1);
        CGContextAddLineToPoint(context, pX + (pY - b), b - 1);
        CGContextAddLineToPoint(context, pX, pY);
    }
    CGContextFillPath(context);

    CGContextRestoreGState(context);
}

- (void)drawDatesInContext:(CGContextRef)context inRect:(CGRect)rect inRangeX:(ChartRange)rangeX rangeY:(ChartRange)rangeY
{
    CGFloat datesBackgroundStart = rect.size.height * GRID_AREA_HEIGHT_2_WHOLE;
    CGFloat datesBackgroundHeight = rect.size.height - datesBackgroundStart;
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, datesBackgroundStart, rect.size.width, datesBackgroundHeight));
    
    CGFloat gridH = rect.size.height / 24.f;
    CGFloat dateY = rect.origin.y + rect.size.height - gridH * 2 * 0.7f;
    CGFloat cdY = rect.origin.y + rect.size.height - gridH * 2 * 0.3f;
    CGContextSetFillColorWithColor(context, DATE_COLOR.CGColor);
    for (NSInteger i = self.rangeX.start - 1; i <= self.rangeX.start + self.rangeX.length + 1; i++) {
        CGFloat screenX = xValueToScreen(i, rect, rangeX);
        NSString *text = [Utils dateIndexToShortDateLabelFrom20130101:i];
        
        NSDictionary *attrs = @{NSFontAttributeName:small};
        CGSize size = [text sizeWithAttributes:attrs];
        CGPoint point = CGPointMake(screenX - size.width * 0.5f,
                                    dateY - size.height / 2);
        [text drawAtPoint:point withAttributes:attrs];
        
        // only draw cd in x-axis for cycle chart or mom
        if (self.chartDataType == CHART_DATA_TYPE_TEMP || [User currentUser].isPrimaryOrSingle) {
            NSInteger cd = [self getCdForDateIdx:i];
            if (cd <= 0) {
                continue;
            }
            
            text = catstr(@"CD", [@(cd) stringValue], nil);
            size = [text sizeWithAttributes:attrs];
            point = CGPointMake(screenX - size.width * 0.5f,
                                cdY - size.height / 2);
            [text drawAtPoint:point withAttributes:attrs];
        }
    }

}

- (void)drawThumbBubbleInContext:(CGContextRef)context inRect:(CGRect)rect
    pointAt:(CGPoint)pointer{
    
    NSString *markdownString = nil;
    if (self.isTtc) {
        CGFloat temp = self.inCelsius
            ? self.todayPointInThumb.y
            : [Utils fahrenheitFromCelcius:self.todayPointInThumb.y];
        NSString *tempFormat = self.inCelsius ? @"**Today: **%f℃"
            : @"**Today: **%f℉";
        markdownString = self.todayPointInThumb.alpha < 0
            ? @"**Today: **--"
            : [Utils stringWithFloatOfTwoToZeroDecimal:tempFormat float:temp];
    }
    else {
        BOOL useMetricUnit = [[Utils getDefaultsForKey:kUnitForWeight]
            isEqualToString:UNIT_KG];
        CGFloat weight = useMetricUnit
            ? self.todayPointInThumb.y
            : [Utils poundsFromKg:self.todayPointInThumb.y];
        NSString *weightFormat = [NSString stringWithFormat:@"**Today: **%%f%@",
            useMetricUnit ? UNIT_KG : UNIT_LB];
        markdownString = self.todayPointInThumb.alpha < 0
            ? @"**Today: **--"
            : [Utils stringWithFloatOfOneOrZeroDecimal:weightFormat float:weight];
    }
    
    if (self.chartDataType == CHART_DATA_TYPE_CALORIE) {
        NSString *intakes = @"--";
        NSString *burned = @"--";
        if (!self.isMockData) {
            NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
            for (NSInteger i = self.calorieInKnots.count-1; i >= 0; i--) {
                ChartPoint *point = (ChartPoint *)self.calorieInKnots[i];
                // today
                if ((int)point.x == (int)todayIndex) {
                    intakes = [NSString stringWithFormat:@"%dCAL",(int)point.y];
                    break;
                }
            }
            for (NSInteger i = self.calorieOutKnots.count-1; i >= 0; i--) {
                ChartPoint *point = (ChartPoint *)self.calorieOutKnots[i];
                // today
                if ((int)point.x == (int)todayIndex) {
                    burned = [NSString stringWithFormat:@"%dCAL",(int)point.y];
                    break;
                }
            }
        }
        markdownString = [NSString stringWithFormat:@"**Intake: **%@\n**Burned: **%@",intakes,burned];
    }
    
    NSAttributedString *text = [Utils markdownToAttributedText:markdownString
        fontSize:12 color:[UIColor whiteColor]];
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGSize size = [text size];
    
    // alter position according to text size
    rect.size.width = size.width + 10;
    rect.origin.x = self.width - rect.size.width - 10;
    
    [self _drawBubbleInContext:context inRect:rect pointAt:pointer withColor:
     THUMB_BUBBLE_COLOR];

    [text drawAtPoint:CGPointMake(rect.origin.x +
        (rect.size.width - size.width) * 0.5f,
        rect.origin.y + (rect.size.height - size.height) * 0.5f)];
}

#pragma mark - helper
- (NSInteger)getCdForDateIdx:(NSInteger)dateIdx {
    for (NSInteger i = 0; i < [allPbs count]; i++) {
        if (dateIdx >= [allPbs[i] intValue] &&
            dateIdx < [allPbs[i] intValue] + [allCls[i] intValue]) {
            return dateIdx - [allPbs[i] intValue] + 1;
        }
    }
    return -1;
}

- (NSInteger)getOvulationForDateIndex:(NSInteger)dateIndex
{
    if (allOvulationDates.count == 0) {
        return -1;
    }
    
    for (NSInteger i = 0; i < allOvulationDates.count-1; i++) {
        if (dateIndex >= [allOvulationDates[i] intValue] &&
            dateIndex < [allPbs[i+1] intValue]) {
            return dateIndex - [allOvulationDates[i] intValue];
        }
    }
    return -1;
}

- (NSNumber *)getPbBetweenStart:(NSInteger)start toEnd:(NSInteger)end {
    for (NSInteger i = 0; i < [allPbs count]; i++) {
        if (end > [allPbs[i] intValue] &&
            start < [allPbs[i] intValue]) {
            return allPbs[i];
        }
    }
    return nil;
}

- (NSArray *)getCdsForRange:(ChartRange)range {
    NSMutableArray *result = [@[] mutableCopy];
    NSRange r = NSMakeRange(range.start, range.length + 1);
    for (NSInteger i = 0; i < [allPbs count]; i++) {
        NSRange cycle = NSMakeRange([allPbs[i] intValue],
            [allCls[i] intValue] - 1);
        NSRange intersect = NSIntersectionRange(cycle, r);
        if (intersect.length <= 0) {
            continue;
        }
        for (NSInteger j = 0; j < intersect.length; j++) {
            [result addObject:@(intersect.location + j - cycle.location + 1)];
        }
    }
    return result;
}

- (CGPoint)noGridAreaInRect:(CGRect)rect {
    if (baseLineNameRect.size.width <= 0 || baseLineNameRect.size.height <= 0) {
        return CGPointZero;
    }
    float gridH = rect.size.height / GRID_DIVIDER, t = 0, b = rect.size.height;
    for (NSInteger i = 1; i <= GRID_DIVIDER; i++) {
        float gridY = rect.origin.y + i * gridH;
        if (gridY <= baseLineNameRect.origin.y) {
            t = gridY;
        }
        if (gridY >= baseLineNameRect.origin.y + baseLineNameRect.size.height) {
            b = gridY;
            break;
        }
    }
    return (CGPoint){t, b};
}

- (CGRect)getBaseLineNameRect {
    return baseLineNameRect;
}

- (NSDictionary *)italicFontAttrWithColor:(UIColor *)color {
    if (nil == color) {
        color = [UIColor blackColor];
    }
    if (italicSmall) {
        return @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Italic" size:9],
            NSForegroundColorAttributeName:color};
    } else {
        return @{NSForegroundColorAttributeName:color};
    }
}


@end



