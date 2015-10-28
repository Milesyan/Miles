//
//  GeniusTutorialViewController.m
//  emma
//
//  Created by Xin Zhao on 5/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "GeniusTutorialViewController.h"
#import "UIView+Helpers.h"
#import "AnimationSequence.h"
#import "User.h"

@interface GeniusTutorialViewController ()
@property (weak, nonatomic) IBOutlet UIView *onOverlay;
@property (weak, nonatomic) IBOutlet UIView *bottomOverlay;
@property (weak, nonatomic) IBOutlet UIImageView *gestureFinger;
@property (weak, nonatomic) IBOutlet UIView *tapDot1;
@property (weak, nonatomic) IBOutlet UIView *tapDot2;
@property (assign, nonatomic) BOOL tapAnimating;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;

@end

@implementation GeniusTutorialViewController

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
    // Do any additional setup after loading the view from its nib.
    self.tapDot1.layer.cornerRadius = self.tapDot1.width / 2.0;
    self.tapDot2.layer.cornerRadius = self.tapDot2.width / 2.0;
    self.tapDot1.hidden = YES;
    self.tapDot2.hidden = YES;
    self.gestureFinger.hidden = YES;
    self.tutorialCompleted = NO;
    
    self.tipLabel.layer.cornerRadius = 10;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startTutorialWithView:(UIView *)view {
    if ([User currentUser].isSecondary) {
        self.tipLabel.text = @"Tap on HER CYCLES to learn more about her health.";
    }
    setWidthOfRect(self.view.frame, SCREEN_WIDTH);
    setHeightOfRect(self.view.frame, SCREEN_HEIGHT);

    self.mainViewController.containerScrollView.contentOffset =
        CGPointMake(0, -66);
    
    float l = view.frame.origin.x - 5;
    float t = view.frame.origin.y -
        self.mainViewController.containerScrollView.contentOffset.y - 5;
    float r = l + view.frame.size.width + 10;
    float b = t + view.frame.size.height + 10;
    
    self.onOverlay.frame = CGRectMake(l, t, r - l, b - t);
    self.bottomOverlay.frame = CGRectMake(0, b, self.view.frame.size.width,
        self.view.frame.size.height - b + 50);
    [self setBgGradientForView:self.bottomOverlay fromColor:[UIColor colorWithWhite:0 alpha:0] toColor:[UIColor blackColor]];
    [self startTapAnimation:CGPointMake(l + (r - l) * 0.38f,
        t + (b - t) * 0.62)];
}

#pragma mark - IBAction
- (IBAction)overlayClicked:(id)sender {
    self.tutorialCompleted = YES;
    [UIView animateWithDuration:0.3f animations:^{
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self stopTapAnimation];
        [self.mainViewController tutorialDidComplete];
    }];
    
}

#pragma mark - tap animation

- (void)startTapAnimation:(CGPoint)offset {
    if (self.tapAnimating) return;

    self.tapAnimating = YES;
    self.gestureFinger.transform = CGAffineTransformIdentity;
    self.gestureFinger.layer.anchorPoint = CGPointMake(0.32, 0.2);
    self.gestureFinger.center = offset;
    self.tapDot1.center = offset;
    self.tapDot2.center = offset;
    self.gestureFinger.hidden = NO;
    self.gestureFinger.alpha = 1.0;
    self.tapDot1.hidden = NO;
    self.tapDot2.hidden = NO;
    self.tapDot2.alpha = 1.0;
    [self animateTap];
}

- (void)stopTapAnimation {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateTap) object:nil];
    self.tapAnimating = NO;
    self.gestureFinger.transform = CGAffineTransformIdentity;
    self.gestureFinger.hidden = YES;
    self.gestureFinger.alpha = 1.0;
    self.tapDot1.hidden = YES;
    self.tapDot2.hidden = YES;
    self.tapDot2.alpha = 1.0;
}

- (void)animateTap {
    self.gestureFinger.transform = CGAffineTransformIdentity;
    self.tapDot2.transform = CGAffineTransformIdentity;
    self.tapDot2.alpha = 1.0;
    [AnimationSequence performAnimations:@[[AnimationBlock duration:0.5 animations:^{
        self.gestureFinger.transform = CGAffineTransformMakeScale(1.2, 1.2);
        self.tapDot2.transform = CGAffineTransformMakeScale(1.5, 1.5);
        self.tapDot2.alpha = 0.0;
    }], [AnimationBlock duration:0.25 animations:^{
        self.gestureFinger.transform = CGAffineTransformIdentity;
        self.tapDot2.transform = CGAffineTransformIdentity;
    }]] completion:^(BOOL finished) {
        self.tapDot2.alpha = 1.0;
        if (self.tapAnimating)
            [self animateTap];
    }];
}

- (void)setBgGradientForView:(UIView *)view fromColor:(UIColor *)fromColor toColor:(UIColor *)toColor
{
    view.backgroundColor = [UIColor clearColor];
    NSArray *colors = @[(id)fromColor.CGColor, (id)toColor.CGColor];
    NSArray *locations = [NSArray arrayWithObjects:@(0.0), @(1.0), nil];
    CAGradientLayer *bgLayer = [CAGradientLayer layer];
    bgLayer.frame = CGRectMake(0, 0, view.width, view.height);
    bgLayer.colors = colors;
    bgLayer.locations = locations;
    [view.layer insertSublayer:bgLayer atIndex:0];
}


@end
