//
//  FulfillmentViewController.m
//  emma
//
//  Created by Xin Zhao on 13-12-30.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "Errors.h"
#import "FontReplaceableBarButtonItem.h"
#import "FulfillmentGoodsViewController.h"
#import "FulfillmentManager.h"
#import "Logging.h"
#import "NetworkLoadingView.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "User.h"

#define simpleRegex(p, e) [NSRegularExpression regularExpressionWithPattern:p options:NSRegularExpressionCaseInsensitive error:&e];
#define orderId(ut) [NSString stringWithFormat:@"%@-%@", DEFAULTS_FULFILLMENT_ORDER_PREFIX, ut]

#define CONTENT_SIZE_Y_TO_REVEAL_TEXTFIELD 46

@interface FulfillmentGoodsViewController ()
@property (weak, nonatomic) IBOutlet UIButton *buyNowButton;
@property (weak, nonatomic) IBOutlet UIWebView *goodsWebView;
@property (weak, nonatomic) IBOutlet UIView *bottomContainer;
@property (nonatomic) NSMutableDictionary *goodsInfo;
@end

@implementation FulfillmentGoodsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    [self.view setGradientBackground:UIColorFromRGB(0xfefefe)
//            toColor:UIColorFromRGB(0xf6f6ef)];
    self.goodsWebView.opaque = NO;
    self.goodsWebView.backgroundColor = [UIColor clearColor];
    self.buyNowButton.layer.cornerRadius =
            self.buyNowButton.frame.size.height * 0.5f;
    self.buyNowButton.clipsToBounds = YES;
    self.goodsWebView.delegate = self;
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    self.bottomContainer.frame = setRectY(self.bottomContainer.frame,
            self.view.frame.size.height);
    self.buyNowButton.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [Logging log:PAGE_IMP_FULFILLMENT_GOODS];
    self.goodsInfo = [NSMutableDictionary dictionary];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:
            [NSURL URLWithString:[Utils makeUrl:
                [NSString stringWithFormat:@"/fulfillment/goods/%ld?ut=%@",
                (long)self.goodsId, [User currentUser].encryptedToken]]]];
    self.goodsInfo[@"goods_type"] = @(self.goodsId);
    [self.goodsWebView loadRequest:requestObj];
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *goodsHead = [webView stringByEvaluatingJavaScriptFromString: @"document.head.innerHTML"];
    NSDictionary *goodsInfo = [self goodsInfoFromHtml:goodsHead];
    for (NSString *key in goodsInfo.allKeys) {
        self.goodsInfo[key] = goodsInfo[key];
    }
    if (goodsInfo[@"name"]) {
        self.navigationItem.title = goodsInfo[@"name"];
    }
    if (!goodsInfo[@"stock"] || [goodsInfo[@"stock"] intValue] <= 0) {
        return;
    } else if (goodsInfo[@"price"]) {
        self.buyNowButton.enabled = YES;
        [UIView animateWithDuration:0.2f animations:^{
            self.bottomContainer.frame = setRectY(self.bottomContainer.frame,
                    self.view.frame.size.height -
                    self.bottomContainer.frame.size.height);
        }];
    }
}

- (NSDictionary *)goodsInfoFromHtml:(NSString *)html {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSError *error = NULL;
    for (NSString *fetch in @[@"stock", @"name", @"price"]) {
//        NSString *pattern = [NSString stringWithFormat:@"<meta goods-%@=\"\\S+\">", fetch];
        NSRegularExpression *regex = simpleRegex(
                ([NSString stringWithFormat:@"<meta goods-%@=\".+\">", fetch]),
                error);
        [regex enumerateMatchesInString:html options:0
                range:NSMakeRange(0, [html length])
                usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags,
                    BOOL *stop){
                    NSString *fetched = [html substringWithRange:match.range];
                    NSRange rStart = [fetched rangeOfString:@"=\""];
                    NSRange rEnd = [fetched rangeOfString:@"\"" options:NSBackwardsSearch];
                    result[fetch] = [fetched substringWithRange:NSMakeRange(
                            rStart.location + rStart.length,
                            rEnd.location - rStart.location - rStart.length)];
                }];
    }
    return result;
}

