//
//  GradientLabel.h
//  emma
//
//  Created by Jirong Wang on 3/29/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GradientLabel : UILabel

- (void)initGradientColor:(UIColor *)startColor endColor:(UIColor *)endColor direction:(NSUInteger)direction;

+ (NSInteger)topToBottom;
+ (NSInteger)leftToRight;
+ (NSInteger)leftTopToRightBottom;
+ (NSInteger)rightTopToLeftBottom;

@end
