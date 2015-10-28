//
//  Reminder.m
//  emma
//
//  Created by Eric Xu on 8/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "Reminder.h"
#import "User.h"
#import "LocalNotification.h"
#import "Utils+DateTime.h"
#import "HealthProfileData.h"
#import "Network.h"

#define OLD_REMINDER_MIGRATED @"old_reminder_migrated"

@interface Reminder()

@end

@implementation Reminder

@dynamic id;
@dynamic uuid;
@dynamic title;
@dynamic note;
@dynamic type;
@dynamic flags;
@dynamic isHide;
@dynamic on;
@dynamic repeat;
@dynamic timeCreated;
@dynamic timeModified;
@dynamic medPerTake;
@dynamic medPerTakeUnit;
@dynamic frequency;
@dynamic startDate0;
@dynamic startDate1;
@dynamic startDate2;
@dynamic startDate3;
@dynamic startDate4;
@dynamic startDate5;
@dynamic startDate6;

// old usage
@dynamic when;
@dynamic whenList;

@dynamic user;

#pragma mark - mappings
+ (NSString *)repeatLabel:(REPEAT)repeat time:(NSInteger)time{
    NSString *label;
    NSString *times  = [NSString stringWithFormat:@"%ld time%@", (long)time, time==1? @"": @"s"];
    switch (repeat) {
        case REPEAT_NO:
            label = [NSString stringWithFormat:@"%@ no repeat", times];
            break;
        case REPEAT_DAILY:
            label = [NSString stringWithFormat:@"%@ daily", times];
            break;
        case REPEAT_WEEKLY:
            label = [NSString stringWithFormat:@"%@ weekly", times];
            break;
        case REPEAT_MONTHLY:
            label = [NSString stringWithFormat:@"%@ monthly", times];
            break;
        case REPEAT_YEARLY:
            label = [NSString stringWithFormat:@"%@ yearly", times];
            break;
        default:
            break;
    }

    return label;
}

- (NSDictionary *)attrMapper {
    return @{
             @"uuid"            : @"uuid",
             @"type"            : @"type",
             @"title"           : @"title",
             @"note"            : @"note",
             @"flags"           : @"flags",
             @"is_hide"         : @"isHide",
             @"modifiable"      : @"modifiable",
             @"on"              : @"on",
             @"repeat"          : @"repeat",
             @"frequency"       : @"frequency",
             @"start_date0"     : @"startDate0",
             @"start_date1"     : @"startDate1",
             @"start_date2"     : @"startDate2",
             @"start_date3"     : @"startDate3",
             @"start_date4"     : @"startDate4",
             @"start_date5"     : @"startDate5",
             @"start_date6"     : @"startDate6",
             @"med_per_take_unit" : @"medPerTakeUnit",
             @"med_per_take"      : @"medPerTake",
             @"time_created"    : @"timeCreated",
             @"time_modified"   : @"timeModified"
             };
}


- (NSDictionary *)oldIdToTypeMapper {
    return @{
             OLD_SYS_REMINDER_ID_BBT           : @(REMINDER_TYPE_SYS_BBT),
             OLD_SYS_REMINDER_ID_PB            : @(REMINDER_TYPE_SYS_PB),
             OLD_SYS_REMINDER_ID_FB            : @(REMINDER_TYPE_SYS_FB),
             OLD_SYS_REMINDER_ID_PILL          : @(REMINDER_TYPE_SYS_PILL),
             OLD_SYS_REMINDER_ID_IUD           : @(REMINDER_TYPE_SYS_IUD),
             OLD_SYS_REMINDER_ID_VRING         : @(REMINDER_TYPE_SYS_VRING),
             OLD_SYS_REMINDER_ID_DRINK_WATER   : @(REMINDER_TYPE_SYS_DRINK_WATER),
             OLD_SYS_REMINDER_ID_STRETEH_BREAK : @(REMINDER_TYPE_SYS_STRETEH_BREAK),
             OLD_SYS_REMINDER_ID_BREAST_CHECK  : @(REMINDER_TYPE_SYS_BREAST_CHECK),
             OLD_SYS_REMINDER_ID_ANNUAL_EXAM   : @(REMINDER_TYPE_SYS_ANNUAL_EXAM),
             OLD_SYS_REMINDER_ID_CHANGE_PATCH  : @(REMINDER_TYPE_SYS_CHANGE_PATCH)
             };
}

+ (NSArray *)defaultSystemTypes {
    return @[
        @(REMINDER_TYPE_SYS_BBT),
        @(REMINDER_TYPE_SYS_PB),
        @(REMINDER_TYPE_SYS_FB),
        @(REMINDER_TYPE_SYS_PILL),
        @(REMINDER_TYPE_SYS_IUD),
        @(REMINDER_TYPE_SYS_VRING),
        @(REMINDER_TYPE_SYS_DRINK_WATER),
        @(REMINDER_TYPE_SYS_STRETEH_BREAK),
        @(REMINDER_TYPE_SYS_BREAST_CHECK),
        @(REMINDER_TYPE_SYS_ANNUAL_EXAM),
        @(REMINDER_TYPE_SYS_CHANGE_PATCH)
    ];
}

