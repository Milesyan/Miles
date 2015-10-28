//
//  SettingViewController.h
//  emma
//
//  Created by Eric Xu on 1/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PeriodNavButton.h"

#define DAILY_PAGE_OPEN_OPTION  @"daily_page_open_option"

@interface HomeViewController : UIViewController

@property (weak, nonatomic) IBOutlet PeriodNavButton *periodEditButton;

- (void)beginTutorial;
- (void)gotoPeriodPage;
- (void)gotoDailyLogPage;
// + (HomeViewController *)getInstance;
@end
