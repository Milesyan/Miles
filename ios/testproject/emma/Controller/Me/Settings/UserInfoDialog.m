//
//  UserInfoDialog.m
//  emma
//
//  Created by Ryan Ye on 8/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "UserInfoDialog.h"
#import "DropdownMessageController.h"
#import "GLDialogViewController.h"
#import "PillGradientButton.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "StatusBarOverlay.h"

@interface UserInfoDialog ()<UITextFieldDelegate> {
    
}

@property (nonatomic, weak) User *user;
@property (nonatomic, strong) GLDialogViewController *dialog;
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *tfBgViews;
@property (nonatomic, strong) IBOutlet UITextField *firstNameField;
@property (nonatomic, strong) IBOutlet UITextField *lastNameField;
@property (nonatomic, strong) IBOutlet UITextField *emailField;
@property (nonatomic, strong) IBOutlet PillGradientButton *updateButton;

@end

@implementation UserInfoDialog

- (id)initWithUser:(User *)user {
    self = [super initWithNibName:@"UserInfoDialog" bundle:nil];
    if (self) {
        self.user = user;
    }
    return self;
}

- (GLDialogViewController *)dialog {
    return [GLDialogViewController sharedInstance];
}

- (void)present {
    [self.dialog presentWithContentController:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    for (UIView *bg in self.tfBgViews) {
        bg.layer.borderColor = [UIColorFromRGB(0xdddddd) CGColor];
        bg.layer.borderWidth = 1.0;
        bg.layer.cornerRadius = 5;
    }
    [self.updateButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
}

- (void)viewWillAppear:(BOOL)animate {
    [super viewWillAppear:animate];
    [CrashReport leaveBreadcrumb:@"UserInfoDialog"]; 
    self.emailField.text = self.user.email;
    self.firstNameField.text = self.user.firstName;
    self.lastNameField.text = self.user.lastName;
    //[self.dialog.view addGestureRecognizer:tap];
}

- (void)viewWillDisappear:(BOOL)animate {
    [super viewWillDisappear:animate];
    //[self.dialog.view removeGestureRecognizer:tap];
}

- (IBAction)updateButtonClicked:(id)sender {
    if ([self validateInfo]) {
        NSString *email = self.emailField.text;
        if ([email isEqual:self.user.email]){
            [self updateInfo];
            [self.dialog close];
            return;
        }
        [self.user checkEmailAvailability:email handler:^(BOOL isAvailable) {
            if (isAvailable) {
                [self updateInfo];
                [self.dialog close];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"This email is already registered by another user."  delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alertView show];
            }
        }];
    }
}

- (void)updateInfo {
    [self.user update:@"firstName" value:self.firstNameField.text];
    [self.user update:@"lastName" value:self.lastNameField.text];
    [self.user update:@"email" value:self.emailField.text];
    [self.user pushToServer];
    [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
}

- (BOOL)validateInfo {
    NSString *errMsg = nil;
    if ([self.firstNameField.text length] == 0) {
        [self.firstNameField becomeFirstResponder];
        errMsg = @"Please enter your first name.";
    } else if (![Utils isValidEmail:self.emailField.text]) {
        [self.emailField becomeFirstResponder];
        errMsg = @"Please enter a valid email address.";
    }
    if (errMsg) {
        [[DropdownMessageController sharedInstance] postMessage:errMsg duration:3 position:60 inView:self.view.window];
    }
    return errMsg == nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger tag = textField.tag;
    UIView *next = [self.view viewWithTag:tag+1];
    if (next) {
        [next becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

@end
