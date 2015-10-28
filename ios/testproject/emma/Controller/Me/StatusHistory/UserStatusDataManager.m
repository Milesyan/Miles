//
//  StatusHistoryDataManager.m
//  emma
//
//  Created by ltebean on 15/6/23.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "UserStatusDataManager.h"
@interface UserStatusDataManager()
@end

@implementation UserStatusDataManager
+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


- (void)cutAndRemoveAllFutureStatusHistory
{
    User *user = [User currentUser];
    if (!user) {
        return;
    }
    if ([user isSecondary]) {
        return;
    }
    // remove future status history
    NSDate *today = [NSDate date];
    NSDate *veryFuture = [Utils dateByAddingYears:10 toDate:today];
    NSArray *historyBetween = [StatusHistory historyBetweenDate:[today toDateLabel]  andDate:[veryFuture toDateLabel] forUser:user];
    for (StatusHistory *history in historyBetween) {
        [history remove];
    }
    // cut the current one
    StatusHistory *currentTreatment = [StatusHistory historyOnDate:[today toDateLabel] forUser:user];
    if (currentTreatment) {
        currentTreatment.endDate = [[Utils dateByAddingDays:-1 toDate:today] toDateLabel];
    }
    user.statusHistoryDirty = YES;
}


- (UserStatus *)statusOnDate:(NSString *)date forUser:(User *)user
{
    if (!user) {
        return nil;
    }
    StatusHistory *history = [StatusHistory historyOnDate:date forUser:user];
    if (history && history.status == STATUS_TREATMENT) {
        return [UserStatus instanceWithStatus:history.status treatmentType:history.treatmentType startDate:[Utils dateWithDateLabel:history.startDate] endDate:[Utils dateWithDateLabel:history.endDate]];
    } else {
        return [UserStatus instanceWithStatus:user.settings.currentStatus treatmentType:TREATMENT_TYPE_INTERVAL startDate:nil endDate:nil];
    }
}


- (NSArray *)statusHistoryForUser:(User *)user
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *statusHistory = [StatusHistory allHistoryForUser:user];
    for (StatusHistory *history in statusHistory) {
        [result addObject:[UserStatus instanceWithStatus:history.status treatmentType:history.treatmentType startDate:[Utils dateWithDateLabel:history.startDate] endDate:[Utils dateWithDateLabel:history.endDate]]];
    }
    return result;
}

- (UserStatus *)lastTreatmentStatusForUser:(User *)user
{
    NSArray *treatmentHistory = [self statusHistoryForUser:user];
    if (!treatmentHistory || treatmentHistory.count == 0) {
        return nil;
    }
    return [treatmentHistory firstObject];
}

- (void)updateStatusHistory:(UserStatus *)originalStatus to:(UserStatus *)status forUser:(User *)user
{
    NSDate *beginDate;
    NSDate *endDate;

    if ([status.startDate compare:originalStatus.startDate] == NSOrderedAscending) {
        beginDate = status.startDate;
    } else {
        beginDate = originalStatus.startDate;
    }
    
    if ([status.endDate compare:originalStatus.endDate] == NSOrderedAscending) {
        endDate = originalStatus.endDate;
    } else {
        endDate = status.endDate;
    }
    NSString *beginDateLabel = [beginDate toDateLabel];
    NSString *endDateLabel = [endDate toDateLabel];
    
    NSArray *historyBetween;
    historyBetween = [StatusHistory historyBetweenDate:beginDateLabel andDate:endDateLabel forUser:user];
    for (StatusHistory *history in historyBetween) {
         [history remove];
    }
    
    NSDate *datePrevToStartDate = [Utils dateByAddingDays:-1 toDate:status.startDate];
    StatusHistory *historyPrev = [StatusHistory historyOnDate:[datePrevToStartDate toDateLabel] forUser:user];
    if (historyPrev) {
        historyPrev.endDate = [datePrevToStartDate toDateLabel];
    }
    
    if (status.endDate) {
        NSDate *dateNextToEndDate = [Utils dateByAddingDays:1 toDate:status.endDate];
        StatusHistory *historyNext = [StatusHistory historyOnDate:[dateNextToEndDate toDateLabel] forUser:user];
        if (historyNext) {
            historyNext.startDate = [dateNextToEndDate toDateLabel];
        }
    }
    
    StatusHistory *history = [StatusHistory newInstance:user.dataStore];
    history.user = user;
    history.startDate = [status.startDate toDateLabel];
    history.endDate = [status.endDate toDateLabel];
    history.treatmentType = status.treatmentType;
    history.status = status.status;
    
    user.statusHistoryDirty = YES;

    [self publish:EVENT_USER_STATUS_HISTORY_CHANGED];
}

- (void)createStatusHistory:(UserStatus *)status forUser:(User *)user
{
    [self updateStatusHistory:status to:status forUser:user];
}

- (void)deleteStatusHistory:(UserStatus *)status forUser:(User *)user
{
    StatusHistory *treament = [StatusHistory historyWithStartDate:[status.startDate toDateLabel] endDate:[status.endDate toDateLabel] forUser:user];
    [treament remove];
    user.statusHistoryDirty = YES;
    [self publish:EVENT_USER_STATUS_HISTORY_CHANGED];
}


@end
