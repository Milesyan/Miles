//
//  GLLineChartRenderView.m
//  kaylee
//
//  Created by Allen Hsu on 12/5/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLLineChartRenderView.h"
#import "User.h"
#import "PeriodInfo.h"
#import "UserDailyData.h"
#import "User.h"

#define FERTILE_WINDOW_COLOR UIColorFromRGB(0xd0f8cb)
#define FERTILE_WINDOW_TEXT @"Fertile window"
#define FERTILE_WINDOW_TEXT_COLOR UIColorFromRGB(0x86ce7e)
#define FERTILE_WINDOW_FONT_SIZE 12
#define FERTILE_WINDOW_TEXT_RELATIVE_Y (1.f - 11.5f/12.f)
#define BG_TEXT_SPACER 16.f

#define PERIOD_COLOR UIColorFromRGB(0xeda8c3)
#define PERIOD_TEXT_COLOR UIColorFromRGB(0xE55A8C)
#define PERIOD_TEXT @"Period"


CG_INLINE CGFloat
xValueToScreen(CGFloat value, CGRect screen, GLLineChartRange range)
{
    return (CGFloat)(value - range.location) / range.length * screen.size.width;
}

bool GLLineChartRangeEqualToRange(GLLineChartRange range1, GLLineChartRange range2)
{
    return (range1.location == range2.location && range1.length == range2.length);
}

@implementation GLLineChartDot
@end

@implementation GLLineChartLineData
@end

@interface GLLineChartRenderView()
@property (nonatomic, strong) UIImage* sexSymbol;
@end

@implementation GLLineChartRenderView

+ (NSDictionary *)dateAttr
{
    static NSDictionary *sAttr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIFont *font = [Utils defaultFont:9];
        sAttr = @{NSFontAttributeName: font, NSForegroundColorAttributeName: DATE_COLOR};
    });
    return sAttr;
}

+ (NSDictionary *)labelAttr
{
    static NSDictionary *sAttr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIFont *font = [Utils lightFont:13.0];
        sAttr = @{NSFontAttributeName: font, NSForegroundColorAttributeName: LABEL_COLOR};
    });
    return sAttr;
}

- (UIImage *)sexSymbol
{
    if (!_sexSymbol) {
        _sexSymbol = [UIImage imageNamed:@"calendar-sex"];
    }
    return _sexSymbol;
}

- (void)drawRect:(CGRect)rect
{
    [self drawGrid:rect];
    [self drawIndicator:rect];
    [self drawLines:rect];
    [self drawLabels:rect];
    [self drawToday:rect];
}

- (void)drawToday:(CGRect)rect
{
    if (!self.showToday) {
        return;
    }
    
    if (self.todayString.length <= 0) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    NSString *markdownString = self.todayString.length > 0 ? self.todayString : @"**Today: **--";
    NSAttributedString *text = [Utils markdownToAttributedText:markdownString
        fontSize:12 color:[UIColor whiteColor]];
    CGSize size = [text size];
    
    CGRect todayRect = CGRectMake(self.width - size.width - 20.0, 5.0, size.width + 10.0, size.height + 6.0);
    if (self.todayDot) {
        // draw triangle
        CGFloat dayWidth = self.width / self.range.length;
        CGFloat diffY = (self.height - GRID_X_LABEL_HEIGHT) / GRID_NUM_Y_AXIS;
        CGFloat diffValue = (self.maxValue - self.minValue) / (GRID_NUM_Y_AXIS - 2);
        CGFloat x = dayWidth * (self.todayDot.dateIndex - self.range.location);
        CGFloat y = (self.maxValue - self.todayDot.value) / diffValue * diffY + diffY;
        
        if (y >= self.height / 2.0) {
            // above
            y -= (TODAY_TRIANGLE_HEIGHT + 2.0);
            CGContextMoveToPoint(context, x - TODAY_TRIANGLE_HEIGHT, y - TODAY_TRIANGLE_HEIGHT);
            CGContextAddLineToPoint(context, x, y);
            CGContextAddLineToPoint(context, x + TODAY_TRIANGLE_HEIGHT, y - TODAY_TRIANGLE_HEIGHT);
            CGContextClosePath(context);
            CGContextSetFillColorWithColor(context, INDICATOR_COLOR.CGColor);
            CGContextFillPath(context);
            
            todayRect.origin.y = ceilf(y - TODAY_TRIANGLE_HEIGHT - todayRect.size.height);
        } else {
            // below
            y += (TODAY_TRIANGLE_HEIGHT + 2.0);
            CGContextMoveToPoint(context, x - TODAY_TRIANGLE_HEIGHT, y + TODAY_TRIANGLE_HEIGHT);
            CGContextAddLineToPoint(context, x, y);
            CGContextAddLineToPoint(context, x + TODAY_TRIANGLE_HEIGHT, y + TODAY_TRIANGLE_HEIGHT);
            CGContextClosePath(context);
            CGContextSetFillColorWithColor(context, INDICATOR_COLOR.CGColor);
            CGContextFillPath(context);
            
            todayRect.origin.y = floorf(y + TODAY_TRIANGLE_HEIGHT);
        }
    }
    
    CGContextSetFillColorWithColor(context, INDICATOR_COLOR.CGColor);
    [self drawRect:todayRect withCornerRadius:3.0 inContext:context];
    
    [text drawAtPoint:CGPointMake(todayRect.origin.x +
        (todayRect.size.width - size.width) * 0.5f,
        todayRect.origin.y + (todayRect.size.height - size.height) * 0.5f)];
    CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)rect withCornerRadius:(CGFloat)radius inContext:(CGContextRef)context
{
    CGFloat l = rect.origin.x;
    CGFloat t = rect.origin.y;
    CGFloat r = l + rect.size.width;
    CGFloat b = t + rect.size.height;
    
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
}

