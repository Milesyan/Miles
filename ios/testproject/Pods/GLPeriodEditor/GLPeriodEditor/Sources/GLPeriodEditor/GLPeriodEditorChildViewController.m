//
//  GLPeriodEditorChildViewController.m
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-23.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLPeriodEditorChildViewController.h"

@implementation GLPeriodEditorChildViewController

+ (instancetype)instance
{
    return nil;
}

- (void)reloadData
{
    
}

- (void)leftNavButtonPressed:(UIButton *)sender
{
    [self sendLoggingEvent:BTN_CLK_BACK data:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)rightNavButtonPressed:(UIButton *)sender
{
    [self sendLoggingEvent:BTN_CLK_TIPS data:nil];
    [self.containerViewController didClickInfoIcon];
}

- (void)updateCycleData:(GLCycleData *)cycleData withPeriodBeginDate:(NSDate *)periodBeginDate periodEndDate:(NSDate *)periodEndDate
{
    [self.containerViewController didUpdateCycleData:cycleData withPeriodBeginDate:periodBeginDate periodEndDate:periodEndDate];
}

- (void)addCycleData:(GLCycleData *)cycleData
{
    [self.containerViewController didAddCycleData:cycleData];
}

- (void)removeCycleData:(GLCycleData *)cycleData
{
    [self.containerViewController didRemoveCycleData:cycleData];
}

- (void)setMode:(MODE)mode
{
    _mode = mode;
    self.containerViewController.mode = mode;
}

- (void)sendLoggingEvent:(LOGGING_EVENT)event data:(id)data
{
    [self.containerViewController didReceiveLoggingEvent:event data:data];
}


- (BOOL)isLatestCycle:(GLCycleData *)cycleData
{
    if (!self.cycleDataList || self.cycleDataList.count == 0) {
        return NO;
    }
    for (GLCycleData *data in self.cycleDataList) {
        if (![data isFuture]) {
            if (data == cycleData) {
                return YES;
            }
            break;
        }
    }
    return NO;
}

@end
