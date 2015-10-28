//
//  GLSlidingViewController.m
//  emma
//
//  Created by ltebean on 15-1-4.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "GLSlidingViewController.h"

@interface GLSlidingViewController ()<UIScrollViewDelegate>
@property(nonatomic) CGFloat beginOffset;
@property int currentPage;
@end

@implementation GLSlidingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.currentPage = 0;
}


- (UIScrollView*)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMinY(self.view.bounds), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
        [self.view addSubview:_scrollView];
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.directionalLockEnabled = YES;
    }
    return _scrollView;
}

- (void)addChildViewController:(UIViewController *)childController
{
    CGFloat width = CGRectGetWidth(self.scrollView.bounds);
    CGFloat height = CGRectGetHeight(self.scrollView.bounds);
    
    childController.view.frame = CGRectMake(width*self.childViewControllers.count, childController.view.frame.origin.y, width, height);
    [self.scrollView addSubview:childController.view];

    [super addChildViewController:childController];
    [childController didMoveToParentViewController:self];

    self.scrollView.contentSize = CGSizeMake(width*self.childViewControllers.count, height);
}

- (void)removeAllChildViewControllers
{
    [self.childViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *vc = (UIViewController *)obj;
        [vc willMoveToParentViewController:nil];
        [vc.view removeFromSuperview];
        [vc removeFromParentViewController];
    }];
    self.currentPage = 0;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    CGFloat offset = self.scrollView.contentOffset.x;
    
    CGFloat progress = MIN(1,fabs((offset - self.beginOffset)/pageWidth));
    
    UIViewController* sourceVC = self.childViewControllers[self.currentPage];
    UIView* sourceView = sourceVC.view;
    UIView* destView;
    
    int nextPage = (offset - self.beginOffset)>0? self.currentPage+1 :self.currentPage-1;
    if (nextPage >= 0 && nextPage < self.childViewControllers.count) {
        UIViewController* destinationVC = self.childViewControllers[nextPage];
        destView = destinationVC.view;
    }

    SlideDirection direction = (offset - self.beginOffset>0) ? right : left;
    if (self.animator) {
        [self.animator updateSourceView:sourceView destinationView:destView withProgress:progress direction:direction];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.beginOffset = self.scrollView.contentOffset.x;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = CGRectGetWidth(self.view.bounds);
    self.currentPage = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    [self didScrollToPage:self.currentPage];
}


- (void)scrollToPage:(int)page animated:(BOOL)animated
{
    CGFloat pageWidth = CGRectGetWidth(self.view.bounds);
    CGPoint offset = CGPointMake(pageWidth * page, 0);
    [self.scrollView setContentOffset:offset animated:animated];
}


- (void)didScrollToPage:(int)page
{
    
}

@end