+ (NSDate *)reminderStringToDate:(NSString *)reminderString {
    /*
     String : yyyy-mm-dd-HH-MM-SS
     */
    if ([Utils isEmptyString:reminderString]) {
        return nil;
    }
    NSArray *splitedDate = [reminderString componentsSeparatedByString:@"-"];
    if (splitedDate.count < 6) {
        return nil;
    }
    return [Utils dateOfYear:[(NSNumber *)splitedDate[0] intValue]
                       month:[(NSNumber *)splitedDate[1] intValue]
                         day:[(NSNumber *)splitedDate[2] intValue]
                        hour:[(NSNumber *)splitedDate[3] intValue]
                      minute:[(NSNumber *)splitedDate[4] intValue]
                      second:[(NSNumber *)splitedDate[5] intValue]
            ];
}

+ (NSString *)reminderDateToString:(NSDate *)reminderDate {
    /*
     String : yyyy-mm-dd-HH-MM-SS
     */
    if (reminderDate == nil) {
        return nil;
    }
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *time = [calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit
                                        fromDate:reminderDate];
    return [NSString stringWithFormat:@"%.4ld-%.2ld-%.2ld-%.2ld-%.2ld-%.2ld",
            time.year, time.month, time.day, time.hour, time.minute, time.second];
}

- (NSDate *)getStartDate:(int)i {
    NSString * dateString = nil;
    switch (i) {
        case 0:
            dateString = self.startDate0;
            break;
        case 1:
            dateString = self.startDate1;
            break;
        case 2:
            dateString = self.startDate2;
            break;
        case 3:
            dateString = self.startDate3;
            break;
        case 4:
            dateString = self.startDate4;
            break;
        case 5:
            dateString = self.startDate5;
            break;
        case 6:
            dateString = self.startDate6;
            break;
        default:
            return nil;
    }
    return [Reminder reminderStringToDate:dateString];
}

- (void)setStartDate:(int)i date:(NSDate *)date{
    NSString * dateString = [Reminder reminderDateToString:date];
    switch (i) {
        case 0:
            [self update:@"startDate0" value:dateString];
            break;
        case 1:
            [self update:@"startDate1" value:dateString];
            break;
        case 2:
            [self update:@"startDate2" value:dateString];
            break;
        case 3:
            [self update:@"startDate3" value:dateString];
            break;
        case 4:
            [self update:@"startDate4" value:dateString];
            break;
        case 5:
            [self update:@"startDate5" value:dateString];
            break;
        case 6:
            [self update:@"startDate6" value:dateString];
            break;
        default:
            break;
    }
}

#pragma mark - migration
- (void)migrate {
    BOOL needMigrate = NO;
    if (self.whenList && [self.whenList count] > 0) {
        needMigrate = YES;
    } else if (self.when != nil) {
        needMigrate = YES;
    }

    if (needMigrate)   {
        /*
         migrate start
         */
        // migrate start time
        if (self.startDate0 == nil) {
            if (self.whenList && [self.whenList count] > 0) {
                int i = 0;
                for (id _when in self.whenList) {
                    if ([_when isKindOfClass:[NSDate class]]) {
                        [self setStartDate:i date:_when];
                        i += 1;
                    }
                }
            } else if (self.when != nil) {
                [self setStartDate:0 date:self.when];
            }
        }
        self.whenList = nil;
        self.when = nil;
        
        // migrate id, uuid, and type
        if (self.id != nil) {
            // remove the current notification in the system
            [LocalNotification cancelNotification:self.id];
            NSNumber * reminderType = [[self oldIdToTypeMapper] objectForKey:self.id];
            if (reminderType == nil) {
                self.type = REMINDER_TYPE_USER;
                self.flags = 0;
            } else {
                self.type = [reminderType intValue];
                self.flags = REMINDER_FLAG_LOCK_DELETE | REMINDER_FLAG_LOCK_REPEAT | REMINDER_FLAG_LOCK_TITLE;
            }
            self.uuid = [[NSUUID UUID] UUIDString];
            self.id = nil;
        }
        
        // migrate repeat
        if (self.repeat == OLD_REPEAT_NO) {
            self.repeat = REPEAT_NO;
        } else if (self.repeat == OLD_REPEAT_DAILY) {
            self.repeat = REPEAT_DAILY;
        } else if (self.repeat == OLD_REPEAT_WEEKLY) {
            self.repeat = REPEAT_WEEKLY;
        } else if (self.repeat == OLD_REPEAT_BIWEEKLY) {
            self.repeat = REPEAT_WEEKLY;
        } else if (self.repeat == OLD_REPEAT_MONTHLY) {
            self.repeat = REPEAT_MONTHLY;
        } else if (self.repeat == OLD_REPEAT_YEARLY) {
            self.repeat = REPEAT_YEARLY;
        } else {
            self.repeat = REPEAT_NO;
        }
        
        self.note = @"";
        self.isHide = NO;
        
        if (self.on) {
            [self setLocalNotification:self.on];
        }
        
        // mark self as dirty
        self.changedAttributes = nil;
        self.dirty = NO;
    }
}

+ (void)migrateOldRemindersForUser:(User *)user {
    // this function can be run multiple time, and get the same result
    if (![Reminder finishedMigrationForUser:user]) {
        for (Reminder *rmdr in user.reminders) {
            [rmdr migrate];
        }
        [user save];
        [self pushOldRemindersToServer];
    }
}

