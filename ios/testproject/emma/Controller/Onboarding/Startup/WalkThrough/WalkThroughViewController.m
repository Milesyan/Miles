//
//  WalkThroughViewController.m
//  emma
//
//  Created by Peng Gu on 8/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "WalkThroughViewController.h"
#import "StartupViewController.h"
#import "UIView+Helpers.h"
#import "StartupPageControl.h"
#import "UIImage+blur.h"

@interface WalkThroughViewController () <UIScrollViewDelegate>

@property (nonatomic, assign) CGFloat lastContentOffsetX;
@property (nonatomic, assign) NSInteger targetPageIndexOfProgramaticallyScrolling;
@property (nonatomic, strong) UIImageView *blurredCoverView;
@end


@implementation WalkThroughViewController

@synthesize pagingWidth = _pagingWidth;
@synthesize walkThroughViews = _walkThroughViews;

- (id)init
{
    return [self initWithWalkThroughViews:nil];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([Utils getDefaultsForKey:USER_DEFAULTS_KEY_UNDER_HOME_PAGE_TRANSITION]) {
        return;
    }
    
    [Logging syncLog:PAGE_IMP_START_WALK_THROUGH eventData:@{@"step": @(0)}];
}


- (id)initWithWalkThroughViews:(NSArray *)views
{
    self = [super init];
    if (self) {
        self.view.frame = setRectY(self.view.frame, 0);
        _targetPageIndexOfProgramaticallyScrolling = -1;
        _pagingWidth = SCREEN_WIDTH;
        _walkThroughViews = views;
        [self setupViews];
    }
    return self;
}


#pragma mark - getters / setters
- (CGFloat)pagingWidth
{
    if (_pagingWidth == 0) {
        _pagingWidth = SCREEN_WIDTH;
    }
    return _pagingWidth;
}


- (void)setPagingWidth:(CGFloat)pagingWidth
{
    if (_pagingWidth != pagingWidth) {
        _pagingWidth = pagingWidth;
        self.scrollView.frame = [self frameForScrollView];
    }
}


- (void)setWalkThroughViews:(NSArray *)walkThroughViews
{
    _walkThroughViews = walkThroughViews;
    [self setupViews];
}


- (void)setBackgroundView:(UIImageView *)backgroundView
{
    if (_backgroundView) {
        [_backgroundView removeFromSuperview];
    }
    _backgroundView = backgroundView;
    [self.view insertSubview:_backgroundView atIndex:0];
    
    [_backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (StartupPageControl *)pageControl
{
    if (!_pageControl) {
        _pageControl = [[StartupPageControl alloc] init];
        _pageControl.numberOfPages = self.walkThroughViews.count;
        _pageControl.size = CGSizeMake(22 * _pageControl.numberOfPages, 36);
        
        CGFloat y = SCREEN_HEIGHT - 160;
        _pageControl.top = y;
        _pageControl.centerX = self.view.centerX;
        
        [_pageControl addTarget:self action:@selector(pageControlClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pageControl;
}


- (void)setShowPageControl:(BOOL)showPageControl
{
    self.pageControl = nil;
    
    if (showPageControl) {
        [self.view addSubview:self.pageControl];
    }
}


- (void)setCurrentStep:(NSUInteger)currentStep
{
    _currentStep = currentStep;
    self.pageControl.currentPage = currentStep;
}


#pragma mark - views
- (CGRect)frameForScrollView
{
    CGRect frame = self.view.bounds;
    frame.origin.x = (CGRectGetWidth(frame) - self.pagingWidth) / 2;
    frame.size.width = self.pagingWidth;
    
    return frame;
}


- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:[self frameForScrollView]];
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.scrollEnabled = YES;
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.userInteractionEnabled = YES;
        _scrollView.clipsToBounds = NO;
        
        _scrollView.delegate = self;
        [self.view addSubview:_scrollView];
    }
    return _scrollView;
}


- (void)setupViews
{
    if (!self.walkThroughViews || self.walkThroughViews.count == 0) {
        return;
    }
    
    CGFloat contentWidth = 0;
    for (UIView *view in self.walkThroughViews) {
        view.left = contentWidth;
        contentWidth += SCREEN_WIDTH;
        [view layoutIfNeeded];
        [self.scrollView addSubview:view];
    }
    self.scrollView.contentSize = CGSizeMake(contentWidth, self.scrollView.contentSize.height);
    
    self.showPageControl = YES;
    
    self.blurredCoverView = [[UIImageView alloc]init];
    self.blurredCoverView.width = SCREEN_WIDTH;
    self.blurredCoverView.height = SCREEN_HEIGHT;
    self.blurredCoverView.image = [self.backgroundView.image applyBlurWithRadius:7 tintColor:nil saturationDeltaFactor:1 maskImage:nil];
    self.blurredCoverView.alpha = 0;
    [self.view insertSubview:self.blurredCoverView belowSubview:self.scrollView];
}


#pragma mark - Actions
- (void)pageControlClicked:(id)sender
{
    NSUInteger index = self.pageControl.currentPage;
    if (index > self.currentStep) {
        [self transiteToStep:self.currentStep+1 animated:YES];
    }
    else if (index < self.currentStep) {
        [self transiteToStep:self.currentStep-1 animated:YES];
    }
}


- (void)transiteToStep:(NSUInteger)stepIndex animated:(BOOL)animated
{
    if (stepIndex < self.walkThroughViews.count) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(walkThroughViewController:willTransiteFromView:atIndex:toView:atIndex:)]) {
            [self.delegate walkThroughViewController:self
                                willTransiteFromView:[self.walkThroughViews objectAtIndex:self.currentStep] atIndex:self.currentStep
                                              toView:[self.walkThroughViews objectAtIndex:stepIndex] atIndex:stepIndex];
        }
        
        self.targetPageIndexOfProgramaticallyScrolling = stepIndex;
        
        UIView *view = [self.walkThroughViews objectAtIndex:stepIndex];
        CGPoint offset = self.scrollView.contentOffset;
        offset.x = view.left;
        [self.scrollView setContentOffset:offset animated:animated];
    }
}


