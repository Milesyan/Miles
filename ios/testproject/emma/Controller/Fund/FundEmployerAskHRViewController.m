//
//  FundEmployerAskHRViewController.m
//  emma
//
//  Created by Jirong Wang on 12/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundEmployerAskHRViewController.h"
#import "WebViewController.h"
#import "Logging.h"
#import "GlowFirst.h"
#import "NetworkLoadingView.h"
#import "StatusBarOverlay.h"
#import "Errors.h"
#import <GLFoundation/NSString+Markdown.h>


#define HR_EMAIL_BODY_PLACEHOLDER @"Tell them why they should sign up for Glow First!"

@interface FundEmployerAskHRViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailAddress;
@property (weak, nonatomic) IBOutlet UITextView *emailBody;
@property (weak, nonatomic) IBOutlet UILabel *companyLink;
@property (weak, nonatomic) IBOutlet UIButton *ccUserEmail;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *fontAttributedTexts;
- (IBAction)backButtonPressed:(id)sender;
- (IBAction)sendButtonPressed:(id)sender;
- (IBAction)toggleCCUserEmail:(id)sender;

@property (nonatomic) UIColor * placeholderColer;

@end

@implementation FundEmployerAskHRViewController

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

    self.placeholderColer = UIColorFromRGB(0xc7c7cd);
    self.emailBody.delegate = self;
    self.emailBody.text = HR_EMAIL_BODY_PLACEHOLDER;
    self.emailBody.textColor = self.placeholderColer;
    
    // add font for the text
    for (UILabel *label in self.fontAttributedTexts) {
        label.attributedText = [NSString addFont:[Utils defaultFont:17.0] toAttributed:label.attributedText];
    }
    
    self.emailBody.frame = setRectHeight(self.emailBody.frame, IS_IPHONE_4 ? 152 : 240);
    
    self.companyLink.userInteractionEnabled = YES;
    UITapGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(companyLinkPressed:)];
    [reg setNumberOfTapsRequired:1];
    [self.companyLink addGestureRecognizer:reg];
    
    [self.ccUserEmail setImage:[self.ccUserEmail imageForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateHighlighted];
    [self.ccUserEmail setImage:[self.ccUserEmail imageForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateDisabled];
    [self.ccUserEmail setTitleColor:[self.ccUserEmail titleColorForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateHighlighted];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self subscribe:EVENT_FUND_SEND_EMAIL_TO_ENTERPRISE selector:@selector(onSendEmail:)];
    // logging
    [CrashReport leaveBreadcrumb:@"FundEmployerVerifyViewController"];
    [Logging log:PAGE_IMP_FUND_ENTERPRISE_REJECT];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)companyLinkPressed:(id)sender {
    WebViewController *controller = (WebViewController *)[UIStoryboard webView];
    [self.navigationController pushViewController:controller animated:YES from:self];
    [controller openUrl:[Utils makeUrl:FUND_PARTNER_COMPANIES_URL]];
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 1) && (indexPath.row==1)) {
        return HEIGHT_MORE_THAN_IPHONE_4 + 168;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

/*
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==0)
        return 3;
    else
        return 0;
}
*/


#pragma mark - IBActions
- (IBAction)backButtonPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_ENTERPRISE_REJECT_BACK];
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (IBAction)sendButtonPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_ENTERPRISE_REJECT_SEND];
    if ((self.emailAddress.text.length <= 0) || (self.emailBody.text.length <= 0)) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
            message:@"Please enter valid email address and body"
            delegate:self
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil];
        [alertView show];
        return;
    } else {
        [NetworkLoadingView show];
        [[GlowFirst sharedInstance] enterpriseSendEmail:self.emailAddress.text content:self.emailBody.text cc:self.ccUserEmail.selected];
    }
}

#pragma mark - UITextView delegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:HR_EMAIL_BODY_PLACEHOLDER]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor]; //optional
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = HR_EMAIL_BODY_PLACEHOLDER;
        textView.textColor = self.placeholderColer; //optional
    }
    [textView resignFirstResponder];
}

#pragma mark - Glow First enterprise apply callback
- (void)onSendEmail:(Event *)event {
    [NetworkLoadingView hide];
    NSDictionary * response = (NSDictionary *)(event.data);
    
    NSInteger rc = [[response objectForKey:@"rc"] integerValue];
    if (rc == RC_NETWORK_ERROR) {
        StatusBarOverlay *sbar = [StatusBarOverlay sharedInstance];
        [sbar postMessage:@"Failed due to network problem." duration:3.0];
    } else if (rc == RC_SUCCESS) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Done"
                                                            message:@"Email sent!"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    } else {
        NSString *errMsg = [response objectForKey:@"msg"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:errMsg
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (IBAction)toggleCCUserEmail:(id)sender {
    self.ccUserEmail.selected = !self.ccUserEmail.selected;
}

@end
