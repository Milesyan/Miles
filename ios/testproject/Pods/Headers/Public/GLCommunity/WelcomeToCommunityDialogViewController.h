//
//  WelcomeToCommunityDialogViewController.h
//  emma
//
//  Created by Peng Gu on 8/28/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeToCommunityDialogViewController : UIViewController

@property (nonatomic, copy) void (^getStartedAction)();

+ (WelcomeToCommunityDialogViewController *)presentDialogOnlyTheFirstTime;

- (instancetype)initFromNib;
- (void)present;

@end
