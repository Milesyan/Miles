//
//  AppUpgradeDialog.h
//  emma
//
//  Created by Jirong Wang on 4/10/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLDialogViewController.h"

@interface AppUpgradeDialog : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) GLDialogViewController *dialog;

- (void)presentWithRemind;
- (void)presentWithEnforce;
+ (AppUpgradeDialog *)getInstance;

@end


@interface NewVersionInfoCell : UITableViewCell

@end
