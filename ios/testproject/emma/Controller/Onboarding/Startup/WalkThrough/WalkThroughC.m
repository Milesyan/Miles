//
//  WalkThroughC.m
//  emma
//
//  Created by Peng Gu on 1/9/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "WalkThroughC.h"
#import "GLMeterView.h"
#import "NSString+Markdown.h"

#define kChecksContainerHeight 105
#define kChecksHiddenTopOffset 120
#define kSlideDuration 0.6
#define kZoomDuration 0.25
#define kCycleRotationInterval 1.7
#define kCycleRotationDuration 0.4
#define kCommunityContentHeightOffset 90

@interface WalkThroughC ()

@property (nonatomic, weak) IBOutlet UIView *backgroundView;
@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;

@property (nonatomic, weak) IBOutlet UIView *stepOneView;
@property (nonatomic, weak) IBOutlet UIView *stepTwoView;
@property (nonatomic, weak) IBOutlet UIView *stepThreeView;
@property (nonatomic, weak) IBOutlet UIView *stepFourView;

@property (nonatomic, weak) IBOutlet UIView *stepTwoCycleContainerView;
@property (nonatomic, strong) IBOutletCollection(UILabel) NSArray *cycleLabels;

@property (nonatomic, weak) IBOutlet GLMeterView *stepThreeHeartView;
@property (nonatomic, weak) IBOutlet UILabel *heartLabel;
@property (nonatomic, weak) IBOutlet UIView *stepThreeCheckContainerView;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *stepThreeCheckViews;
@property (nonatomic, strong) IBOutletCollection(UIImageView) NSArray *stepThreeCheckImageViews;
@property (nonatomic, strong) IBOutletCollection(UILabel) NSArray *checkLabels;
@property (nonatomic, strong) IBOutletCollection(NSLayoutConstraint) NSArray *checkTopConstraints;

@property (nonatomic, weak) IBOutlet UIImageView *communityFrameImageView;
@property (nonatomic, weak) IBOutlet UIImageView *communityContentImageView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *communityContentTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *communityImageContainerHeightConstraint;

@property (nonatomic, strong) IBOutletCollection(UILabel) NSArray *introLabels;
@property (nonatomic, strong) IBOutletCollection(UILabel) NSArray *mainTextLabels;
@property (nonatomic, strong) IBOutletCollection(NSLayoutConstraint) NSArray *textBottomConstraints;

@property (nonatomic, assign) BOOL shouldDoAnimation;
@property (nonatomic, strong) NSTimer *cycleRotationTimer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stepTwoChecksTop;
@end


@implementation WalkThroughC


- (void)setupViews
{
    self.walkThroughViews = @[self.stepOneView, self.stepTwoView, self.stepThreeView, self.stepFourView];
    for (UIView *view in self.walkThroughViews) {
        view.frame = [UIScreen mainScreen].bounds;
    }
    
    self.backgroundView.frame = [UIScreen mainScreen].bounds;
    self.walkThroughViewController.backgroundView = self.backgroundImageView;
    self.walkThroughViewController.walkThroughViews = self.walkThroughViews;
    
    // Text in all steps
    CGFloat textBottomMargin = (IS_IPHONE_6_PLUS ? 230 : (IS_IPHONE_6 ? 200 : (IS_IPHONE_5 ? 190 : 165)));
    for (NSLayoutConstraint *constraint in self.textBottomConstraints) {
        constraint.constant = textBottomMargin;
    }

    CGFloat fontSize = IS_IPHONE_6 || IS_IPHONE_6_PLUS ? 20 : 18;
    for (UILabel *label in self.mainTextLabels) {
        NSAttributedString *attrText = [NSString markdownToAttributedText:label.text
                                                                 fontSize:fontSize
                                                               lineHeight:fontSize * 1.3
                                                                    color:label.textColor
                                                                alignment:label.textAlignment];
        
        label.attributedText = attrText;
    }
    
    // Step one
    fontSize = (IS_IPHONE_6_PLUS ? 26 : (IS_IPHONE_6 ? 24 : (IS_IPHONE_5 ? 22 : 20)));
    for (UILabel *label in self.introLabels) {
        label.font = [Utils lightFont:fontSize];
    }
    
    // Step two
    for (UILabel *label in self.cycleLabels) {
        NSAttributedString *attrText = [NSString markdownToAttributedText:label.text
                                                                 fontSize:fontSize
                                                               lineHeight:fontSize * 1.3
                                                                    color:label.textColor
                                                                alignment:label.textAlignment];
        
        label.attributedText = attrText;
    }
    
    for (UIView *each in self.stepTwoCycleContainerView.subviews) {
        each.layer.cornerRadius = each.height / 2;
    }
    
    if (IS_IPHONE_4) {
        self.stepTwoChecksTop.constant = -10;
    }
    else if(IS_IPHONE_6){
        self.stepTwoChecksTop.constant = 10;
    }
    else if (IS_IPHONE_6_PLUS){
        self.stepTwoChecksTop.constant = 10;
    }

    // Step three
    fontSize = IS_IPHONE_6 || IS_IPHONE_6_PLUS ? 20 : 18;
    for (UILabel *label in self.checkLabels) {
        label.font = [Utils defaultFont:fontSize];
    }
    self.heartLabel.font = [Utils defaultFont:fontSize + 2];
    
    for (NSLayoutConstraint *each in self.checkTopConstraints) {
        each.constant = kChecksHiddenTopOffset;
    }
    
    [self.stepThreeHeartView drawHeart];

    // Step four
    if (IS_IPHONE_6_PLUS) {
        self.communityImageContainerHeightConstraint.constant = 277;
    }
}


