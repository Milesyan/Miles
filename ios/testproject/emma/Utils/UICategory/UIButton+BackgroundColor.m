//
//  UIButton+BackgroundColor.m
//  emma
//
//  Created by ltebean on 15-3-27.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "UIButton+BackgroundColor.h"

@implementation UIButton (BackgroundColor)
- (void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state
{
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    colorView.backgroundColor = color;
    
    UIGraphicsBeginImageContext(colorView.bounds.size);
    [colorView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self setBackgroundImage:colorImage forState:state];
}
@end
