//
//  HealthChartViewController.m
//  emma
//
//  Created by Xin Zhao on 5/13/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ChartConstants.h"
#import "HealthChartViewController.h"

@interface HealthChartViewController ()

@end

@implementation HealthChartViewController

+ (id)getInstance {
    return (HealthChartViewController *)[UIStoryboard chart];
}

- (NSInteger) _thumbDataType {
    return CHART_DATA_TYPE_WEIGHT;
}

@end
