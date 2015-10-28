//
//  StartupPageControl.m
//  emma
//
//  Created by Xin Zhao on 13-12-2.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "StartupPageControl.h"

@interface StartupPageControl()

@property (nonatomic) NSUInteger dotSize;
@end

@implementation StartupPageControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.tintColor = [UIColor colorWithRed:164/255.0 green:164/255.0 blue:228/255.0 alpha:1];
//        self.pageIndicatorTintColor = [UIColor colorWithRed:164/255.0 green:164/255.0 blue:228/255.0 alpha:1];
        self.pageIndicatorTintColor = [UIColor colorWithRed:105/255.0 green:114/255.0 blue:205/255.0 alpha:1];
        self.dotSize = 12;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
*/
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGFloat intervalW = (self.frame.size.width - 2 - self.numberOfPages * self.dotSize) / (self.numberOfPages - 1);
    CGFloat y = (self.frame.size.height - self.dotSize) * 0.5f;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    
    CGContextSetFillColorWithColor(context, self.pageIndicatorTintColor.CGColor);
    CGContextSetStrokeColorWithColor(context, self.pageIndicatorTintColor.CGColor);
    for (int i = 0; i <= self.numberOfPages; i++) {
        CGFloat x = (intervalW + self.dotSize) * i + 1;
        if (i != self.currentPage) {
            CGContextAddArc(context, x + self.dotSize * .5f, y + self.dotSize * .5f, self.dotSize * 0.5f, 0, 2 * M_PI, 1);
            CGContextStrokePath(context);
        }
        else {
            CGContextFillEllipseInRect(context, CGRectMake(x, y, self.dotSize, self.dotSize));
        }
    }
    for (UIView *dot in self.subviews) {
        [dot removeFromSuperview];
    }
}

/** override to update dots */
- (void) setCurrentPage:(NSInteger)currentPage
{
    [super setCurrentPage:currentPage];
    
    // update dot views
    [self setNeedsDisplay];
}

/** override to update dots */
- (void) updateCurrentPageDisplay
{
    [super updateCurrentPageDisplay];
    
    // update dot views
    [self setNeedsDisplay];
}

/** Override to fix when dots are directly clicked */
- (void) endTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    
    [self setNeedsDisplay];
}
@end
