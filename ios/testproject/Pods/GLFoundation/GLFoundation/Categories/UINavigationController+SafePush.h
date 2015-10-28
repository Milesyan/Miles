//
//  UINavigationController+SafePush.h
//  emma
//
//  Created by Jirong Wang on 2/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (SafePush)

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated from:(UIViewController *)fromViewController;
- (void)popViewControllerAnimated:(BOOL)animated from:(UIViewController *)fromViewController;

@end
