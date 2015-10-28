//
//  Appointment.h
//  emma
//
//  Created by Jirong Wang on 10/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "BaseModel.h"
#import "Reminder.h"

@class User;

@interface Appointment : BaseModel

@property (nonatomic) int64_t appointmentId;
@property (nonatomic, retain) NSString * reminderUUID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * note;
@property (nonatomic) int64_t type;
@property (nonatomic) BOOL attend;
@property (nonatomic, strong) NSDate *timeCreated;
@property (nonatomic, strong) NSDate *timeModified;
@property (nonatomic, retain) NSString * when;
// relation
@property (nonatomic, strong) User *user;

@property (nonatomic, readonly) NSDate *date;

+ (void)upsertWithServerArray:(NSArray *)appointments forUser:(User *)user;

+ (void)createOrUpdateAppointment:(NSString *)reminderUUID title:(NSString *)title note:(NSString *)note when:(NSDate *)when repeat:(REPEAT)repeat on:(BOOL)on forUser:(User *)user;
+ (void)deleteAppointment:(NSString *)reminderUUID forUser:(User *)user;
+ (NSArray *)getAppointments:(NSArray *)sortDescriptors onlyHistory:(BOOL)onlyHistory;


+ (NSArray *)dateLabelsForAppointmentsInMonth:(NSDate *)date;
+ (BOOL)currentUserHasAppointmentsOnDate:(NSDate *)date;
+ (Appointment *)currentUserUpcomingAppointmentForDate:(NSDate *)date;
+ (Appointment *)appointmentByReminderUUID:(NSString *)uuid;

@end
