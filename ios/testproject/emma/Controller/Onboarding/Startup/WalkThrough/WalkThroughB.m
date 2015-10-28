//
//  WalkThroughB.m
//  emma
//
//  Created by Peng Gu on 8/26/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "WalkThroughB.h"

@interface WalkThroughB ()

@property (nonatomic, weak) IBOutlet UIView *backgroundView;
@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;

@property (nonatomic, weak) IBOutlet UIView *stepOneView;
@property (nonatomic, weak) IBOutlet UIView *stepTwoView;
@property (nonatomic, weak) IBOutlet UIView *stepThreeView;
@property (nonatomic, weak) IBOutlet UIView *stepFourView;

@property (nonatomic, weak) IBOutlet UIImageView *stepTwoImageView;
@property (nonatomic, weak) IBOutlet UIImageView *stepFourImageView;

@property (nonatomic, weak) IBOutlet UIView *stepThreeImageContainerView;
@property (nonatomic, weak) IBOutlet UIImageView *stepThreeImageView;
@property (nonatomic, weak) IBOutlet UIImageView *insightImageView;
@property (nonatomic, weak) IBOutlet UIImageView *bbtImageView;
@property (nonatomic, weak) IBOutlet UIImageView *checkImageView;
@property (nonatomic, weak) IBOutlet UIImageView *crossImageView;


@property (nonatomic, strong) IBOutletCollection(UILabel) NSArray *labels;
@property (nonatomic, strong) IBOutletCollection(NSLayoutConstraint) NSArray *imageHeightConstraints;
@property (nonatomic, strong) IBOutletCollection(NSLayoutConstraint) NSArray *imageTopMarginConstraints;
@property (nonatomic, strong) IBOutletCollection(NSLayoutConstraint) NSArray *textConstraintTop;
@property (nonatomic, strong) IBOutletCollection(NSLayoutConstraint) NSArray *buttonsConstraintTop;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *insightImageViewTopMarginConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *introLogoConstraintTop;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *introTextConstraintTop;

@property (nonatomic, assign) BOOL shouldStopAnimation;

@end


@implementation WalkThroughB

#define IMAGE_HEIGHT_FOR_IPHONE_5 318


- (void)setupViews
{
    self.walkThroughViews = @[self.stepOneView, self.stepTwoView, self.stepThreeView, self.stepFourView];
    for (UIView *view in self.walkThroughViews) {
        view.frame = [UIScreen mainScreen].bounds;
    }
    
    self.backgroundView.frame = [UIScreen mainScreen].bounds;
    self.walkThroughViewController.backgroundView = self.backgroundView;
    self.walkThroughViewController.walkThroughViews = self.walkThroughViews;
    
    if (HEIGHT_MORE_THAN_IPHONE_4 == 0) {
        for (NSLayoutConstraint *constraint in self.imageHeightConstraints) {
            constraint.constant = 241;
        }
    }
    
    CGFloat textTopPadding = (IS_IPHONE_6_PLUS ? 30 : (IS_IPHONE_6 ? 20 : 10));
    for (NSLayoutConstraint *constraint in self.textConstraintTop) {
        constraint.constant = textTopPadding;
    }
    
    if (IS_IPHONE_6_PLUS || IS_IPHONE_6) {
        for (NSLayoutConstraint *constraint in self.imageTopMarginConstraints) {
            constraint.constant = 60;
        }
        
        self.introLogoConstraintTop.constant += 30;
        self.introTextConstraintTop.constant += 20;
    }
    
    if (IS_IPHONE_6_PLUS) {
        for (NSLayoutConstraint *constraint in self.buttonsConstraintTop) {
            constraint.constant += 2;
        }
    }
    
    self.insightImageViewTopMarginConstraint.constant = CGRectGetHeight(self.stepThreeImageContainerView.frame);
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
    
}


- (void)walkThroughViewController:(WalkThroughViewController *)viewController
              didTransiteFromView:(UIView *)fromView atIndex:(NSUInteger)fromIndex
                           toView:(UIView *)toView atIndex:(NSUInteger)toIndex
{
    if (toIndex == 2) {
        [self runStepThreeAnimation];
    }
    else if (fromIndex == 2){
        [self stopStepThreeAnimation];
    }
}


#pragma mark - Animations
- (void)stopStepThreeAnimation
{
    self.shouldStopAnimation = YES;
    for (UIView *each in @[self.bbtImageView, self.checkImageView, self.crossImageView]) {
        [each.layer removeAllAnimations];
        each.transform = CGAffineTransformIdentity;
    }
    
    self.insightImageViewTopMarginConstraint.constant = CGRectGetHeight(self.stepThreeImageContainerView.frame);
}


- (void)runStepThreeAnimation
{
    self.shouldStopAnimation = NO;
    CGFloat animationDuration = 0.2;
    CGAffineTransform tranform = CGAffineTransformMakeScale(2, 2);
    
    void (^animationBlock)(UIImageView *, void (^)(BOOL finished)) = ^(UIImageView *imageView, void (^completion)(BOOL finished)) {
        if (self.shouldStopAnimation) {
            return;
        }
        
        [UIView animateWithDuration:animationDuration
                         animations:^{
                             imageView.transform = tranform;
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:animationDuration
                                              animations:^{
                                                  imageView.transform = CGAffineTransformIdentity;
                                              }
                                              completion:^(BOOL finished) {
                                                  if (completion) {
                                                      completion(finished);
                                                  }
            }];
        }];
    };
    
    void (^fourthAnimation)() = ^() {
        if (self.shouldStopAnimation) {
            return;
        }
        
        [self.insightImageView.superview bringSubviewToFront:self.insightImageView];
        [self.insightImageView.superview layoutIfNeeded];
        
        [UIView animateWithDuration:0.5 animations:^{
            self.insightImageViewTopMarginConstraint.constant = 0;
            [self.insightImageView.superview layoutIfNeeded];
        } completion:^(BOOL finished) {
            
        }];
    };

    void (^thirdAnimation)() = ^() {
        animationBlock(self.crossImageView, ^(BOOL finished) {
            fourthAnimation();
        });
    };
    
    void (^secondAnimation)() = ^() {
        animationBlock(self.checkImageView, ^(BOOL finished) {
            thirdAnimation();
        });
    };
    
    void (^firstAnimation)() = ^() {
        animationBlock(self.bbtImageView, ^(BOOL finished) {
            secondAnimation();
        });
    };
    
    firstAnimation();
}




@end