+ (void)pushOldRemindersToServer {
    /*
     * function to push migrated old reminders to server
     */
    User * u = [User currentUser];
    if (!u)
        return;
    
    // TODO
    //NSString * k = [NSString stringWithFormat:@"%@_%@", OLD_REMINDER_MIGRATED, u.id];
    //[Utils setDefaultsForKey:k withValue:nil];

    NSMutableArray * reminderRequest = [[NSMutableArray alloc] init];
    for (Reminder * rmd in u.reminders) {
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        [dict addEntriesFromDictionary:@{
            @"type": @(rmd.type),
            @"title": rmd.title,
            @"repeat": @(rmd.repeat),
            @"flags": @(rmd.flags),
            @"on": (rmd.on ? @1 : @0),
            @"start_date0": rmd.startDate0
        }];
        if (rmd.note) {
            [dict setObject:rmd.note forKey:@"note"];
        }
        if (rmd.medPerTakeUnit) {
            [dict setObject:rmd.medPerTakeUnit forKey:@"med_per_take_unit"];
        }
        if (rmd.medPerTake) {
            [dict setObject:@(rmd.medPerTake) forKey:@"med_per_take"];
        }
        if (rmd.frequency) {
            [dict setObject:@(rmd.frequency) forKey:@"frequency"];
        } else {
            [dict setObject:@1 forKey:@"frequency"];
        }
        // is hide
        [dict setObject:(rmd.isHide ? @1 : @0) forKey:@"is_hide"];
        
        if (rmd.timeCreated) {
            [dict setObject:@([rmd.timeCreated timeIntervalSince1970]) forKey:@"time_created"];
        }
        if (rmd.timeModified) {
            [dict setObject:@([rmd.timeModified timeIntervalSince1970]) forKey:@"time_modified"];
        }
        if (rmd.startDate1) {
            [dict setObject:rmd.startDate1 forKey:@"start_date1"];
        }
        if (rmd.startDate2) {
            [dict setObject:rmd.startDate2 forKey:@"start_date2"];
        }
        if (rmd.startDate3) {
            [dict setObject:rmd.startDate3 forKey:@"start_date3"];
        }
        if (rmd.startDate4) {
            [dict setObject:rmd.startDate4 forKey:@"start_date4"];
        }
        if (rmd.startDate5) {
            [dict setObject:rmd.startDate5 forKey:@"start_date5"];
        }
        if (rmd.startDate6) {
            [dict setObject:rmd.startDate6 forKey:@"start_date6"];
        }
        [reminderRequest addObject:dict];
    }
    // NSLog(@"AAAAAA jr debug, migration, before push to server, %@", reminderRequest);
    
    NSString *url = @"v2/users/migration/push_old_reminders";
    NSDictionary *request = [u postRequest:@{@"reminders": reminderRequest}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            if ([result[@"rc"] intValue] == RC_SUCCESS) {
                NSArray * serverReminders = [result objectForKey:@"reminders"];
                for (NSDictionary *data in serverReminders) {
                    [Reminder upsertWithServerData:data forUser:u];
                }
                [u save];
                NSString * k = [NSString stringWithFormat:@"%@_%@", OLD_REMINDER_MIGRATED, u.id];
                [Utils setDefaultsForKey:k withValue:@(1)];
            }
        }
    }];
}

+ (BOOL)finishedMigrationForUser:(User *)user {
    if (!user)
        return NO;
    NSString * k = [NSString stringWithFormat:@"%@_%@", OLD_REMINDER_MIGRATED, user.id];
    NSNumber * migrated = [Utils getDefaultsForKey:k];
    return (migrated && ([migrated intValue] == 1));
}

#pragma mark - update local data from server
+ (void)upsertWithServerArray:(NSArray *)reminders forUser:(User *)user {
    // before local migration, we do not accept any server data
    if (![Reminder finishedMigrationForUser:user]) {
        return;
    }
    for (NSDictionary *data in reminders) {
        [Reminder upsertWithServerData:data forUser:user];
    }
    [user save];
}

+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user {
    NSInteger repeat = [[data objectForKey:@"repeat"] integerValue];
    if ((repeat < 0) || (repeat > REPEAT_LAST)) {
        return nil;
    }
    
    Reminder * reminder;
    NSString * reminderUUID = [data objectForKey:@"uuid"];
    int reminderType = [[data objectForKey:@"type"] intValue];
    
    if ([[Reminder defaultSystemTypes] indexOfObject:@(reminderType)] == NSNotFound ) {
        reminder = [self tsetUserReminder:reminderUUID forUser:user];
        reminder.type = reminderType;
    } else {
        reminder = [self tsetSysReminder:reminderType forUser:user];
        reminder.uuid = reminderUUID;
    }
    
    // check if the reminder should be removed or not
    NSNumber * timeRemoved = [data objectForKey:@"time_removed"];
    if (timeRemoved != nil) {
        if ([timeRemoved longLongValue] != 0) {
            [Reminder deleteOnLocal:reminder];
            return nil;
        }
    }
    [reminder updateAttrsFromServerData:data];
    [reminder setLocalNotification:reminder.on];
    return reminder;
}

