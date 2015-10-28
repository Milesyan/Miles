//
//  StepsNavigationItem.m
//  emma
//
//  Created by Xin Zhao on 13-12-4.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "StepsNavigationItem.h"

#define INDICATOR_SIZE 12
#define INDICATOR_SPACING 16

@interface StepsNavigationItem() {
    UIView *titleView;
    UILabel *titleLabel;
    UIView *stepsIndicatorContainer;
}

@property (nonatomic) NSString * customTitle;

@end

@implementation StepsNavigationItem

- (void)awakeFromNib {
    [super awakeFromNib];
    [self _internalSetupSubviews];
}

- (void)redraw {
    [self _internalSetupSubviews];
}

- (void)_internalSetupSubviews {
    if (!self.indicatorColor) {
        self.indicatorColor = GLOW_COLOR_LIGHT_PURPLE;
    }
    if ([self.allSteps intValue] <= 0 || [self.currentStep intValue] <= 0) {
        titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 172, 66)];
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 172, 66)];
        titleLabel.text = self.customTitle ? self.customTitle : self.title;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [Utils semiBoldFont:23];
        titleLabel.textColor = UIColorFromRGB(0x5b5b5b);
        titleLabel.backgroundColor = [UIColor clearColor];
        [titleLabel sizeToFit];
        titleLabel.frame = setRectHeight(titleLabel.frame, 66);
        [titleView addSubview:titleLabel];
        [self setTitleView:titleView];
        return;
    }
    
    titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 172, 44)];
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 172, 22)];
    stepsIndicatorContainer = [[UIView alloc] initWithFrame:
            CGRectMake(0, 23, 172, 14)];
    titleLabel.text = self.customTitle ? self.customTitle : self.title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [Utils lightFont:12];
    titleLabel.backgroundColor = [UIColor clearColor];
    [titleView addSubview:titleLabel];
    [titleView addSubview:stepsIndicatorContainer];
    int allSteps = [self.allSteps intValue];
    int currentStep = [self.currentStep intValue];
    currentStep = currentStep == 0 ? 1 : currentStep;
    CGFloat indicatorAreaW = allSteps * INDICATOR_SIZE + (allSteps - 1) *
            INDICATOR_SPACING;
    CGFloat indicatorSpacing = INDICATOR_SPACING;
    if (indicatorAreaW > stepsIndicatorContainer.frame.size.width) {
        indicatorAreaW = stepsIndicatorContainer.frame.size.width;
        indicatorSpacing = (indicatorAreaW - (allSteps * INDICATOR_SIZE)) /
                (allSteps - 1);
    }
    CGFloat leftSpacing = (stepsIndicatorContainer.frame.size.width -
            indicatorAreaW) * 0.5f;
    
    for (int i = 0; i < allSteps; i++) {
        CGFloat x = leftSpacing + i * (INDICATOR_SIZE + indicatorSpacing);
        UIView *indicator = [[UIView alloc] initWithFrame:CGRectMake(x, 0,
                INDICATOR_SIZE, INDICATOR_SIZE)];
        indicator.layer.cornerRadius = indicator.frame.size.height * 0.5;
        if (i <= currentStep - 1) {
            indicator.backgroundColor = self.indicatorColor;
        }
        else  {
            indicator.backgroundColor = [UIColor clearColor];
            indicator.layer.borderWidth = 1;
            indicator.layer.borderColor = self.indicatorColor.CGColor;
        }
        [stepsIndicatorContainer addSubview:indicator];
        if (i < allSteps - 1) {
            UIView *connectingLine = [[UIView alloc] initWithFrame:CGRectMake(
                    x + INDICATOR_SIZE, INDICATOR_SIZE * 0.5f - 0.5f,
                    indicatorSpacing, 1)];
            connectingLine.backgroundColor = self.indicatorColor;
            [stepsIndicatorContainer addSubview:connectingLine];
        }
    }
    [self setTitleView:titleView];
}

- (BOOL)setTitle:(NSString *)title {
    if (!titleLabel) {
        return NO;
    }
    titleLabel.text = title;
    self.customTitle = title;
    return YES;
}

@end