- (void)drawLines:(CGRect)rect
{
    if (!self.showLines && !self.showDots) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGFloat dayWidth = self.width / self.range.length;
    CGFloat diffY = (self.height - GRID_X_LABEL_HEIGHT) / GRID_NUM_Y_AXIS;
    CGFloat diffValue = (self.maxValue - self.minValue) / (GRID_NUM_Y_AXIS - 2);
    CGFloat bubbleRadius = dayWidth / 4.0;
    bubbleRadius = MIN(MAX(4.0, bubbleRadius), BUBBLE_RADIUS);
    CGFloat lineWidth = bubbleRadius / 4.0;
    lineWidth = MIN(MAX(1.0, lineWidth), CHART_LINE_WIDTH);
    NSNumber *todayMinY = nil;
    NSMutableArray *todayPoints = [NSMutableArray array];
    for (GLLineChartLineData *data in self.data) {
        GLLineChartDot *prevDot = nil;
        NSNumber *todayY = nil;
        // draw lines
        for (GLLineChartDot *dot in data.dots) {
            CGFloat x2 = dayWidth * (dot.dateIndex - self.range.location);
            CGFloat y2 = (self.maxValue - dot.value) / diffValue * diffY + diffY;
            if (roundf(x2) == roundf(self.indicatorOffsetX)) {
                todayY = @(y2);
            }
            if (prevDot) {
                CGFloat x1 = dayWidth * (prevDot.dateIndex - self.range.location);
                CGFloat y1 = (self.maxValue - prevDot.value) / diffValue * diffY + diffY;
                BOOL needDrawLine = (((x1 + bubbleRadius >= 0.0) && (x1 - bubbleRadius <= self.width)) ||
                                     ((x2 + bubbleRadius >= 0.0) && (x2 - bubbleRadius <= self.width)) ||
                                     ((x1 + bubbleRadius <= 0.0) && (x2 - bubbleRadius >= self.width)) ||
                                     ((x2 + bubbleRadius <= 0.0) && (x1 - bubbleRadius >= self.width)));
                if (needDrawLine) {
                    CGContextMoveToPoint(context, x1, y1);
                    CGContextAddLineToPoint(context, x2, y2);
                    CGContextSetStrokeColorWithColor(context, data.lineColor.CGColor);
                    CGContextSetLineWidth(context, lineWidth);
                    CGContextSetLineCap(context, kCGLineCapRound);
                    CGContextStrokePath(context);
                    if (!todayY && roundf(x1) <= roundf(self.indicatorOffsetX) && roundf(x2) >= roundf(self.indicatorOffsetX)) {
                        todayY = @((y2 - y1) / (roundf(x2) - roundf(x1)) * (roundf(self.indicatorOffsetX) - roundf(x1)) + y1);
                    }
                }
            }
            prevDot = dot;
        }
        // draw dots
        if (self.showDots) {
            for (GLLineChartDot *dot in data.dots) {
                CGFloat x = dayWidth * (dot.dateIndex - self.range.location);
                if ((x + bubbleRadius >= 0.0) && (x - bubbleRadius <= self.width)) {
                    CGFloat y = (self.maxValue - dot.value) / diffValue * diffY + diffY;
                    CGRect rect = CGRectMake(x - bubbleRadius, y - bubbleRadius, bubbleRadius * 2, bubbleRadius * 2);
                    CGContextAddEllipseInRect(context, rect);
                    CGContextSetFillColorWithColor(context, data.dotColor.CGColor);
                    CGContextFillPath(context);
                }
            }
        }
        // draw today indicator
        if (todayY && self.showIndicator) {
            if (!todayMinY || [todayY floatValue] < [todayMinY floatValue]) {
                todayMinY = todayY;
            }
            CGPoint p = CGPointMake(self.indicatorOffsetX, [todayY floatValue]);
            [todayPoints addObject:@{@"color": data.dotColor, @"point": [NSValue valueWithCGPoint:p]}];
        }
    }
    if (todayPoints.count > 0 && self.showIndicator) {
        CGContextSetFillColorWithColor(context, INDICATOR_COLOR.CGColor);
        CGContextFillRect(context, CGRectMake(self.indicatorOffsetX - 1.0, [todayMinY floatValue], 2.0, self.height - [todayMinY floatValue]));
        for (NSDictionary *dict in todayPoints) {
            UIColor *color = dict[@"color"] ?: GLOW_COLOR_GREEN;
            CGPoint p = [dict[@"point"] CGPointValue];
            CGRect rect1 = CGRectMake(self.indicatorOffsetX - bubbleRadius - 3.0, p.y - bubbleRadius - 3.0, (bubbleRadius + 3.0) * 2, (bubbleRadius + 3.0) * 2);
            CGRect rect2 = CGRectMake(self.indicatorOffsetX - bubbleRadius, p.y - bubbleRadius, bubbleRadius * 2, bubbleRadius * 2);
            CGContextAddEllipseInRect(context, rect1);
            CGContextSetFillColorWithColor(context, INDICATOR_COLOR.CGColor);
            CGContextFillPath(context);
            CGContextAddEllipseInRect(context, rect2);
            CGContextSetFillColorWithColor(context, color.CGColor);
            CGContextFillPath(context);
        }
    }
    CGContextRestoreGState(context);
}

