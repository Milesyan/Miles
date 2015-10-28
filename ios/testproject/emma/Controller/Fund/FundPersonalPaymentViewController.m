//
//  FundPersonalPaymentViewController.m
//  emma
//
//  Created by Jirong Wang on 12/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundPersonalPaymentViewController.h"
#import "FontReplaceableBarButtonItem.h"
#import "Logging.h"
#import "GlowFirst.h"
#import "NetworkLoadingView.h"
#import "User.h"
#import "StatusBarOverlay.h"
#import "Errors.h"
#import "UIStoryboard+Emma.h"
#import "TabbarController.h"
#import "StepsNavigationItem.h"
#import "UIView+FindAndResignFirstResponder.h"

#define CONTENT_SIZE_Y_TO_REVEAL_TEXTFIELD 46

@interface FundPersonalPaymentViewController ()<UIActionSheetDelegate> {
    IBOutlet FontReplaceableBarButtonItem *doneButton;
}

@property (weak, nonatomic) IBOutlet UITextField *cardNumber;
@property (weak, nonatomic) IBOutlet UITextField *cardExpire;
@property (weak, nonatomic) IBOutlet UITextField *cardCVC;
@property (weak, nonatomic) IBOutlet UITextField *cardName;

- (IBAction)backButtonPressed:(id)sender;
- (IBAction)doneButtonPressed:(id)sender;

@end

@implementation FundPersonalPaymentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!ENABLE_GF_ENTERPRISE) {
        StepsNavigationItem * navItem = (StepsNavigationItem *)self.navigationItem;
        navItem.allSteps = @(2);
        navItem.currentStep = @(2);
        [navItem redraw];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    doneButton.enabled = [self canEnableNextButton];
    [self subscribe:EVENT_APPLY_OVATION_REVIEW
            selector:@selector(onApplyReview:)];
    
    // logging
    [CrashReport leaveBreadcrumb:@"FundPersonalPaymentViewController"];
    [Logging log:PAGE_IMP_FUND_PERSONAL_PAYMENT];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self unsubscribeAll];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions
- (IBAction)backButtonPressed:(id)sender {
    [Logging log:BTN_CLK_FUND_PERSONAL_PAY_BACK];
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Do you want to leave this page?"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"Yes, please leave", nil];
    actionSheet.cancelButtonIndex = 1;
    [actionSheet showInView:self.view];
}

- (IBAction)doneButtonPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_PERSONAL_PAY_DONE];
    
    if (![self canEnableNextButton]) {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Invalid credit card" message:@"Please enter a valid credit card info." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    } else {
        UITextField * editingField = nil;
        if (self.cardName.editing)
            editingField = self.cardName;
        else if (self.cardNumber.editing)
            editingField = self.cardNumber;
        else if (self.cardExpire.editing)
            editingField = self.cardExpire;
        else
            editingField = self.cardCVC;
        if (editingField)
            [editingField resignFirstResponder];
        
        [NetworkLoadingView show];
        doneButton.enabled = NO;
        NSMutableDictionary *request = [NSMutableDictionary dictionaryWithDictionary:@{
                                  @"latitude": @([User currentUser].currentLocation.coordinate.latitude),
                                  @"longitude": @([User currentUser].currentLocation.coordinate.longitude),
                                  @"number": self.cardNumber.text,
                                  @"exp_month": @([self getCardMonth]),
                                  @"exp_year": @([self getCardYear]),
                                  @"cvc": self.cardCVC.text
                                  }];
        if (self.cardName.text.length > 0) {
            [request setObject:self.cardName.text forKey:@"name"];
        }
        [[GlowFirst sharedInstance] ovationReview:request];
    }
}

#pragma mark - Glow First apply review server callback
- (void)onApplyReview:(Event *)evt {
    // Server apply review callback
    [NetworkLoadingView hide];
    doneButton.enabled = YES;
    NSDictionary *data = (NSDictionary *)(evt.data);
    [self appliedOvationReview:data];
}

