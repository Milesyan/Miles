//
//  GLCalendarMonthCoverView.h
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-17.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLCalendarMonthCoverView : UIScrollView
@property (nonatomic, copy) NSDate *firstDate;
@property (nonatomic, copy) NSDate *lastDate;
@property (nonatomic, strong) NSDictionary *textAttributes;
- (void)updateWithFirstDate:(NSDate *)firstDate lastDate:(NSDate *)lastDate calendar:(NSCalendar *)calendar rowHeight:(CGFloat)rowHeight;
@end