- (void)updateAttrsFromServerData:(NSDictionary *)data {
    NSMutableDictionary * newData = [NSMutableDictionary dictionaryWithDictionary:data];
    [newData removeObjectForKey:@"id"];
    [newData removeObjectForKey:@"uuid"];
    [newData removeObjectForKey:@"type"];
    [super updateAttrsFromServerData:newData];
}

+ (id)tsetSysReminder:(int)reminderType forUser:(User *)user {
    DataStore *ds = user.dataStore;
    Reminder *reminder = (Reminder *)[self fetchObject:@{@"user.id" : user.id, @"type" : @(reminderType)} dataStore:ds];;
    if (!reminder) {
        reminder = [Reminder newInstance:ds];
        reminder.user = user;
        reminder.type = reminderType;
    }
    return reminder;
}

+ (id)tsetUserReminder:(NSString *)uuid forUser:(User *)user {
    DataStore *ds = user.dataStore;
    Reminder *reminder = (Reminder *)[self fetchObject:@{@"user.id" : user.id, @"uuid" : uuid} dataStore:ds];
    if (!reminder) {
        reminder = [Reminder newInstance:ds];
        reminder.uuid = uuid;
        reminder.user = user;
    }
    return reminder;
}

- (void)setDirty:(BOOL)val {
    [super setDirty:val];
    if (val) {
        self.user.dirty = YES;
    }
}

+ (void)deleteOnLocal:(Reminder *)rmd {
    if (rmd) {
        [rmd setLocalNotification:NO];
        [Reminder deleteInstance:rmd];
    }
}

#pragma mark - push data to server
+ (void)deleteReminderOnServer:(Reminder *)reminder {
    User * u = [User currentUser];
    if (!u)
        return;
    NSString *url = @"v2/users/remove_reminder";
    NSDictionary *request = [u postRequest:@{@"rmd_uuid": reminder.uuid}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if ([result[@"rc"] intValue] == RC_SUCCESS) {
            [Reminder deleteOnLocal:reminder];
        }
    }];
}

+ (NSArray *)createPushRequestList:(User *)user {
    NSMutableArray * reminderRequest = [[NSMutableArray alloc] init];
    for (Reminder * rmd in user.reminders) {
        NSDictionary * rmdRequest = [rmd createPushRequest];
        if (rmdRequest && rmdRequest.count>=1) {
            [reminderRequest addObject:rmdRequest];
        }
    }
    return reminderRequest;
}

- (NSDictionary *)createPushRequest {
    NSMutableDictionary *request = [super createPushRequest];
    if (request.count >= 1) {
        [request setObject:self.uuid forKey:@"uuid"];
        return request;
    } else {
        return nil;
    }
}

#pragma mark - set Local notification (iOS)
- (void)setLocalNotification:(BOOL)on {
    if (on) {
        NSInteger repeat = 0;
        switch (self.repeat) {
            case REPEAT_DAILY:
                repeat = NSCalendarUnitDay;
                break;
            case REPEAT_WEEKLY:
                repeat = NSCalendarUnitWeekday;
                break;
            case REPEAT_MONTHLY:
                repeat = NSCalendarUnitMonth;
                break;
            case REPEAT_YEARLY:
                repeat = NSCalendarUnitYear;
                break;
            default:
                break;
        }
        for (int i=0; i<7; i++) {
            NSDate * time = [self getStartDate:i];
            if (time != nil) {
                if ((self.repeat == REPEAT_NO) && ([time isPassedTime])) {
                    continue;
                }
                [LocalNotification scheduleLocalNotification:NOTIF_USERINFO_VAL_TYPE_REMINDER title:self.title date:time repeat:repeat id:self.uuid userId:self.user.id info:@(self.type)];
            }
        }
    } else {
        [LocalNotification cancelNotification:self.uuid];
    }
}

/*
- (void)setWhenDate:(NSDate *)when {
    self.when = nil;
    if (when) {
        self.whenList = @[when, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER,TIME_HOLDER, TIME_HOLDER, TIME_HOLDER];
    }
}
*/

#pragma mark - APIs, for internal usage
- (void)toggleActive:(BOOL)on {
    /*
     * this is IBAction, handle user's action
     */
    [self update:@"on" boolValue:(int)on];
    [self setLocalNotification:on];
    self.user.dirty = YES;
    [self.user save];
}

- (NSDate *)nextWhen {
    NSMutableArray *arr = [NSMutableArray array];
    for (int i=0; i<7; i++) {
        NSDate * when = [self getStartDate:i];
        if ([when isKindOfClass:[NSDate class]]) {
            NSDate *d = when;
            if ([when isPassedTime] && self.repeat != REPEAT_NO) {
                for (int j=0; j<3000; j++) { // limit the loop in 3000
                    if (self.repeat == REPEAT_DAILY) {
                        d = [Utils dateByAddingDays:1 toDate:d];
                    } else if (self.repeat == REPEAT_WEEKLY) {
                        d = [Utils dateByAddingDays:7 toDate:d];
                    } else if (self.repeat == REPEAT_MONTHLY) {
                        d = [Utils dateByAddingMonths:1 toDate:d];
                    } else if (self.repeat == REPEAT_YEARLY) {
                        d = [Utils dateByAddingYears:1 toDate:d];
                    } else {
                        break;
                    }
                    if (![d isPassedTime]) {
                        break;
                    }
                }
            }
            [arr addObject:d];
        }
    }
    if ([arr count] > 0) {
        NSArray *ordered = [arr sortedArrayUsingComparator:^NSComparisonResult(NSDate *obj1, NSDate *obj2) {
            return [obj1 compare:obj2];
        }];
        return ordered[0];
    } else
        return nil;
}

