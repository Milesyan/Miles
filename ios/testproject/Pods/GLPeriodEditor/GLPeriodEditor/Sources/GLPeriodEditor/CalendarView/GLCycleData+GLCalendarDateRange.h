//
//  GLCycleData+GLCalendarDateRange.h
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-24.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLCycleData.h"
#import "GLCalendarDateRange.h"

@interface GLCycleData (GLCalendarDateRange)
- (NSArray *)dateRanges;
- (BOOL)sameAsRange:(GLCalendarDateRange *)range;
- (void)updatePeriodRangeLook:(GLCalendarDateRange *)range;
@end
