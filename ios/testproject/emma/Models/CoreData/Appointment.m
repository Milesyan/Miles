//
//  Appointment.m
//  emma
//
//  Created by Jirong Wang on 10/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "Appointment.h"
#import "User.h"
#import "Network.h"
#import "Reminder.h"

@interface Appointment()

@end

@implementation Appointment

@dynamic appointmentId;
@dynamic reminderUUID;
@dynamic title;
@dynamic note;
@dynamic type;
@dynamic attend;
@dynamic timeCreated;
@dynamic timeModified;
@dynamic when;

@dynamic user;

- (NSDictionary *)attrMapper {
    return @{
             @"reminder_uuid"   : @"reminderUUID",
             @"type"            : @"type",
             @"title"           : @"title",
             @"note"            : @"note",
             @"when"            : @"when",
             @"attend"          : @"attend",
             @"time_created"    : @"timeCreated",
             @"time_modified"   : @"timeModified",
             @"id"              : @"appointmentId"
             };
}

+ (NSDate *)stringToDate:(NSString *)string {
    /*
     String : yyyy-mm-dd-HH-MM-SS
     */
    if ([Utils isEmptyString:string]) {
        return nil;
    }
    NSArray *splitedDate = [string componentsSeparatedByString:@"-"];
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

+ (NSString *)dateToString:(NSDate *)apptDate {
    /*
     String : yyyy-mm-dd-HH-MM-SS
     */
    if (apptDate == nil) {
        return nil;
    }
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *time = [calendar components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond
                                         fromDate:apptDate];
    return [NSString stringWithFormat:@"%.4ld-%.2ld-%.2ld-%.2ld-%.2ld-%.2ld",
            time.year, time.month, time.day, time.hour, time.minute, time.second];
}


- (NSDate *)date
{
    return [Appointment stringToDate:self.when];
}

#pragma mark - update local data from server
+ (void)upsertWithServerArray:(NSArray *)appointments forUser:(User *)user {
    for (NSDictionary *data in appointments) {
        [Appointment upsertWithServerData:data forUser:user];
    }
    [user save];
}

+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user {
    int64_t appointmentId = [[data objectForKey:@"id"] unsignedLongLongValue];
    if (!appointmentId) {
        return nil;
    }
    Appointment * appt = [self tset:appointmentId forUser:user];
    // check if the appointment should be removed or not
    NSNumber * timeRemoved = [data objectForKey:@"time_removed"];
    if (timeRemoved != nil) {
        if ([timeRemoved longLongValue] != 0) {
            [Appointment deleteInstance:appt];
            return nil;
        }
    }
    [appt updateAttrsFromServerData:data];
    return appt;
}

+ (id)tset:(int64_t)apptId forUser:(User *)user {
    DataStore *ds = user.dataStore;
    Appointment *appt = (Appointment *)[self fetchObject:@{@"user.id" : user.id, @"appointmentId" : @(apptId)} dataStore:ds];;
    if (!appt) {
        appt = [Appointment newInstance:ds];
        appt.user = user;
        appt.appointmentId = apptId;
    }
    return appt;
}

+ (id)getAppointmentByReminderUUID:(NSString *)reminderUUID forUser:(User *)user {
    DataStore *ds = user.dataStore;
    Appointment *appt = (Appointment *)[self fetchObject:@{
        @"user.id" : user.id,
        @"reminderUUID" : reminderUUID
    } dataStore:ds];
    return appt;
}

- (void)setDirty:(BOOL)val {
    [super setDirty:val];
    if (val) {
        self.user.dirty = YES;
    }
}

#pragma mark - APIs, for reminder page usage

+ (void)createOrUpdateAppointment:(NSString *)reminderUUID title:(NSString *)title note:(NSString *)note when:(NSDate *)when repeat:(REPEAT)repeat on:(BOOL)on forUser:(User *)user {
    if (![Utils isEmptyString:reminderUUID]) {
        return [Appointment updateAppointment:reminderUUID title:title note:note when:when repeat:repeat on:on forUser:user];
    } else {
        return [Appointment createAppointment:title note:note when:when repeat:repeat on:on forUser:user];
    }
}

+ (void)createAppointment:(NSString *)title note:(NSString *)note when:(NSDate *)when repeat:(REPEAT)repeat on:(BOOL)on forUser:(User *)user {
    if (!user) {
        [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:@{@"rc": @(RC_USER_NOT_EXIST),@"msg": @"Can not create the appointment"}];
        return;
    }
    
    NSMutableDictionary * apptRequest = [[NSMutableDictionary alloc] init];
    // title
    [apptRequest setObject:title forKey:@"title"];
    // note
    if (note) {
        [apptRequest setObject:note forKey:@"note"];
    }
    // when
    [apptRequest setObject:[Appointment dateToString:when] forKey:@"when"];
    // repeat
    [apptRequest setObject:@(repeat) forKey:@"repeat"];
    // on
    [apptRequest setObject:(on ? @1 : @0) forKey:@"on"];

    NSString *url = @"users/create_appointment";
    NSDictionary *request = [user postRequest:@{@"appointment": apptRequest}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            if ([result[@"rc"] intValue] == RC_SUCCESS) {
                NSMutableDictionary * eventData = [[NSMutableDictionary alloc] init];
                [eventData setObject:@(RC_SUCCESS) forKey:@"rc"];
                NSDictionary * serverAppointment = [result objectForKey:@"appointment"];
                if (serverAppointment) {
                    [Appointment upsertWithServerData:serverAppointment forUser:user];
                    NSDictionary * serverReminder = [result objectForKey:@"reminder"];
                    if (serverReminder) {
                        Reminder * rmd = [Reminder upsertWithServerData:serverReminder forUser:user];
                        [eventData setObject:rmd forKey:@"reminder"];
                    }
                }
                [user save];
                [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:eventData];
            } else {
                [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:result];
            }
        } else {
            [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:@{
                @"rc": @(RC_USER_NOT_EXIST),
                @"msg": @"Can not create the appointment"
            }];
        }
    }];
    return;
}

