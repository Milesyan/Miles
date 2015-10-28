//
//  GLHomeSummaryView.h
//  LTInfiniteScrollView
//
//  Created by ltebean on 14-12-16.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GLDynamicContentScrollView;

@protocol GLDynamicContentScrollViewDelegate <NSObject>
- (void)scrollView:(GLDynamicContentScrollView *)scrollView internalScrollViewDidScroll:(UIScrollView *)internalScrollView;
- (void)scrollView:(GLDynamicContentScrollView *)scrollView internalScrollViewDidEndDragging:(UIScrollView *)internalScrollView;
- (void)scrollView:(GLDynamicContentScrollView *)scrollView internalScrollViewDidEndDecelerating:(UIScrollView *)internalScrollView;
@end

@interface GLDynamicContentScrollView : UIView
@property (nonatomic,weak) id<GLDynamicContentScrollViewDelegate> delegate;
@property (nonatomic,strong) UIView* contentView;
@property (nonatomic,strong) UIScrollView* scrollView;
@property (nonatomic) BOOL scrollEnabled;

- (void)setContentViewTop:(CGFloat) top animated:(BOOL)animated;
- (void)setContentViewHeight:(CGFloat) height;
- (void)setContentOffset:(CGPoint) contentOffset animated:(BOOL) animated;
- (CGPoint)contentOffset;

@end