+ (NSArray *)getDisplayedReminders:(NSArray *)sortDescriptors isAppointment:(BOOL)isAppt {
    User *u = [User currentUser];
    if (!u)
        return @[];
    
    NSArray * sourceArray = nil;
    if (sortDescriptors == nil) {
        sourceArray = u.reminders.array;
    } else {
        sourceArray = [u.reminders sortedArrayUsingDescriptors:sortDescriptors];
    }
    NSMutableArray * result = [[NSMutableArray alloc] init];
    for (Reminder * rmd in sourceArray) {
        if (isAppt && (rmd.type != REMINDER_TYPE_APPOINTMENT)) {
            continue;
        } else if (!isAppt && (rmd.type == REMINDER_TYPE_APPOINTMENT)) {
            continue;
        }
        if (rmd.isHide) {
            continue;
        } else {
            [result addObject:rmd];
        }
    }
    return result;
}

+ (void)updateAllReminders {
    // setup iPhone alert based on all given reminders
    User *user = [User currentUser];
    if (!user)
        return;
    if (![Reminder finishedMigrationForUser:user]) {
        return;
    }
    
    for (Reminder * rmdr in user.reminders) {
        // for hidden reminders, turn off it
        if (rmdr.isHide) {
            [rmdr setLocalNotification:NO];
            continue;
        }
        // sometimes user does not have internet, the reminder past
        // we have to reset the time on the local site
        if (rmdr.type == REMINDER_TYPE_SYS_PB) {
            if ([[rmdr getStartDate:0] isPassedTime]) {
                [Reminder updatePBReminder:rmdr];
            } else {
                [rmdr setLocalNotification:rmdr.on];
            }
        } else if (rmdr.type == REMINDER_TYPE_SYS_FB) {
            if ([[rmdr getStartDate:0] isPassedTime]) {
                [Reminder updateFBReminder:rmdr];
            } else {
                [rmdr setLocalNotification:rmdr.on];
            }
        } else {
            [rmdr setLocalNotification:rmdr.on];
        }
    }
}

+ (void)updateByPurposeChanged {
    User * user = [User currentUser];
    if (!user)
        return;
    Reminder * turnOnReminder = nil;
    if (user.isAvoidingPregnancy) {
        if (user.settings.birthControl == SETTINGS_BC_PILL) {
            turnOnReminder = [Reminder getReminderByType:REMINDER_TYPE_SYS_PILL];
        }
        else if (user.settings.birthControl == SETTINGS_BC_IUD) {
            turnOnReminder = [Reminder getReminderByType:REMINDER_TYPE_SYS_IUD];
        }
        else if (user.settings.birthControl == SETTINGS_BC_VAGINAL_RING) {
            turnOnReminder = [Reminder getReminderByType:REMINDER_TYPE_SYS_VRING];
        }
        else if (user.settings.birthControl == SETTINGS_BC_PATCH) {
            turnOnReminder = [Reminder getReminderByType:REMINDER_TYPE_SYS_CHANGE_PATCH];
        }
    }
    if (turnOnReminder) {
        [turnOnReminder update:@"on" boolValue:(int)YES];
        user.dirty = YES;
        [user save];
    }
}

- (NSArray *)startDateList {
    NSMutableArray * whenList = [[NSMutableArray alloc] init];
    for (int i=0; i<7; i++) {
        NSDate * d = [self getStartDate:i];
        if (d) {
            [whenList addObject:d];
        } else {
            [whenList addObject:TIME_HOLDER];
        }
    }
    return whenList;
}

