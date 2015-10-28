//
//  PushbackTransitioningDelegate.m
//  emma
//
//  Created by Ryan Ye on 10/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "PushbackTransitioningDelegate.h"
#define PULL_COMPLETION_THRESHOLD 0.2f

@interface PushbackAnimator : NSObject<UIViewControllerAnimatedTransitioning>
@property (nonatomic)BOOL dismissing;
@end

@implementation PushbackAnimator 
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
   return 0.3f;
}
 
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    // Grab the from and to view controllers from the context
    UIView *containerView = [transitionContext containerView];
    UIView *fromView = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey].view;
    UIView *toView = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey].view;
    CGFloat duration = [self transitionDuration:transitionContext];

    CGFloat scale = 0.85f;
    if (!self.dismissing) {
        [containerView addSubview:toView];
        toView.frame = CGRectOffset(fromView.frame, 0, containerView.frame.size.height);
        [UIView animateWithDuration:duration animations:^{
            toView.frame = fromView.frame;
            fromView.center = CGPointMake(160, fromView.frame.size.height * scale / 2);
            fromView.transform =  CGAffineTransformMakeScale(scale, scale);
            fromView.alpha = 0;
        } completion:^(BOOL finished) {
            fromView.transform = CGAffineTransformIdentity;
            fromView.alpha = 1.0;
            [fromView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    } else {
        // cancelInteractiveTransition bug fix begin
        /*
         * Please do not change
         *
         * We have a bug, that, if we drag a very little distance on screen,
         * interactivePull.cancelInteractiveTransition will be called before the 
         * animation starts ( dismiss view controller )
         * In this case, the dismiss animation will start, but with duration=0,
         * even we set the duration be 0.3 sec, it does not work, since the animation
         * should be cancelled.
         * The animation "completion" function will not be called, if the animation 
         * duration=0. It will be called in next animation loop. See IOS spec.
         * So, "transitionContext completeTransition" will not be called. Thus the App
         * stops at "dismissing" view controller without crash. 
         * If press "Home" button and launch app again, everything fine. The animation
         * callback - "completion" will be called.
         *
         * To fix this problem, we should not start the animation if the drag is too small
         *
         * interactivePull.dragged 
         *     - indicates that the dismiss is from user's drag, not from "back button"
         * interactivePull.started
         *     - indicates that the drag is finished, ( cancel is called before dismiss )
         *
         * contact jirong@ to learn more,    - 2014/02/25
         */
        UIViewController * controller = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        PushbackTransitioningDelegate * pushDelegate = (PushbackTransitioningDelegate *)controller.transitioningDelegate;
        if ((pushDelegate.interactivePull.dragged == YES) && (pushDelegate.interactivePull.started == NO)) {
            pushDelegate.interactivePull.dragged = NO;
            [transitionContext completeTransition:NO];
            return;
        }
        // cancelInteractiveTransition bug fix end
        
        [containerView insertSubview:toView belowSubview:fromView];
        toView.alpha = 0;
        toView.frame = fromView.frame;
        toView.transform =  CGAffineTransformMakeScale(scale, scale);
        toView.center = CGPointMake(160, fromView.frame.size.height * scale / 2);
        [UIView animateWithDuration:duration animations:^{
            toView.alpha = 1.0;
            toView.transform =  CGAffineTransformIdentity;
            toView.frame = fromView.frame;
            fromView.frame = CGRectOffset(fromView.frame, 0, containerView.frame.size.height);
        } completion:^(BOOL finished) {
            pushDelegate.interactivePull.dragged = NO;
            if ([transitionContext transitionWasCancelled]) {
                [transitionContext completeTransition:NO];
            } else {
                [fromView removeFromSuperview];
                [transitionContext completeTransition:YES];
            }
        }];
    }
}
@end

@interface InteractivePull () {
    BOOL _shouldComplete;
    UIPanGestureRecognizer *pan;
}
@end

@implementation InteractivePull
- (id)initWithViewController:(UIViewController *)controller{
    if (self = [super init]) {
        pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPull:)];
        self.viewController = controller;
        [self.viewController.view addGestureRecognizer:pan];
        self.dragged = NO;
    } 
    return self;
}

- (void)setEnabled:(BOOL)val {
    _enabled = val;
    pan.enabled = val;
    _dragged = NO;
}

- (void)onPull:(UIPanGestureRecognizer *)_pan {
    CGPoint translation = [pan translationInView:pan.view.superview];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            self.started = YES;
            self.dragged = YES;
            [self.viewController dismissViewControllerAnimated:YES completion:nil];
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGFloat percent = translation.y / pan.view.frame.size.height;
            percent = fmaxf(percent, 0.0);
            percent = fminf(percent, 1.0);
            [self updateInteractiveTransition:percent];
            _shouldComplete = percent >= PULL_COMPLETION_THRESHOLD;
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            self.started = NO;
            if (!_shouldComplete) {
                [self cancelInteractiveTransition];
            } else {
                [self finishInteractiveTransition];
            }
            break;
        default:
            break;
    }
}

//- (CGFloat)completionSpeed {
//    return 1 - self.percentComplete;
//}
@end

@interface PushbackTransitioningDelegate() {
    PushbackAnimator *animator; 
}
@end

@implementation PushbackTransitioningDelegate
-(id) init {
    if (self = [super init]) {
        animator = [[PushbackAnimator alloc] init];
    }
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    animator.dismissing = NO;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    animator.dismissing = YES;
    return animator;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.interactivePull.started ? self.interactivePull : nil;
}

- (void)enableInteractiveDismissal:(UIViewController *)controller {
    self.interactivePull = [[InteractivePull alloc] initWithViewController:controller];
}

@end
