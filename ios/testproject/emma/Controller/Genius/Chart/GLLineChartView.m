//
//  GLLineChartView.m
//  kaylee
//
//  Created by Allen Hsu on 12/4/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLLineChartView.h"

@interface GLLineChartView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) GLLineChartRenderView *renderView;
@property (strong, nonatomic) UIScrollView *scrollView;

@end

@implementation GLLineChartView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (BOOL)showGrid
{
    return self.renderView.showGrid;
}

- (void)setShowGrid:(BOOL)showGrid
{
    [self.renderView setShowGrid:showGrid];
}

- (BOOL)showLines
{
    return self.renderView.showLines;
}

- (void)setShowLines:(BOOL)showLines
{
    [self.renderView setShowLines:showLines];
}

- (BOOL)showDots
{
    return self.renderView.showDots;
}

- (void)setShowDots:(BOOL)showDots
{
    [self.renderView setShowDots:showDots];
}

- (BOOL)showIndicator
{
    return self.renderView.showIndicator;
}

- (void)setShowIndicator:(BOOL)showIndicator
{
    [self.renderView setShowIndicator:showIndicator];
}

- (BOOL)showToday
{
    return self.renderView.showToday;
}

- (void)setShowToday:(BOOL)showToday
{
    [self.renderView setShowToday:showToday];
}

- (void)setShowPeriodBg:(BOOL)showPeriodBg
{
    [self.renderView setShowPeriodBg:showPeriodBg];
}

- (void)setShowCycleDay:(BOOL)showCycleDay
{
    [self.renderView setShowCycleDay:showCycleDay];
}

- (CGFloat)indicatorOffsetX
{
    return self.renderView.indicatorOffsetX;
}

- (void)setIndicatorOffsetX:(CGFloat)indicatorOffsetX
{
    [self.renderView setIndicatorOffsetX:indicatorOffsetX];
}

- (void)setDaysInView:(CGFloat)daysInView
{
    daysInView = MAX(BASE_DAYS_IN_VIEW * 0.5, MIN(BASE_DAYS_IN_VIEW * 4, daysInView));
    if (_daysInView != daysInView) {
        _daysInView = daysInView;
        [self resetScrollViewContentSize];
        [self reloadData];
    }
}

- (void)internalInit
{
    _daysInView = BASE_DAYS_IN_VIEW;
    
    NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    _currentDateIndex = todayIndex;
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    self.renderView = [[GLLineChartRenderView alloc] initWithFrame:self.bounds];
    self.renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.renderView.userInteractionEnabled = NO;
    self.renderView.opaque = NO;
    self.renderView.backgroundColor = [UIColor clearColor];
    self.renderView.showGrid = YES;
    self.renderView.showLines = YES;
    self.renderView.showDots = YES;
    self.renderView.showIndicator = YES;
    self.renderView.showToday = YES;
    self.renderView.indicatorOffsetX = 0.0;
    self.renderView.layer.shouldRasterize = YES;
    self.renderView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    self.renderView.clearsContextBeforeDrawing = YES;
    [self addSubview:self.renderView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.alwaysBounceHorizontal = YES;
    self.scrollView.userInteractionEnabled = YES;
    self.scrollView.delegate = self;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:self.scrollView];
    
//    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
//    pinch.delegate = self;
//    [self.scrollView addGestureRecognizer:pinch];

    
    [self resetScrollViewContentSize];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)reloadData
{
    CGFloat fullWidth = self.width;
    CGFloat dayWidth = fullWidth / self.daysInView;
    
    CGFloat minDateIndex = [self.dataSource minDateIndexOfLineChart:self];
    CGPoint offset = self.scrollView.contentOffset;
    CGFloat location = minDateIndex + (offset.x - self.indicatorOffsetX) / dayWidth;
    CGFloat length = self.daysInView;
    GLLineChartRange range = GLLineChartRangeMake(location, length);
    CGFloat minValue = [self.dataSource minValueOfLineChart:self];
    CGFloat maxValue = [self.dataSource maxValueOfLineChart:self];
    NSInteger num = [self.dataSource numberOfLinesInLineChart:self];
    NSString *unit = [self.dataSource unitOfLineChart:self];
    GLLineChartDot *todayDot = nil;
    NSString *todayString = nil;
    if ([self.dataSource respondsToSelector:@selector(todayDotOfLineChart:)]) {
        todayDot = [self.dataSource todayDotOfLineChart:self];
    }
    if ([self.dataSource respondsToSelector:@selector(todayStringOfLineChart:)]) {
        todayString = [self.dataSource todayStringOfLineChart:self];
    }
    
    self.renderView.minValue = minValue;
    self.renderView.maxValue = maxValue;
    self.renderView.valueUnit = unit;
    self.renderView.range = range;
    self.renderView.todayDot = todayDot;
    self.renderView.todayString = todayString;
    self.renderView.symbols = [self.dataSource symbolsOfLineChart:self];
    
    NSMutableArray *data = [NSMutableArray array];
    for (NSInteger i = 0; i < num; ++i) {
        GLLineChartLineData *d = [[GLLineChartLineData alloc] init];
        if ([self.dataSource respondsToSelector:@selector(lineChart:lineColorForLineIndex:)]) {
            d.lineColor = [self.dataSource lineChart:self lineColorForLineIndex:i];
        } else {
            d.lineColor = GLOW_COLOR_GREEN;
        }
        if ([self.dataSource respondsToSelector:@selector(lineChart:dotColorForLineIndex:)]) {
            d.dotColor = [self.dataSource lineChart:self dotColorForLineIndex:i];
        } else {
            d.dotColor = GLOW_COLOR_GREEN;
        }
        d.dots = [self.dataSource lineChart:self dotsForLineIndex:i inRange:range];
        [data addObject:d];
    }
    self.renderView.data = data;
    [self.renderView setNeedsDisplay];
    
    NSInteger currentDateIndex = roundf(minDateIndex + self.scrollView.contentOffset.x / dayWidth);
    self.currentDateIndex = currentDateIndex;
}

