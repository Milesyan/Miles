//
//  OnboardingDataProviderMakeUpTTC.m
//  emma
//
//  Created by Xin Zhao on 13-12-12.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//
#import "MakeUpOnboardingInfoViewController.h"
#import "OnboardingDataProviderMakeUpTTC.h"

@implementation OnboardingDataProviderMakeUpTTC

- (NSArray *)_answerKeys {
    NSArray *missedSettings =
            ((MakeUpOnboardingInfoViewController*)self.receiver).missedSettings;
    if ([missedSettings indexOfObject:SETTINGS_KEY_HEIGHT] != NSNotFound ||
        [missedSettings indexOfObject:SETTINGS_KEY_WEIGHT] != NSNotFound) {
        return @[SETTINGS_KEY_TTC_START, SETTINGS_KEY_CHILDREN_NUMBER, SETTINGS_KEY_WEIGHT];
    }
    else {
        return @[SETTINGS_KEY_TTC_START, SETTINGS_KEY_CHILDREN_NUMBER];
    }
}

- (NSString *)navigationTitle {
    return nil;
}
@end