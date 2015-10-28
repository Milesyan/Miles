//
//  ChartInfoVIew.h
//  emma
//
//  Created by Xin Zhao on 13-7-15.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "ChartUtils.h"
#import "UserDailyData.h"
#import "SingleColorImageView.h"
#import "XYPieChart.h"
#import <UIKit/UIKit.h>

@interface ChartInfoView : UIView

@property __weak IBOutlet XYPieChart *nutritionChart;
@property __weak IBOutlet UIView *nutritionView;
@property __weak IBOutlet UIView *infoPanel;
@property __weak IBOutlet UIView *currentDayDot;
@property __weak IBOutlet UIView *extraDayDot;
@property __weak IBOutlet SingleColorImageView *currentArrow;
@property (nonatomic, weak) IBOutlet UIButton *exportReportButton;

@property ChartPointerInfo *cpInfo;
- (void)setupPointerWithRadius:(CGFloat)dotRadius;
- (void)setupNutritionViewInDataType:(NSInteger)dataType;
- (void)setupInfoPanelInDataType:(NSInteger)dataType landscape:(BOOL)isLandscape;

- (void)updateDateWithDateIdx:(NSInteger)dateIdx cycleDay:(NSInteger)cd ovulationDay:(NSInteger)ov;
- (void)updateInfoPanelWithDailyData:(UserDailyData *)daily;
- (void)updateInfoPanelWithNutritionDesc:(NSDictionary *)desc;
- (void)updateNutritionLegendsWithNutrition:(NSDictionary *)nutrition
    atDateIdx:(NSInteger)dateIdx;
- (void)posCurrentDotAtX:(CGFloat)x y:(CGFloat)y inDataType:(NSInteger)dataType
    withRadius:(CGFloat)dotRadius extra:(NSArray *)extra;


//- (void)startMoving;
//- (void)stopMovingWithDotSize:(CGFloat)dotSize;
//- (void)stopMovingWithDotSize:(CGFloat)dotSize inDataType:(NSInteger)dataType;
//- (void)updateLabelsWith:(ChartPointerInfo*)cpInfo inDataType:(NSInteger)chartDataType;
//- (void)updateCalorieIntake:(float)offsetX;
//- (void)addCpInfo:(ChartPointerInfo*)cpInfo forDateIdx:(NSInteger)dateIdx;
//- (void)invalidateCpInfoForDateIdx:(NSInteger)dateIdx;
//- (void)invalidateCpInfoCache;
//- (ChartPointerInfo*)getCpInfo:(NSInteger)dateIdx;
- (void)setPieChartDelegate:(id<XYPieChartDelegate>) delegate;
- (void)setPieChartDataSource:(id<XYPieChartDataSource>) dataSource;
- (void)setPieChartHidden:(BOOL)hidden;
- (void)updatePieChartForDateChange:(NSDate *)date;
- (void)highLight:(NSInteger)line;
- (void)stopHighLight;
- (void)updatePieChartInRect:(CGRect)rect;
- (void)hideViewsExceptForChartView;
- (void)showViewsExceptForChartView;

@end
