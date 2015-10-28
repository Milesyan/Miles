//
//  EmmaTextField.h
//  emma
//
//  Created by Allen Hsu on 1/3/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLTextField : UITextField

@property (assign, nonatomic) UIEdgeInsets edgeInsets;

- (void)setBorderColor:(UIColor *)borderColor width:(CGFloat)width;
- (void)setCornerRadius:(CGFloat)radius;
- (void)setupDefaultStyle;

@end