- (void)setCurrentDateIndex:(NSInteger)currentDateIndex
{
    if (_currentDateIndex != currentDateIndex) {
        _currentDateIndex = currentDateIndex;
        if ([self.delegate respondsToSelector:@selector(lineChart:didSelectDateIndex:)]) {
            [self.delegate lineChart:self didSelectDateIndex:currentDateIndex];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self resetScrollViewContentSize];
}

- (void)resetScrollViewContentSize
{
    CGFloat minDateIndex = [self.dataSource minDateIndexOfLineChart:self];
    CGFloat maxDateIndex = [self.dataSource maxDateIndexOfLineChart:self];
    CGFloat fullWidth = self.width;
    CGFloat dayWidth = fullWidth / self.daysInView;
    CGFloat totalDays = maxDateIndex - minDateIndex;
    CGFloat totalWidth = dayWidth * totalDays;
    
    CGPoint offset = CGPointMake((self.currentDateIndex - minDateIndex) * dayWidth, 0.0);
    self.scrollView.contentSize = CGSizeMake(ceilf(totalWidth) + self.scrollView.width, self.scrollView.height);
    self.scrollView.contentOffset = offset;
}

- (void)backToLatestDateAnimated:(BOOL)animated
{
    [self resetScrollViewContentSize];
    CGFloat minDateIndex = [self.dataSource minDateIndexOfLineChart:self];
    CGFloat fullWidth = self.width;
    CGFloat dayWidth = fullWidth / self.daysInView;
    NSInteger todayIndex = [self.dataSource latestDateIndexWithDataOfLineChart:self];
    [self.scrollView setContentOffset:CGPointMake((todayIndex - minDateIndex) * dayWidth, 0.0) animated:animated];
    [self reloadData];
    if ([self.delegate respondsToSelector:@selector(lineChart:didSelectDateIndex:)]) {
        [self.delegate lineChart:self didSelectDateIndex:todayIndex];
    }
}

- (void)backToTodayAnimated:(BOOL)animated
{
//    [self setNeedsLayout];
//    [self layoutIfNeeded];
    [self resetScrollViewContentSize];
    CGFloat minDateIndex = [self.dataSource minDateIndexOfLineChart:self];
    CGFloat fullWidth = self.width;
    CGFloat dayWidth = fullWidth / self.daysInView;
    NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    [self.scrollView setContentOffset:CGPointMake((todayIndex - minDateIndex) * dayWidth, 0.0) animated:animated];
    [self reloadData];
    if ([self.delegate respondsToSelector:@selector(lineChart:didSelectDateIndex:)]) {
        [self.delegate lineChart:self didSelectDateIndex:todayIndex];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self reloadData];
}

//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    if (!decelerate) {
//        [self snapToDay];
//    }
//}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    targetContentOffset->x = [self snappedContentOffsetX:targetContentOffset->x];
}

- (void)snapToDay
{
    CGPoint offset = CGPointMake([self snappedContentOffsetX:self.scrollView.contentOffset.x], 0.0);
    [self.scrollView setContentOffset:offset animated:YES];
}

- (CGFloat)snappedContentOffsetX:(CGFloat)offsetX
{
    CGFloat fullWidth = self.width;
    CGFloat dayWidth = fullWidth / self.daysInView;
    
    int dayOffset = roundf(offsetX / dayWidth);
    return dayOffset * dayWidth;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer
{
    static CGFloat originalDays = BASE_DAYS_IN_VIEW;
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            originalDays = self.daysInView;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat daysInView = originalDays / recognizer.scale;
            daysInView = MAX(BASE_DAYS_IN_VIEW * 0.5, MIN(BASE_DAYS_IN_VIEW * 4, daysInView));
            self.daysInView = daysInView;
            break;
        }
        default:
            break;
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.3 animations:^{
            if (self.daysInView > BASE_DAYS_IN_VIEW) {
                self.daysInView = BASE_DAYS_IN_VIEW;
            } else {
                self.daysInView = BASE_DAYS_IN_VIEW * 2;
            }
        }];
    }
}

@end
