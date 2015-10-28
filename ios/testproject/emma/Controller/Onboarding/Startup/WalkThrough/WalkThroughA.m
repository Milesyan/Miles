//
//  WalkThrough.m
//  emma
//
//  Created by Peng Gu on 8/25/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "WalkThroughA.h"
#import "UIView+Helpers.h"
#import "StartupPageControl.h"

#define BLUE_FADE_IN_START 0
#define BLUE_FADE_IN_END 0.3f
#define BLUE_GLOW_ZOOM_IN_START 0.1f
#define BLUE_GLOW_ZOOM_IN_END 0.4f
#define BLUE_GLOW_SCALE 1.6f

#define RED_FADE_IN_START 0.2
#define RED_FADE_IN_END 0.5f
#define RED_GLOW_ZOOM_IN_START 0.3f
#define RED_GLOW_ZOOM_IN_END 0.6f
#define RED_GLOW_SCALE 1.62f

#define GREEN_FADE_IN_START 0.4
#define GREEN_FADE_IN_END 0.7f
#define GREEN_GLOW_ZOOM_IN_START 0.5f
#define GREEN_GLOW_ZOOM_IN_END 0.9f
#define GREEN_GLOW_SCALE 2.3f



@interface WalkThroughA ()

@property (nonatomic, weak) IBOutlet UIView *backgroundContainerView;

@property (nonatomic, weak) IBOutlet UIView *stepOneBackgroundView;
@property (nonatomic, weak) IBOutlet UIView *stepTwoBackgroundView;
@property (nonatomic, weak) IBOutlet UIView *stepThreeBackgroundView;

@property (nonatomic, weak) IBOutlet UIImageView *stepOneBackgroundImageView;
@property (nonatomic, weak) IBOutlet UIImageView *stepTwoBackgroundImageView;
@property (nonatomic, weak) IBOutlet UIImageView *stepThreeBackgroundImageView;
@property (nonatomic, weak) IBOutlet UIImageView *stepThreeImageView;

@property (nonatomic, weak) IBOutlet UIView *stepOneView;
@property (nonatomic, weak) IBOutlet UIView *stepTwoView;
@property (nonatomic, weak) IBOutlet UIView *stepThreeView;

@property (nonatomic, weak) IBOutlet UIView *greenCycleOuter;
@property (nonatomic, weak) IBOutlet UIView *greenCycleInner;
@property (nonatomic, weak) IBOutlet UIView *redCycleOuter;
@property (nonatomic, weak) IBOutlet UIView *redCycleInner;
@property (nonatomic, weak) IBOutlet UIView *blueCycleOuter;
@property (nonatomic, weak) IBOutlet UIView *blueCycleInner;

@end


@implementation WalkThroughA

- (void)setupViews
{
    self.walkThroughViews = @[self.stepOneView, self.stepTwoView, self.stepThreeView];
    self.backgroundViews = @[self.stepThreeBackgroundView, self.stepTwoBackgroundView, self.stepOneBackgroundView];
    
    self.walkThroughViewController.backgroundView = self.backgroundContainerView;
    self.walkThroughViewController.walkThroughViews = self.walkThroughViews;
    
    if (self.walkThroughViewController.pageControl) {
        CGFloat offset = IS_IPHONE_4 ? 33: 20;
        self.walkThroughViewController.pageControl.top += offset;
    }
    
    CGFloat top = IS_IPHONE_4 ? 308 : 358;
    for (UIView *view in self.walkThroughViews) {
        view.top = top;
    }
    for (UIView *backgroundView in self.backgroundViews) {
        backgroundView.frame = setRectHeight(backgroundView.frame, self.backgroundContainerView.frame.size.height);
        [self.backgroundContainerView addSubview:backgroundView];
    }
    
    self.stepOneBackgroundImageView.image = [Utils imageNamed:@"startup1"];
    self.stepTwoBackgroundImageView.image = [Utils imageNamed:@"startup2"];
    self.stepThreeBackgroundImageView.image = [Utils imageNamed:@"startup2"];
    self.stepThreeImageView.image = [Utils imageNamed:@"startup3"];
    
    NSArray *cycles = @[self.greenCycleInner, self.greenCycleOuter, self.redCycleInner, self.redCycleOuter, self.blueCycleInner, self.blueCycleOuter];
    for (UIView *view in cycles) {
        view.layer.cornerRadius = view.height * 0.5;
    }
}


#pragma mark - WalkThroughViewController Delegate
- (void)walkThroughViewController:(WalkThroughViewController *)viewController
             willTransiteFromView:(UIView *)fromView atIndex:(NSUInteger)fromIndex
                           toView:(UIView *)view atIndex:(NSUInteger)toIndex
{
    
}


