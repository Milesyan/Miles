//
//  networkLoadingView.m
//  emma
//
//  Created by Jirong Wang on 3/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "NetworkLoadingView.h"
#import <GLFoundation/GLUtils.h>

// 20 seconds
#define DEFAULT_LOADING_TIME 20.0
// 3 mins to avoid app die
#define MAX_LOADING_TIME    180.0

@implementation NetworkLoadingView

static NetworkLoadingView * fullview = nil;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-36)/2, (SCREEN_HEIGHT-36)/2, 36, 36)];
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [indicator startAnimating];
        [self addSubview:indicator];
    }
    self.backgroundColor = [UIColor darkTextColor];
    self.alpha = 0.7;
    return self;
}

+ (NetworkLoadingView *)getInstance {
    if (!fullview) {
        fullview = [[NetworkLoadingView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return fullview;
}

+ (void)show {
    [NetworkLoadingView showWithDelay:DEFAULT_LOADING_TIME];
}

+ (void)showWithoutAutoClose {
    [NetworkLoadingView showWithDelay:MAX_LOADING_TIME];
}

+ (void)showWithDelay:(CGFloat)delay {
    NetworkLoadingView *view = [NetworkLoadingView getInstance];
    UIWindow *w = [GLUtils keyWindow];
    [w addSubview:view];
    [view performSelector:@selector(hideView:) withObject:nil afterDelay:delay];
}

- (void)hideView:(id)sender {
    [NetworkLoadingView hide];
}

+ (void)hide {
    NetworkLoadingView *view = [NetworkLoadingView getInstance];
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
