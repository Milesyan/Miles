//
//  OnboardingDataProviderNormaltrack.h
//  emma
//
//  Created by Xin Zhao on 13-11-20.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BooleanPicker.h"
#import "DaysPicker.h"
#import "OnboardingDataProviderTTC.h"



@interface OnboardingDataProviderNormalTrack : OnboardingDataProviderTTC<OnboardingDataProviderProtocol, UIActionSheetDelegate>

@end