- (void)drawIndicator:(CGRect)rect
{
    if (!self.showIndicator) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextMoveToPoint(context, self.indicatorOffsetX - INDICATOR_HEIGHT, self.height);
    CGContextAddLineToPoint(context, self.indicatorOffsetX, self.height - INDICATOR_HEIGHT);
    CGContextAddLineToPoint(context, self.indicatorOffsetX + INDICATOR_HEIGHT, self.height);
    CGContextClosePath(context);
    CGContextSetFillColorWithColor(context, INDICATOR_COLOR.CGColor);
    CGContextFillPath(context);
    CGContextRestoreGState(context);
}

- (void)drawGrid:(CGRect)rect
{
    if (!self.showGrid) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    int minX = floorf(self.range.location) - 7;
    int maxX = ceilf(self.range.location + self.range.length) + 7;

    CGFloat diffX = self.width / self.range.length;
    CGFloat diffY = (self.height - GRID_X_LABEL_HEIGHT) / GRID_NUM_Y_AXIS;
    int step = 1;
    
    
    UIColor *gridColor = GRID_COLOR;
    NSDictionary *dateAttr = [[self class] dateAttr];
    CGFloat verticalLineHeight = diffY * GRID_NUM_Y_AXIS;
    CGFloat dateY = verticalLineHeight + 5.0;
    
    // draw fertile window
    if (self.showPeriodBg) {
        NSArray *bg = [[PeriodInfo sharedInstance] fertileWindows];
        NSInteger count = [bg count];
        CGFloat rangeLeft = minX;
        CGFloat rangeRight = maxX;
        
        GLLineChartRange rangeX = self.range;
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
                                                          screenW, verticalLineHeight));
                    
                    NSString *text = @"Fertile window";
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
                                                      screenW, verticalLineHeight));
                
                NSDictionary *attrs = [self italicFontAttrWithColor:PERIOD_TEXT_COLOR];
                CGSize size = [PERIOD_TEXT sizeWithAttributes:attrs];
                CGPoint point = CGPointMake(screenX + 0.5f * (screenW - size.width),
                                            rect.origin.y + BG_TEXT_SPACER - size.height / 2);
                [PERIOD_TEXT drawAtPoint:point withAttributes:attrs];
            }
            
            r = [bg[i][@"pb"] intValue] + [bg[i][@"cl"] intValue];
            if (((l >= rangeLeft && l < rangeRight - 3) ||
                    (r > rangeLeft && r <= rangeRight - 3) ||
                    (rangeLeft >= l && rangeLeft < r) ||
                    (rangeRight - 3 > l && rangeRight - 3 <= r)) &&
                [bg[i][@"cover_line"] floatValue] > 0) {
            }
            
        }
    }
    
    for (int i = 0; i <= GRID_NUM_Y_AXIS; ++i) {
        CGFloat y = i * diffY;
        CGContextSetFillColorWithColor(context, gridColor.CGColor);
        CGContextFillRect(context, CGRectMake(0.0, y, self.width, 1.0));
    }

    for (int i = minX; i < maxX; i += step) {
        
        CGFloat x = (i - self.range.location) * diffX;
        NSString *text = nil;
        NSString *cycleDay = nil;
        
        text = [Utils dateIndexToShortDateLabelFrom20130101:i];
        
        CGContextSetFillColorWithColor(context, gridColor.CGColor);
        CGContextFillRect(context, CGRectMake(x, 0.0, 1.0, verticalLineHeight));
        CGSize size = [text sizeWithAttributes:dateAttr];
        [text drawAtPoint:CGPointMake(x - size.width / 2.0, dateY) withAttributes:dateAttr];
        
        if (self.showCycleDay) {
            NSInteger cd = [[PeriodInfo sharedInstance] cycleDayForDateIndex:i];
            if (cd > 0) {
                cycleDay = [NSString stringWithFormat:@"CD%ld", (long)cd];
                size = [cycleDay sizeWithAttributes:dateAttr];
                [cycleDay drawAtPoint:CGPointMake(x - size.width / 2.0, dateY + 10.0) withAttributes:dateAttr];
            }
        }
        

        if ([self.symbols containsObject:[Utils dateIndexToDateLabelFrom20130101:i]]) {
            CGFloat sexSymbolSize = 13;
            [self.sexSymbol drawInRect:CGRectMake((x - sexSymbolSize / 2.0), verticalLineHeight - sexSymbolSize / 2, sexSymbolSize, sexSymbolSize)];
        }
    }
    
    CGContextRestoreGState(context);
}

