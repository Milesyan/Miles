//
//  WalkThroughViewController.h
//  emma
//
//  Created by Peng Gu on 8/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@class WalkThroughViewController;
@class StartupPageControl;

#pragma mark - Data Source
@protocol WalkThroughViewControllerDataSource <NSObject>

@optional
- (NSUInteger)numberOfStepsForWalkThroughViewController:(WalkThroughViewController *)viewController;
- (UIView *)walkThroughViewController:(WalkThroughViewController *)viewController walkThroughViewForStepIndex:(NSUInteger)stepIndex;

@end


#pragma mark - Delegate
@protocol WalkThroughViewControllerDelegate <NSObject>

@optional
- (void)walkThroughViewController:(WalkThroughViewController *)viewController
             willTransiteFromView:(UIView *)fromView atIndex:(NSUInteger)fromIndex
                           toView:(UIView *)view atIndex:(NSUInteger)toIndex;

- (void)walkThroughViewController:(WalkThroughViewController *)viewController
             isTransitingFromView:(UIView *)fromView atIndex:(NSUInteger)fromIndex
                           toView:(UIView *)toView atIndex:(NSUInteger)toIndex
              withCompletionRatio:(CGFloat)completionRatio;

- (void)walkThroughViewController:(WalkThroughViewController *)viewController
              didTransiteFromView:(UIView *)fromView atIndex:(NSUInteger)fromIndex
                           toView:(UIView *)toView atIndex:(NSUInteger)toIndex;

@end


#pragma mark - Class
@interface WalkThroughViewController : UIViewController

@property (nonatomic, weak) id<WalkThroughViewControllerDelegate> delegate;
@property (nonatomic, weak) id<WalkThroughViewControllerDataSource> dataSource;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *backgroundView;
@property (nonatomic, strong) StartupPageControl *pageControl;

@property (nonatomic, strong) NSArray *walkThroughViews;
@property (nonatomic, assign) NSUInteger currentStep;
@property (nonatomic, assign) CGFloat pagingWidth;
@property (nonatomic, assign) BOOL showPageControl;


- (id)initWithWalkThroughViews:(NSArray *)views;

- (void)transiteToStep:(NSUInteger)stepIndex animated:(BOOL)animated;


@end
