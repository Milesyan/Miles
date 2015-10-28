//
//  SignUpFormViewController.h
//  emma
//
//  Created by Eric Xu on 5/15/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StartupViewController.h"
#import "TextValidationTableViewController.h"

@interface PopupWebViewController : UIViewController
- (void)openUrl:(NSString *)urlAddress;
@end

@interface SignUpViewController : TextValidationTableViewController <TextValidator, UITableViewDelegate>

@property (nonatomic, assign) BOOL isMaleSignup;

@end
