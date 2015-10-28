//
//  GLCycleData+GLCalendarDateRange.m
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-24.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLCycleData+GLCalendarDateRange.h"
#import "GLPeriodEditorHeader.h"
#import "GLDateUtils.h"

@implementation GLCycleData (GLCalendarDateRange)

- (NSArray *)dateRanges
{
    GLCalendarDateRange *period = [GLCalendarDateRange rangeWithBeginDate:self.periodBeginDate endDate:self.periodEndDate];
    period.backgroundColor = [GLCycleAppearance sharedInstance].backgroundColorForPeriod ?: GLOW_COLOR_PINK;
    period.binding = self;
    [self updatePeriodRangeLook:period];
    
    if (self.fertileWindowBeginDate && self.fertileWindowEndDate) {
        GLCalendarDateRange *fertileWindow = [GLCalendarDateRange rangeWithBeginDate:self.fertileWindowBeginDate endDate:self.fertileWindowEndDate];
        fertileWindow.textColor = GLOW_COLOR_GREEN;
        fertileWindow.editable = NO;
        fertileWindow.binding = self;
        return @[period, fertileWindow];
    } else {
        return @[period];
    }
}

- (BOOL)sameAsRange:(GLCalendarDateRange *)range
{
    return [GLDateUtils date:self.periodBeginDate isSameDayAsDate:range.beginDate]  && [GLDateUtils date:self.periodEndDate isSameDayAsDate:range.endDate];
}

- (void)updatePeriodRangeLook:(GLCalendarDateRange *)range
{
    if ([self isFuture] || self.showAsPrediction) {
        range.editable = NO;
        range.backgroundImage = [UIImage imageNamed:@"gl-period-editor-predicted-period-bg.png"];
        range.textColor = [UIColor blackColor];
    } else {
        range.editable = YES;
        range.backgroundImage = nil;
        range.textColor = nil;
    }
}
@end