+ (void)createOrUpdateReminder:(NSString *)uuid type:(NSInteger)reminderType withTitle:(NSString *)_title note:(NSString *)note when:(NSArray *)_whenList repeat:(REPEAT)_repeat frequency:(NSInteger)_freq on:(BOOL)on medCount:(NSInteger)med andMedUnit:(NSString *)medUnit forUser:(User *)user {
    
    if (!user) {
        [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:@{@"rc": @(RC_USER_NOT_EXIST),@"msg": @"Can not update the reminder"}];
        return;
    }
    NSMutableDictionary * reminderRequest = [[NSMutableDictionary alloc] init];
    // uuid
    if (!uuid) {
        // create flow, *type* is every important
        [reminderRequest setObject:@"" forKey:@"uuid"];
        [reminderRequest setObject:@(reminderType) forKey:@"type"];
    } else {
        // ignore "type", since it should not be changed after created
        [reminderRequest setObject:uuid forKey:@"uuid"];
    }
    
    // title
    if (_title) {
        [reminderRequest setObject:_title forKey:@"title"];
    }
    if (![Utils isEmptyString:note]) {
        [reminderRequest setObject:note forKey:@"note"];
    }
    
    // start date from when list
    if (_freq > 0) {
        [reminderRequest setObject:@(_freq) forKey:@"frequency"];
        int i = 0;
        for (id obj in _whenList) {
            if ([obj isKindOfClass:[NSDate class]]) {
                NSDate * d = (NSDate *)obj;
                NSString * s = [Reminder reminderDateToString:d];
                [reminderRequest setObject:s forKey:[NSString stringWithFormat:@"start_date%d", i]];
                i++;
                // we have match the freq
                if (i >= _freq) {
                    break;
                }
            }
        }
    }
    // repeat
    [reminderRequest setObject:@(_repeat) forKey:@"repeat"];
    // med count
    [reminderRequest setObject:@(med) forKey:@"med_per_take"];
    if (medUnit) {
        [reminderRequest setObject:medUnit forKey:@"med_per_take_unit"];
    }
    // on
    [reminderRequest setObject:(on ? @1 : @0) forKey:@"on"];
    
    NSString *url = @"v2/users/upsert_reminder";
    NSDictionary *request = [user postRequest:@{@"reminder": reminderRequest}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            if ([result[@"rc"] intValue] == RC_SUCCESS) {
                NSDictionary * serverReminder = [result objectForKey:@"reminder"];
                Reminder * rmd = [Reminder upsertWithServerData:serverReminder forUser:user];
                
                // print out
                //NSLog(@"BBBBBBB jr debug, upsert reminder: uuid=%@, type=%lld, on=%d, hide=%d", rmd.uuid, rmd.type, rmd.on, rmd.isHide);
                if (rmd) {
                    [rmd setLocalNotification:on];
                }
                [user save];
                [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:@{
                                                                    @"rc": @(RC_SUCCESS),
                                                                    @"reminder": rmd
                                                                    }];
            } else {
                [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:result];
            }
        } else {
            [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:@{
                @"rc": @(RC_USER_NOT_EXIST),
                @"msg": @"Can not update the reminder"
                }];
        }
    }];
    return;
}

- (void)setStartDateFromList:(NSArray *)whenList frequency:(NSInteger)frequency {
    int i = 0;
    for (id obj in whenList) {
        if ([obj isKindOfClass:[NSDate class]]) {
            NSDate * d = (NSDate *)obj;
            [self setStartDate:i date:d];
            i++;
            // we have match the freq
            if (i >= frequency) {
                break;
            }
        }
    }
    self.frequency = i;
}

+ (void)updatePredictionReminders {
    Reminder * rmd = [Reminder getReminderByType:REMINDER_TYPE_SYS_PB];
    [Reminder updatePBReminder:rmd];
    
    rmd = [Reminder getReminderByType:REMINDER_TYPE_SYS_FB];
    [Reminder updateFBReminder:rmd];
    return;
}

#pragma mark - get / delete reminder logic
+ (Reminder *)getReminderByType:(int)reminderType {
    User * u = [User currentUser];
    if (!u)
        return nil;
    if ([[Reminder defaultSystemTypes] indexOfObject:@(reminderType)] == NSNotFound)
        return nil;
    
    for (Reminder * rmd in u.reminders) {
        if (rmd.type == reminderType)
            return rmd;
    }
    return nil;
}

+ (Reminder *)getReminderByUUID:(NSString *)uuid {
    //    GLLog(@"getReminders: %@", reminderId);
    //    GLLog(@"getReminders: %@", self.reminders);
    User * u = [User currentUser];
    if (!u)
        return nil;
    if ([Utils isEmptyString:uuid])
        return nil;
    
    for (Reminder * rmd in u.reminders) {
        if ([rmd.uuid isEqualToString:uuid])
            return rmd;
    }
    return nil;
}

+ (void)deleteByUUID:(NSString *)uuid {
    Reminder * rmd = [Reminder getReminderByUUID:uuid];
    if (rmd) {
        rmd.isHide = YES;
        [rmd setLocalNotification:NO];
        [Reminder deleteReminderOnServer:rmd];
    }
}
/*
 + (void)delete:(NSString *)reminderId {
 User *u = [User currentUser];
 Reminder *r = [u getReminder:reminderId];
 if (r) {
 [r toggleActive:NO];
 [Reminder deleteInstance:r];
 }
 [u save];
 }
 */


