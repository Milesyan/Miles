//
//  StepsNavigationItem.h
//  emma
//
//  Created by Xin Zhao on 13-12-4.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StepsNavigationItem : UINavigationItem

@property (nonatomic) NSNumber *currentStep;  // start from 1
@property (nonatomic) NSNumber *allSteps;
@property (nonatomic) UIColor *indicatorColor;

- (BOOL)setTitle:(NSString *)title;
- (void)redraw;
@end
