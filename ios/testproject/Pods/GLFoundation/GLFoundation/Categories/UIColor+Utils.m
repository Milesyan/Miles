//
//  UIColor+Utils.m
//  GLFoundation
//
//  Created by Allen Hsu on 8/27/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "UIColor+Utils.h"

@implementation UIColor (Utils)

+ (UIColor *)colorFromWebHexValue:(NSString *)hexString
{
    unsigned int val;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString hasPrefix:@"#"]) {
        [scanner setScanLocation:1];
    }
    [scanner scanHexInt:&val];
    return UIColorFromRGB(val);
}

- (NSArray *)getHsla
{
    CGFloat hue;
    CGFloat saturation;
    CGFloat brightness;
    CGFloat alpha;
    BOOL success = [self getHue:&hue saturation:&saturation brightness:
        &brightness alpha:&alpha];
    if (!success) {
        return @[@(-1), @(-1), @(-1), @(-1)];
    }
    else {
        return @[@(hue), @(saturation), @(brightness), @(alpha)];
    }
}

- (UIColor *)brighterAndUnsaturatedColor
{
    NSArray *hsla = [self getHsla];
    UIColor *result = [UIColor colorWithHue:[hsla[0] floatValue]
        saturation:[hsla[1] floatValue] * 0.15f
        brightness:1.0f alpha:[hsla[3] floatValue]];
    return result;
}

@end