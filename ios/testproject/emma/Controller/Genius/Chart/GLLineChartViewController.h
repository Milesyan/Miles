//
//  GLLineChartViewController.h
//  kaylee
//
//  Created by Allen Hsu on 12/3/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GeniusChildViewController.h"

@class GLChartDataProvider;

@interface GLLineChartViewController : GeniusChildViewController

@property (strong, nonatomic) GLChartDataProvider *dataProvider;
@property (assign, nonatomic) BOOL demoMode;
@property (assign, nonatomic) BOOL showExportReportButton;
@property (copy, nonatomic) NSString *pageImpressionKey;

- (void)reloadData;
- (void)reloadChartView;

@end
