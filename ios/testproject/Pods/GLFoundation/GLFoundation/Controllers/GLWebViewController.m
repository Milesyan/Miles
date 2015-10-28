//
//  WebViewController.m
//  emma
//
//  Created by Xin Zhao on 13-4-12.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "UINavigationController+SafePush.h"
#import "GLWebViewController.h"
#import "GLNetworkLoadingView.h"

@interface GLWebViewController () <UIWebViewDelegate, UIActionSheetDelegate> {
    BOOL reloadButtonRotating;
}

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UIButton *reloadButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@end

@implementation GLWebViewController

+ (id)viewController
{
    return [[UIStoryboard storyboardWithName:@"GLWebViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"webView"];
}

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
	self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    self.reloadButton.adjustsImageWhenDisabled = NO;
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.toolbar];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickNavigationBack:(id)sender {
    [self.webView stopLoading];
//    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.loadingIndicator stopAnimating];

    if (self.navigationController.viewControllers[0] == self) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        // already checked
        [self.navigationController popViewControllerAnimated:YES from:self];
    }
}

- (void)openUrl:(NSString *)urlAddress{
    //Create a URL object.
    NSURL *url = [NSURL URLWithString:urlAddress];
    
//    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"WebViewController openUrl:%@", url]];
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    if (self.view)
        [self.webView loadRequest:requestObj];
}

//Called whenever the view starts loading something
- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self updateButtons];
}

//Called whenever the view finished loading something
- (void)webViewDidFinishLoad:(UIWebView *)webView_ {
    [self updateButtons];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self updateButtons];
}

- (void)updateButtons {
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    self.reloadButton.hidden = self.webView.loading;
    if (self.webView.loading) {
        [self.loadingIndicator startAnimating];
    } else {
        [self.loadingIndicator stopAnimating];
    }
}

- (IBAction)clickSend {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"Open in Safari", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[UIApplication sharedApplication] openURL:[self.webView.request URL]];
    }
}
@end
