//
//  ResetPasswordViewController.m
//  emma
//
//  Created by Eric Xu on 5/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#define TAG_EMAIL 1
#define TAG_VERIFICATION_CODE 2
#define TAG_PASSWORD 3
#define TAG_PASSWORD_CONFIRM 4


#import "ResetPasswordViewController.h"
#import "User.h"
#import "Network.h"
#import "NetworkLoadingView.h"
#import "StatusBarOverlay.h"
#import "UIStoryboard+Emma.h"
#import "SignUpViewController.h"

@interface ResetPasswordViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSString *ut;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UITextField *emailTF;
@property (strong, nonatomic) IBOutlet UITextField *verificationCode;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UITextField *passwordConfirm;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (strong, nonatomic) IBOutlet UILabel *verificationTip;
@property (strong, nonatomic) IBOutlet UILabel *passwordTip;
@property (strong, nonatomic) IBOutlet UILabel *passwordConfirmTip;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *bg;
- (IBAction)backButtonPressed:(id)sender;
- (IBAction)nextButtonPressed:(id)sender;
- (IBAction)textFieldEditingChanged:(id)sender;

@end

@implementation ResetPasswordViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView.contentSize = CGSizeMake(320, 544);

    for (UIView *bg in self.bg) {
        bg.layer.borderColor = [UIColorFromRGB(0xdddddd) CGColor];
        bg.layer.borderWidth = 1.0;
        bg.layer.cornerRadius = 5;
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self subscribe:EVENT_USER_LOGGED_IN selector:@selector(userLoggedIn:)];
    [self subscribe:EVENT_RESET_PASSWORD_FAILED selector:@selector(resetPasswordFailed:)];
//    [self subscribe:EVENT_RESET_PASSWORD_SUCCEEDED selector:@sel`ector(resetPasswordSucceeded:)];

//    self.emailTF.text = self.email;
    [self updateNextButtonState];
    
//    if ([self.emailTF.text length]) {
//        self.emailTF.enabled = NO;
//        [self.verificationCode becomeFirstResponder];
//    } else {
//        self.emailTF.enabled = YES;
//        [self.emailTF becomeFirstResponder];
//    }
//    
    [self.password becomeFirstResponder];

}

- (void)viewDidDisappear:(BOOL)animated {
    [self unsubscribe:EVENT_USER_LOGGED_IN];
    [self unsubscribe:EVENT_NETWORK_ERROR];
    [self unsubscribe:EVENT_RESET_PASSWORD_FAILED];
}

- (void)userLoggedIn:(Event *)evt {
    GLLog(@"user logged in now: %@", evt);
    User *user = [User currentUser];
    [self hideNetworkLoading];
    
    if (user) {
        [self presentViewController:[UIStoryboard main] animated:YES completion:nil];
    } else {
        [self presentViewController:[UIStoryboard welcome] animated:YES completion:nil];
    }
}

- (void)resetPasswordFailed:(Event *)event {
    id msg = event.data;
    [self hideNetworkLoading];
    
    [[[UIAlertView alloc] initWithTitle:@"" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];

}

- (void)resetPasswordSucceeded:(Event *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showNetworkLoading {
    [NetworkLoadingView showWithoutAutoClose];
}

- (void)hideNetworkLoading {
    [NetworkLoadingView hide];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

- (void)updateNextButtonState {
    BOOL shouldEnableNextButton = YES;

//    shouldEnableNextButton = shouldEnableNextButton && [Utils isValidEmail:self.emailTF.text];
//    shouldEnableNextButton = shouldEnableNextButton && ([self.verificationCode.text length] == VERIFICATION_CODE_LENGTH);
    shouldEnableNextButton = shouldEnableNextButton && ([self.passwordConfirm.text length] >= MIN_PASSWORD_LENGTH);
    shouldEnableNextButton = shouldEnableNextButton && [self.passwordConfirm.text isEqualToString:self.password.text];
    
    self.nextButton.enabled = shouldEnableNextButton;
}
#pragma -
#pragma mark IBAction
- (IBAction)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
//    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonPressed:(id)sender {
    NSString *password = self.password.text;
    
    [User resetPassword:@{@"ut": self.ut, @"password": password}];
    [self showNetworkLoading];
}

#pragma - 
#pragma mark UITextFieldDelegate
- (IBAction)textFieldEditingChanged:(id)sender {
    if (sender == self.verificationCode) {
        self.verificationTip.text = [[Utils trim:self.verificationCode.text] length] == 6? @"": @"* 6 characters";
    } else if (sender == self.passwordConfirm) {
        self.passwordConfirmTip.text = [Utils isConfirmPassword:self.passwordConfirm.text partialyMatchingPassword:self.password.text]? @"": @"* Mismatched";
    } else if (sender == self.password) {
        if ([self.password.text length] < MIN_PASSWORD_LENGTH) {
            self.passwordTip.text = @"* 6+ characters required";
        } else {
            self.passwordTip.text = @"";
            self.passwordConfirmTip.text = [Utils isConfirmPassword:self.passwordConfirm.text partialyMatchingPassword:self.password.text]? @"": @"* Mismatched";
        }
        
    }
    [self updateNextButtonState];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.nextButton.enabled) {
        [textField resignFirstResponder];
    } else {
        NSInteger tag = textField.tag;
        UIView *next = [self.scrollView viewWithTag:tag+1];
        if (next) {
            [next becomeFirstResponder];
        } else {
            [textField resignFirstResponder];
            
            [UIView animateWithDuration:0.3 animations:^{
                self.scrollView.contentOffset = CGPointMake(0, 0);
            }];
        }
    }
    return YES;
}

#pragma -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
