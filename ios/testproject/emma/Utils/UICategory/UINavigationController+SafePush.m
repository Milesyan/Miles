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
    if (self.topViewController && self.topViewController != fromViewController) {
        return;
    }
    [self pushViewController:viewController animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated from:(UIViewController *)fromViewController {
    if (self.topViewController && self.topViewController != fromViewController) {
        return;
    }
    [self popViewControllerAnimated:animated];
}

@end
