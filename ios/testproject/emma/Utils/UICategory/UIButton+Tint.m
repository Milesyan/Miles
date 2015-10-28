//
//  UIButton+Tint.m
//  emma
//
//  Created by Eric Xu on 2/12/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UIButton+Tint.h"

@implementation UIButton (Tint)

- (void)tintWithColor:(UIColor *)color {
    if (self.imageView.image) {
        UIImage *tinted = [Utils image:self.imageView.image withColor:color];
        [self setImage:tinted forState:UIControlStateNormal];
        [self setImage:tinted forState:UIControlStateHighlighted];
        [self setImage:tinted forState:UIControlStateSelected];
    }
}
@end