#pragma mark - IBAction
- (IBAction)backButtonClicked:(id)sender {
//    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)buyNowButtonClicked:(id)sender {
    if (!self.goodsInfo[@"name"] || !self.goodsInfo[@"price"]) {
        return;
    }
    [Logging log:BTN_CLK_FULFILLMENT_BUY_NOW];
    User *user = [User currentUser];
    [Utils setDefaultsForKey:orderId(user.encryptedToken)
            withValue:self.goodsInfo];
    [self performSegueWithIdentifier:@"toPaymentVerification" sender:self];
}

@end

@interface FulfillmentPaymentViewController () {}

@property (weak, nonatomic) IBOutlet UITextField *cardNumberTextField;
@property (weak, nonatomic) IBOutlet UITextField *expireDateTextField;
@property (weak, nonatomic) IBOutlet UITextField *cardCodeTextField;
@property (weak, nonatomic) IBOutlet UITextField *cardOwnerNameTextField;
@property (weak, nonatomic) IBOutlet FontReplaceableBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;

@end

@implementation FulfillmentPaymentViewController
- (void)viewWillAppear:(BOOL)animated {
    User *user = [User currentUser];
    NSDictionary *goodsInfo = [Utils getDefaultsForKey:
            orderId(user.encryptedToken)];
    self.totalLabel.text = [NSString stringWithFormat:@"Your total: %@",
            goodsInfo[@"price"]];
    self.nextButton.enabled = [self canEnableNextButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_FULFILLMENT_PAYMENT];
}

- (IBAction)textFieldEditingChanged:(id)sender {
    [super _textFieldEditingChanged:sender];
    self.nextButton.enabled = [self canEnableNextButton];
}

- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (IBAction)nextButtonClicked:(id)sender {
    [Logging log:BTN_CLK_FULFILLMENT_PAYMENT_NEXT];
    User *user = [User currentUser];
    NSString *orderId = orderId(user.encryptedToken);
    NSMutableDictionary *goodsInfo = [[Utils getDefaultsForKey:orderId]
            mutableCopy];
    goodsInfo[@"cardNumber"] = self.cardNumberTextField.text;
    goodsInfo[@"expire"] = self.expireDateTextField.text;
    goodsInfo[@"cvc"] = self.cardCodeTextField.text;
    goodsInfo[@"ownerName"] = self.cardOwnerNameTextField.text;
    [Utils setDefaultsForKey:orderId withValue:goodsInfo];
    [self performSegueWithIdentifier:@"toShippingAddress" sender:self];
}

- (BOOL)canEnableNextButton {
    return [self isValid:self.cardNumberTextField] &&
            [self isValid:self.expireDateTextField] &&
            [self isValid:self.cardCodeTextField] &&
            [self isValid:self.cardOwnerNameTextField];
}

