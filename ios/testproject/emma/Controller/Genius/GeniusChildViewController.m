//
//  GeniusChildViewController.m
//  emma
//
//  Created by Ryan Ye on 7/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GeniusChildViewController.h"
#import "GeniusMainViewController.h"
#import "Logging.h"
#import "AnimationSequence.h"
#import "TabbarController.h"

#define DEBUT_X 100
#define DEBUT_Y 100

@interface GeniusChildViewController () {
    UIGestureRecognizer *thumbTap;
    NSDictionary *delays;
    NSDictionary *logByTags;
    transitionCallback transitionCompleteCallback;
}
@end

@implementation GeniusChildViewController

+ (id)getInstance {
    //Subclass should implement it by themselvies.
    return nil;
}

static BOOL exclusiveViewOpenning;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.userInteractionEnabled = YES;
    thumbTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(thumbClicked:)];
    if (!self.isPresented) {
        [self.view addGestureRecognizer:thumbTap];
    }
    _inFullView = YES;
    exclusiveViewOpenning = _underZooming = NO;
    self.thumbTitleIndent = 0;
    transitionCompleteCallback = nil;

    delays = @{
                TOPLEFT: @0.0,
                TOPRIGHT: @0.2,
                MIDDLE: @0.4,
                BOTTOMLEFT: @0.6,
                BOTTOMRIGHT: @0.8,
               };
    
    logByTags = @{
                  @(TAG_GENIUS_CHILD_INSIGHT): LOG_GENIUS_CHILD_INSIGHT,
                  @(TAG_GENIUS_CHILD_MY_CYCLES): LOG_GENIUS_CHILD_CYCLES,
                  @(TAG_GENIUS_CHILD_BBT_CHART): LOG_GENIUS_CHILD_CYCLE_CHART,
                  @(TAG_GENIUS_CHILD_WEIGHT_CHART): LOG_GENIUS_CHILD_WEIGHT_CHART,
                  @(TAG_GENIUS_CHILD_NUTRITION_CHART): LOG_GENIUS_CHILD_NUTRITION_CHART,
                  @(TAG_GENIUS_CHILD_CALORIES_CHART): LOG_GENIUS_CHILD_CALORIES_CHART,
                };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.underZooming) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    }
}

- (void)setupVarsWhenGeniusWillAppear {}

- (void)teardownVarsWhenGeniusWillDisappear {}

- (NSTimeInterval)transitionDuration {
    return 0.3;
}

- (void)animateDebutForPos {
    self.view.alpha = 0;
    self.view.transform = CGAffineTransformMakeScale(1.1, 1.1);

    [AnimationSequence performAnimations:@[
     [AnimationBlock duration:0.3
                        delay:0.5
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^{
                       self.view.alpha = 1;
                       self.view.transform = CGAffineTransformIdentity;
                   }],
     ]];
}

- (void)firstLaunchChild {
    _inFullView = NO;
    thumbTap.enabled = YES;
    [self showThumbView];
}


/* All sub class should implement some of below 8 functions
 *  - _showThumbView          by default, used by "showThumbView" and "fullToThumb"
 *  - _showFullView           by default, used by "showFullView" and "thumbToFull"
 *  - showThumbView           (be called multiple times should get same result)
 *  - showFullView            (be called multiple times should get same result)
 *  - thumbToFullBegin
 *  - thumbToFull
 *  - thumbToFullCompletion
 *  - fullToThumbBegin
 *  - fullToThumb
 *  - fullToThumbCompletion
 */
- (void)_showThumbView {
}
- (void)_showFullView {
}

- (void)showThumbView {
    // Function that show the ThumbView. Does not contain any animation
    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"%@ showThumbView", NSStringFromClass([self class])]];
    [self _showThumbView];
}

- (void)showFullView {
    // Function that show the FullView. Does not contain any animation
    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"%@ showFullView", NSStringFromClass([self class])]];
    [self _showFullView];
}

- (void)fullToThumbBegin {
}
- (void)fullToThumb {
    // Function that show the ThumbView from FullView (with animation)
    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"%@ fullToThumb", NSStringFromClass([self class])]];
    [self _showThumbView];
}
- (void)fullToThumbCompletion {
}