#pragma mark - WalkThroughViewController Delegate
- (void)walkThroughViewController:(WalkThroughViewController *)viewController
             willTransiteFromView:(UIView *)fromView atIndex:(NSUInteger)fromIndex
                           toView:(UIView *)view atIndex:(NSUInteger)toIndex
{
    if (toIndex == 2 && fromIndex != 2) {
        [self stopStepThreeAnimation];
    }
    
    if (toIndex == 3 && fromIndex != 3) {
        [self stopStepFourAnimation];
    }
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
    if (toIndex == 1 && fromIndex != 1) {
        [self doStepTwoAnimation];
    }
    else if (toIndex == 2 && fromIndex != 2) {
        [self doStepThreeAnimation];
    }
    else if (toIndex == 3 && fromIndex != 3) {
        [self.communityContentImageView.layer removeAllAnimations];
        [self doStepFourAnimations];
    }
    
    if (fromIndex == 1 && toIndex != 1) {
        [self stopStepTwoAnimation];
    }
    else if (fromIndex == 2 && toIndex != 2) {
        [self stopStepThreeAnimation];
    }
    else if (fromIndex == 3 && toIndex != 3) {
        [self stopStepFourAnimation];
    }
    
    [Logging syncLog:PAGE_IMP_START_WALK_THROUGH eventData:@{@"step": @(toIndex)}];
}


#pragma mark - step two animations
- (void)doStepTwoAnimation
{
    [self doRotationAnimation];
    
    self.cycleRotationTimer = [NSTimer timerWithTimeInterval:kCycleRotationInterval
                                                      target:self
                                                    selector:@selector(doRotationAnimation)
                                                    userInfo:nil
                                                     repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:self.cycleRotationTimer forMode:NSDefaultRunLoopMode];
}


- (void)stopStepTwoAnimation
{
    [self.cycleRotationTimer invalidate];
    self.cycleRotationTimer = nil;
}


- (void)doRotationAnimation
{
    NSUInteger count = self.stepTwoCycleContainerView.subviews.count;
    UIView *currView = self.stepTwoCycleContainerView.subviews.lastObject;
    UIView *nextView = self.stepTwoCycleContainerView.subviews[count - 2];

    // hide all views except for current view
    for (UIView *view in self.stepTwoCycleContainerView.subviews){
        if (view != currView) {
            view.hidden = YES;
        }
    }
    currView.hidden = NO;
    
    // fix a autolayout bug in 7.x
    if ([[UIDevice currentDevice] systemVersion].floatValue < 8) {
        nextView.width = currView.width = self.stepTwoCycleContainerView.width * 0.6;
    }
    
    // flip current view from 0 to pi/2, then flip next view from -pi/2 to 0;
    [UIView animateWithDuration:kCycleRotationDuration/2
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DRotate(transform, M_PI/2 , 0.0f, 1.0f, 0.0f);
        transform.m34 = 1.0 / -500;
        currView.layer.transform = transform;
        
    } completion:^(BOOL finished) {
        currView.hidden = YES;
        nextView.hidden = NO;
        nextView.layer.transform = CATransform3DMakeRotation(-M_PI/2, 0.0f, 1.0f, 0.0f);
        
        [UIView animateWithDuration:kCycleRotationDuration/2
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
            CATransform3D transform = CATransform3DIdentity;
            transform = CATransform3DRotate(transform, 0 , 0.0f, 1.0f, 0.0f);
            transform.m34 = 1.0 / -500;
            nextView.layer.transform = transform;
                             
        } completion:^(BOOL finished) {
            [self.stepTwoCycleContainerView sendSubviewToBack:currView];
            [self.stepTwoCycleContainerView bringSubviewToFront:nextView];
            currView.hidden = YES;
        }];
    }];
    
}


