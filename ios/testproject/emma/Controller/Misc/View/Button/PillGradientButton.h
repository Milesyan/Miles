//
//  PillGradientButton.h
//  emma
//
//  Created by Xin Zhao on 13-4-3.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PillGradientButton : UIButton

- (id)initWithFrame:(CGRect)rect color:(UIColor *)colorOne toColor:(UIColor *)colorTwo;
- (void)setupWithColor:(UIColor *)colorOne toColor:(UIColor *)colorTwo;
- (void)setupColorWithNoBorder:(UIColor *)colorOne toColor:(UIColor *)colorTwo;

@end
