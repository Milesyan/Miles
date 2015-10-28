//
//  FlipTransition.m
//  emma
//
//  Created by ltebean on 14-12-30.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "WalgreensFlipTransition.h"

@implementation WalgreensFlipTransition
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIView *containerView = [transitionContext containerView];
    
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [containerView addSubview:fromVC.view];
    
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [containerView addSubview:toVC.view];
    
    UIViewAnimationOptions animationOption = ([toVC.presentedViewController isEqual:fromVC])?UIViewAnimationOptionTransitionFlipFromLeft:UIViewAnimationOptionTransitionFlipFromRight;
    
    
    [UIView transitionFromView:fromVC.view
                        toView:toVC.view
                      duration:[self transitionDuration:transitionContext]
                       options:animationOption
                    completion:^(BOOL finished) {
                        [transitionContext completeTransition:YES];
                    }];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.6;
}
@end
