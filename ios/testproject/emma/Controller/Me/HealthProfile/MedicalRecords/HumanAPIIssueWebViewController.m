//
//  HumanAPIIssueWebViewController.m
//  emma
//
//  Created by Peng Gu on 3/31/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "HumanAPIIssueWebViewController.h"

@interface HumanAPIIssueWebViewController ()

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end


@implementation HumanAPIIssueWebViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/health_help", EMMA_BASE_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:requestObj];
}





@end
