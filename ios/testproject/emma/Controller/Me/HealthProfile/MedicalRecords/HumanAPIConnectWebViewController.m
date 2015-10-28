//
//  HumanAPIConnectWebViewController.m
//  emma
//
//  Created by ltebean on 15-2-3.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "HumanAPIConnectWebViewController.h"
#import "GLWebViewBridge.h"
#import <GLFoundation/NSString+Markdown.h>
#import "WebViewRequest.h"
#import "MedicalRecordsDataManager.h"
#import "Sendmail.h"

#define CONNECT_PAGE_PATH @"webview/human-api/connect"

@interface HumanAPIConnectWebViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIButton *tellUsButton;
@end

@implementation HumanAPIConnectWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.spinner startAnimating];
    
    NSAttributedString *attributedTitle = [NSString addFont:[Utils defaultFont:13.0] toAttributed:[self.tellUsButton attributedTitleForState:UIControlStateNormal]];
    [self.tellUsButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];

    @weakify(self)
    [GLWebViewBridge bridgeForWebView:self.webView
                               params:nil
                          dataHandler:^(NSDictionary *data)
    {
        @strongify(self)
        if ([data[@"action"] isEqualToString:@"connected"]) {
            [self.spinner stopAnimating];
            return;
        }
        if ([data[@"action"] isEqualToString:@"close"]) {
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
        if ([data[@"action"] isEqualToString:@"auth_finished"]) {
            [self publish:EVENT_HUMAN_API_AUTH_FINISHED];
            [self.navigationController popViewControllerAnimated:NO];
            return;
        }
    }];
    [NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    [self.webView loadRequest:[WebViewRequest requestWithPath:CONNECT_PAGE_PATH]];
}


- (IBAction)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    [Logging log:BTN_CLK_HUMANAPI_CONNECT_BACK];
}

@end




