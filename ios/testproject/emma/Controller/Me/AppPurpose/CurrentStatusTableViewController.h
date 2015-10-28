//
//  CurrentStatusTableViewController.h
//  emma
//
//  Created by Peng Gu on 10/9/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPregnantConfirmTag 222

@class User;
@class AppPurposesManager;

@interface CurrentStatusTableViewController : UITableViewController

@property (nonatomic, strong) User *user;
@property (nonatomic, strong) AppPurposesManager *appPurposeManager;

- (void)updateUserStatus;

@end
