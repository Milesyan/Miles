//
//  OnboardingPeriodEditorViewController.m
//  emma
//
//  Created by ltebean on 15-5-4.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//
#import "FontReplaceableBarButtonItem.h"
#import "NetworkLoadingView.h"
#import "OnboardingDataProvider.h"
#import "OnboardingPeriodEditorViewController.h"
#import "User.h"
#import "Logging.h"
#import "StepsNavigationItem.h"
#import <GLPeriodEditor/GLCycleData.h>

@interface OnboardingPeriodEditorViewController()
@property (nonatomic) BOOL alwaysEnableNextButton;
@property (nonatomic, strong) NSString *tipText;
@end

@implementation OnboardingPeriodEditorViewController
+ (instancetype)instance
{
    return (OnboardingPeriodEditorViewController *)[GLOnboardingPeriodCalendarBaseViewController instanceOfSubClass:NSStringFromClass([self class])];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.alwaysEnableNextButton) {
        self.doneButton.enabled = YES;
    }
    if (self.tipText) {
        [self setTipLabelText:self.tipText];
    }
    [Logging syncLog:PAGE_IMP_ONBOARDING_PERIOD eventData:nil];
}

- (GLCycleData *)initialCycleData
{
    if ([Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS][SETTINGS_KEY_FIRST_PB]) {
        NSDictionary *onboardingData = [Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS];
        NSString *firstPb = onboardingData[SETTINGS_KEY_FIRST_PB];
        NSNumber *pl0 = onboardingData[SETTINGS_KEY_PERIOD_LENGTH];
        NSDate *begin = [Utils dateWithDateLabel:firstPb];
        NSDate *end = [Utils dateByAddingDays:(pl0 ? [pl0 integerValue] : 4)
                                       toDate:begin];
        return [GLCycleData dataWithPeriodBeginDate:begin periodEndDate:end];
    } else {
        return nil;
    }
}

- (void)didClickDoneButtonWithCycleData:(GLCycleData *)cycleData
{
    NSDictionary *firstPeriod;
    if (cycleData) {
        firstPeriod = @{
                        @"begin": cycleData.periodBeginDate,
                        @"end": cycleData.periodEndDate
                        };
    }
    if (self.delegate && [self.delegate respondsToSelector:
                          @selector(firstPeriodSelector:didDismissWithPeriod:)]) {
        [self.delegate firstPeriodSelector:self
                      didDismissWithPeriod:firstPeriod];
    }
    [self dismissViewControllerAnimated:YES completion:^{
       
    }];
    
}


- (void)setAlwaysEnableNextButton:(BOOL)enable
{
    _alwaysEnableNextButton = YES;
}

- (NSInteger)periodLength
{
    id pl =[Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS][@"periodLength"];
    if (pl) {
        return [pl integerValue];
    } else {
        return 4;
    }
}
@end
