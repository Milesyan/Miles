//
//  MedicalRecordsDetailViewController.m
//  emma
//
//  Created by ltebean on 15-2-3.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "MedicalRecordsDetailViewController.h"
#import "WebViewRequest.h"

@interface MedicalRecordsDetailViewController ()<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation MedicalRecordsDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = [Utils capitalizeFirstOnlyFor:self.type];
    
    NSString* path = [NSString stringWithFormat:@"webview/human-api/%@", self.type];
    
    [self.webView loadRequest:[WebViewRequest requestWithPath:path]];
    self.webView.delegate = self;
    [self.spinner startAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.spinner stopAnimating];
    UIAlertView * alertView =[[UIAlertView alloc ] initWithTitle:@"Oops, bad connection."
                                                         message:nil
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [alertView show];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.spinner stopAnimating];
}



@end
