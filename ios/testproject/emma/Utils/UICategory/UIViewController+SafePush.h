//
//  UIViewController+SafePush.h
//  emma
//
//  Created by Jirong Wang on 2/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (SafePush)

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender from:(UIViewController *)viewController;

@end
