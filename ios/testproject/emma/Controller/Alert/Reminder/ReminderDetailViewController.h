//
//  ReminderDetailViewController.h
//  emma
//
//  Created by Eric Xu on 7/23/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reminder.h"

typedef void(^ReminderSavedCallback)(Reminder *r);
typedef void(^ReminderDeletedCallback)(NSString *reminderID);

@interface ReminderDetailViewController : UITableViewController

//@property (nonatomic, strong) Reminder *model;
@property (nonatomic) REPEAT repeatWay;
@property (nonatomic) BOOL isAppointment;

- (void)setModel:(Reminder *)model;
- (void)setMedicineForm:(NSString *)form;
- (void)setMedicineName:(NSString *)medName andForm:(NSString *)form;
- (void)setShowMed:(BOOL)show;
- (void)setPrefilledTitle:(NSString *)title;
- (void)setReminderSavedCallback:(ReminderSavedCallback)cb;
- (void)setReminderDeletedCallback:(ReminderDeletedCallback)cb;
- (void)setReminderType:(int64_t)reminderType;

@end
