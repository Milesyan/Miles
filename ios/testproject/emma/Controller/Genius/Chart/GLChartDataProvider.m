//
//  GLChartDataProvider.m
//  kaylee
//
//  Created by Allen Hsu on 12/9/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLChartDataProvider.h"

@implementation GLChartDataProvider

- (NSInteger)latestDateIndexWithDataOfLineChart:(GLLineChartView *)lineChart
{
    NSInteger minIndex = [self minDateIndexOfLineChart:lineChart];
    NSInteger maxIndex = [self maxDateIndexOfLineChart:lineChart];
    NSInteger latestIndex = [self.latestDateIndex integerValue];
    if (latestIndex >= minIndex && latestIndex <= maxIndex) {
        return latestIndex;
    }
    return maxIndex;
}

- (NSInteger)minDateIndexOfLineChart:(GLLineChartView *)lineChart
{
    NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    if (self.minDateIndex && [self.minDateIndex integerValue] < todayIndex) {
        return [self.minDateIndex integerValue];
    }
    return todayIndex;
}

- (NSInteger)maxDateIndexOfLineChart:(GLLineChartView *)lineChart
{
    NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    if (self.maxDateIndex && [self.maxDateIndex integerValue] > [self minDateIndexOfLineChart:lineChart]) {
        return [self.maxDateIndex integerValue];
    }
    return todayIndex;
}

- (CGFloat)minValueOfLineChart:(GLLineChartView *)lineChart
{
    if (self.minValue) {
        return [self.minValue floatValue];
    }
    return 0.0;
}

- (CGFloat)maxValueOfLineChart:(GLLineChartView *)lineChart
{
    CGFloat min = [self minValueOfLineChart:lineChart];
    if ([self.maxValue floatValue] > min) {
        return [self.maxValue floatValue];
    }
    return min + 100.0;
}

- (NSString *)unitOfLineChart:(GLLineChartView *)lineChart
{
    return @"";
}

- (NSInteger)numberOfLinesInLineChart:(GLLineChartView *)lineChart
{
    return 0;
}

- (NSArray *)lineChart:(GLLineChartView *)lineChart dotsForLineIndex:(NSInteger)lineIndex inRange:(GLLineChartRange)range
{
    return nil;
}

- (UIColor *)lineChart:(GLLineChartView *)lineChart lineColorForLineIndex:(NSInteger)lineIndex
{
    if (self.chartViewController.demoMode && !self.chartViewController.inFullView) {
        switch (lineIndex) {
            case 0:
                return UIColorFromRGB(0xe2f1d5);
                break;
            case 1:
                return UIColorFromRGB(0xfee8cd);
                break;
            default:
                break;
        }
    } else {
        switch (lineIndex) {
            case 0:
                return UIColorFromRGB(0x6dba2e);
                break;
            case 1:
                return UIColorFromRGB(0xfc8d03);
                break;
            default:
                break;
        }
    }
    return GLOW_COLOR_GREEN;
}

- (UIColor *)lineChart:(GLLineChartView *)lineChart dotColorForLineIndex:(NSInteger)lineIndex
{
    if (self.chartViewController.demoMode && !self.chartViewController.inFullView) {
        switch (lineIndex) {
            case 0:
                return UIColorFromRGB(0xe2f1d5);
                break;
            case 1:
                return UIColorFromRGB(0xfee8cd);
                break;
            default:
                break;
        }
    } else {
        switch (lineIndex) {
            case 0:
                return UIColorFromRGB(0x6dba2e);
                break;
            case 1:
                return UIColorFromRGB(0xfc8d03);
                break;
            default:
                break;
        }
    }
    return GLOW_COLOR_GREEN;
}

- (NSArray *)lineChart:(GLLineChartView *)lineChart infoKeysForDateIndex:(NSInteger)dateIndex
{
    return nil;
}

- (NSDictionary *)lineChart:(GLLineChartView *)lineChart infoListForDateIndex:(NSInteger)dateIndex
{
    return nil;
}

- (GLLineChartDot *)todayDotOfLineChart:(GLLineChartView *)lineChart
{
    return self.todayDot;
}

- (NSString *)todayStringOfLineChart:(GLLineChartView *)lineChart
{
    return self.todayString;
}

- (void)reloadData
{
}

- (BOOL)needsShowPeriodBg
{
    return YES;
}

- (BOOL)needsShowCycleDay
{
    return YES;
}

@end