#pragma mark - step three animations
- (void)doStepThreeAnimation
{
    for (UIView * view in self.stepThreeCheckViews) {
        view.alpha = 0;
    }
    self.shouldDoAnimation = YES;
    [self doSlideAnimation:0];
}


- (void)stopStepThreeAnimation
{
    self.shouldDoAnimation = NO;
    
    [self.stepThreeHeartView setProgress:0 animated:NO];
    
    for (NSLayoutConstraint *each in self.checkTopConstraints) {
        each.constant = kChecksHiddenTopOffset;
    }
    
    for (UIImageView *each in self.stepThreeCheckImageViews) {
        [each.layer removeAllAnimations];
        each.transform = CGAffineTransformIdentity;
    }
}


- (void)doSlideAnimation:(NSUInteger)index
{
    if (index >= self.stepThreeCheckViews.count || !self.shouldDoAnimation) {
        return;
    }
    
    [self.stepThreeCheckContainerView layoutIfNeeded];
    UIView *view = self.stepThreeCheckViews[index];
    NSLayoutConstraint *constraint = self.checkTopConstraints[index];
    view.alpha = 0;
    
    NSInteger previousIndex = index - 1;

    @weakify(self)
    [UIView animateWithDuration:kSlideDuration delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        @strongify(self)
        if (previousIndex >= 0) {
            NSLayoutConstraint *previousViewConstraint = self.checkTopConstraints[previousIndex];
            previousViewConstraint.constant = -10;
            UIView *previousView = self.stepThreeCheckViews[previousIndex];
            previousView.alpha = 0;
        }
        constraint.constant = 15;
        view.alpha = 1;
        [self.stepThreeCheckContainerView layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        @strongify(self)
        [self doZoomAnimation:index];

    }];
}


- (void)doZoomAnimation:(NSUInteger)index
{
    if (!self.shouldDoAnimation) {
        return;
    }
    
    UIImageView *checkImage = index < self.stepThreeCheckImageViews.count ? self.stepThreeCheckImageViews[index] : nil;
    GLMeterView *heartView = self.stepThreeHeartView;
    BOOL doNext = index < self.stepThreeCheckViews.count;
    
    @weakify(self)
    [UIView animateWithDuration:kZoomDuration
                     animations:^{
                         
                         checkImage.transform = CGAffineTransformMakeScale(1.5, 1.5);
                         
                     } completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:kZoomDuration - 0.1 animations:^{
                             
                             [heartView setProgress:0.33 * (index + 1) + 0.01 animated:YES];
                             checkImage.transform = CGAffineTransformIdentity;
                             
                         } completion:^(BOOL finished) {
                             @strongify(self)
                             if (doNext) {
                                 [self doSlideAnimation:index + 1];
                             }
                         }];
                     }];
}


#pragma mark - step four animations
- (void)doStepFourAnimations
{
    CGFloat duration = 0.4;
    CGFloat delay = 0.7;
    CGFloat offset = IS_IPHONE_6_PLUS ? 20 : 0;
    
    [self.communityContentImageView.superview layoutIfNeeded];
    [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveLinear animations:^{
        self.communityContentTopConstraint.constant = -kCommunityContentHeightOffset - offset;
        [self.communityContentImageView.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
//        [UIView animateWithDuration:duration-0.1 delay:delay+0.2 options:UIViewAnimationOptionCurveLinear animations:^{
//            self.communityContentTopConstraint.constant = -kCommunityContentHeightOffset - offset - 10;
//            [self.communityContentImageView.superview layoutIfNeeded];
//        } completion:^(BOOL finished) {
//            
//        }];
    }];
}


- (void)stopStepFourAnimation
{
    [self.communityContentImageView.layer removeAllAnimations];
    self.communityContentTopConstraint.constant = 0;
    [self.communityContentImageView.superview layoutIfNeeded];
}


@end





