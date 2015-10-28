//
//  WelcomeViewController.h
//  emma
//
//  Created by Eric Xu on 2/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OnboardingDataProvider.h"

@interface WelcomeViewController : UIViewController <OnboardingDataReceiver>

@property (nonatomic, retain) OnboardingDataProvider *variousPurposesDataProvider;
@property (nonatomic, retain) NSMutableDictionary *data;
@property (nonatomic) NSNumber *stepInOnboarding;

- (void)_checkDoneButtonStatusWithShowingMessage:(BOOL)showMsg;
@end
