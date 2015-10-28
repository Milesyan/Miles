//
//  CalendarCell.h
//  emma
//
//  Created by Peng Gu on 9/24/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SWITCH_ACCEL 1.5 

@class TinyCalendarView;
@class CKCalendarView;

typedef enum {
    dateRelationVeryPast = 0,
    dateRelationYesterday = 1,
    dateRelationToday = 2,
    dateRelationTomorrowUnlocked = 3,
    dateRelationTomorrowLocked = 4,
    dateRelationVeryFuture = 5
} DateRelationOfToday;

@interface CalendarCell : UITableViewCell

@property(nonatomic, weak) IBOutlet UIView *calendarContainerView;
@property(nonatomic, weak) IBOutlet CKCalendarView *calendar;
@property(nonatomic, weak) IBOutlet TinyCalendarView *tinyCalendar;
@property(nonatomic, weak) IBOutlet UIView *indicator;
@property(nonatomic, weak) IBOutlet UIImageView *indicatorArrow;
@property(nonatomic, weak) IBOutlet UIButton *backgroundButton;

// backgroundImageView is not in calendar cell, it's subview of homeViewController.view
@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundBlurredImageView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *backgroundImageConstraintBottom;

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, assign, readonly) CGFloat cellHeight;

@property (nonatomic, assign) BOOL showFullCalendar;
@property (nonatomic, assign) BOOL isSwitchingCalendar;

- (void)setupViews;
- (void)layoutTinyCalendar;

- (void)moveToDate:(NSDate *)date animated:(BOOL)animated;
- (void)updateCalendarCellMask;
- (void)pullDownWithDistance:(CGFloat)distance maxValue:(CGFloat)maxValue;


- (void)updateAlphaTo:(CGFloat)alpha animated:(BOOL)animated;
- (void)startTinyCalendarCenterButtonTipsRotation;
- (void)stopTinyCalendarCenterButtonTipsRotation;

- (void)switchToFullCalendarView:(BOOL)animated;
- (void)switchToTinyCalendarView:(BOOL)animated;

- (void)backgroundImageChanged:(Event *)event;

@end
