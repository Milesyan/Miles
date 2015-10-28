//
//  SignUpFormViewController.m
//  emma
//
//  Created by Eric Xu on 5/15/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "BirthdayPicker.h"
#import "Logging.h"
#import "Network.h"
#import "NetworkLoadingView.h"
#import "SignUpViewController.h"
#import "StatusBarOverlay.h"
#import "StepsNavigationItem.h"
#import "UIStoryboard+Emma.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "User.h"
#import "User+Jawbone.h"
#import "User+Fitbit.h"
#import "UIView+Helpers.h"
#import "HealthProfileData.h"
#import "StartupViewController.h"

#define TAG_IMAGE_CHECKMARK 10
#define TAG_ALERT_EMAIL_SENT 22
#define TAG_ACTIONSHEET_CONFIRM 31
#define TAG_ACTIONSHEET_GENDER 32
#define CONTENT_SIZE_Y_TO_REVEAL_TEXTFIELD (78 - 64)

@interface PopupWebViewController() <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end

@implementation PopupWebViewController
- (IBAction)clickClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openUrl:(NSString *)urlAddress{
    //Create a URL object.
    NSURL *url = [NSURL URLWithString:urlAddress];
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
//    self.webView.delegate = self;
    if (self.view) {
        GLLog(@"debug: webView:%@", self.webView);
        [self.webView loadRequest:requestObj];
    }
}

//Called whenever the view starts loading something
- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.loadingIndicator startAnimating];
}

//Called whenever the view finished loading something
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.loadingIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.loadingIndicator stopAnimating];
}

@end

@interface SignUpViewController ()<UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate, DatePickerDelegate> {
    NSArray *textFields;
}

@property (nonatomic, strong) NSDate *birthday;
@property (nonatomic, strong) NSString *gender;

@property (strong, nonatomic) IBOutlet UITextField *nameField;
@property (strong, nonatomic) IBOutlet UITextField *emailField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UITextField *birthdayField;
@property (strong, nonatomic) BirthdayPicker *birthdayPicker;
//@property (strong, nonatomic) IBOutlet UITextField *genderField;
@property (strong, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UIView *tipsView;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *termsContainerTopConstraint;

- (IBAction)clickTerms;
- (IBAction)clickPrivacy;
- (IBAction)backPressed:(id)sender;
- (IBAction)nextButtonPressed:(id)sender;
- (IBAction)textFieldEditingChanged:(id)sender;

@end

@implementation SignUpViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    textFields = @[
        self.nameField,
        self.emailField,
        self.passwordField,
        self.birthdayField,
//        self.genderField
    ];
    self.nextButton.enabled = NO;
    [self.navigationController.navigationBar setNeedsLayout];
    
    StepsNavigationItem *navItem = (StepsNavigationItem *)self.navigationItem;
    if ([navItem isKindOfClass:[StepsNavigationItem class]]) {
                if (self.isMaleSignup) {
            navItem.currentStep = @(2);
            navItem.allSteps = @(2);
            navItem.title = @"Step 2 - Last step!";
        }
        else {
            navItem.currentStep = @(3);
            navItem.allSteps = @(3);
        }
        [navItem redraw];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.isMaleSignup) {
        [Logging log:PAGE_IMP_ONBOARDING_MALE_2];
    }
    else {
        NSDictionary *setting = [Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS];
        NSNumber *status = setting[SETTINGS_KEY_CURRENT_STATUS];
        
        NSString *logName = @{
            @(AppPurposesTTC): PAGE_IMP_ONBOARDING_TTC_3,
            @(AppPurposesNormalTrack): PAGE_IMP_ONBOARDING_NO_TTC_3,
            @(AppPurposesTTCWithTreatment): PAGE_IMP_ONBOARDING_TTC_TREATMENT_3
        }[status];
        
        if (status && logName) {
            [Logging syncLog:logName eventData:nil];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CrashReport leaveBreadcrumb:@"SignUpFormViewController - Sign Up"];
    [self subscribe:EVENT_USER_LOGGED_IN selector:@selector(userLoggedIn:)];
    [self subscribe:EVENT_FB_CONNECT_FAILED selector:@selector(signUpFailed:)];
    [self subscribe:EVENT_MFP_CONNECT_FAILED selector:@selector(signUpFailed:)];
    [self subscribe:EVENT_MISFIT_AUTH_FAILED selector:@selector(signUpFailed:)];
    [self subscribe:EVENT_MISFIT_TOKEN_AND_PROFILE_STAGE selector:@selector(showNetworkLoading)];
    [self subscribe:EVENT_USER_SIGNUP_FAILED selector:@selector(signUpFailed:)];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self unsubscribeAll];
}

- (void)keyboardWillShow:(NSNotification *)notif {
    if (IS_IPHONE_4) {
        [self.tableView setContentOffset:CGPointMake(0,
                CONTENT_SIZE_Y_TO_REVEAL_TEXTFIELD)
                animated:YES];
    }
}