- (void)walkThroughViewController:(WalkThroughViewController *)viewController
             isTransitingFromView:(UIView *)fromView atIndex:(NSUInteger)fromIndex
                           toView:(UIView *)toView atIndex:(NSUInteger)toIndex
              withCompletionRatio:(CGFloat)completionRatio
{
    if (fromIndex == toIndex) {
        return;
    }
    
    if (toIndex == 0) {
        [self animateTransitionFromStepTwoToOneWithRatio:completionRatio];
    }
    else if (toIndex == 1 && fromIndex == 0) {
        [self animateTransitionFromStepOneToTwoWithRatio:completionRatio];
    }
    else if (toIndex == 1 && fromIndex == 2) {
        [self animateTransitionFromStepThreeToTwoWithRatio:completionRatio];
    }
    else if (toIndex == 2) {
        [self animateTransitionFromStepTwoToThreeWithRatio:completionRatio];
    }
}


- (void)walkThroughViewController:(WalkThroughViewController *)viewController
              didTransiteFromView:(UIView *)fromView atIndex:(NSUInteger)fromIndex
                           toView:(UIView *)toView atIndex:(NSUInteger)toIndex
{
}


#pragma mark - Scrolling Animation
- (void)animateTransitionFromStepTwoToOneWithRatio:(CGFloat)ratio
{
    if (self.stepThreeBackgroundView.alpha != 0) {
        self.stepThreeBackgroundView.alpha = 0;
        [self.backgroundContainerView bringSubviewToFront:self.stepOneBackgroundView];
    }
    
    self.stepOneBackgroundView.alpha = ratio;
    self.stepTwoBackgroundView.alpha = 1 - ratio;
    [self animateStepTwoBubblesWithRatio:1 - ratio];
}


- (void)animateTransitionFromStepOneToTwoWithRatio:(CGFloat)ratio
{
    if (self.stepThreeBackgroundView.alpha != 0) {
        self.stepThreeBackgroundView.alpha = 0;
        [self.backgroundContainerView bringSubviewToFront:self.stepTwoBackgroundView];
    }
    
    self.stepOneBackgroundView.alpha = 1 - ratio;
    self.stepTwoBackgroundView.alpha = ratio;
    [self animateStepTwoBubblesWithRatio:ratio];
}


- (void)animateTransitionFromStepThreeToTwoWithRatio:(CGFloat)ratio
{
    if (self.stepOneBackgroundView.alpha != 0) {
        self.stepOneBackgroundView.alpha = 0;
        [self.backgroundContainerView bringSubviewToFront:self.stepTwoBackgroundView];
    }
    
    self.stepTwoBackgroundView.alpha = ratio;
    self.stepThreeBackgroundView.alpha = 1 - ratio;
    [self animateStepTwoBubblesWithRatio:ratio];
    
    self.stepThreeImageView.top = 40 * ratio;
}


- (void)animateTransitionFromStepTwoToThreeWithRatio:(CGFloat)ratio
{
    if (self.stepOneBackgroundView.alpha != 0) {
        self.stepOneBackgroundView.alpha = 0;
        [self.backgroundContainerView bringSubviewToFront:self.stepThreeBackgroundView];
    }
    
    self.stepTwoBackgroundView.alpha = 1 - ratio;
    self.stepThreeBackgroundView.alpha = ratio;
    [self animateStepTwoBubblesWithRatio:1 - ratio];
    
    self.stepThreeImageView.top = 40 * (1.0f - ratio);
}


- (void)animateStepTwoBubblesWithRatio:(CGFloat)ratio
{
    self.blueCycleOuter.alpha = (ratio - BLUE_FADE_IN_START) / (BLUE_FADE_IN_END - BLUE_FADE_IN_START);
    self.redCycleOuter.alpha = (ratio - RED_FADE_IN_START) / (RED_FADE_IN_END - RED_FADE_IN_START);
    self.greenCycleOuter.alpha = (ratio - GREEN_FADE_IN_START) / (GREEN_FADE_IN_END - GREEN_FADE_IN_START);

    CGFloat scaleP = (ratio - BLUE_GLOW_ZOOM_IN_START) * (BLUE_GLOW_SCALE - 1.0f) / (BLUE_GLOW_ZOOM_IN_END - BLUE_GLOW_ZOOM_IN_START) + 1.0f;
    scaleP = MIN(scaleP, BLUE_GLOW_SCALE);
    self.blueCycleInner.transform = CGAffineTransformMakeScale(scaleP, scaleP);
    
    CGFloat scaleR = (ratio - RED_GLOW_ZOOM_IN_START) * (RED_GLOW_SCALE - 1.0f) / (RED_GLOW_ZOOM_IN_END - RED_GLOW_ZOOM_IN_START) + 1.0f;
    scaleR = MIN(scaleR, RED_GLOW_SCALE);
    self.redCycleInner.transform = CGAffineTransformMakeScale(scaleR, scaleR);
    
    CGFloat scaleG = (ratio - GREEN_GLOW_ZOOM_IN_START) * (GREEN_GLOW_SCALE - 1.0f) / (GREEN_GLOW_ZOOM_IN_END - GREEN_GLOW_ZOOM_IN_START) + 1.0f;
    scaleG = MIN(scaleG, GREEN_GLOW_SCALE);
    self.greenCycleInner.transform = CGAffineTransformMakeScale(scaleG, scaleG);
}



@end






