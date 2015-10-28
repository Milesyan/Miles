//
//  LoginViewController.m
//  emma
//
//  Created by Ryan Ye on 8/26/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "SignInViewController.h"
#import "FacebookSDK/FacebookSDK.h"
#import "Logging.h"
#import "Network.h"
#import "NetworkLoadingView.h"
#import "StatusBarOverlay.h"
#import "UIStoryboard+Emma.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "User.h"
#import "User+Jawbone.h"
#import "User+Fitbit.h"
#import "StartupViewController.h"

#define TAG_SIGNIN_EMAIL 10
#define TAG_SIGNIN_PASSWORD 11

#define TAG_ALERT_RESET_REQUEST 20
#define TAG_ALERT_EMAIL_SENT 21

@interface SignInViewController () <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *emailField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UIButton *facebookConnectButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@end

@implementation SignInViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.facebookConnectButton.layer.cornerRadius = 25;
    [self.navigationController.navigationBar setNeedsLayout];
    self.nextButton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CrashReport leaveBreadcrumb:@"SignUpFormViewController - Sign In"];
    [Logging syncLog:PAGE_IMP_SIGNIN eventData:nil];
    [self subscribe:EVENT_USER_LOGGED_IN selector:@selector(userLoggedIn:)];
    [self subscribe:EVENT_USER_LOGIN_FAILED selector:@selector(loginFailed:)];
    [self subscribe:EVENT_FB_CONNECT_FAILED selector:@selector(loginFailed:)];
    [self subscribe:EVENT_MFP_CONNECT_FAILED selector:@selector(loginFailed:)];
    [self subscribe:EVENT_JAWBONE_CONNECT_FAILED selector:@selector(loginFailed:)];
    [self subscribe:EVENT_MISFIT_AUTH_FAILED selector:@selector(loginFailed:)];
    [self subscribe:EVENT_RECOVERY_PASSWORD_SUCCEEDED selector:@selector(recoverPasswordSucceeded:)];
    [self subscribe:EVENT_RECOVERY_PASSWORD_FAILED selector:@selector(recoverPasswordFailed:)];
    [self subscribe:EVENT_MISFIT_TOKEN_AND_PROFILE_STAGE selector:@selector(showNetworkLoading)];
    [self.emailField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self unsubscribeAll];
}

- (void)showNetworkLoading {
    [NetworkLoadingView showWithoutAutoClose];
}

- (void)hideNetworkLoading {
    [NetworkLoadingView hide];
}

# pragma mark - Button Clicks

- (IBAction)connectFacebook:(id)sender
{
    [self showNetworkLoading];
    GLLog(@"signin with fb");
    [Logging syncLog:BTN_CLK_FB_CONNECT eventData:@{}];
    [User signInWithFacebook];
}
- (IBAction)connectMfp:(id)sender {
    [self showNetworkLoading];
    GLLog(@"signin with mfp");
    [User signInWithMFP];
}

- (IBAction)connectJawbone:(id)sender {
//    [self showNetworkLoading];
    GLLog(@"signin with jawbone");
    [User signInWithJawbone];
}

- (IBAction)connectFitbit:(id)sender {
    [self showNetworkLoading];
    GLLog(@"signin with mfp");
    [User signInWithFitbit];
}
- (IBAction)connectMisfit:(id)sender {
    GLLog(@"signin with Misfit");
    [User misfitAuthForSignin];
}

- (IBAction)forgetPasswordPressed:(id)sender {
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self showAlertToCollectEmail];
}

- (void)showAlertToCollectEmail {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Forgot your password?" message:@"Reset your password via email. Be sure to check from this device." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = TAG_ALERT_RESET_REQUEST;
    [[alert textFieldAtIndex:0] setPlaceholder:@"Enter your email"];
    [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    [[alert textFieldAtIndex:0] becomeFirstResponder];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == TAG_ALERT_RESET_REQUEST) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            NSString *email = [alertView textFieldAtIndex:0].text;
            if ([Utils isValidEmail:email]) {
                [self showNetworkLoading];
                [User recoverPassword:@{@"email":email}];
            } else {
                [self showAlertToCollectEmail];
            }
        }
    } else if (alertView.tag == TAG_ALERT_EMAIL_SENT) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)nextButtonPressed:(id)sender {
    [Logging syncLog:BTN_CLK_EMAIL_SIGNIN eventData:@{@"keyboard": @NO}];
    [self.view findAndResignFirstResponder];
    [self emailSignIn];
}