+ (void)updateAppointment:(NSString *)reminderUUID title:(NSString *)title note:(NSString *)note when:(NSDate *)when repeat:(REPEAT)repeat on:(BOOL)on forUser:(User *)user {
    BOOL badRequest = NO;
    Appointment * appt = nil;
    if (!user) {
        badRequest = YES;
    } else {
        appt = [Appointment getAppointmentByReminderUUID:reminderUUID forUser:user];
        if (!appt)
            badRequest = YES;
    }
    if (badRequest) {
        [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:@{@"rc": @(RC_USER_NOT_EXIST),@"msg": @"Can not update the appointment"}];
        return;
    }
    
    NSMutableDictionary * apptRequest = [[NSMutableDictionary alloc] init];
    // id
    [apptRequest setObject:@(appt.appointmentId) forKey:@"id"];
    // title
    if (title) {
        [apptRequest setObject:title forKey:@"title"];
    }
    // note
    if (note) {
        [apptRequest setObject:note forKey:@"note"];
    }
    // when
    if (when) {
        [apptRequest setObject:[Appointment dateToString:when] forKey:@"when"];
    }
    // repeat
    if (when) {
        [apptRequest setObject:@(repeat) forKey:@"repeat"];
    }
    // on
    [apptRequest setObject:(on ? @1 : @0) forKey:@"on"];
    
    NSString *url = @"users/update_appointment";
    NSDictionary *request = [user postRequest:@{@"appointment": apptRequest}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            if ([result[@"rc"] intValue] == RC_SUCCESS) {
                NSMutableDictionary * eventData = [[NSMutableDictionary alloc] init];
                [eventData setObject:@(RC_SUCCESS) forKey:@"rc"];
                
                NSDictionary * serverAppointment = [result objectForKey:@"appointment"];
                if (serverAppointment) {
                    [Appointment upsertWithServerData:serverAppointment forUser:user];
                } else {
                    // the appointment is not exist in the server
                    [Appointment deleteInstance:appt];
                }
                
                NSDictionary * serverReminder = [result objectForKey:@"reminder"];
                if (serverReminder) {
                    Reminder * rmd = [Reminder upsertWithServerData:serverReminder forUser:user];
                    [eventData setObject:rmd forKey:@"reminder"];
                }
                
                [user save];
                [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:eventData];
            } else {
                [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:result];
            }
        } else {
            [user publish:EVENT_REMINDER_UPDATE_RESPONSE data:@{
                @"rc": @(RC_USER_NOT_EXIST),
                @"msg": @"Can not update the appointment"
            }];
        }
    }];
    return;
}