# pragma mark - Scroll View Delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSUInteger toViewIndex = [self getScrollingToPageIndex];
    UIView *fromView = self.walkThroughViews[self.currentStep];
    UIView *toView = self.walkThroughViews[toViewIndex];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(walkThroughViewController:willTransiteFromView:atIndex:toView:atIndex:)]) {
        [self.delegate walkThroughViewController:self
                            willTransiteFromView:fromView atIndex:self.currentStep
                                          toView:toView atIndex:toViewIndex];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSUInteger toViewIndex = [self getScrollingToPageIndex];
    if (self.targetPageIndexOfProgramaticallyScrolling >= 0) {
        toViewIndex = self.targetPageIndexOfProgramaticallyScrolling;
    }
    
    UIView *fromView = self.walkThroughViews[self.currentStep];
    UIView *toView = self.walkThroughViews[toViewIndex];
    
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat ratio = 1 - fabsf(CGRectGetMinX(toView.frame) - offsetX) / self.pagingWidth;
    
    if (offsetX <= self.pagingWidth) {
        self.blurredCoverView.alpha = offsetX / self.pagingWidth;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(walkThroughViewController:isTransitingFromView:atIndex:toView:atIndex:withCompletionRatio:)]) {
        [self.delegate walkThroughViewController:self
                            isTransitingFromView:fromView atIndex:self.currentStep
                                          toView:toView atIndex:toViewIndex
                             withCompletionRatio:MIN(ratio, 1.0f)];
    }
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    // won't be called if this scrolls by code instead of user interaction
    //  so we call didEndDecelerating to update currentStep and call delegate method
    self.targetPageIndexOfProgramaticallyScrolling = -1;
    [self scrollViewDidEndDecelerating:scrollView];
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSUInteger previousPage = self.currentStep;
    NSUInteger currentPage = [self getCurrentPageIndex];
    UIView *fromView = self.walkThroughViews[self.currentStep];
    UIView *toView = self.walkThroughViews[currentPage];
    self.currentStep = currentPage;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(walkThroughViewController:didTransiteFromView:atIndex:toView:atIndex:)]) {
        [self.delegate walkThroughViewController:self
                             didTransiteFromView:fromView atIndex:previousPage
                                          toView:toView atIndex:currentPage];
    }
}


#pragma mark - helpers
- (NSUInteger)getScrollingToPageIndex
{
    CGPoint translation = [self.scrollView.panGestureRecognizer translationInView:self.scrollView.superview];
    
    // towards to the right
    if (translation.x < 0) {
        NSUInteger lastPageIndex = self.walkThroughViews.count - 1;
        return self.currentStep == lastPageIndex ? lastPageIndex : self.currentStep + 1;
    }
    else if (translation.x > 0) {
        return self.currentStep == 0 ? 0 : self.currentStep - 1;
    }
    
    return self.currentStep;
}


- (NSUInteger)getCurrentPageIndex
{
    if (!self.walkThroughViews || self.walkThroughViews.count < 2) {
        return 0;
    }
    
    CGPoint centerPoint = self.scrollView.contentOffset;
    centerPoint.x += self.pagingWidth / 2;
    centerPoint.y = CGRectGetMidY([self.walkThroughViews[0] frame]);
    
    for (UIView *view in self.walkThroughViews) {
        if (CGRectContainsPoint(view.frame, centerPoint)) {
            return [self.walkThroughViews indexOfObject:view];
        }
    }
    return 0;
}


@end






