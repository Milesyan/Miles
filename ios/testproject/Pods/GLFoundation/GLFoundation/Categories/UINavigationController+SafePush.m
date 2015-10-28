//
//  UINavigationController+SafePush.m
//  emma
//
//  Created by Jirong Wang on 2/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UINavigationController+SafePush.h"

@implementation UINavigationController (SafePush)

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated from:(UIViewController *)fromViewController {
    UIViewController *topParent = fromViewController.parentViewController;
    while (topParent.parentViewController
           && ![topParent.parentViewController isKindOfClass:[UINavigationController class]]
           && ![topParent.parentViewController isKindOfClass:[UITabBarController class]]) {
        topParent = topParent.parentViewController;
    }
    if (self.topViewController && self.topViewController != fromViewController && self.topViewController != topParent) {
        return;
    }
    [self pushViewController:viewController animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated from:(UIViewController *)fromViewController {
    UIViewController *topParent = fromViewController.parentViewController;
    while (topParent.parentViewController
           && ![topParent.parentViewController isKindOfClass:[UINavigationController class]]
           && ![topParent.parentViewController isKindOfClass:[UITabBarController class]]) {
        topParent = topParent.parentViewController;
    }
    if (self.topViewController && self.topViewController != fromViewController && self.topViewController != topParent) {
        return;
    }
    [self popViewControllerAnimated:animated];
}

@end
