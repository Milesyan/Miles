//
//  FundEmployerVerifyViewController.m
//  emma
//
//  Created by Jirong Wang on 12/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundEmployerVerifyViewController.h"
#import "FontReplaceableBarButtonItem.h"
#import "GlowFirst.h"
#import "NetworkLoadingView.h"
#import "StatusBarOverlay.h"
#import "Errors.h"
#import "TabbarController.h"
#import "WebViewController.h"
#import "Logging.h"
#import <GLFoundation/NSString+Markdown.h>

#define VERIFY_ALERT_VIEW_NORMAL  1
#define VERIFY_ALERT_VIEW_GOBACK  2

@interface FundEmployerVerifyViewController () <UIActionSheetDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet FontReplaceableBarButtonItem *nextButton;
@property (weak, nonatomic) IBOutlet UITextField *verifyCode;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UILabel *glowFirstTosLink;

- (IBAction)nextButtonPressed:(id)sender;
- (IBAction)backButtonPressed:(id)sender;

@end

@implementation FundEmployerVerifyViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bottomView.frame = setRectHeight(self.bottomView.frame, 237 + HEIGHT_MORE_THAN_IPHONE_4);
    
    UITapGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tosLinkPressed:)];
    [reg setNumberOfTapsRequired:1];
    [self.glowFirstTosLink addGestureRecognizer:reg];
    
    self.glowFirstTosLink.attributedText = [NSString addFont:[Utils defaultFont:15.0] toAttributed:self.glowFirstTosLink.attributedText];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self subscribe:EVENT_FUND_ENTERPRISE_VERIFY selector:@selector(onEnterpriseVerify:)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // logging
    [CrashReport leaveBreadcrumb:@"FundEmployerVerifyViewController"];
    [Logging log:PAGE_IMP_FUND_ENTERPRISE_VERIFY];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unsubscribeAll];
}

#pragma mark - IBActions
- (IBAction)backButtonPressed:(id)sender {
    [Logging log:BTN_CLK_FUND_ENTERPRISE_VERIFY_BACK];
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"You will have to resend a new verification code if you leave this page. Are you sure?"
                                  delegate:self
                                  cancelButtonTitle:@"No, check again"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"Yes, please leave", nil];
    actionSheet.cancelButtonIndex = 1;
    [actionSheet showInView:self.view];
}

- (void)tosLinkPressed:(id)sender {
    WebViewController *controller = (WebViewController *)[UIStoryboard webView];
    [self.navigationController pushViewController:controller animated:YES from:self];
    [controller openUrl:[Utils makeUrl:FUND_TOS_URL]];
}

#pragma make - next button pressed
- (IBAction)nextButtonPressed:(id)sender {
    [Logging log:BTN_CLK_FUND_ENTERPRISE_VERIFY_DONE];
    if (self.verifyCode.text.length==0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:@"Please input a valid verification code"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    [NetworkLoadingView show];
    self.nextButton.enabled = NO;
    [self.verifyCode resignFirstResponder];

    NSDictionary * req = @{@"verify_code": self.verifyCode.text};
    [[GlowFirst sharedInstance] enterpriseVerify:req];
}

#pragma mark - Glow First enterprise apply callback
- (void)onEnterpriseVerify:(Event *)event {
    [NetworkLoadingView hide];
    self.nextButton.enabled = YES;
    NSDictionary * response = (NSDictionary *)(event.data);
    
    NSInteger rc = [[response objectForKey:@"rc"] integerValue];
    if (rc == RC_NETWORK_ERROR) {
        StatusBarOverlay *sbar = [StatusBarOverlay sharedInstance];
        [sbar postMessage:@"Failed to verify due to network problem." duration:3.0];
    } else if (rc == RC_SUCCESS) {
        [[TabbarController getInstance:self] rePerformFundSegue];
    } else if (rc == RC_ENTERPRISE_VERIFY_CODE_EXPIRE) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Sorry, your verification code is expired. Please verify again!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        alertView.tag = VERIFY_ALERT_VIEW_GOBACK;
        [alertView show];
    } else {
        NSString *errMsg = [response objectForKey:@"msg"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:errMsg
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        alertView.tag = VERIFY_ALERT_VIEW_NORMAL;
        [alertView show];
    }
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            // go back to employer apply page
            [Logging log:BTN_CLK_FUND_ENTERPRISE_VERIFY_BACK_YES];
            // TODO do we need add from here?
            [self.navigationController popViewControllerAnimated:YES];
            break;
        default:
            [Logging log:BTN_CLK_FUND_ENTERPRISE_VERIFY_BACK_NO];
            break;
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == VERIFY_ALERT_VIEW_GOBACK) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