- (void)emailSignIn {
    [self showNetworkLoading];
    NSString *email = [Utils trim:self.emailField.text];
    NSString *password = self.passwordField.text;
    GLLog(@"sign in:%@ %@", email, password );
    [User signInWithEmail:@{USERINFO_KEY_EMAIL:email, USERINFO_KEY_PASSWORD:password}];
}

- (void)updateNextButtonState {
    self.nextButton.enabled = [Utils isValidEmail:self.emailField.text] && ([self.passwordField.text length] >= MIN_PASSWORD_LENGTH);
}

- (IBAction)backPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tapped:(UIGestureRecognizer *)rec {
    [self.view findAndResignFirstResponder];
}

# pragma mark - Event Handlers
- (void)userLoggedIn:(Event *)evt {
    User *user = [User currentUser];
    GLLog(@"Has user onboarded? %@", user.onboarded ? @"YES": @"NO");
    if (!user.onboarded)
    {
        ChooseJourneyViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"chooseJourney"];
        vc.hidePartnerSignUp = YES;
        [self hideNetworkLoading];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    if ([user isMissingInfo]) {
        // TODO, confirmInfo is not a full view? do we need add "from:self" here?
        [self.navigationController pushViewController:[UIStoryboard confirmInfo] animated:YES];
        [self hideNetworkLoading];
    } else {
        [self hideNetworkLoading];
        [Utils setDefaultsForKey:USER_DEFAULTS_KEY_UNDER_HOME_PAGE_TRANSITION withValue:@(YES)];
        UIViewController *vc = self.presentingViewController;
        UIView *snapshotView = [self.navigationController.view snapshotViewAfterScreenUpdates:YES];
        [vc.view addSubview:snapshotView];
        [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
            [vc presentViewController:[UIStoryboard main] animated:YES completion:^{
                [snapshotView removeFromSuperview];
                [Utils setDefaultsForKey:USER_DEFAULTS_KEY_UNDER_HOME_PAGE_TRANSITION withValue:nil];
            }];
        }];
    }
}


- (void)loginFailed:(Event *)event {
    NSString *msg = nil;
    if ([event.data isKindOfClass:[NSError class]]) {
        msg = [(NSError *)event.data description];
    } else {
        msg = (NSString *)event.data;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [self hideNetworkLoading];
}


- (void)recoverPasswordSucceeded:(Event *)event {
    GLLog(@"ok, next -> %@", event.data);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email sent!" message:@"An email has been sent to your email address, please check the email on this device." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alert.tag = TAG_ALERT_EMAIL_SENT;
    [self hideNetworkLoading];
    [alert show];
}

- (void)recoverPasswordFailed:(Event *)event {
    [self hideNetworkLoading];
    [[[UIAlertView alloc] initWithTitle:@"" message:(NSString *)event.data delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

# pragma mark - UITextFieldDelegate
- (IBAction)textFieldEditingChanged:(id)sender {
    [self updateNextButtonState];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (self.nextButton.enabled) {
        [Logging syncLog:BTN_CLK_EMAIL_SIGNIN eventData:@{@"keyboard": @YES}];
        [self emailSignIn];
    } 
    return YES;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (textField != self.emailField || textField.text.length < 5) {
        return YES;
    }
    
    if ([[textField.text substringFromIndex:textField.text.length-4] isEqualToString:@".con"]) {
        textField.text = [textField.text stringByReplacingCharactersInRange:NSMakeRange(textField.text.length - 4, 4) withString:@".com"];
    }
    return YES;
}


@end


