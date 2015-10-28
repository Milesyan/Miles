//
//  FundAcceptedViewController.m
//  emma
//
//  Created by Eric Xu on 5/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundAcceptedViewController.h"
#import "Logging.h"
#import "UIStoryboard+Emma.h"
#import "User.h"
#import "NetworkLoadingView.h"
#import "Errors.h"
#import "StatusBarOverlay.h"
#import "GlowFirst.h"
#import "PillGradientButton.h"
#import "TabbarController.h"
#import <GLFoundation/NSString+Markdown.h>

#define ALERTVIEW_TAG_ADD 1

@interface FundAcceptedViewController() <UIAlertViewDelegate, UIWebViewDelegate>{
    IBOutlet UIActivityIndicatorView *webLoadingIndicator;
    IBOutlet PillGradientButton *agreeButton;
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIWebView *webViewTos;

- (IBAction)agreeButtonPressed:(id)sender;

@end

@implementation FundAcceptedViewController 

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.title = @"Glow First™";

    // Agree and start contribution button
    agreeButton.layer.cornerRadius = agreeButton.frame.size.height / 2;
    UIColor *buttonColor = agreeButton.backgroundColor;
    [agreeButton setupColorWithNoBorder:buttonColor toColor:buttonColor];
    
    NSAttributedString * s = [NSString addFont:[Utils defaultFont:16.0] toAttributed:agreeButton.titleLabel.attributedText];
    [agreeButton setAttributedTitle:s forState:UIControlStateNormal];
    
    // [self.scrollView setContentSize:CGSizeMake(320, 3250)];
    __weak FundAcceptedViewController *_self = self;
    [self subscribe:EVENT_JOIN_FUND handler:^(Event *event) {
        [NetworkLoadingView hide];
        [_self joinFundResponse:(NSDictionary *)event.data];
    }];
    [self openWebTos];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CrashReport leaveBreadcrumb:@"FundAcceptedViewController"];
    [Logging log:PAGE_IMP_FUND_PASS_REVIEW];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openWebTos {
    self.webViewTos.delegate = self;
    //Create a URL object.
    NSURL *url = [NSURL URLWithString:[Utils makeUrl:FUND_TOS_URL]];
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.webViewTos loadRequest:requestObj];
}

//Called whenever the view starts loading something
- (void)webViewDidStartLoad:(UIWebView *)webView {
    [webLoadingIndicator startAnimating];
    webView.scrollView.scrollEnabled = NO;
}

//Called whenever the view finished loading something
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [webLoadingIndicator stopAnimating];

    // Change the height dynamically of the UIWebView to match the html content
    CGRect webViewFrame = webView.frame;
    webViewFrame.size.height = 1;
    webView.frame = webViewFrame;
    CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
    webViewFrame.size = fittingSize;
    webView.frame = webViewFrame;
    
    [[webView scrollView] setContentOffset:CGPointMake(0,0) animated:NO];

    // float webViewHeight = webView.bounds.size.height;
    float webViewHeight = webView.frame.size.height;
    [self.scrollView setContentSize:CGSizeMake(320, webViewHeight + 160)];
}


#pragma mark - IBActions
- (IBAction)agreeButtonPressed:(id)sender {
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
//    scanViewController.appToken = CARDIO_TOKEN; // get your app token from the card.io website
//    scanViewController.showsFirstUseAlert = NO;
    [self presentViewController:scanViewController animated:YES completion:nil];
}

#pragma mark - CardIOPaymentViewControllerDelegate
- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)paymentViewController {
    GLLog(@"User canceled payment info");
    // Handle user cancellation here...
    [paymentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)info inPaymentViewController:(CardIOPaymentViewController *)paymentViewController {
    // Use the card info...    
    [paymentViewController dismissViewControllerAnimated:YES completion:nil];
    [NetworkLoadingView show];
    
    [[GlowFirst sharedInstance] joinFund:info.cardNumber expMonth:info.expiryMonth expYear:info.expiryYear cvc:info.cvv];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        //cancel
        return;
    }
}

- (void)joinFundResponse:(NSDictionary *)result {
    NSInteger rc = [[result objectForKey:@"fundRC"] integerValue];
    NSError *err = [result objectForKey:@"error"];
    if (!err) {
        if (rc != RC_OPERATION_NOT_ALLOWED) {
            User *user = [User currentUser];
            if ((user.ovationStatus == OVATION_STATUS_UNDER_FUND) ||
                (user.ovationStatus == OVATION_STATUS_UNDER_FUND_DELAY)) {
                [[TabbarController getInstance:self] rePerformFundSegue];
                return;
            }
        }
        NSString *errMsg = [result objectForKey:@"errMsg"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:(errMsg ? errMsg : [Errors errorMessage:rc])
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    } else {
        StatusBarOverlay *sbar = [StatusBarOverlay sharedInstance];
        [sbar postMessage:@"Failed to join Glow First" duration:4.0];
    }
}

@end
