//
//  GeniusTutorialViewController.h
//  emma
//
//  Created by Xin Zhao on 5/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeniusMainViewController.h"

@interface GeniusTutorialViewController : UIViewController

@property (nonatomic) GeniusMainViewController *mainViewController;
@property (assign, nonatomic) BOOL tutorialCompleted;

- (void)startTutorialWithView:(UIView *)view;

@end
