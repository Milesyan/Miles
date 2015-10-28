//
//  UserStatus.m
//  emma
//
//  Created by ltebean on 15/6/16.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "StatusHistory.h"

#define STATUS_TTC 0
#define STATUS_PREGNANT 2
#define STATUS_NON_TTC 3
#define STATUS_TREATMENT 4


@implementation StatusHistory
@dynamic startDate;
@dynamic endDate;
@dynamic treatmentType;
@dynamic user;
@dynamic status;

- (NSDictionary *)attrMapper
{
    return @{
             @"treatment_type" : @"treatmentType",
             @"start_date"     : @"startDate",
             @"end_date"       : @"endDate",
             @"status"         : @"status"
             };
}

+ (NSArray *)allHistoryForUser:(User *)user
{
    return [user.statusHistory sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO]]];
}

+ (NSArray *)treatmentHistoryForUser:(User *)user
{
    NSOrderedSet *treatmentHistory = [user.statusHistory filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"status == %d", STATUS_TREATMENT]];
    return [treatmentHistory sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:NO]]];
}

+ (StatusHistory *)historyOnDate:(NSString *)date forUser:(User *)user
{
    NSOrderedSet *result = [user.statusHistory filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"status == 4 and startDate <= %@ and endDate >= %@", date, date]];
    if (result && result.count > 0) {
        return result[0];
    } else {
        return nil;
    }
}

+ (StatusHistory *)historyWithStartDate:(NSString *)startDate endDate:(NSString *)endDate forUser:(User *)user
{
    NSOrderedSet *result = [user.statusHistory filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"startDate == %@ and endDate == %@", startDate, endDate]];
    if (result && result.count > 0) {
        return result[0];
    } else {
        return nil;
    }
}

- (void)setDirty:(BOOL)dirty
{
    
}

- (void)remove
{
    [self.managedObjectContext deleteObject:self];
    [self save];
}

+ (NSArray *)historyBetweenDate:(NSString *)startDate andDate:(NSString *)endDate forUser:(User *)user;
{
    NSOrderedSet *result = [user.statusHistory filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"startDate >= %@ and endDate <=%@", startDate, endDate]];
    return [result array];
}


+ (NSArray *)modifiedHistoryForUser:(User *)user;
{
    NSOrderedSet *result = [user.statusHistory filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"objState == %d", EMMA_OBJ_STATE_DIRTY]];
    return [result array];
}


+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user;
{
    StatusHistory *history = [StatusHistory newInstance:user.dataStore];
    history.user = user;
    history.startDate = data[@"start_date"];
    history.endDate = data[@"end_date"];
    history.status =  [data[@"status"] integerValue];
    history.treatmentType = [data[@"treatment_type"] integerValue];
    return history;
}

+ (void)resetWithServerData:(NSArray *)serverData forUser:(User *)user
{
    if (!serverData) {
        return;
    }
    NSArray *allHistory = [self allHistoryForUser:user];
    for (StatusHistory *history in allHistory) {
        [history remove];
    }
    for (NSDictionary *data in serverData) {
        [self upsertWithServerData:data forUser:user];
    }
}


- (NSMutableDictionary *)createPushRequest
{
    NSMutableDictionary *request = [NSMutableDictionary dictionary];
    request[@"start_date"] = self.startDate;
    request[@"end_date"] = self.endDate;
    request[@"treatment_type"] = @(self.treatmentType);
    request[@"status"] = @(self.status);
    return request;
}

@end
