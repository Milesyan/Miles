//
//  PickerViewController.h
//  emma
//
//  Created by Ryan Ye on 7/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PICKER_MODE_NORMAL  1
#define PICKER_MODE_DATE    2

@interface GLPickerViewController : UIViewController
- (void)presentWithContentController:(UIViewController*)controller;
- (void)dismiss;
+ (GLPickerViewController *)sharedInstance;
@end
