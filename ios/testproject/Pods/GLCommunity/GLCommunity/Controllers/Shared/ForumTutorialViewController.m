//
//  ForumTutorialViewController.m
//  emma
//
//  Created by Allen Hsu on 2/19/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLAnimationSequence.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import <GLFoundation/GLFoundation.h>
#import "ForumTutorialViewController.h"
#import "ForumEvents.h"

@interface ForumTutorialViewController () <UIScrollViewDelegate>

@property (assign, nonatomic) BOOL finished;
@property (assign, nonatomic) NSInteger step;

@property (weak, nonatomic) IBOutlet UIView *viewStep1;
@property (weak, nonatomic) IBOutlet UIView *viewStep1Bg;

@property (weak, nonatomic) IBOutlet UIView *viewStep2;

@property (weak, nonatomic) IBOutlet UIView *viewStep3;
@property (weak, nonatomic) IBOutlet UIView *viewStep3Bg;
@property (weak, nonatomic) IBOutlet UIScrollView *step3ScrollView;

@property (weak, nonatomic) IBOutlet UIImageView *gestureFinger;
@property (assign, nonatomic) BOOL swipeAnimating;
@property (assign, nonatomic) BOOL tapAnimating;

@property (weak, nonatomic) IBOutlet UIView *tapDot1;
@property (weak, nonatomic) IBOutlet UIView *tapDot2;

@end

@implementation ForumTutorialViewController

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
    [self setupTutorialScreens];
}

- (void)setupTutorialScreens
{
    self.tapDot1.layer.cornerRadius = self.tapDot1.width / 2.0;
    self.tapDot2.layer.cornerRadius = self.tapDot2.width / 2.0;
    self.viewStep1Bg.backgroundColor = [UIColor clearColor];
    [self.viewStep1Bg setGradientBackground:[UIColor colorWithWhite:0.0 alpha:0.8] toColor:[UIColor colorWithWhite:0.0 alpha:1.0]];
    
    self.viewStep3Bg.backgroundColor = [UIColor clearColor];
    [self.viewStep3Bg setGradientBackground:[UIColor colorWithWhite:0.0 alpha:0.8] toColor:[UIColor colorWithWhite:0.0 alpha:1.0]];
    self.tapDot1.hidden = YES;
    self.tapDot2.hidden = YES;
    self.gestureFinger.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)start
{
    [self publish:EVENT_FORUM_TUTORIAL_DID_START];
    self.finished = NO;
    self.view.userInteractionEnabled = YES;
    [self step1];
}

- (void)step1
{
    self.step = 1;
    [self startTapAnimation:CGPointMake(40.0, 40.0)];
    __weak ForumTutorialViewController *wself = self;
    [self subscribeOnce:EVENT_FORUM_BACK_TO_GROUP handler:^(Event *event) {
        [GLUtils performInMainQueueAfter:0.1 callback:^{
            [wself step2];
        }];
    }];
    self.viewStep1.hidden = NO;
    self.viewStep1.alpha = 0.0;
    [UIView animateWithDuration:0.25 animations:^{
        self.viewStep1.alpha = 1.0;
    }];
}

- (void)step2
{
    self.step = 2;
    [self stopTapAnimation];
    self.view.userInteractionEnabled = NO;
    self.gestureFinger.hidden = YES;
    __weak ForumTutorialViewController *wself = self;
//    [self subscribeOnce:EVENT_FORUM_ROOMS_WILL_HIDE handler:^(Event *event) {
//        wself.view.userInteractionEnabled = YES;
//        [UIView animateWithDuration:0.25 animations:^{
//            wself.viewStep2.alpha = 0.0;
//        } completion:^(BOOL finished) {
//            wself.viewStep2.hidden = YES;
//        }];
//    }];
//    [self subscribeOnce:EVENT_FORUM_ROOMS_DID_HIDE handler:^(Event *event) {
//        [Utils performInMainQueueAfter:0.1 callback:^{
//            [wself step3];
//        }];
//    }];
//    self.viewStep2.hidden = NO;
//    self.viewStep2.alpha = 0.0;
    [UIView animateWithDuration:0.25 animations:^{
        self.viewStep1.alpha = 0.0;
//        self.viewStep2.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.viewStep1.hidden = YES;
        [wself step3];
    }];
}