/*
+ (REPEAT)repeatForReminder:(NSString *)reminder
{
    NSDictionary *mapping = @{
        SYS_REMINDER_ID_BBT: @(DAILY),
        SYS_REMINDER_ID_PB: @(MONTHLY),
        SYS_REMINDER_ID_FB: @(MONTHLY),
        SYS_REMINDER_ID_PILL: @(DAILY),
        SYS_REMINDER_ID_IUD: @(MONTHLY),
        SYS_REMINDER_ID_VRING: @(MONTHLY),
        SYS_REMINDER_ID_DRINK_WATER: @(WEEKLY),
        SYS_REMINDER_ID_STRETEH_BREAK: @(WEEKLY),
        SYS_REMINDER_ID_BREAST_CHECK: @(MONTHLY),
        SYS_REMINDER_ID_ANNUAL_EXAM: @(YEARLY),
        SYS_REMINDER_ID_CHANGE_PATCH: @(MONTHLY),
    };
    
    return [mapping[reminder] integerValue];
}

+ (NSString *)titleForReminder:(NSString *)reminder
{
    NSDictionary *mapping = @{
        SYS_REMINDER_ID_BBT: @"Take AM temperature",
        SYS_REMINDER_ID_PB: @"Period begins in 2 days",
        SYS_REMINDER_ID_FB: @"Fertile window starts",
        SYS_REMINDER_ID_PILL: @"Take your pill",
        SYS_REMINDER_ID_IUD: @"Check your IUD strings",
        SYS_REMINDER_ID_VRING: @"Replace your ring",
        SYS_REMINDER_ID_DRINK_WATER: @"Drink water",
        SYS_REMINDER_ID_STRETEH_BREAK: @"Take a stretch break",
        SYS_REMINDER_ID_BREAST_CHECK: @"Perform self breast check",
        SYS_REMINDER_ID_ANNUAL_EXAM: @"Annual well woman exam",
        SYS_REMINDER_ID_CHANGE_PATCH: @"Change your patch",
    };
    
    return mapping[reminder];
}
*/
/*

+ (void)updateSysReminders {
    User *user = [User currentUser];
    if (!user) {
        return;
    }
    
    for (NSString *each in [Reminder validSysReminders]) {
        Reminder *reminder = [user getReminder:each];
        
        if (!reminder) {
//            BOOL on = !([each isEqualToString:SYS_REMINDER_ID_DRINK_WATER] ||
//                        [each isEqualToString:SYS_REMINDER_ID_STRETEH_BREAK]);
            
            reminder = [Reminder createSysReminder:each
                                         withTitle:[Reminder titleForReminder:each]
                                        withRepeat:[Reminder repeatForReminder:each]
                                                on:NO];
        }
        
        if ([each isEqualToString:SYS_REMINDER_ID_PB]) {
            [Reminder updatePBReminder:reminder];
        }
        else if ([each isEqualToString:SYS_REMINDER_ID_FB]) {
            [Reminder updateFBReminder:reminder];
        }
        else {
            [Reminder updateSingleReminder:reminder];
        }
        
    }

    [user save];
}
 */

/*
+ (NSArray *)validSysReminders
{
    User *user = [User currentUser];
    if (!user) {
        return @[];
    }
    
    NSMutableArray *reminders = [NSMutableArray arrayWithArray:@[SYS_REMINDER_ID_DRINK_WATER, SYS_REMINDER_ID_STRETEH_BREAK, SYS_REMINDER_ID_BREAST_CHECK, SYS_REMINDER_ID_ANNUAL_EXAM, SYS_REMINDER_ID_PB]];
    
    if (user.isAvoidingPregnancy) {
        if (user.settings.birthControl == SETTINGS_BC_PILL) {
            [reminders addObject:SYS_REMINDER_ID_PILL];
        }
        else if (user.settings.birthControl == SETTINGS_BC_IUD) {
            [reminders addObject:SYS_REMINDER_ID_IUD];
        }
        else if (user.settings.birthControl == SETTINGS_BC_VAGINAL_RING) {
            [reminders addObject:SYS_REMINDER_ID_VRING];
        }
        else if (user.settings.birthControl == SETTINGS_BC_PATCH) {
            [reminders addObject:SYS_REMINDER_ID_CHANGE_PATCH];
        }
        else if (user.settings.birthControl == SETTINGS_BC_IMPLANT || user.settings.birthControl == SETTINGS_BC_SHOT) {
            [reminders addObject:SYS_REMINDER_ID_BBT];
        }
        else {
            [reminders addObjectsFromArray: @[SYS_REMINDER_ID_BBT, SYS_REMINDER_ID_FB]];
        }
    }
    else {
        [reminders addObjectsFromArray: @[SYS_REMINDER_ID_BBT, SYS_REMINDER_ID_FB]];
    }
    
    return reminders;
}
*/

/*
+ (void)updateAllRemindersOld {
    User *user = [User currentUser];
    if (!user)
        return;
    
    //[Reminder updateSysReminders];
    //UILocalNotification has repeatInterval for DAILY/WEEKLY/MONTHLY
    for (Reminder *rmdr in user.reminders) {
        if (![rmdr isSystemReminder] && rmdr.on && [rmdr.when timeIntervalSinceNow] < 0) {
            NSInteger add = 0;
            switch (rmdr.repeat) {
                case NO_REPEAT:
                    [rmdr toggleActive:NO];
                    break;
                case BIWEEKLY:
                    add = 14;
                    break;
                default:
                    break;
            }

            NSDate *newDate = nil;
            if (add) {
                newDate = [Utils dateByAddingDays:add toDate:rmdr.when];
                NSInteger limit = 0;
                while ([newDate timeIntervalSinceNow] < 0 && limit < 100) {
                    newDate = [Utils dateByAddingDays:add toDate:newDate];
                    limit += 1;
                }
            }
            
            if (newDate) {
                [rmdr setWhenDate:newDate];
                [rmdr toggleActive:rmdr.on];
            }
            
        }
    }
    [user save];
}
*/

