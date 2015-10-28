//
//  TLMenuInteractor.h
//  UIViewController-Transitions-Example
//
//  Created by Ash Furrow on 2013-07-18.
//  Copyright (c) 2013 Teehan+Lax. All rights reserved.
//
//  Renamed and modified by Xin Zhao on 2014-07-21

#import <UIKit/UIKit.h>

@protocol GLPushableViewControllerPanTarget <NSObject>

- (void)userDidPan:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer;

@end

@protocol GLPushablePresentee <NSObject>

- (void)setInteractorAsPanTarget:(id<GLPushableViewControllerPanTarget>)panTarget;

@end

@interface GLPushableInteractor : UIPercentDrivenInteractiveTransition
    <GLPushableViewControllerPanTarget>

-(id)initWithParentViewController:(UIViewController *)viewController;

@property (nonatomic, readonly) UIViewController *parentViewController;

-(void)presentMenu; // Presents the menu non-interactively
-(void)presentViewController:(UIViewController<GLPushablePresentee> *)presentee; // Presents the menu non-interactively

@end
