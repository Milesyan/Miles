//
//  DayPointerEdgeView.m
//  emma
//
//  Created by Xin Zhao on 13-7-22.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "DayPointerEdgeView.h"

@interface DayPointerEdgeView (){
    CGFloat currentRotation;
}

@end

@implementation DayPointerEdgeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect
//{
//    // Drawing code
//    CGContextRef context = UIGraphicsGetCurrentContext();    CGContextSetLineCap(context, kCGLineCapRound);
//    CGContextSetLineWidth(context, 2);
//    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
//    if (self.leftUpToRightBottom) {
//        GLLog(@"draw edge %f - %f", rect.origin.x + 1, rect.origin.x + rect.size.width - 1);
//        CGContextMoveToPoint(context, rect.origin.x + 1, rect.origin.y);
//        CGContextAddLineToPoint(context, rect.origin.x + rect.size.width - 1, rect.origin.y + rect.size.height);
//    }
//    else {
//        GLLog(@"draw edge %f - %f", rect.origin.x + rect.size.width - 1, rect.origin.x + 1);
//        CGContextMoveToPoint(context, rect.origin.x + rect.size.width - 1, rect.origin.y);
//        CGContextAddLineToPoint(context, rect.origin.x + 1, rect.origin.y + rect.size.height);
//    }
//    //draw to this point
//    // and now draw the Path!
//    CGContextStrokePath(context);
//
//}

- (void) transformWithPoint:(CGPoint)basePoint andPoint:(CGPoint)anotherPoint {
    CGFloat dist = sqrtf(powf(anotherPoint.x - basePoint.x, 2) + powf(anotherPoint.y - basePoint.y, 2));
    CGFloat frameY = basePoint.y < anotherPoint.y ? basePoint.y : anotherPoint.y;
    CGFloat anchorY = basePoint.y < anotherPoint.y ? 0 : 1;
    
    self.transform = CGAffineTransformMakeRotation(0);
    self.frame = CGRectMake(basePoint.x - 0.5, frameY, 1, dist);
    self.layer.anchorPoint = CGPointMake(0.5, anchorY);
    CGFloat rotation = atanf((anotherPoint.x - basePoint.x) / (basePoint.y - anotherPoint.y));
    
    currentRotation = rotation;
    self.transform = CGAffineTransformMakeRotation(rotation);
}

- (CGAffineTransform) bounceTransformWithRotationMultiplier:(CGFloat)multiplier{
    return CGAffineTransformMakeRotation(multiplier * currentRotation);
}

- (CGFloat)offsetXWithY:(CGFloat)y andRotationMultiplier:(CGFloat)multiplier {
    CGFloat tan = tanf(currentRotation * multiplier);
    CGFloat x = y * tan;
    return x;
}

CGAffineTransform CGAffineTransformMakeRotationAt(CGFloat angle, CGPoint pt){
    const CGFloat fx = pt.x;
    const CGFloat fy = pt.y;
    const CGFloat fcos = cos(angle);
    const CGFloat fsin = sin(angle);
    return CGAffineTransformMake(fcos, fsin, -fsin, fcos, fx - fx * fcos + fy * fsin, fy - fx * fsin - fy * fcos);
}



@end
