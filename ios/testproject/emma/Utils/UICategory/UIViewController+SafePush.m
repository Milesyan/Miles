//
//  UIViewController+SafePush.m
//  emma
//
//  Created by Jirong Wang on 2/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UIViewController+SafePush.h"

@implementation UIViewController (SafePush)

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender from:(UIViewController *)viewController {
    // This function can not work for a sub view controller
    if (self.navigationController && self.navigationController.topViewController && self.navigationController.topViewController != viewController) {
        return;
    }
    [self performSegueWithIdentifier:identifier sender:sender];
}

@end