- (BOOL)isValid:(UITextField *)textField {
    if (self.cardNumberTextField == textField) {
        return [Utils validateCardNumber:textField.text];
    }
    else if (self.expireDateTextField == textField) {
        return [Utils validateCardExpire:textField.text];
    }
    else if (self.cardCodeTextField == textField) {
        return [Utils validateCardCVC:textField.text];
    }
    else if (self.cardOwnerNameTextField == textField) {
        return textField.text.length > 0;
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:
        (NSRange)range replacementString:(NSString *)string {
    BOOL PASSED = YES;
    if (self.cardNumberTextField == textField) {
        NSString *newString = [Utils cardNumberWithOldString:textField.text
                replacementString:string];
        if (newString != nil) {
            textField.text = newString;
        }
        PASSED = (string.length == 0);
    }
    else if (self.expireDateTextField == textField) {
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
    else if (self.cardCodeTextField == textField) {
        NSString *newString = [Utils cvcWithOldString:textField.text
                replacementString:string];
        PASSED = (newString != nil);
    }
    if (self.cardOwnerNameTextField != textField) {
        [self textFieldEditingChanged:textField];
    }
    return PASSED;
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
    if (IS_IPHONE_4) {
        [self.tableView setContentOffset:
                CGPointMake(0, CONTENT_SIZE_Y_TO_REVEAL_TEXTFIELD)
                animated:YES];
    }
}

@end

@interface FulfillmentShippingViewController() {}
@property (weak, nonatomic) IBOutlet UITextField *streetTextField;
@property (weak, nonatomic) IBOutlet UITextField *cityTextField;
@property (weak, nonatomic) IBOutlet UITextField *stateTextField;
@property (weak, nonatomic) IBOutlet UITextField *zipCodeTextField;
@property (weak, nonatomic) IBOutlet FontReplaceableBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;

@end

@implementation FulfillmentShippingViewController
- (void)viewWillAppear:(BOOL)animated {
    User *user = [User currentUser];
    NSDictionary *goodsInfo = [Utils getDefaultsForKey:
            orderId(user.encryptedToken)];
    self.totalLabel.text = [NSString stringWithFormat:@"Your total: %@",
            goodsInfo[@"price"]];
    self.doneButton.enabled = [self canEnableNextButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_FULFILLMENT_SHIPPING];
}
- (IBAction)textFieldEditingChanged:(id)sender {
    [self _textFieldEditingChanged:sender];
    self.doneButton.enabled = [self canEnableNextButton];
}

- (BOOL)isValid:(UITextField *)textField {
    if (self.zipCodeTextField == textField) {
        return textField.text.length == [US_ZIP_CODE_DIGITS[0] intValue] ||
                textField.text.length == [US_ZIP_CODE_DIGITS[1] intValue] + 1;
    }
    return textField.text.length > 0;
}

- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (IBAction)doneButtonClicked:(id)sender {
    [Logging log:BTN_CLK_FULFILLMENT_SHIPPING_DONE];
    User *user = [User currentUser];
    NSString *orderId = orderId(user.encryptedToken);
    NSMutableDictionary *goodsInfo = [[Utils getDefaultsForKey:orderId]
            mutableCopy];
    goodsInfo[@"street"] = self.streetTextField.text;
    goodsInfo[@"city"] = self.cityTextField.text;
    goodsInfo[@"state"] = self.stateTextField.text;
    goodsInfo[@"zipCode"] = self.zipCodeTextField.text;
    [Utils setDefaultsForKey:orderId withValue:goodsInfo];
    [FulfillmentManager sendFulfillmentRequestWithGoods:goodsInfo completion:
            ^(NSDictionary *result, NSError *error){
                [NetworkLoadingView hide];
                NSString *errMsg = nil;
                if (error) {
                    errMsg = @"Network error. Please try again later.";
                }
                else if ([result[@"rc"] intValue] != RC_SUCCESS) {
                    errMsg = ![result[@"msg"] isEqualToString:@""]
                            ? result[@"msg"]
                            : ([result[@"rc"] isEqual:
                                @(RC_FULFILLMENT_EXCEED_LIMIT)]
                                ? @"Sorry, every user could only order ONE "
                                    "package per day."
                                : @"Network error. Please try again later.");
                }
                if (errMsg) {
                    UIAlertView *alert = [[UIAlertView alloc]
                            initWithTitle:@"Purchase failed"
                            message:errMsg delegate:nil
                            cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
                else {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [self publish:EVENT_FULFILLMENT_PURCHASE_SUCCESSFUL];
                    }];
                }
            }];
    [self.view findAndResignFirstResponder];
    [NetworkLoadingView showWithoutAutoClose];
}

- (BOOL)canEnableNextButton {
    return [self isValid:self.streetTextField] &&
    [self isValid:self.cityTextField] &&
    [self isValid:self.stateTextField] &&
    [self isValid:self.zipCodeTextField];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:
        (NSRange)range replacementString:(NSString *)string {
    BOOL PASSED = YES;
    if (self.zipCodeTextField == textField) {
        NSString *newString = [Utils usaZipCodeWithOldString:textField.text
                replacementString:string];
        if (newString) {
            self.zipCodeTextField.text = newString;
        }
        PASSED = (string.length == 0);
    }
    if (self.zipCodeTextField == textField) {
        [self textFieldEditingChanged:textField];
    }
    return PASSED;
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
    if (IS_IPHONE_4) {
        [self.tableView setContentOffset:
                CGPointMake(0, CONTENT_SIZE_Y_TO_REVEAL_TEXTFIELD)
                animated:YES];
    }
}
@end
