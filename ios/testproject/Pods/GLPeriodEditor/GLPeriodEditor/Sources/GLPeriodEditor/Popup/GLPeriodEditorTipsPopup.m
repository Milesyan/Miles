//
//  GLPeriodEditorTipsPopup.m
//  GLPeriodEditor
//
//  Created by ltebean on 15/5/1.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLPeriodEditorTipsPopup.h"
#import <GLFoundation/GLDialogViewController.h>

@interface GLPeriodEditorTipsPopup () <UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, copy) NSString *url;
@end

@implementation GLPeriodEditorTipsPopup


+ (void)presentWithURL:(NSString *)url
{
    GLPeriodEditorTipsPopup *popup = [[GLPeriodEditorTipsPopup alloc] initWithUrl:url];
    [[GLDialogViewController sharedInstance] presentWithContentController:popup];
}

- (instancetype)initWithUrl:(NSString *)url
{
    self = [super initWithNibName:@"GLPeriodEditorTipsPopup" bundle:nil];
    if (self) {
        self.url = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.webView.delegate = self;
    self.spinner.hidesWhenStopped = YES;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [self.webView loadRequest:request];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.spinner stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.spinner stopAnimating];
    [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"Could not connect to the server", @"GLPeriodEditorLocalizedString", nil)  delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"GLPeriodEditorLocalizedString", nil) otherButtonTitles:nil] show];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.spinner startAnimating];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
