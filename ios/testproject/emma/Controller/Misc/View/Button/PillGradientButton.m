//
//  PillGradientButton.m
//  emma
//
//  Created by Xin Zhao on 13-4-3.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "PillGradientButton.h"
#import <UIKit/UIKit.h>


#define BORDER_WIDTH 1.0

@interface PillGradientButton() {
    UIImage *bgImage;
}

@end

@implementation PillGradientButton


- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        self.tintColor = self.currentTitleColor;
    }
    return self;
}


- (id)initWithFrame:(CGRect)rect color:(UIColor *)colorOne toColor:(UIColor *)colorTwo {
    self = [super initWithFrame:rect];
    if (self) {
        [self setupWithColor:colorOne toColor:colorTwo];
    }
    return self;
}


- (void)setupWithColor:(UIColor *)colorOne toColor:(UIColor *)colorTwo {
    [self setupColor:colorOne toColor:colorTwo];
}


- (void)setupColor:(UIColor *)colorOne toColor:(UIColor *)colorTwo {
    CGFloat radius = self.frame.size.height / 2;
    CGFloat height = self.frame.size.height;
    CGFloat width = self.frame.size.width;
    if (!bgImage) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width + 1 , height), NO, 0.0);
        CGFloat innerRadius = radius - BORDER_WIDTH;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, width + 1, height) cornerRadius: radius];
        [[UIColor lightGrayColor] setFill];
        [path fill];
        
        // Gradient Declarations
        // Draw rounded rectangle bezier path
        UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(1, 1, width - 1, height - 2 ) cornerRadius: innerRadius];
        // Use the bezier as a clipping path
        [roundedRectanglePath addClip];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        NSArray *gradientColors = (@[
                                   (id)colorOne.CGColor,
                                   (id)colorTwo.CGColor
                                   ]);
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)(gradientColors), NULL);
        CGContextRef context = UIGraphicsGetCurrentContext();
        // Draw gradient within the path
        CGContextDrawLinearGradient(context, gradient, CGPointMake(width - 1, 0), CGPointMake(width - 1, height - 1), 0);
        
        bgImage =  UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        bgImage = [bgImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, radius, 0, radius)];
    }
    CALayer *layer = self.layer;
    layer.shadowColor = [[UIColor blackColor] CGColor];
    layer.shadowOffset = CGSizeMake(0, 1.0);
    layer.shadowRadius = 1.0;
    layer.shadowOpacity = 0.15f;
    layer.shouldRasterize = YES;
    layer.rasterizationScale = [[UIScreen mainScreen] scale];
    [self setBackgroundImage:bgImage forState:UIControlStateNormal];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
}

- (void)setupColorWithNoBorder:(UIColor *)colorOne toColor:(UIColor *)colorTwo {
    CGFloat radius = self.frame.size.height / 2;
    CGFloat height = self.frame.size.height;
    CGFloat width = self.frame.size.width;
    if (!bgImage) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width + 1 , height), NO, 0.0);
        CGFloat innerRadius = radius - BORDER_WIDTH;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, width + 1, height) cornerRadius: radius];
        [[UIColor lightGrayColor] setFill];
        [path fill];
        
        UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, width+1, height) cornerRadius: innerRadius+1];
        // Use the bezier as a clipping path
        [roundedRectanglePath addClip];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        NSArray *gradientColors = (@[
                                   (id)colorOne.CGColor,
                                   (id)colorTwo.CGColor
                                   ]);
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)(gradientColors), NULL);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextDrawLinearGradient(context, gradient, CGPointMake(width, 0), CGPointMake(width, height), 0);
        
        bgImage =  UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        bgImage = [bgImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, radius, 0, radius)];
    }
    CALayer *layer = self.layer;
    layer.shadowColor = [[UIColor blackColor] CGColor];
    layer.shadowOffset = CGSizeMake(0, 1.0);
    layer.shadowRadius = 1.0;
    layer.shadowOpacity = 0.15f;
    layer.shouldRasterize = YES;
    layer.rasterizationScale = [[UIScreen mainScreen] scale];
    [self setBackgroundImage:bgImage forState:UIControlStateNormal];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
