//
//  PushbackTransitioningDelegate.h
//  emma
//
//  Created by Ryan Ye on 10/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InteractivePull : UIPercentDrivenInteractiveTransition
@property (nonatomic, retain)UIViewController *viewController;
@property (nonatomic)BOOL started;
@property (nonatomic)BOOL enabled;
@property (nonatomic)BOOL dragged;
@end

@interface PushbackTransitioningDelegate : NSObject<UIViewControllerTransitioningDelegate>
- (void)enableInteractiveDismissal:(UIViewController *)controller;
@property (nonatomic, retain)InteractivePull *interactivePull;
@end
