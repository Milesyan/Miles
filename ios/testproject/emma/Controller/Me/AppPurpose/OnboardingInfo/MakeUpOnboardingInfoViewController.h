//
//  MakeUpOnboardingInfoViewController.h
//  emma
//
//  Created by Xin Zhao on 13-12-12.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "WelcomeViewController.h"

@interface MakeUpOnboardingInfoViewController : WelcomeViewController

@property (nonatomic) AppPurposes targetAppPurpose;
@property (nonatomic, retain) NSArray *missedSettings;
@end
