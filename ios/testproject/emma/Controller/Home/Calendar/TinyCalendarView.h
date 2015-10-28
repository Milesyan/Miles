//
//  TinyCalendarView.h
//  emma
//
//  Created by Eric Xu on 2/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CKCalendarView.h"
#import "PagedScrollView.h"

#define TINY_CAL_HEIGHT 180
#define EVENT_TINY_CALENDAR_SWIPE @"event_tiny_calendar_swipe"

@class ButtonHalo;

@interface TinyCalendarView : CKCalendarView<PagedScrollViewDelegate>

@property (nonatomic, strong) ButtonHalo *halo;
@property (nonatomic, assign) BOOL calculationAnimationSwtich;

- (void)moveToDate:(NSDate *)newDate animated:(BOOL)animated;
- (void)updateButtonsForPrediction;
// - (void)updateButtonsForScrollOffset:(float)offsetX;
- (void)updateButtonsForPulling:(float)progress;
- (void)finishPulling;
- (void)scrollBegan;
- (void)scrollEnded:(BOOL)animated;
- (void)stopCenterButtonTipsRotation;
- (void)startCenterButtonTipsRotation;
- (void)setCenterButtonTipsIndex:(NSInteger)index;
- (void)startCalculationAnimation;

- (BOOL)isCalculating;

@end
