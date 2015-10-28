//
//  ChangePasswordViewController.m
//  emma
//
//  Created by Peng Gu on 11/25/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "User.h"
#import "StatusBarOverlay.h"

@interface ChangePasswordViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *oldPassTextField;
@property (nonatomic, weak) IBOutlet UITextField *passTextField;
@property (nonatomic, weak) IBOutlet UITextField *reenterPassTextField;

@property (nonatomic, weak) IBOutlet UIImageView *oldPassImageView;
@property (nonatomic, weak) IBOutlet UIImageView *passImageView;
@property (nonatomic, weak) IBOutlet UIImageView *reenterPassImageView;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *saveButtonItem;

@property (nonatomic, assign) BOOL oldPassValidatedCorrect;

@end


@implementation ChangePasswordViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.saveButtonItem.enabled = NO;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [Logging log:PAGE_IMP_CHANGE_PASSWORD];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.oldPassTextField) {
        self.oldPassImageView.image = nil;
    }
    else if (textField == self.passTextField) {
        self.passImageView.image = nil;
    }
    else {
        self.reenterPassImageView.image = nil;
    }
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"text field did end editing");
    if (textField == self.oldPassTextField) {
        [[User currentUser] verifyPassword:textField.text completion:^(BOOL isValid, NSError *error) {
            if (error) {
                self.oldPassImageView.image = [UIImage imageNamed:@"cross-red"];
                return;
            }
            
            NSString *imageName = isValid ? @"check-green" : @"cross-red";
            self.oldPassImageView.image = [UIImage imageNamed:imageName];
            
            self.oldPassValidatedCorrect = isValid;
        }];
    }
    else if (textField == self.passTextField) {
        BOOL isValid = self.passTextField.text.length >= MIN_PASSWORD_LENGTH;
        
        NSString *imageName = isValid ? @"check-green" : @"cross-red";
        self.passImageView.image = [UIImage imageNamed:imageName];
    }
    else if (textField == self.reenterPassTextField) {
        BOOL isValid = (self.reenterPassTextField.text.length >= MIN_PASSWORD_LENGTH) &&
                        [self.reenterPassTextField.text isEqual:self.passTextField.text];
        
        NSString *imageName = isValid ? @"check-green" : @"cross-red";
        self.reenterPassImageView.image = [UIImage imageNamed:imageName];
    }
    [self updateSaveButtonStatus];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self updateSaveButtonStatus];
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length < MIN_PASSWORD_LENGTH) {
        return NO;
    }
    
    UITextField *nextTextField = (UITextField *)[self.tableView viewWithTag:textField.tag+1];

    if (textField == nextTextField) {
        [self saveClicked:nil];
    }
    else {
        [textField resignFirstResponder];
        [nextTextField becomeFirstResponder];
    }
    
    return YES;
}


- (void)updateSaveButtonStatus
{
    if (!self.oldPassValidatedCorrect) {
        self.saveButtonItem.enabled = NO;
        return;
    }
    
    for (UITextField *each in @[self.oldPassTextField, self.passTextField, self.reenterPassTextField]) {
        if (each.text.length < MIN_PASSWORD_LENGTH) {
            self.saveButtonItem.enabled = NO;
            return;
        }
    }
    
    if (![self.passTextField.text isEqual:self.reenterPassTextField.text]) {
        self.saveButtonItem.enabled = NO;
        return;
    }
    
    self.saveButtonItem.enabled = YES;
}


- (IBAction)saveClicked:(id)sender
{
    [Logging log:BTN_CLK_CHANGE_PASSWORD_SAVE];
    
    UIView *view = [[UIView alloc] initWithFrame:self.view.window.bounds];
    view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.center = view.center;
    [spinner startAnimating];
    
    [view addSubview:spinner];
    [self.view.window addSubview:view];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[User currentUser] updatePassword:self.passTextField.text
                                completion:^(BOOL success, NSError *error) {
                                    [UIView animateWithDuration:0.3 animations:^{
                                        view.alpha = 0;
                                    } completion:^(BOOL finished) {
                                        [view removeFromSuperview];
                                        
                                        if (error) {
                                            [[StatusBarOverlay sharedInstance] postMessage:@"Network error! Password not updated!"
                                                                                  duration:2];
                                            return;
                                        }
                                        
                                        [self dismissViewControllerAnimated:YES completion:^{
                                            [[StatusBarOverlay sharedInstance] postMessage:@"Password updated!"
                                                                                  duration:2];
                                        }];
                                    }];
                                }];
    });
}


- (IBAction)cancelClicked:(id)sender
{
    [Logging log:BTN_CLK_CHANGE_PASSWORD_CANCEL];
    
    [self.oldPassTextField resignFirstResponder];
    [self.passTextField resignFirstResponder];
    [self.reenterPassTextField resignFirstResponder];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}



@end





