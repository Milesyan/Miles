//
//  ConfirmInfoViewController.m
//  emma
//
//  Created by Ryan Ye on 9/16/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ConfirmInfoViewController.h"
#import "Logging.h"
#import "Network.h"
#import "NetworkLoadingView.h"
#import "StatusBarOverlay.h"
#import "UIStoryboard+Emma.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "User.h"
#import "BirthdayPicker.h"

#define TAG_IMAGE_CHECKMARK 10

#define TAG_ACTIONSHEET_CONFIRM 31
#define TAG_ACTIONSHEET_GENDER 32

@interface ConfirmInfoViewController () <UIActionSheetDelegate, DatePickerDelegate>{
    NSArray *textFields;
    NSDateFormatter *dateFormatter;
}

@property (readonly) User *user;
@property (nonatomic, strong) NSDate *birthday;
@property (nonatomic, strong) NSString *gender;

@property (strong, nonatomic) IBOutlet UITextField *nameField;
@property (strong, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UITextField *birthdayField;
@property (strong, nonatomic) BirthdayPicker *birthdayPicker;
@property (strong, nonatomic) IBOutlet UITextField *genderField;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextButton;
@end

@implementation ConfirmInfoViewController

- (User *)user {
    return [User currentUser];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    textFields = @[
        self.nameField,
        self.emailField,
        self.passwordField,
        self.birthdayField,
        self.genderField
    ];
    self.nextButton.enabled = NO;
    [self.navigationController.navigationBar setNeedsLayout];

}

- (void)viewWillAppear:(BOOL)animated {
    // Leave it empty, we don't want to call [super viewWillAppear:animated] here
    // We don't want the auto-scroll when focusing on a text-field behavior for tableViewController
    self.nameField.text = self.user.fullName;
    self.emailField.text = self.user.email;
    self.birthday = self.user.birthday;
    self.birthdayField.text = [self.user.birthday toReadableDate];
    if (self.user.gender) {
        self.genderField.text = self.user.isFemale ? @"Female" : @"Male";
        self.gender = self.user.isFemale ? FEMALE : MALE;
    }
    
    [self updateCheckMarkForField:self.nameField];
    [self updateCheckMarkForField:self.emailField];
    [self updateCheckMarkForField:self.passwordField];
    [self updateCheckMarkForField:self.birthdayField];
    [self updateCheckMarkForField:self.genderField];
    [self publish:EVENT_CONFIRMINFO_VIEW_APPEAR];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CrashReport leaveBreadcrumb:@"ConfirmInfoViewController"];
    [Logging syncLog:PAGE_IMP_CONFIRMINFO eventData:nil];
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

- (void)updateNextButtonState {
    self.nextButton.enabled = [self isValid:self.nameField] && 
                              [self isValid:self.emailField] &&
                              [self isValid:self.passwordField] &&
                              self.gender &&
                              self.birthday;
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

- (void)updateCheckMarkForField:(UITextField *)field {
    if ([self isValid:field]) {
        [self showCheckMark:YES forView:field];
    } else if([field.text length] > 0) {
        [self showCheckMark:NO forView:field];
    } else {
        [self hideCheckMarkForView:field];
    }
}

# pragma mark - Button clicks
- (IBAction)backPressed:(id)sender {
    [self.user logout];
    // TODO do we need add from here?
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonPressed:(id)sender {
    [Logging syncLog:BTN_CLK_CONFIRM_INFO eventData:nil];
    [self.view findAndResignFirstResponder];
    
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Are you sure the information is correct?" delegate:self cancelButtonTitle:@"No, let me check again." destructiveButtonTitle:nil otherButtonTitles:@"Yes, it's correct!", nil];
    as.tag = TAG_ACTIONSHEET_CONFIRM;
    [as showInView:self.view];
}

- (void)confirmInfo {
    [self showNetworkLoading];
    NSString *fullname = [Utils trim:self.nameField.text];
    NSArray *nameArray = [fullname componentsSeparatedByString:@" "];
    NSString *firstName = nameArray[0];
    NSString *lastName = [nameArray count] == 1 ? @"" : [fullname substringFromIndex:[firstName length]+1];
    NSString *email = [Utils trim:self.emailField.text];
    GLLog(@" %@ %@ %@ %@ %@", firstName, lastName, email, self.birthday, self.gender);
    [self.user checkEmailAvailability:email handler:^(BOOL isAvailable) {
        if (isAvailable) {
            [self.user update:@"firstName" value:firstName];
            [self.user update:@"lastName" value:lastName];
            [self.user update:@"email" value:email];
            [self.user update:@"birthday" value:self.birthday];
            [self.user update:@"gender" value:self.gender];
            [self.user updatePassword:self.passwordField.text completion:NULL];
            [self.user pushToServer];
            
            [self hideNetworkLoading];
            [self presentViewController:[UIStoryboard main] animated:YES completion:nil];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"This email is already registered by another user."  delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            [self hideNetworkLoading];
        }
    }];
}

- (IBAction)tapped:(UIGestureRecognizer *)rec {
    [self.view findAndResignFirstResponder];
}

#pragma mark - UITextFieldDelegate
- (IBAction)textFieldEditingChanged:(id)sender {
    UITextField *textField = (UITextField*)sender;
    if ([self isValid:textField]) {
        [self showCheckMark:YES forView:textField];
    } else {
        [self hideCheckMarkForView:textField];
    }
    [self updateNextButtonState];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (![self isValid:textField]) {
        [self hideCheckMarkForView:textField];
    }
    if (textField == self.birthdayField) {
        [self.view findAndResignFirstResponder];
        self.birthdayPicker = [[BirthdayPicker alloc] init];
        self.birthdayPicker.delegate = self;
        [self.birthdayPicker present];
        if (self.birthday) 
            self.birthdayPicker.date = self.birthday;
        return NO;
    } else if (textField == self.genderField) {
        [self.view findAndResignFirstResponder];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Female", @"Male", nil];
        actionSheet.tag = TAG_ACTIONSHEET_GENDER;
        [actionSheet showInView:self.view];
        return NO;
    }
    return YES;
}

- (void)datePicker:(BaseDatePicker *)birthdayPicker didDismissWithDate:(NSDate *)date {
    self.birthday = date;
    [self.birthdayField setText:[self.birthday toReadableDate]];
    [self showCheckMark:YES forView:self.birthdayField];
    [self updateNextButtonState];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text length] && ![self isValid:textField]) {
        [self showCheckMark:NO forView:textField];
    }
}

- (BOOL)isValid:(UITextField *)textField {
    if (textField == self.nameField) {
        return [[Utils trim:self.nameField.text] length];
    } else if (textField == self.emailField) {
        return [Utils isValidEmail:self.emailField.text];
    } else if (textField == self.birthdayField) {
        return self.birthday;
    } else if (textField == self.genderField) {
        return self.gender; 
    } else if (textField == self.passwordField) {
        return self.passwordField.text.length >= MIN_PASSWORD_LENGTH;
    }
    return NO;
}

# pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == TAG_ACTIONSHEET_CONFIRM) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            [self confirmInfo];
        }
    } else if (actionSheet.tag == TAG_ACTIONSHEET_GENDER) {
        self.genderField.text = (buttonIndex == 0) ? @"Female" : @"Male";
        self.gender = (buttonIndex == 0) ? FEMALE : MALE;
        [self showCheckMark:YES forView:self.genderField];
        [self updateNextButtonState];
    }
}
@end
