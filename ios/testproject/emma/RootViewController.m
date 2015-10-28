//
//  RootViewController.m
//  emma
//
//  Created by Ryan Ye on 3/14/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "RootViewController.h"
#import "User.h"
#import "UIStoryboard+Emma.h"
#import "StartupViewController.h"
#import "WelcomeViewController.h"
#import "HomeViewController.h"
#import "StatusBarOverlay.h"

@interface SplashWindow : UIWindow {
    UIImageView *imageView;
}
@end

@implementation SplashWindow 
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.hidden = NO;
        self.opaque = NO;
        self.backgroundColor = [UIColor blackColor];
        self.windowLevel = UIWindowLevelStatusBar + 2.0f;
        imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        if (IS_IPHONE_6_PLUS) {
            imageView.image = [UIImage imageNamed:@"LaunchImage-800-Portrait-736h@3x"];
        }
        else if (IS_IPHONE_6) {
            imageView.image = [UIImage imageNamed:@"LaunchImage-800-667h@2x"];
        }
        else if (IS_IPHONE_5) {
            imageView.image = [UIImage imageNamed:@"LaunchImage-700-568h@2x"];
        }
        else {
            imageView.image = [UIImage imageNamed:@"LaunchImage@2x"];
        }
        
        [self addSubview:imageView];
        UIViewController *vc = [[UIViewController alloc] init];
        self.rootViewController = vc;
    }
    return self;
}
@end

@interface RootViewController () {
    SplashWindow *splashWindow;
    StatusBarOverlay *statusBarOverlay;
    NSTimeInterval splashFadeOutDelay;
}
@end

@implementation RootViewController

- (void)viewDidLoad {
    splashWindow = [[SplashWindow alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    statusBarOverlay = [StatusBarOverlay sharedInstance];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    User *user = [User currentUser];

    splashFadeOutDelay = 0.0;
    if (!user || [user isMissingInfo] || !user.onboarded) {
        [self subscribeOnce:EVENT_STARTUP_VIEW_APPEAR selector:@selector(appLoaded:)];
        [self presentViewController:[UIStoryboard startUp] animated:NO completion:nil];
    } else {
        splashFadeOutDelay = 0.5;
        [statusBarOverlay postMessage:@"Loading..." options:StatusBarShowSpinner | StatusBarShowProgressBar];
        [statusBarOverlay setProgress:1.0 animated:NO];
        [self subscribeOnce:EVENT_HOME_VIEW_APPEAR selector:@selector(appLoaded:)];
        GLLog(@"Presenting tabbar controller");
        [self presentViewController:[UIStoryboard main] animated:NO completion:^{
            GLLog(@"done!");
            [self publish:EVENT_HOME_VIEW_APPEAR];
        }];
    }
}

- (void)appLoaded:(Event *)evt {
    [statusBarOverlay clearText:splashFadeOutDelay];
    [UIView animateWithDuration:0.5 delay:splashFadeOutDelay options:0 animations:^{
        splashWindow.alpha = 0;
    } completion: ^(BOOL finished) {
        splashWindow.hidden = YES;
        splashWindow = nil;
    }];
}

@end
