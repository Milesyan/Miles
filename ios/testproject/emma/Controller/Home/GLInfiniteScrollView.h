//
//  LTInfiniteScrollView.h
//  LTInfiniteScrollView
//
//  Created by ltebean on 14/11/21.
//  Copyright (c) 2014年 ltebean. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum ScrollDirection {
    ScrollDirectionRight,
    ScrollDirectionLeft,
} ScrollDirection;

@class GLInfiniteScrollView;

@protocol GLInfiniteScrollViewDelegate <NSObject>
- (void)updateView:(UIView *) view withDistanceToCenter:(CGFloat)distance scrollDirection:(ScrollDirection)direction;
- (BOOL)scrollView:(GLInfiniteScrollView *)scrollView shouldHandleEventWithBeginPoint:(CGPoint) point;
- (void)scrollViewDidBeginScroll:(GLInfiniteScrollView *)scrollView;
- (void)scrollViewDidEndScroll:(GLInfiniteScrollView *)scrollView;

@end

@protocol GLInfiniteScrollViewDataSource <NSObject>
- (UIView *)viewAtIndex:(int)index reusingView:(UIView *)view;
- (int)totalViewCount;
- (int)visibleViewCount;
@end


@interface GLInfiniteScrollView : UIView
@property (nonatomic) int currentIndex;
@property (nonatomic,weak) id<GLInfiniteScrollViewDataSource> dataSource;
@property (nonatomic,weak) id<GLInfiniteScrollViewDelegate> delegate;
@property (nonatomic) BOOL scrollEnabled;
@property (nonatomic) BOOL pagingEnabled;

- (void)reloadData;
- (void)scrollToIndex:(int) index animated:(BOOL) animated;
- (UIView *)viewAtIndex:(int) index;
- (NSArray *)allViews;


@end
