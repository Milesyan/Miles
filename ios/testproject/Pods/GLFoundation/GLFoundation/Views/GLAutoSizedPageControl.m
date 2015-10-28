//
//  ResizablePageControl.m
//  emma
//
//  Created by Xin Zhao on 7/30/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "GLAutoSizedPageControl.h"

@implementation GLAutoSizedPageControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (NSMutableArray *)getDotSizeCandidates {
    if (!_dotSizeCandidates) {
        _dotSizeCandidates = [@[] mutableCopy];
        [_dotSizeCandidates addObject:[NSValue valueWithCGSize:(CGSize){7, 9}]];
        [_dotSizeCandidates addObject:[NSValue valueWithCGSize:(CGSize){6, 7}]];
        [_dotSizeCandidates addObject:[NSValue valueWithCGSize:(CGSize){5, 5}]];
        [_dotSizeCandidates addObject:[NSValue valueWithCGSize:(CGSize){5, 4}]];
        [_dotSizeCandidates addObject:[NSValue valueWithCGSize:(CGSize){4, 3}]];
    }
    return _dotSizeCandidates;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
//    [super drawRect:rect];
    // test dot and space size from candidates
    CGSize dotSpaceSize;
    for (NSValue *size in [self getDotSizeCandidates]) {
        dotSpaceSize = [size CGSizeValue];
        if (self.frame.size.width - 4 >=
            self.numberOfPages * dotSpaceSize.width +
            (self.numberOfPages - 1) * dotSpaceSize.height) {
            break;
        }
    }
    
    CGFloat dotSize = dotSpaceSize.width;
    CGFloat intervalW = dotSpaceSize.height;
    CGFloat y = (self.frame.size.height - dotSize) * 0.5f;
    CGFloat startX = (self.frame.size.width - dotSize * self.numberOfPages -
        (self.numberOfPages - 1) * intervalW) / 2 + 2;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    
    CGContextSetFillColorWithColor(context, self.pageIndicatorTintColor.CGColor);
    for (int i = 0; i < self.numberOfPages; i++) {
        CGFloat x = startX + (intervalW + dotSize) * i + 1;
        if (i != self.currentPage) {
            CGContextFillEllipseInRect(context, CGRectMake(x, y, dotSize, dotSize));
        }
        else {
            CGContextSetFillColorWithColor(context, self.currentPageIndicatorTintColor.CGColor);
            CGContextFillEllipseInRect(context, CGRectMake(x, y, dotSize, dotSize));
            CGContextSetFillColorWithColor(context, self.pageIndicatorTintColor.CGColor);
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
