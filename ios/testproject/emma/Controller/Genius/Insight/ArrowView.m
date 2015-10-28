//
//  ArrowView.m
//  emma
//
//  Created by Eric Xu on 2/13/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ArrowView.h"

@interface ArrowView(){
    NSArray *points;
    UIColor *filledColor;
}

@end

@implementation ArrowView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setArrowPoints:(NSArray *)_points {
    if (_points && [_points isKindOfClass:[NSArray class]] && [_points count] > 2) {
        points = [NSArray arrayWithArray:_points];
    } else {
        points = @[];
    }
}

- (void)setFilledColor:(UIColor *)color {
    filledColor = color;
    self.backgroundColor = [UIColor clearColor];
}

- (void) drawRect: (CGRect) rect {
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(currentContext);
    
    CGColorRef color = [filledColor CGColor];
    size_t numComponents = CGColorGetNumberOfComponents(color);
    CGFloat red, green, blue, alpha;
    const CGFloat *components = CGColorGetComponents(color);
    red = numComponents >= 1? components[0]: 1.0;
    green = numComponents >= 2?  components[1]: 1.0;
    blue =  numComponents >= 3? components[2]: 1.0;
    alpha =  numComponents >= 4? components[3]: 1.0;

    CGContextSetRGBFillColor(currentContext, red, green, blue, alpha);
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPoint p0 = [points[0] CGPointValue];
    CGPathMoveToPoint(pathRef, NULL, p0.x, p0.y);

    CGContextSetLineWidth(currentContext, 0.5);
    CGContextSetRGBStrokeColor(currentContext, red, green, blue, alpha);
    CGContextBeginPath(currentContext);

    for (int i = 0; i<[points count]; i++) {
        CGPoint p = [points[i] CGPointValue];
        CGPoint t = [points[(i+1) % [points count]] CGPointValue];

        CGPathAddLineToPoint(pathRef, NULL, t.x, t.y);

        CGContextMoveToPoint(currentContext, p.x, p.y);
        CGContextAddLineToPoint(currentContext, t.x, t.y);
        CGContextStrokePath(currentContext);
    }
    
    CGPathMoveToPoint(pathRef, NULL, p0.x, p0.y);
    CGContextAddPath(currentContext, pathRef);
    CGContextFillPath(currentContext);
    CGPathRelease(pathRef);

    CGContextRestoreGState(currentContext);
}

@end
