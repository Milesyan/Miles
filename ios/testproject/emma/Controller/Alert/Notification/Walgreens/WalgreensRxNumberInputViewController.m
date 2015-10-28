//
//  RxNumberInputViewController.m
//  emma
//
//  Created by ltebean on 14-12-26.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "WalgreensRxNumberInputViewController.h"
#import "WalgreensWebViewController.h"
#import "WalgreensManager.h"
#import "NetworkLoadingView.h"
#import "WalgreensFlipTransition.h"
#import "WalgreensScannerViewController.h"

#define INPUT_CORNER_RADIUS 0.0f

@interface WalgreensRxNumberInputViewController ()<UITextFieldDelegate,UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *firstInputField;
@property (weak, nonatomic) IBOutlet UITextField *secondInputField;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@end

@implementation WalgreensRxNumberInputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.firstInputField.delegate = self;
    self.secondInputField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.nextButton.layer.cornerRadius = self.nextButton.height/2;
    // clear when user back to this page from web page
    self.firstInputField.text = @"";
    self.secondInputField.text = @"";
}

- (void)viewDidAppear:(BOOL)animated
{
    [Logging log:PAGE_IMP_WALGREENS_RX_INPUT];
    [super viewDidAppear:animated];
    [self.firstInputField becomeFirstResponder];
    self.navigationController.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.navigationController.delegate == self) {
        self.navigationController.delegate = nil;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.firstInputField) {
        if ([string isEqual:@""]) {
            return YES;
        }
        // when input the 8th number
        if (textField.text.length == 6) {
            self.firstInputField.text = [NSString stringWithFormat:@"%@%@", self.firstInputField.text, string];
            [self.secondInputField becomeFirstResponder];
            return NO;
        } else if (textField.text.length == 7) {
            self.secondInputField.text = string;
            [self.secondInputField becomeFirstResponder];
            return NO;
        }
    } else if(textField == self.secondInputField) {
        // when delete the first number
        if ([string isEqual:@""] && textField.text.length ==1) {
            self.secondInputField.text = @"";
            [self.firstInputField becomeFirstResponder];
            return NO;
        }
        if ([string isEqual:@""]) {
            return YES;
        }
        if (textField.text.length == 5) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isValidRxNumber
{
    return self.firstInputField.text.length == 7 && self.secondInputField.text.length == 5;
}

- (NSString *)rxNumber
{
    return [self.firstInputField.text stringByAppendingString:self.secondInputField.text];
}

- (IBAction)cancel:(id)sender {
    [Logging log:BTN_CLK_WALGREENS_RX_INPUT_CANCEL];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)goToScanner:(id)sender {
    [Logging log:BTN_CLK_WALGREENS_RX_INPUT_SCAN];
    [self.navigationController popViewControllerAnimated:YES from:self];
    // [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)askWalgreens:(id)sender {
    [Logging log:BTN_CLK_WALGREENS_RX_INPUT_NEXT];
    BOOL valid = [WalgreensManager isValidRxNumber:[self rxNumber]];
    if (!valid) {
        [self showErrorWithTitle:@"Rx Number Incorrect" message:@"It must be 12 digits"];
        return;
    }
    [NetworkLoadingView showWithoutAutoClose];
    [WalgreensManager getLandingURL:^(NSDictionary *response, NSError *err) {
        [NetworkLoadingView hide];
        if (err || response == nil) {
            [self showErrorWithTitle:@"Failed to load Walgreens page" message:nil];
        } else {
            [self performSegueWithIdentifier:@"openPage" sender:nil];
        }
    }];
}

- (void)showErrorWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView * alertView =[[UIAlertView alloc ] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [alertView show];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqual:@"openPage"]) {
        WalgreensWebViewController *vc = segue.destinationViewController;
        vc.request = [WalgreensManager getRefillRequest:[self rxNumber]];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if ([toVC isKindOfClass:[WalgreensScannerViewController class]]) {
        return [[WalgreensFlipTransition alloc] init];
    } else {
        return nil;
    }
}

@end