- (void)drawLabels:(CGRect)rect
{
    if (!self.showGrid) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGFloat diffY = (self.height - GRID_X_LABEL_HEIGHT) / GRID_NUM_Y_AXIS;
    
    CGFloat diffValue = (self.maxValue - self.minValue) / (GRID_NUM_Y_AXIS - 2);
    NSDictionary *labelAttr = [[self class] labelAttr];
    
    for (int i = 0; i <= GRID_NUM_Y_AXIS; ++i) {
        CGFloat y = i * diffY;
        if (i % 2 == 1) {
            NSString *text = nil;
            CGFloat value = self.maxValue - diffValue * (i - 1);
            if (i == 1) {
                text = [NSString stringWithFormat:@"%0.0f %@", value, self.valueUnit];
            } else {
                text = [NSString stringWithFormat:@"%0.0f", value];
            }
            CGSize size = [text sizeWithAttributes:labelAttr];
            [text drawAtPoint:CGPointMake(10.0, y - size.height / 2.0) withAttributes:labelAttr];
        }
    }
    
    CGContextRestoreGState(context);
}

- (void)setIndicatorOffsetX:(CGFloat)indicatorOffsetX
{
    if (_indicatorOffsetX != indicatorOffsetX) {
        _indicatorOffsetX = indicatorOffsetX;
        [self setNeedsDisplay];
    }
}

- (void)setShowGrid:(BOOL)showGrid
{
    if (_showGrid != showGrid) {
        _showGrid = showGrid;
        [self setNeedsDisplay];
    }
}

- (void)setShowLines:(BOOL)showLines
{
    if (_showLines != showLines) {
        _showLines = showLines;
        [self setNeedsDisplay];
    }
}

- (void)setShowDots:(BOOL)showDots
{
    if (_showDots != showDots) {
        _showDots = showDots;
        [self setNeedsDisplay];
    }
}

- (void)setShowIndicator:(BOOL)showIndicator
{
    if (_showIndicator != showIndicator) {
        _showIndicator = showIndicator;
        [self setNeedsDisplay];
    }
}

- (void)setShowToday:(BOOL)showToday
{
    if (_showToday != showToday) {
        _showToday = showToday;
        [self setNeedsDisplay];
    }
}

- (void)setShowPeriodBg:(BOOL)showPeriodBg
{
    if (_showPeriodBg != showPeriodBg) {
        _showPeriodBg = showPeriodBg;
        [self setNeedsDisplay];
    }
}

- (void)setShowCycleDay:(BOOL)showCycleDay
{
    if (_showCycleDay != showCycleDay) {
        _showCycleDay = showCycleDay;
        [self setNeedsDisplay];
    }
}

- (void)setRange:(GLLineChartRange)range
{
    if (!GLLineChartRangeEqualToRange(_range, range)) {
        _range = range;
        [self setNeedsDisplay];
    }
}

- (void)setData:(NSArray *)data
{
    if (_data != data) {
        _data = data;
        [self setNeedsDisplay];
    }
}

- (NSDictionary *)italicFontAttrWithColor:(UIColor *)color {
    if (nil == color) {
        color = [UIColor blackColor];
    }
    return @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Italic" size:9],
                 NSForegroundColorAttributeName:color};
}


@end
