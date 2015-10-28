//
//  OnboardingDataProviderAvoidPregnancy.h
//  emma
//
//  Created by Eric Xu on 12/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "OnboardingDataProviderTTC.h"
#import "BooleanPicker.h"
#import "DaysPicker.h"
#import "OnboardingDataProvider.h"
#import "OnboardingPeriodEditorViewController.h"

@interface OnboardingDataProviderMapMc : OnboardingDataProviderTTC<OnboardingDataProviderProtocol, DaysPickerDelegate, FirstPeriodSelectorDelegate>

@end
