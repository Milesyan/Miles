//
//  OnboardingPeriodEditorViewController.h
//  emma
//
//  Created by ltebean on 15-5-4.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <GLPeriodEditor/GLOnboardingPeriodCalendarBaseViewController.h>
@class OnboardingPeriodEditorViewController;

@protocol FirstPeriodSelectorDelegate <NSObject>
- (void)firstPeriodSelector:(OnboardingPeriodEditorViewController *)firstPeriodSelector
       didDismissWithPeriod:(NSDictionary *)firstPeriod;
@end

@interface OnboardingPeriodEditorViewController : GLOnboardingPeriodCalendarBaseViewController

@property (nonatomic) id<FirstPeriodSelectorDelegate> delegate;

+ (instancetype)instance;
- (void)setAlwaysEnableNextButton:(BOOL)enable;
- (void)setTipText:(NSString *)tip;
@end
