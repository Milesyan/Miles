//
//  TextValidationTableViewController.h
//  emma
//
//  Created by Xin Zhao on 14-1-2.
//  Copyright (c) 2014年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TextValidator <NSObject>
@required
- (BOOL)isValid:(UITextField *)textField;
- (IBAction)textFieldEditingChanged:(id)sender;
@optional
- (IBAction)tapped:(id)sender;
@end

@interface TextValidationTableViewController : UITableViewController<UITextFieldDelegate>

- (void)tapped:(UIGestureRecognizer *)rec;
- (void)_textFieldEditingChanged:(id)sender;
- (void)showCheckMark:(BOOL)valid forView:(UIView *)view;
- (void)hideCheckMarkForView:(UIView *)view;
@end