- (PopupWebViewController *) popupWebViewController {
    return (PopupWebViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"popup"];
}

- (void)showNetworkLoading {
    [NetworkLoadingView showWithoutAutoClose];
}

- (void)hideNetworkLoading {
    [NetworkLoadingView hide];
}

- (void)updateNextButtonState {
    self.nextButton.enabled = [self isValid:self.nameField] && 
                              [self isValid:self.emailField] && 
                              [self isValid:self.passwordField] &&
                              self.birthday;
}

# pragma mark - Event handlers
- (void)userLoggedIn:(Event *)evt {
    User *user = [User currentUser];    
    
    if ([user isMissingInfo]) {
        // TODO, do we need add "from:self" here?
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

- (void)signUpFailed:(Event *)event {
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

# pragma mark - IBAction
- (IBAction)backPressed:(id)sender
{
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES from:self];
    }
    else {
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (IBAction)clickTerms {
    PopupWebViewController *controller = [self popupWebViewController];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    controller.title = @"Terms of Service";
    [self presentViewController:navController animated:YES completion:nil];
    [controller openUrl:[Utils makeUrl:TOS_URL]];
}

- (IBAction)clickPrivacy {
    PopupWebViewController *controller = self.popupWebViewController;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    controller.title = @"Privacy Policy";
    [self presentViewController:navController animated:YES completion:nil];
    [controller openUrl:[Utils makeUrl:PRIVACY_POLICY_URL]];
}

- (IBAction)nextButtonPressed:(id)sender {
    [Logging syncLog:BTN_CLK_EMAIL_SIGNUP eventData:nil];
    [self.view findAndResignFirstResponder];
    
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Are you sure the information is correct?" delegate:self cancelButtonTitle:@"No, let me check again." destructiveButtonTitle:nil otherButtonTitles:@"Yes, it's correct!", nil];
    as.tag = TAG_ACTIONSHEET_CONFIRM;
    [as showInView:self.view];
}

- (IBAction)facebookButtonPressed:(id)sender {
    [self showNetworkLoading];
    GLLog(@"signup with fb");
    [Logging syncLog:BTN_CLK_FB_CONNECT eventData:@{}];
    if (self.isMaleSignup) {
        [User signUpAsPartnerWithFacebook];
    } else {
        [User signUpWithFacebook];
    }
}

- (void)emailSignUp {
    [self showNetworkLoading];
    NSString *fullname = [Utils trim:self.nameField.text];
    NSArray *nameArray = [fullname componentsSeparatedByString:@" "];
    NSString *firstName = nameArray[0];
    NSString *lastName = [nameArray count] == 1 ? @"" : [fullname substringFromIndex:[firstName length]+1];
    NSString *email = [Utils trim:self.emailField.text];
    NSString *password = self.passwordField.text;
    
    GLLog(@" %@ %@ %@ %@ %@ %@", firstName, lastName, email, password, self.birthday, self.gender);
    [User signUpWithEmail:@{
                            USERINFO_KEY_FIRSTNAME:firstName,
                            USERINFO_KEY_LASTNAME:lastName,
                            USERINFO_KEY_EMAIL:email,
                            USERINFO_KEY_PASSWORD:password,
                            USERINFO_KEY_GENDER:self.isMaleSignup? MALE : FEMALE,
                            USERINFO_KEY_BIRTHDAY:self.birthday,
                            }];
}

#pragma mark - UITextFieldDelegate
- (IBAction)textFieldEditingChanged:(id)sender {
    [super _textFieldEditingChanged:sender];
    [self updateNextButtonState];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [super textFieldShouldBeginEditing:textField];
    if (textField == self.passwordField) {
        [self hideCheckMarkForView:textField];
    }
    if (textField == self.birthdayField) {
        [self.view findAndResignFirstResponder];
        self.birthdayPicker = [[BirthdayPicker alloc] init];
        self.birthdayPicker.delegate = self;
        [self.birthdayPicker present];
        return NO;
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

#pragma mark - TextValidator protocol
- (BOOL)isValid:(UITextField *)textField {
    if (textField == self.nameField) {
        return [[Utils trim:self.nameField.text] length];
    } else if (textField == self.emailField) {
        return [Utils isValidEmail:self.emailField.text];
    } else if (textField == self.passwordField) {
        return [self.passwordField.text length] >= MIN_PASSWORD_LENGTH;
    } else if (textField == self.birthdayField) {
        return self.birthday;
    }
    return NO;
}

#pragma mark - DatePickerDelegate
- (void)datePicker:(BaseDatePicker *)birthdayPicker didDismissWithDate:(NSDate *)date {
    self.birthday = date;
    [self.birthdayField setText:[self.birthday toReadableDate]];
    [self showCheckMark:YES forView:self.birthdayField];
    [self updateNextButtonState];
}


# pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == TAG_ACTIONSHEET_CONFIRM) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            [self emailSignUp];
        }
    }
}

@end

