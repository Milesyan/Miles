//
//  PagedScrollView.h
//  emma
//
//  Created by Ryan Ye on 4/10/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PagedScrollView;

@protocol PagedScrollViewDelegate<UIScrollViewDelegate>
- (void)pageWillAppear:(PagedScrollView *)scrollView pageIndex:(NSInteger)index;
- (void)pageDidDisappear:(PagedScrollView *)scrollView pageIndex:(NSInteger)index;
- (void)updateSubviewsForScrollOffset:(PagedScrollView *)scrollView offsetX:(CGFloat)offsetX;
@end

@interface PagedScrollView : UIScrollView {
    CGFloat pageSize;
    NSInteger leftCount;
    NSInteger rightCount;
    NSInteger visibleCount;
}
@property (nonatomic) NSInteger pageIndex;
@property (nonatomic, weak) id<PagedScrollViewDelegate> delegate;
- (id)initWithFrame:(CGRect)frame pageSize:(CGFloat)psize pageCount:(NSInteger)pcount;
- (void)setPageIndex:(NSInteger)index animated:(BOOL)animated;
- (CGFloat)snapToClosestPage:(CGFloat)offset;
@end

