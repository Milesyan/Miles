//
//  WalgreensWebViewController.m
//  emma
//
//  Created by ltebean on 14-12-26.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "WalgreensWebViewController.h"
#import "DropdownMessageController.h"

#define showBackToGlowTipsDelay WALGREENS_BACK_TO_GLOW_DELAY

@interface WalgreensWebViewController()<UIWebViewDelegate,UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic) BOOL animating;
@property (nonatomic) CGPoint previousContentOffset;
@property (nonatomic,strong) NSTimer* timer;
@end

@implementation WalgreensWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.webView.delegate = self;
    self.webView.scrollView.delegate = self;
    
    @weakify(self);
    [self subscribeOnce:EVENT_WALGREENS_CALLBACK_CLOSE handler:^(Event *evt){
        @strongify(self);
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }];
    [self subscribeOnce:EVENT_WALGREENS_CALLBACK_REFILL handler:^(Event *evt){
        @strongify(self);
        [self.navigationController popViewControllerAnimated:YES from:self];
    }];
    [self subscribeOnce:EVENT_WALGREENS_CALLBACK_TRY_AGAIN handler:^(Event *evt){
        @strongify(self);
        [self.navigationController popViewControllerAnimated:YES from:self];
        [[DropdownMessageController sharedInstance] postMessage:@"Your code is not valid. Please try again" duration:3 inWindow:self.view.window];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [Logging log:PAGE_IMP_WALGREENS_WEB];
    [self.spinner startAnimating];
    [self.webView loadRequest:self.request];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:showBackToGlowTipsDelay target:self selector:@selector(showBackToGlowTips) userInfo:nil repeats:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)showBackToGlowTips
{
    [[DropdownMessageController sharedInstance]postMessage:@"Need to exit? Pull down and tap 'Cancel'" duration:3.0 inWindow:self.view.window];
}


- (IBAction)cancel:(id)sender {
    [Logging log:BTN_CLK_WALGREENS_WEB_BACK_TO_GLOW];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self hideNavigationBar];
    [self.spinner stopAnimating];
    self.spinner.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{

}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.previousContentOffset = scrollView.contentOffset;
    
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    if (targetContentOffset->y > self.previousContentOffset.y) {
        [self hideNavigationBar];
    } else {
        [self showNavigationbar];
    }
}


- (void)showNavigationbar
{
    if (!self.navigationController.navigationBar.hidden) {
        return;
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)hideNavigationBar
{
    if (self.navigationController.navigationBar.hidden) {
        return;
    }
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}




@end
