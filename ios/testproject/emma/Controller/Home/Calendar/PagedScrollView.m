//
//  PagedScrollView.m
//  emma
//
//  Created by Ryan Ye on 4/10/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "PagedScrollView.h"
#define MAX_PAGE_COUNT 250

@implementation PagedScrollView
- (id)initWithFrame:(CGRect)frame pageSize:(CGFloat)psize pageCount:(NSInteger)pcount {
    self = [super initWithFrame:frame];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.clipsToBounds = NO;
        self.alwaysBounceHorizontal = YES;
        pageSize = psize;
        visibleCount = frame.size.width / psize + 1;
        leftCount = (visibleCount - 1) / 2; 
        rightCount = visibleCount - 1 - leftCount;
        self.pageIndex = -1;
        self.contentSize = CGSizeMake(psize * pcount, self.frame.size.height);
        self.decelerationRate = UIScrollViewDecelerationRateFast;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat offsetX = self.contentOffset.x;
    NSInteger pageIndex = leftCount + offsetX / pageSize;
    if (self.pageIndex == -1) {
        self.pageIndex = pageIndex;
        for (NSInteger i = self.pageIndex - leftCount; i <= self.pageIndex + rightCount; i++) {
            [self.delegate pageWillAppear:self pageIndex:i];
        }
    } else {
        NSInteger delta = pageIndex - self.pageIndex;
        NSInteger prevIndex = self.pageIndex;
        self.pageIndex = pageIndex;
        NSInteger i, c;
        if (delta > 0) {
            for (i = prevIndex - leftCount, c = 0; c < delta && c < visibleCount; i++, c++) {
                [self.delegate pageDidDisappear:self pageIndex:i];
            }
            for (i = pageIndex + rightCount, c = 0; c < delta && c < visibleCount; i--, c++) {
                [self.delegate pageWillAppear:self pageIndex:i];
            }
        } else if (delta < 0){
            delta = -delta;
            for (i = prevIndex + rightCount, c = 0; c < delta && c < visibleCount; i--, c++) {
                [self.delegate pageDidDisappear:self pageIndex:i];
            }
            for (i = pageIndex - leftCount, c = 0; c < delta && c < visibleCount; i++, c++) {
                [self.delegate pageWillAppear:self pageIndex:i];
            }
        }
    }
    [self.delegate updateSubviewsForScrollOffset:self offsetX:offsetX];
}

- (CGFloat)snapToClosestPage:(CGFloat)offset {
    NSInteger pageIndex = (NSInteger)(offset / pageSize + 0.5);
    return pageIndex * pageSize;
}

- (void)setPageIndex:(NSInteger)index animated:(BOOL)animated {
    [self setContentOffset:CGPointMake((index - leftCount) * pageSize, self.contentOffset.y) animated:animated];
}
@end