- (void)appliedOvationReview:(NSDictionary *)response {
    NSInteger rc = [[response objectForKey:@"rc"] integerValue];
    if (rc == -1) {
        StatusBarOverlay *sbar = [StatusBarOverlay sharedInstance];
        [sbar postMessage:@"Failed to apply Glow First." duration:4.0];
    } else if (rc != RC_SUCCESS) {
        NSString *errMsg = [response objectForKey:@"errMsg"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:(errMsg ? errMsg : [Errors errorMessage:rc])
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    } else {
        User *user = [User currentUser];
        if ((user.ovationStatus == OVATION_STATUS_NONE) ||
            (user.ovationStatus == OVATION_STATUS_DEMO)) {
            StatusBarOverlay *sbar = [StatusBarOverlay sharedInstance];
            [sbar postMessage:@"Failed to apply Glow First." duration:4.0];
        } else {
            [[TabbarController getInstance:self] rePerformFundSegue];
            if (user.ovationStatus == OVATION_STATUS_UNDER_FUND ||
                user.ovationStatus == OVATION_STATUS_UNDER_FUND_DELAY) {
                [user syncWithServer];
            }
        }
    }
}

#pragma mark - credit card related logic
- (BOOL)canEnableNextButton {
    return [self isValid:self.cardNumber] &&
            [self isValid:self.cardExpire] &&
            [self isValid:self.cardCVC] &&
            [self isValid:self.cardName];
}

- (BOOL)isValid:(UITextField *)textField {
    if (self.cardNumber == textField) {
        return [Utils validateCardNumber:textField.text];
    }
    else if (self.cardExpire == textField) {
        return [Utils validateCardExpire:textField.text];
    }
    else if (self.cardCVC == textField) {
        return [Utils validateCardCVC:textField.text];
    }
    else if (self.cardName == textField) {
        return textField.text.length > 0;
    }
    return YES;
}

- (int)getCardMonth {
    if (self.cardExpire.text.length < 5)
        return 0;
    else
        return [[self.cardExpire.text substringToIndex:2] intValue];
}

- (int)getCardYear {
    if (self.cardExpire.text.length < 5)
        return 0;
    else
        return [[self.cardExpire.text substringFromIndex:3] intValue] + 2000;
}

#pragma mark - UITextFieldDelegate
- (IBAction)textFieldEditingChanged:(id)sender {
    
    [super _textFieldEditingChanged:sender];
    doneButton.enabled = [self canEnableNextButton];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:
        (NSRange)range replacementString:(NSString *)string {
    BOOL PASSED = YES;
    if (self.cardNumber == textField) {
        NSString *newString = [Utils cardNumberWithOldString:textField.text
                replacementString:string];
        if (newString != nil) {
            textField.text = newString;
        }
        PASSED = (string.length == 0);
    }
    else if (self.cardExpire == textField) {
        NSString *newString = [Utils expireWithOldString:textField.text
                replacementString:string];
        if (newString != nil) {
            textField.text = newString;
            PASSED = YES;
        }
        else {
            PASSED = NO;
        }
    }
    else if (self.cardCVC == textField) {
        NSString *newString = [Utils cvcWithOldString:textField.text
                replacementString:string];
        PASSED = (newString != nil);
    }
    if (self.cardName != textField) {
        [self textFieldEditingChanged:textField];
    }
    return PASSED;
}

#pragma mark - Keyboard events for Notes
- (void)keyboardWillShow:(NSNotification *)sysNotification
{
    // scroll to card number on the top
    if (IS_IPHONE_4 && self.tableView.contentOffset.y <= 0) {
        [self.tableView setContentOffset:
                    CGPointMake(0, CONTENT_SIZE_Y_TO_REVEAL_TEXTFIELD)
                    animated:YES];
    }
}

- (void)keyboardWillHide:(NSNotification *)sysNotification {}

#pragma mark - UIActionSheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES from:self];
    }
}

@end
