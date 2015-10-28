//
//  TextValidationTableViewController.m
//  emma
//
//  Created by Xin Zhao on 14-1-2.
//  Copyright (c) 2014年 Upward Labs. All rights reserved.
//

#import "TextValidationTableViewController.h"
#import "UIView+FindAndResignFirstResponder.h"

#define TAG_IMAGE_CHECKMARK 10

@interface TextValidationTableViewController ()

@end

@implementation TextValidationTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(tapped:)];
    tap.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:tap];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate
- (void)_textFieldEditingChanged:(id)sender {
    UITextField *textField = (UITextField*)sender;
    if ([self _checkValid:textField]) {
        [self showCheckMark:YES forView:textField];
    } else {
        [self hideCheckMarkForView:textField];
    }
}

- (void)tapped:(UIGestureRecognizer *)rec {
    [self.view findAndResignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (![self _checkValid:textField]) {
        [self hideCheckMarkForView:textField];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text length] && ![self _checkValid:textField]) {
        [self showCheckMark:NO forView:textField];
    }
}

- (BOOL)_checkValid:(UITextField *)textField {
    if ([self respondsToSelector:@selector(isValid:)]) {
        return [self performSelector:@selector(isValid:) withObject:textField];
    }
    return YES;
}

- (void)showCheckMark:(BOOL)valid forView:(UIView *)view {
    UIImageView *checkMark = (UIImageView *)[view.superview viewWithTag:TAG_IMAGE_CHECKMARK];
    checkMark.hidden = NO;
    if (valid) {
        checkMark.image = [UIImage imageNamed:@"check-green"];
    } else {
        checkMark.image = [UIImage imageNamed:@"cross-red"];
    }
}

- (void)hideCheckMarkForView:(UIView *)view {
    UIImageView *checkMark = (UIImageView *)[view.superview viewWithTag:TAG_IMAGE_CHECKMARK];
    checkMark.hidden = YES;
}

- (void)keyboardWillShow:(NSNotification *)notif {}

- (void)keyboardWillHide:(NSNotification *)notif {
    [self.tableView setContentOffset:CGPointMake(0, -64)
            animated:YES];
}
@end