+ (void)deleteAppointment:(NSString *)reminderUUID forUser:(User *)user {
    if (!user)
        return;
    
    Appointment * appt = [Appointment getAppointmentByReminderUUID:reminderUUID forUser:user];
    if (appt) {
        Reminder * rmd = [Reminder getReminderByUUID:reminderUUID];
        if (rmd) {
            rmd.isHide = YES;
            [rmd setLocalNotification:NO];
        } else {
            rmd = nil;
        }
        [Appointment deleteAppointmentOnServer:appt reminder:rmd forUser:user];
    } else {
        [Reminder deleteByUUID:reminderUUID];
    }
}

+ (void)deleteAppointmentOnServer:(Appointment *)appt reminder:(Reminder *)rmd forUser:(User *)user {
    NSString *url = @"users/remove_appointment";
    NSDictionary *request = [user postRequest:@{
        @"appt_id": @(appt.appointmentId),
        @"reminder_uuid": rmd ? rmd.uuid : @""
    }];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if ([result[@"rc"] intValue] == RC_SUCCESS) {
            [Appointment deleteInstance:appt];
            if (rmd) {
                [Reminder deleteOnLocal:rmd];
            }
        }
    }];
}

+ (NSArray *)getAppointments:(NSArray *)sortDescriptors onlyHistory:(BOOL)onlyHistory {
    User *u = [User currentUser];
    if (!u)
        return @[];
    
    NSArray * sourceArray = nil;
    if (sortDescriptors == nil) {
        sourceArray = u.appointments.array;
    } else {
        sourceArray = [u.appointments sortedArrayUsingDescriptors:sortDescriptors];
    }
    
    NSMutableArray * result = [[NSMutableArray alloc] init];
    for (Appointment * appt in sourceArray) {
        if (!appt.attend) {
            continue;
        }
        if (onlyHistory) {
            NSString * appointmentDate = [[Appointment stringToDate:appt.when] toDateLabel];
            NSString * todayLabel = [[NSDate date] toDateLabel];
            if ([Utils dateLabel:appointmentDate minus:todayLabel] >= 0) {
                continue;
            }
        }
        [result addObject:appt];
    }
    return result;
}


+ (NSArray *)dateLabelsForAppointmentsInMonth:(NSDate *)date
{
    NSString *dateString = [[self dateToString:date] substringToIndex:7];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"when BEGINSWITH %@", dateString];
    NSArray *appts = [[User currentUser].appointments.array filteredArrayUsingPredicate:predicate];

    NSMutableArray *result = [NSMutableArray array];
    for (Appointment *each in appts) {
        [result addObject:[Utils dailyDataDateLabel:each.date]];
    }
    return result;
}


+ (BOOL)currentUserHasAppointmentsOnDate:(NSDate *)date
{
    NSString *dateString = [[self dateToString:date] substringToIndex:11];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"when BEGINSWITH %@", dateString];
    NSArray *result = [[User currentUser].appointments.array filteredArrayUsingPredicate:predicate];
    return result.count > 0;
}


+ (Appointment *)currentUserUpcomingAppointmentForDate:(NSDate *)date
{
    NSSortDescriptor* sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    NSArray *result = [[User currentUser].appointments.array sortedArrayUsingDescriptors:@[sortByDate]];
    
    date = [date truncatedSelf];
    for (Appointment *appt in result) {
        NSComparisonResult comp = [date compare:appt.date];
        if (comp == NSOrderedSame || comp == NSOrderedAscending) {
            return appt;
        }
    }
    return nil;
}

+ (Appointment *)appointmentByReminderUUID:(NSString *)uuid
{
    User *user = [User currentUser];
    DataStore *ds = [User currentUser].dataStore;
    return [self fetchObject:@{@"user.id" : user.id, @"reminderUUID" : uuid} dataStore:ds];
}


@end



