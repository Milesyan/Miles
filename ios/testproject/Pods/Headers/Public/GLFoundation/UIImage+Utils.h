//
//  UIImage+Utils.h
//  GLFoundation
//
//  Created by Allen Hsu on 8/27/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLTheme.h"

@interface UIImage (Utils)

+ (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size;
- (UIImage *)imageWithTintColor:(UIColor *)color;
- (GLColorStyle)getColorStyle;

@end
