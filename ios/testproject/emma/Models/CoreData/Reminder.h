//
//  Reminder.h
//  emma
//
//  Created by Eric Xu on 8/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "BaseModel.h"

#define REMINDER_TYPE_USER                0
#define REMINDER_TYPE_SYS_BBT             1
#define REMINDER_TYPE_SYS_PB              2
#define REMINDER_TYPE_SYS_FB              3
#define REMINDER_TYPE_SYS_PILL           11
#define REMINDER_TYPE_SYS_IUD            12
#define REMINDER_TYPE_SYS_VRING          13
#define REMINDER_TYPE_SYS_DRINK_WATER    14
#define REMINDER_TYPE_SYS_STRETEH_BREAK  15
#define REMINDER_TYPE_SYS_BREAST_CHECK   16
#define REMINDER_TYPE_SYS_ANNUAL_EXAM    17
#define REMINDER_TYPE_SYS_CHANGE_PATCH   18
#define REMINDER_TYPE_MEDICINE_DAILY     21
#define REMINDER_TYPE_MEDICINE_TREATMENT 22
#define REMINDER_TYPE_APPOINTMENT        23

#define REMINDER_FLAG_LOCK_DELETE        0x1
#define REMINDER_FLAG_LOCK_REPEAT        0x2
#define REMINDER_FLAG_LOCK_TITLE         0x4

#define OLD_SYS_REMINDER_ID_BBT @"REMINDER_ID_BBT"
#define OLD_SYS_REMINDER_ID_PB @"REMINDER_ID_PB"
#define OLD_SYS_REMINDER_ID_FB @"REMINDER_ID_FB"
#define OLD_SYS_REMINDER_ID_PILL @"REMINDER_ID_PILL"
#define OLD_SYS_REMINDER_ID_IUD @"REMINDER_ID_IUD"
#define OLD_SYS_REMINDER_ID_VRING @"REMINDER_ID_VRING"
#define OLD_SYS_REMINDER_ID_DRINK_WATER @"SYS_REMINDER_ID_DRINK_WATER"
#define OLD_SYS_REMINDER_ID_STRETEH_BREAK @"SYS_REMINDER_ID_STRETEH_BREAK"
#define OLD_SYS_REMINDER_ID_BREAST_CHECK @"SYS_REMINDER_ID_BREAST_CHECK"
#define OLD_SYS_REMINDER_ID_ANNUAL_EXAM @"SYS_REMINDER_ID_ANNUAL_EXAM"
#define OLD_SYS_REMINDER_ID_CHANGE_PATCH @"SYS_REMINDER_ID_CHANGE_PATCH"

#define TIME_HOLDER @"HOLDER"

#define EVENT_REMINDER_UPDATE_RESPONSE @"event_reminder_update_response"

@class User;

typedef NS_ENUM(NSUInteger, REPEAT) {
    REPEAT_NO       = 0,
    REPEAT_DAILY    = 1,
    REPEAT_WEEKLY   = 2,
    REPEAT_MONTHLY  = 3,
    REPEAT_YEARLY   = 4,
    REPEAT_LAST     = 5
};

typedef NS_ENUM(NSUInteger, OLD_REPEAT) {
    OLD_REPEAT_NO       = 1,
    OLD_REPEAT_DAILY    = 2,
    OLD_REPEAT_WEEKLY   = 3,
    OLD_REPEAT_BIWEEKLY = 4,
    OLD_REPEAT_MONTHLY  = 5,
    OLD_REPEAT_YEARLY   = 6,
    OLD_REPEAT_LAST     = 7
};

@interface Reminder : BaseModel

@property (nonatomic, retain) NSString * id;   // available before v4.2
@property (nonatomic, retain) NSString * uuid; // available >= v4.2
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * note;
@property (nonatomic) int64_t type;
@property (nonatomic) int64_t flags;
@property (nonatomic) BOOL isHide;
@property (nonatomic) BOOL on;
@property (nonatomic) int32_t repeat;
@property (nonatomic, strong) NSDate *timeCreated;
@property (nonatomic, strong) NSDate *timeModified;
@property (nonatomic) int16_t frequency;
@property (nonatomic) int16_t medPerTake;
@property (nonatomic, strong) NSString *medPerTakeUnit;
@property (nonatomic, retain) NSString * startDate0;
@property (nonatomic, retain) NSString * startDate1;
@property (nonatomic, retain) NSString * startDate2;
@property (nonatomic, retain) NSString * startDate3;
@property (nonatomic, retain) NSString * startDate4;
@property (nonatomic, retain) NSString * startDate5;
@property (nonatomic, retain) NSString * startDate6;

@property (nonatomic, retain) NSDate * when;
@property (nonatomic, strong) NSArray *whenList;

@property (nonatomic, strong) User *user;

- (void)toggleActive:(BOOL)on;
- (NSDate *)nextWhen;

+ (NSString *)repeatLabel:(REPEAT)repeat time:(NSInteger)time;
+ (NSArray *)getDisplayedReminders:(NSArray *)sortDescriptors isAppointment:(BOOL)isAppt;

//- (void)setWhenDate:(NSDate *)when;
// + (void)updateSysReminders;
+ (void)updateAllReminders;
// + (NSArray *)validSysReminders;
+ (void)updateByPurposeChanged;
+ (void)updatePredictionReminders;


+ (BOOL)finishedMigrationForUser:(User *)user;
+ (void)migrateOldRemindersForUser:(User *)user;
+ (Reminder *)getReminderByType:(int)reminderType;
+ (Reminder *)getReminderByUUID:(NSString *)uuid;
+ (void)deleteByUUID:(NSString *)uuid;
+ (void)deleteOnLocal:(Reminder *)rmd;
- (NSArray *)startDateList;
// + (void)createOrUpdateReminder:(NSString *)uuid withTitle:(NSString *)_title when:(NSArray *)_whenList repeat:(REPEAT)_repeat frequency:(NSInteger)_freq on:(BOOL)on medCount:(NSInteger)med andMedUnit:(NSString *)medUnit forUser:(User *)user;

+ (void)createOrUpdateReminder:(NSString *)uuid type:(NSInteger)reminderType withTitle:(NSString *)_title note:(NSString *)note when:(NSArray *)_whenList repeat:(REPEAT)_repeat frequency:(NSInteger)_freq on:(BOOL)on medCount:(NSInteger)med andMedUnit:(NSString *)medUnit forUser:(User *)user;

+ (NSArray *)createPushRequestList:(User *)user;
+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user;
- (void)setLocalNotification:(BOOL)on;
+ (void)upsertWithServerArray:(NSArray *)reminders forUser:(User *)user;

@end
