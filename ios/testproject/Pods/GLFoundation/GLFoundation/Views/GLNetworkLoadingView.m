//
//  networkLoadingView.m
//  emma
//
//  Created by Jirong Wang on 3/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Masonry/Masonry.h>

#import "GLNetworkLoadingView.h"
#import "GLUtils.h"
#import "GLTheme.h"

// 20 seconds
#define DEFAULT_LOADING_TIME 20.0
// 3 mins to avoid app die
#define MAX_LOADING_TIME    180.0

@interface GLNetworkLoadingView()

@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSInteger count;

@end

@implementation GLNetworkLoadingView

static GLNetworkLoadingView * fullview = nil;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [indicator startAnimating];
        [self addSubview:indicator];
       
        self.messageLabel = [[UILabel alloc] init];
        self.messageLabel.backgroundColor = [UIColor clearColor];
        self.messageLabel.font = [GLTheme defaultFont:13];
        self.messageLabel.text = @"";
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel.textColor = [UIColor lightGrayColor];
        self.messageLabel.numberOfLines = 0;
        
        [self addSubview:self.messageLabel];
        
        [indicator mas_updateConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
       
        [self.messageLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.left.equalTo(self).with.offset(20);
            make.right.equalTo(self).with.offset(-20);
            make.top.equalTo(indicator.mas_bottom).with.offset(20);
        }];
    }
    self.backgroundColor = [UIColor darkTextColor];
    self.alpha = 0.7;
    return self;
}

+ (GLNetworkLoadingView *)getInstance {
    if (!fullview) {
        fullview = [[GLNetworkLoadingView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return fullview;
}

+ (void)show {
    [GLNetworkLoadingView showWithDelay:DEFAULT_LOADING_TIME];
}

+ (void)showWithoutAutoClose {
    [GLNetworkLoadingView showWithDelay:MAX_LOADING_TIME];
}

+ (void)showInWindow:(UIWindow *)window {
    [GLNetworkLoadingView showWithDelay:DEFAULT_LOADING_TIME inWindow:window];
}

+ (void)showWithoutAutoCloseInWindow:(UIWindow *)window {
    [GLNetworkLoadingView showWithDelay:MAX_LOADING_TIME inWindow:window];
}

+ (void)showWithDelay:(CGFloat)delay {
    UIWindow *w = [GLUtils keyWindow];
    [self showWithDelay:delay inWindow:w];
}

+ (void)showWithDelay:(CGFloat)delay inWindow:(UIWindow *)window {
    GLNetworkLoadingView *view = [GLNetworkLoadingView getInstance];
    [window addSubview:view];
    [view performSelector:@selector(hideView:) withObject:nil afterDelay:delay];
   
    view.count = 0;
    [view.timer invalidate];
    view.messageLabel.text = @"";
    view.timer = [NSTimer scheduledTimerWithTimeInterval:30
                                                  target:view
                                                selector:@selector(timeIsUp:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)timeIsUp:(id)sender {
    //NSLog(@"time is up:%@", sender);
    
    NSArray *allMsg = @[
                        @"Still loading...",
                        @"Loading time may differ...",
                        @"Depending on network connection, amount of data, etc...",
                        ];
    if (_count >= allMsg.count) {
        _count = _count - allMsg.count;
    }
    
    self.messageLabel.text = allMsg[_count];
//    [self.messageLabel sizeToFit];
    _count ++;
}

- (void)hideView:(id)sender {
    if (self.timer) {
        [self.timer invalidate];
    }
    self.messageLabel.text = @"";
    [GLNetworkLoadingView hide];
}

+ (void)hide {
    GLNetworkLoadingView *view = [GLNetworkLoadingView getInstance];
    [view removeFromSuperview];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
