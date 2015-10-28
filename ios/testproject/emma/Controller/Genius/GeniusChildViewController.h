//
//  GeniusChildViewController.h
//  emma
//
//  Created by Ryan Ye on 7/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TRANSITION_TO_FULL_VIEW @"transition_to_full_view"
#define TRANSITION_TO_THUMB_VIEW @"transition_to_thumb_view"

typedef void(^transitionCallback)();

@interface GeniusChildViewController : UIViewController
@property (readonly) NSTimeInterval transitionDuration;
@property (readonly) BOOL inFullView;
@property (readonly) BOOL underZooming;
@property (nonatomic) int thumbTitleIndent;
@property (nonatomic, assign) BOOL isPresented;

+ (id)getInstance;
- (void)animateDebutForPos;

- (void)setupVarsWhenGeniusWillAppear;
- (void)teardownVarsWhenGeniusWillDisappear;
- (void)thumbClicked;
- (void)firstLaunchChild;
- (void)showThumbView;
- (void)showFullView;
- (void)thumbToFull;
- (void)thumbToFullCompletion;
- (void)fullToThumb;
- (void)fullToThumbCompletion;

- (void)transitionToFullView;
- (void)transitionToThumbView;
- (void)close;
- (void)closeWithCallback:(transitionCallback)callback;

- (UIView *)getThumbContainerView;
- (UIView *)getFullContainerView;


@end
