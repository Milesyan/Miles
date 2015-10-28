//
//  SignUpViewController.h
//  emma
//
//  Created by Eric Xu on 3/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#define EVENT_STARTUP_VIEW_APPEAR @"event_startup_view_appear"
#define USER_DEFAULTS_KEY_UNDER_HOME_PAGE_TRANSITION      @"user_defaults_key_home_page_under_transition"

@interface ChooseJourneyViewController : UIViewController
@property (nonatomic, assign) BOOL hidePartnerSignUp;
@end

@interface StartupViewController : UIViewController

@end
