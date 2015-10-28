//
//  GLChartDataProvider.h
//  kaylee
//
//  Created by Allen Hsu on 12/9/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLLineChartViewController.h"
#import "GLLineChartView.h"

@interface GLChartDataProvider : NSObject <GLLineChartViewDataSource>

@property (weak, nonatomic) GLLineChartViewController *chartViewController;

@property (strong, nonatomic) NSNumber *minValue;
@property (strong, nonatomic) NSNumber *maxValue;
@property (strong, nonatomic) NSNumber *minDateIndex;
@property (strong, nonatomic) NSNumber *maxDateIndex;
@property (strong, nonatomic) NSNumber *latestDateIndex;
@property (strong, nonatomic) GLLineChartDot *todayDot;
@property (strong, nonatomic) NSString *todayString;
- (BOOL)needsShowPeriodBg;
- (BOOL)needsShowCycleDay;
- (void)reloadData;

@end
