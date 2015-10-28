//
//  QuizPageControl.m
//  GLCommunity
//
//  Created by Allen Hsu on 8/17/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <GLFoundation/UIColor+Utils.h>
#import "QuizPageControl.h"

@implementation QuizPageControl

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self setNeedsDisplay];
}

- (void)setNumberOfPages:(NSInteger)numberOfPages {
    [super setNumberOfPages:numberOfPages];
    [self setNeedsDisplay];
}

- (void)setCurrentPage:(NSInteger)currentPage {
    [super setCurrentPage:currentPage];
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    if (self.numberOfPages < 1) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat dotSize = 10.0;
    CGFloat dotSpacing = 10.0;
    CGFloat dotDistance = dotSpacing + dotSize;
    CGFloat centerX = self.bounds.size.width / 2.0;
    CGFloat centerY = self.bounds.size.height / 2.0;
    CGFloat beginX = centerX - (self.numberOfPages - 1) / 2.0 * dotDistance;
    for (int i = 0; i < self.numberOfPages; ++i) {
        CGFloat x = beginX + dotDistance * i;
        if (i <= self.currentPage) {
            CGContextSetFillColorWithColor(context, UIColorFromRGB(0x5A62D2).CGColor);
        } else {
            CGContextSetFillColorWithColor(context, UIColorFromRGB(0xD8D8D8).CGColor);
        }
        CGRect ellipseRect = CGRectMake(x - dotSize / 2.0, centerY - dotSize / 2.0, dotSize, dotSize);
        CGContextFillEllipseInRect(context, ellipseRect);
    }
}

@end
