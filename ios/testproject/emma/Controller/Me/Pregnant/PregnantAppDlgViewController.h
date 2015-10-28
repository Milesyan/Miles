//
//  PregnantAppDlgViewController.h
//  emma
//
//  Created by Jirong Wang on 7/1/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLDialogViewController.h"

@interface PregnantAppDlgViewController : UIViewController

@property (nonatomic, strong) GLDialogViewController *dialog;

- (void)present;

@end
