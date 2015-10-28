//
//  GLHomeSummaryView.m
//  LTInfiniteScrollView
//
//  Created by ltebean on 14-12-16.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//


#import "GLDynamicContentScrollView.h"
#import "EXTScope.h"

#define animationDuration 0.5

@interface GLDynamicContentScrollView()<UIScrollViewDelegate>
@property(nonatomic,strong) UILabel* label;
@end

@implementation GLDynamicContentScrollView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    CGFloat width = CGRectGetWidth(self.bounds);
    
    self.scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, width, CGRectGetHeight(self.bounds))];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.delegate = self;
    
    [self addSubview:self.scrollView];
    
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    _scrollEnabled = scrollEnabled;
    self.scrollView.scrollEnabled = scrollEnabled;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.delegate scrollView:self internalScrollViewDidScroll:self.scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.delegate scrollView:self internalScrollViewDidEndDragging:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.delegate scrollView:self internalScrollViewDidEndDecelerating:self.scrollView];
}

- (void)setContentViewTop:(CGFloat)top animated:(BOOL)animated
{
    
    CGRect frame = self.contentView.frame;
    frame.origin.y = frame.origin.y - self.scrollView.contentOffset.y;
    self.contentView.frame=frame;
    
    self.scrollView.scrollEnabled = NO;
    self.scrollView.scrollEnabled = YES;

    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds), CGRectGetHeight(self.contentView.bounds)+top);
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
    
    frame.origin.y = top;
    
    if (animated) {
        @weakify(self)
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:5 options:0 animations:^{
            @strongify(self)
            self.contentView.frame = frame;
        } completion:^(BOOL finished) {
        }];
    } else {
        self.contentView.frame = frame;
    }
}

- (void)setContentViewHeight:(CGFloat)height
{
    CGFloat currentHeight = CGRectGetHeight(self.contentView.bounds);
    CGFloat offset = height-currentHeight;
    
    CGRect frame = self.contentView.frame;
    frame.size.height = height;
    self.contentView.frame = frame;
    
    CGSize contentSize = self.scrollView.contentSize;
    contentSize.height = contentSize.height + offset;
    self.scrollView.contentSize = contentSize;    
}

- (void)setContentSize:(CGSize) size
{
    [self.scrollView setContentSize:size];
}

- (void)setContentOffset:(CGPoint) contentOffset animated:(BOOL) animated
{
    [self.scrollView setContentOffset:contentOffset animated:animated];
}

- (void)setContentView:(UIView*) view;
{
    if (self.contentView) {
        [self.contentView removeFromSuperview];
    }
    _contentView=view;
    CGFloat height = CGRectGetHeight(view.frame);
    [self setContentViewHeight:height];
    [self.scrollView addSubview:view];
}

- (CGPoint)contentOffset
{
    return self.scrollView.contentOffset;
}

@end