- (void)thumbToFullBegin {
}
- (void)thumbToFull {
    // Function that show the FullView from ThumbView (with animation)
    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"%@ thumbToFull", NSStringFromClass([self class])]];
    [self _showFullView];
}

- (void)thumbToFullCompletion {
}

- (void)transitionToFullView {
    _inFullView = YES;
    exclusiveViewOpenning = _underZooming = YES;
    [self moveToFront];
    [self thumbToFullBegin];
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = [self getFullContainerView].bounds;
        [self thumbToFull];
    } completion:^(BOOL finished) {
        [self setNeedsStatusBarAppearanceUpdate];
        [self thumbToFullCompletion];
        _underZooming = NO;
    }];
    [self publish:TRANSITION_TO_FULL_VIEW];
}

- (void)transitionToThumbView {
    // delay 0.1 second, for GeniusMainViewContoller to show navigation bar
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_transitionToThumbView) userInfo:nil repeats:NO];
}

- (void)_transitionToThumbView {
    GeniusMainViewController *mainViewController = (GeniusMainViewController *)self.parentViewController;
    _inFullView = NO;
    _underZooming = YES;
    [self fullToThumbBegin];
    [UIView animateWithDuration:0.3
                     animations:^{
        self.view.frame = [mainViewController viewFrameOfChild:self];
        [self fullToThumb];
    } completion:^(BOOL finished) {
        [self setNeedsStatusBarAppearanceUpdate];
        [self moveToScrollView];
        [self fullToThumbCompletion];
        thumbTap.enabled = YES;
        exclusiveViewOpenning = _underZooming = NO;
        if (transitionCompleteCallback) {
            transitionCompleteCallback();
            transitionCompleteCallback = nil;
        }
    }];
    [self publish:TRANSITION_TO_THUMB_VIEW];
}

- (void)thumbClicked:(UIGestureRecognizer *)gesture {
    if (_underZooming || exclusiveViewOpenning) return;
    GeniusMainViewController *mainViewController = (GeniusMainViewController *)self.parentViewController;
    if (mainViewController.animationLocked) return;
    [self thumbClicked];
    // logging
    NSString * part = [logByTags objectForKey:@(self.view.tag)];
    [Logging log:BTN_CLK_GENIUS_THUMB eventData:@{@"part": part}];
}

- (void)thumbClicked {
    if (_underZooming || exclusiveViewOpenning) return;
    thumbTap.enabled = NO;
    [self transitionToFullView];
    [self publish:EVENT_GENIUS_THUMB_VIEW_CLICKED];
}

- (void)close {
    if (self.isPresented) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    else {
        if (_underZooming) return;
        [self transitionToThumbView];
    }

    [self publish:EVENT_GENIUS_THUMB_VIEW_CLOSED];
    // logging
    NSString * part = [logByTags objectForKey:@(self.view.tag)];
    [Logging log:BTN_CLK_GENIUS_CHILD_CLOSE eventData:@{@"part": part}];
}

- (void)closeWithCallback:(transitionCallback)callback {
    transitionCompleteCallback = callback;
    [self close];
}

- (void)moveToFront {
    // move self out of the scroll view
    [self.view removeFromSuperview];
    GeniusMainViewController * mainViewController = (GeniusMainViewController *)self.parentViewController;
    UIView * animationView = [self getFullContainerView];
    animationView.hidden = NO;
    [animationView addSubview:self.view];
    self.view.frame = [mainViewController viewFrameOfChild:self];
}

- (void)moveToScrollView {
    UIView * container = [self getThumbContainerView];
    [self.view removeFromSuperview];
    [container addSubview:self.view];
    self.view.frame = CGRectMake(0, 0, container.frame.size.width, container.frame.size.height);
    
    UIView * animationView = [self getFullContainerView];
    animationView.hidden = YES;
}

- (UIView *)getThumbContainerView {
    GeniusMainViewController * mainViewController = (GeniusMainViewController *)self.parentViewController;
    return [mainViewController getChildContainerView:self.view.tag];
}

- (UIView *)getFullContainerView {
    GeniusMainViewController * mainViewController = (GeniusMainViewController *)self.parentViewController;
    return [mainViewController getBlockAnimationView];
}

@end
