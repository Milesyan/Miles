//
//  ReminderCell.h
//  emma
//
//  Created by Eric Xu on 8/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reminder.h"
#import "Appointment.h"

#define EVENT_REMINDERS_ORDER_UPDATED @"event_reminders_order_updated"

@interface ReminderCell : UITableViewCell
@property (strong, nonatomic) NSString *reminderUUID;
@property (nonatomic) BOOL on;
//@property (strong, nonatomic) Reminder *model;
@property (nonatomic) BOOL isHistory;

- (void)setReminderModel:(Reminder *)reminder;
- (void)setAppointmentModel:(Appointment *)appointment;
- (void)redrawFullView;
- (void)redrawThumbView:(CGFloat)thumbWidth;
+ (CGFloat)cellHeight:(BOOL)hasNote;

@end
