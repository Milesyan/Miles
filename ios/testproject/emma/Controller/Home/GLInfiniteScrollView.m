//
//  LTInfiniteScrollView.m
//  LTInfiniteScrollView
//
//  Created by ltebean on 14/11/21.
//  Copyright (c) 2014 ltebean. All rights reserved.
//



#import "GLInfiniteScrollView.h"

@interface GLInfiniteScrollView()<UIScrollViewDelegate>
@property CGSize viewSize;
@property(nonatomic,strong) UIScrollView *scrollView;
@property(nonatomic,strong) NSMutableArray* views;
@property(nonatomic) int visibleViewCount;
@property(nonatomic) int totalViewCount;
@property(nonatomic) CGFloat preContentOffsetX;
@property(nonatomic) CGFloat totalWidth;
@property BOOL dragging;
@property BOOL initialized;
@property ScrollDirection scrollDirection;
@end

@implementation GLInfiniteScrollView

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
    self.scrollEnabled = YES;
    self.pagingEnabled = NO;
    self.views = [NSMutableArray array];
}

- (void)setupViews
{
    self.scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = self.pagingEnabled;
    self.scrollView.scrollEnabled = self.scrollEnabled;
    [self addSubview: self.scrollView];
}

- (void)addSubview:(UIView *)view
{
    [super addSubview:view];
    [self bringSubviewToFront:self.scrollView];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return [self.delegate scrollView:self shouldHandleEventWithBeginPoint:point];
}


- (void)setPagingEnabled:(BOOL)pagingEnabled
{
    _pagingEnabled = pagingEnabled;
    self.scrollView.pagingEnabled = pagingEnabled;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    _scrollEnabled = scrollEnabled;
    self.scrollView.scrollEnabled = scrollEnabled;
}

- (void)reloadData
{
    if (!self.initialized){
        [self setupViews];
        self.initialized = YES;
    }
    
    for(UIView* view in self.views){
        [view removeFromSuperview];
    }
    
    self.visibleViewCount = [self.dataSource visibleViewCount];
    self.totalViewCount = [self.dataSource totalViewCount];
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds)/self.visibleViewCount;
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    self.viewSize = CGSizeMake(viewWidth, viewHeight);
    
    self.totalWidth = viewWidth * self.totalViewCount;
    
    self.scrollView.contentSize = CGSizeMake(self.totalWidth, CGRectGetHeight(self.bounds));
    
    
    int begin = -ceil(self.visibleViewCount/2.0f);
    int end = ceil(self.visibleViewCount/2.0f);
    self.currentIndex = 0;
    
    self.scrollView.contentOffset = CGPointMake(self.totalWidth/2-CGRectGetWidth(self.bounds)/2, 0);
    
    int delta = 0 - begin;
    BOOL canReuse = self.views.count > 0 ? YES : NO;
    for (int i = begin; i <= end; i++) {
        UIView *reusingView = nil;
        if (canReuse) {
            reusingView = self.views[i+delta];
        }
        UIView *view = [self.dataSource viewAtIndex:i reusingView:reusingView];
        view.center = [self centerForViewAtIndex:i];
        view.tag = i;
        if (!canReuse) {
            [self.views addObject:view];
        }
        [self.scrollView addSubview:view];
    }
}

- (void)scrollToIndex:(int) index animated:(BOOL)animated
{
    self.dragging = YES;
    [self.delegate scrollViewDidBeginScroll:self];
    [self.scrollView setContentOffset:[self contentOffsetForIndex:index] animated:animated];
}

- (UIView*)viewAtIndex:(int) index
{
    CGPoint center = [self centerForViewAtIndex:index];
    for (UIView* view in self.views) {
        if (fabs(center.x - view.center.x) <= self.viewSize.width/2.0f){
            return view;
        }
    }
    return nil;
}

- (NSArray*)allViews
{
    return self.views;
}

- (CGPoint)centerForViewAtIndex:(int) index
{
    CGFloat y = CGRectGetMidY(self.bounds);
    CGFloat x = self.totalWidth/2 + index*self.viewSize.width;
    //    NSLog(@"view center:%f at index:%d",x,index);
    return CGPointMake(x, y);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = [self currentCenter].x - self.totalWidth/2 ;
    self.currentIndex = ceil((offset- self.viewSize.width/2)/self.viewSize.width);
    
    //    NSLog(@"--------------------------------");
    for (UIView* view in self.views) {
        if ([self viewCanBeQueuedForReuse:view]) {
            int indexNeeded;
            int indexOfViewToReuse = (int)view.tag;
            if (indexOfViewToReuse < self.currentIndex) {
                indexNeeded = indexOfViewToReuse + self.visibleViewCount + 2;
            } else{
                indexNeeded = indexOfViewToReuse - (self.visibleViewCount + 2);
            }
            
            //NSLog(@"index:%d indexNeeded:%d",indexOfViewToReuse,indexNeeded);
            
            [view removeFromSuperview];
            
            UIView* viewNeeded = [self.dataSource viewAtIndex:indexNeeded reusingView:view];
            viewNeeded.center = [self centerForViewAtIndex:indexNeeded];
            [self.scrollView addSubview:viewNeeded];
            viewNeeded.tag = indexNeeded;
        };
        
        CGFloat currentCenter = [self currentCenter].x;
        [self.delegate updateView:view withDistanceToCenter:(view.center.x - currentCenter) scrollDirection:self.scrollDirection];
        
    }
    if (self.dragging){
        if (self.scrollView.contentOffset.x > self.preContentOffsetX){
            self.scrollDirection = ScrollDirectionLeft;
        } else{
            self.scrollDirection = ScrollDirectionRight;
        }
    }
    
    self.preContentOffsetX = self.scrollView.contentOffset.x;
}


- (CGPoint)currentCenter
{
    CGFloat x = self.scrollView.contentOffset.x + CGRectGetWidth(self.bounds)/2.0f;
    CGFloat y = self.scrollView.contentOffset.y;
    return  CGPointMake(x, y);
}

- (BOOL)viewCanBeQueuedForReuse:(UIView*) view
{
    
    CGFloat distanceToCenter = [self currentCenter].x - view.center.x;
    CGFloat threshold = (ceil(self.visibleViewCount/2.0f) + 1)*self.viewSize.width;
    
    if (self.scrollDirection == ScrollDirectionLeft){
        if (distanceToCenter <0) {
            return NO;
        }
    } else{
        if (distanceToCenter >0) {
            return NO;
        }
    }
    if (fabs(distanceToCenter) >= threshold){
        return YES;
    }
    return NO;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.dragging = YES;
    [self.delegate scrollViewDidBeginScroll:self];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self.delegate scrollViewDidEndScroll:self];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.dragging = NO;
    if (!self.pagingEnabled) {
        [self.scrollView setContentOffset:[self contentOffsetForIndex:self.currentIndex] animated:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.delegate scrollViewDidEndScroll:self];
    if (!self.pagingEnabled) {
        [self.scrollView setContentOffset:[self contentOffsetForIndex:self.currentIndex] animated:YES];
    }
}

- (CGPoint)contentOffsetForIndex:(int) index
{
    CGFloat x = self.totalWidth/2.0f + index*self.viewSize.width - CGRectGetWidth(self.bounds)/2.0f;
    return CGPointMake(x, 0);
}

@end
