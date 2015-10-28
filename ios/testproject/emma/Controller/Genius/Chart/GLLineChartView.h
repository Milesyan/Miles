//
//  GLLineChartView.h
//  kaylee
//
//  Created by Allen Hsu on 12/4/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLLineChartRenderView.h"

@class GLLineChartView;

#pragma mark - GLLineChartViewDelegate
@protocol GLLineChartViewDelegate <NSObject>
@optional
- (void)lineChart:(GLLineChartView *)lineChart didSelectDateIndex:(NSInteger)dateIndex;
@end

#pragma mark - GLLineChartViewDataSource
@protocol GLLineChartViewDataSource <NSObject>
@required
- (CGFloat)maxValueOfLineChart:(GLLineChartView *)lineChart;
- (CGFloat)minValueOfLineChart:(GLLineChartView *)lineChart;
- (NSInteger)maxDateIndexOfLineChart:(GLLineChartView *)lineChart;
- (NSInteger)minDateIndexOfLineChart:(GLLineChartView *)lineChart;
- (NSInteger)latestDateIndexWithDataOfLineChart:(GLLineChartView *)lineChart;
- (NSString *)unitOfLineChart:(GLLineChartView *)lineChart;
- (NSInteger)numberOfLinesInLineChart:(GLLineChartView *)lineChart;
- (NSArray *)lineChart:(GLLineChartView *)lineChart dotsForLineIndex:(NSInteger)lineIndex inRange:(GLLineChartRange)range;
@optional
- (NSSet *)symbolsOfLineChart:(GLLineChartView *)lineChart;
- (UIColor *)lineChart:(GLLineChartView *)lineChart lineColorForLineIndex:(NSInteger)lineIndex;
- (UIColor *)lineChart:(GLLineChartView *)lineChart dotColorForLineIndex:(NSInteger)lineIndex;
- (NSArray *)lineChart:(GLLineChartView *)lineChart infoKeysForDateIndex:(NSInteger)dateIndex;
- (NSDictionary *)lineChart:(GLLineChartView *)lineChart infoListForDateIndex:(NSInteger)dateIndex;
- (GLLineChartDot *)todayDotOfLineChart:(GLLineChartView *)lineChart;
- (NSString *)todayStringOfLineChart:(GLLineChartView *)lineChart;
- (NSString *)placeholderStringOfLineChart:(GLLineChartView *)lineChart;
- (NSString *)placeholderButtonTitleOfLineChart:(GLLineChartView *)lineChart;
- (NSString *)targetEventOfLineChart:(GLLineChartView *)lineChart;
- (NSInteger)preferredDaysInViewOfLineChart:(GLLineChartView *)lineChart;
@end

#pragma mark - GLLineChartView
@interface GLLineChartView : UIView
@property (weak, nonatomic) id <GLLineChartViewDelegate> delegate;
@property (weak, nonatomic) id <GLLineChartViewDataSource> dataSource;
@property (assign, nonatomic) CGFloat daysInView;
@property (assign, nonatomic) NSInteger currentDateIndex;
@property (assign, nonatomic) BOOL showCycleDay;
@property (assign, nonatomic) BOOL showPeriodBg;
@property (assign, nonatomic) BOOL showGrid;
@property (assign, nonatomic) BOOL showLines;
@property (assign, nonatomic) BOOL showDots;
@property (assign, nonatomic) BOOL showIndicator;
@property (assign, nonatomic) BOOL showToday;
@property (assign, nonatomic) CGFloat indicatorOffsetX;
- (void)reloadData;
- (void)backToTodayAnimated:(BOOL)animated;
- (void)backToLatestDateAnimated:(BOOL)animated;
@end