/*
+ (Reminder *)createSysReminder:(NSString *)reminderId withTitle:(NSString *)title withRepeat:(REPEAT)repeat on:(BOOL)on {
    Reminder *reminder = nil;
    User * user = [User currentUser];
    if (!user)
        return nil;;
    reminder = [Reminder newInstance:user.dataStore];
    reminder.title = title;
    reminder.timeCreated = [NSDate date];
    reminder.on = on;
    
    NSInteger hour = 8;
    if ([reminderId isEqualToString:SYS_REMINDER_ID_DRINK_WATER]) {
        hour = 12;
    }
    else if ([reminderId isEqualToString:SYS_REMINDER_ID_STRETEH_BREAK]) {
        hour = 14;
    }
    else if ([reminderId isEqualToString:SYS_REMINDER_ID_BREAST_CHECK]) {
        hour = 21;
    }
    else if ([reminderId isEqualToString:SYS_REMINDER_ID_ANNUAL_EXAM]) {
        hour = 10 + 7 * 24;
    }
    
    NSDate *date = [Utils dateOfHour:hour minute:0 second:0];
    [reminder setWhenDate:date];
    reminder.repeat = repeat;
    reminder.modifiable = NO;
    reminder.id = reminderId;
    reminder.user = user;
    return reminder;
}


+ (void)updateSingleReminder:(Reminder *)reminder {
    User * user = [User currentUser];
    if (!user)
        return;
    NSCalendar *cal = [Utils calendar];
    
    NSDate *rmdrWhen = [reminder nextWhen];
    
    NSInteger bbtHour = [cal components:NSHourCalendarUnit fromDate:rmdrWhen].hour;
    NSInteger bbtMinute = [cal components:NSMinuteCalendarUnit fromDate:rmdrWhen].minute;
    NSDateComponents *components;
    NSDateComponents *now = [cal components:NSHourCalendarUnit fromDate:[NSDate date]];
    
    NSUInteger flag = NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit;
    if (bbtHour < now.hour || (bbtHour == now.hour &&  bbtMinute <= now.minute)) {
        components = [cal components:flag fromDate:[Utils dateByAddingDays:1 toDate:[NSDate date]]];
    } else {
        components = [cal components:flag fromDate:[NSDate date]];
    }
    
    if ([reminder.id isEqualToString:SYS_REMINDER_ID_ANNUAL_EXAM]) {
        NSInteger days = [cal components:NSDayCalendarUnit fromDate:rmdrWhen].day;
        [components setDay:days];
    }
    
    [components setHour:bbtHour];
    [components setMinute:bbtMinute];
    
    [reminder setWhenDate:[cal dateFromComponents:components]];
    [reminder toggleActive:reminder.on];
}
*/

#pragma mark - old need be check
+ (void)updatePBReminder:(Reminder *)reminderPB {
    User * user = [User currentUser];
    if (!user)
        return;
    NSCalendar *cal = [Utils calendar];
    
    NSString *pb = [user dateLabelForNextPB:YES];
    if (pb) {
        NSDate *pbDate = [Utils dateWithDateLabel:pb];
        NSDate *rmdrWhen = [reminderPB nextWhen];
        NSInteger hour = [cal components:NSHourCalendarUnit fromDate:rmdrWhen].hour;
        if ([Utils date:pbDate isSameDayAsDate:[NSDate date]] && hour <= [cal components:NSHourCalendarUnit fromDate:[NSDate date]].hour ) {
            //If is today but hour has passed, get next pb.
            pb = [user dateLabelForNextPB:NO];
            if (pb) {
                pbDate = [Utils dateWithDateLabel:pb];
            }
        }
        if (pbDate) {
            NSDateComponents *components = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[Utils dateByAddingDays:-2 toDate:pbDate]];
            [components setHour:hour];

            // because we don't want to push it to server, so to not use update
            NSString * dateString = [Reminder reminderDateToString:[cal dateFromComponents:components]];
            reminderPB.startDate0 = dateString;
            [reminderPB setLocalNotification:reminderPB.on];
            reminderPB.title = @"Period begins in 2 days";
        }
    }
}

+ (void)updateFBReminder:(Reminder *)reminderFB {
    User * user = [User currentUser];
    if (!user)
        return;
    NSCalendar *cal = [Utils calendar];
    
    NSString *fb = [user dateLabelForNextFB:YES];
    if (fb) {
        NSDate *fbDate = [Utils dateWithDateLabel:fb];
        
        NSInteger hour = [cal components:NSHourCalendarUnit fromDate:[reminderFB nextWhen]].hour;
        
        if ([Utils date:fbDate isSameDayAsDate:[NSDate date]] && hour <= [cal components:NSHourCalendarUnit fromDate:[NSDate date]].hour ) {
            //If is today but hour has passed, get next fb.
            fb = [user dateLabelForNextFB:NO];
            if (fb) {
                fbDate = [Utils dateWithDateLabel:fb];
            }
        }
        
        if (fbDate) {
            NSDateComponents *components = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:fbDate];
            [components setHour:hour];
            
            // because we don't want to push it to server, so to not use update
            NSString * dateString = [Reminder reminderDateToString:[cal dateFromComponents:components]];
            reminderFB.startDate0 = dateString;
            [reminderFB setLocalNotification:reminderFB.on];
        }
    }
}


@end
