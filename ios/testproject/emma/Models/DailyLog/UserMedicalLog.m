//
//  UserMedicalLog.m
//  emma
//
//  Created by Peng Gu on 10/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UserMedicalLog.h"
#import "User.h"
#import "DataStore.h"

@implementation UserMedicalLog


@dynamic dataKey;
@dynamic date;
@dynamic source;
@dynamic dataValue;
@dynamic user;

- (NSDictionary *)attrMapper
{
    return @{@"date"        : @"date",
             @"data_key"    : @"dataKey",
             @"data_value"  : @"dataValue",
             @"data_source" : @"source",
             };
}


+ (Class)entityClass
{
    return [UserMedicalLog class];
}


+ (NSSet *)medicalLogsOnDate:(NSString *)date forUser:(User *)user
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date == %@", date];
    return [user.medicalLogs filteredSetUsingPredicate:predicate];
}


+ (NSSet *)medicalLogsForKey:(NSString *)key user:(User *)user
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dataKey == %@", key];
    return [user.medicalLogs filteredSetUsingPredicate:predicate];
}


+ (UserMedicalLog *)medicalLogWithKey:(NSString *)key date:(NSString *)date user:(User *)user
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date == %@ AND dataKey == %@", date, key];
    NSSet *results = [user.medicalLogs filteredSetUsingPredicate:predicate];
    if (results.count > 0) {
        return [results anyObject];
    }
    return nil;
}


#pragma mark - Server
+ (instancetype)upsertWithServerData:(NSDictionary *)data forUser:(User *)user
{
    if (!data[@"data_key"] || ![data[@"data_key"] isKindOfClass:[NSString class]]) {
        return nil;
    }
    UserMedicalLog *medLog = [UserMedicalLog tset:data[@"date"] dataKey:data[@"data_key"] forUser:user];
    [medLog updateAttrsFromServerData:data];
    NSLog(@"upsert with server data: %@", data);
    
    return medLog;
}


+ (instancetype)tset:(NSString *)date dataKey:(NSString *)dataKey forUser:(User *)user
{
    if (!dataKey || ![dataKey isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    UserMedicalLog *medLog = [UserMedicalLog medicalLogWithKey:dataKey date:date user:user];
    if (!medLog) {
        medLog = [UserMedicalLog newInstance:user.dataStore];
        medLog.user = user;
        medLog.dataKey = dataKey;
        medLog.date = date;
    }
    
    return medLog;
}


- (void)setDirty:(BOOL)dirty
{
    [super setDirty:dirty];
    if (dirty) {
        self.user.dirty = YES;
    }
}


- (NSMutableDictionary *)createPushRequest
{
    NSMutableDictionary *request = [super createPushRequest];
    request[@"data_key"] = self.dataKey;
    request[@"date"] = self.date;
    request[@"user_id"] = self.user.id;
    
    if (self.dataValue) {
        request[@"data_value"] = self.dataValue;
    }
    return request;
}


- (NSString *)sortKey
{
    return self.date;
}


#pragma mark -
+ (NSArray *)hcgTriggerShotDateIndexes
{
    NSSet *logs = [UserMedicalLog medicalLogsForKey:kMedItemHCGTriggerShot user:[User currentUser]];
    NSMutableArray *dateIndexes = [NSMutableArray array];
    for (UserMedicalLog *each in logs) {
        if (each.dataValue.integerValue == BinaryValueTypeYes) {
            NSInteger index = [Utils dateLabelToIntFrom20130101:each.date];
            [dateIndexes addObject:@(index)];
        }
    }
    return dateIndexes;
}

+ (NSArray *)hcgTriggerShotDateIndexesAdvance
{
    NSSet *logs = [UserMedicalLog medicalLogsForKey:kMedItemHCGTriggerShot user:[User currentUser]];
    NSMutableArray *dateIndexes = [NSMutableArray array];
    for (UserMedicalLog *each in logs) {
        if (each.dataValue.integerValue == BinaryValueTypeYes) {
            NSInteger index = [Utils dateLabelToIntFrom20130101:each.date];
            [dateIndexes addObject:@(index)];
            [dateIndexes addObject:@(index + 1)];
            [dateIndexes addObject:@(index + 2)];
        }
    }
    return dateIndexes;
}

+ (BOOL)isDateIndexWithinHcgTriggerShotDates:(NSInteger)dateIndex
{    
    NSArray *indexes = [UserMedicalLog hcgTriggerShotDateIndexesAdvance];
    return [indexes containsObject:@(dateIndex)];
}


#pragma mark - medication logs

+ (NSArray *)dateLabelsForMedicationLogsInMonth:(NSDate *)date
{
    NSString *dateLable = [[Utils dailyDataDateLabel:date] substringToIndex:7];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dataKey BEGINSWITH %@ AND date BEGINSWITH %@ and dataValue == %@", kMedicationItemKeyPrefix, dateLable, @"1"];
    NSSet *result = [[User currentUser].medicalLogs filteredSetUsingPredicate:predicate];

    return [result.allObjects valueForKeyPath:@"date"];
}


+ (BOOL)user:(User *)user hasMedicationLogsOnDate:(NSString *)date;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dataKey BEGINSWITH %@ AND date == %@", kMedicationItemKeyPrefix, date];
    NSSet *result = [user.medicalLogs filteredSetUsingPredicate:predicate];
    return result.count > 0;
}


+ (BOOL)user:(User *)user hasMedicalLogsOnDate:(NSString *)date
{
    NSSet *results = [UserMedicalLog medicalLogsOnDate:date forUser:user];
    for (UserMedicalLog *log in results) {
        if (log.dataValue) {
            return  YES;
        }
    }
    return NO;
}


@end
