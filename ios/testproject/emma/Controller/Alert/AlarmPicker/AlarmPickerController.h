//
//  AlarmPickerController.h
//  emma
//
//  Created by Ryan Ye on 3/8/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Notification.h"
typedef void (^DatePickedCallback)(NSDate *date);
typedef void (^DatePickerCancelCallback)();

@interface AlarmPickerController : UIViewController
@property (nonatomic, retain) Notification *model;
@property (nonatomic, retain) NSDate *selectedDate;
@property (nonatomic) UIDatePickerMode datePickerMode;
//- (void)present:(UIView *)parentView;
//- (void)present:(UIView *)parentView withPickDateCallback:(DatePickedCallback)callback;
- (void)present:(UIView *)parentView withPickDateCallback:(DatePickedCallback)callback withCancelCallback:(DatePickerCancelCallback)cancelCb;
- (void)dismiss;
- (void)setDatePickerMode:(UIDatePickerMode)mode;
- (void)setMinDate:(NSDate *)date;
- (void)setMaxDate:(NSDate *)date;
@end