- (void)step3
{
    return;
    /*
    self.step = 3;
    self.view.userInteractionEnabled = YES;
    UIScrollView *scrollView = self.forumViewController.scrollView;
    self.step3ScrollView.frame = scrollView.frame;
    self.step3ScrollView.contentSize = scrollView.contentSize;
    self.step3ScrollView.contentOffset = scrollView.contentOffset;
    self.step3ScrollView.contentInset = scrollView.contentInset;
    self.step3ScrollView.scrollIndicatorInsets = scrollView.scrollIndicatorInsets;
    __weak ForumTutorialViewController *wself = self;
    [self subscribeOnce:EVENT_FORUM_ROOMS_DID_CHANGE handler:^(Event *event) {
        [Utils performInMainQueueAfter:0.1 callback:^{
            [wself finish];
        }];
    }];
    self.viewStep3.hidden = NO;
    self.viewStep3.alpha = 0.0;
    [self startSwipeAnimation:500.0];
    [UIView animateWithDuration:0.25 animations:^{
        self.viewStep3.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.viewStep2.hidden = YES;
    }];
     */
}

- (void)finish
{
    [self stopSwipeAnimation];
    self.gestureFinger.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.viewStep3.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.viewStep3.hidden = YES;
        self.finished = YES;
        [[GLDropdownMessageController sharedInstance] postMessage:@"Yay! Glow Community welcomes you!" duration:3 position:84 inView:self.view.window];
        [self publish:EVENT_FORUM_TUTORIAL_COMPLETE];
    }];
}

- (IBAction)showRooms:(id)sender
{
    [self publish:EVENT_FORUM_CLICK_GROUPS_BTN];
}

- (void)startSwipeAnimation:(CGFloat)offsetY {
    self.swipeAnimating = YES;
    self.gestureFinger.transform = CGAffineTransformIdentity;
    self.gestureFinger.layer.anchorPoint = CGPointMake(0.5, 3.0);
    self.gestureFinger.center = CGPointMake(160, offsetY);
    self.gestureFinger.hidden = NO;
    self.gestureFinger.alpha = 1.0;
    [self swipeFromRightToLeft];
}

- (void)stopSwipeAnimation {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(swipeFromRightToLeft) object:nil];
    self.swipeAnimating = NO;
    self.gestureFinger.transform = CGAffineTransformIdentity;
    self.gestureFinger.hidden = YES;
    self.gestureFinger.alpha = 1.0;
}

- (void)swipeFromRightToLeft {
    self.gestureFinger.transform = CGAffineTransformMakeRotation(0.8 / M_PI);
    self.gestureFinger.alpha = 0;
    [GLAnimationSequence performAnimations:@[[GLAnimationBlock duration:0.5 animations:^{
        self.gestureFinger.alpha = 1.0;
    }], [GLAnimationBlock duration:1.0 animations:^{
        self.gestureFinger.transform = CGAffineTransformMakeRotation(-0.8 / M_PI);
        self.gestureFinger.alpha = 1.0;
    }], [GLAnimationBlock duration:0.5 delay:0.5 options:0 animations:^{
        self.gestureFinger.alpha = 0;
    }]] completion:^(BOOL finished) {
        if (self.swipeAnimating)
            [self swipeFromRightToLeft];
    }];
}

- (void)startTapAnimation:(CGPoint)offset {
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
    [GLAnimationSequence performAnimations:@[[GLAnimationBlock duration:0.5 animations:^{
        self.gestureFinger.transform = CGAffineTransformMakeScale(1.2, 1.2);
        self.tapDot2.transform = CGAffineTransformMakeScale(1.5, 1.5);
        self.tapDot2.alpha = 0.0;
    }], [GLAnimationBlock duration:0.25 animations:^{
        self.gestureFinger.transform = CGAffineTransformIdentity;
        self.tapDot2.transform = CGAffineTransformIdentity;
    }]] completion:^(BOOL finished) {
        self.tapDot2.alpha = 1.0;
        if (self.tapAnimating)
            [self animateTap];
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    /*
    if (scrollView == self.step3ScrollView) {
        self.forumViewController.scrollView.contentOffset = scrollView.contentOffset;
    }
    */
}

+ (BOOL)hasCompletedForumTutorial
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_COMPLETED_FORUM_TUTORIAL];
}

+ (void)setCompletedForumTutorial:(BOOL)completed
{
    [[NSUserDefaults standardUserDefaults] setBool:completed forKey:KEY_COMPLETED_FORUM_TUTORIAL];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
