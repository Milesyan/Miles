//
//  StatusHistoryDataManager.h
//  emma
//
//  Created by ltebean on 15/6/23.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StatusHistory.h"
#import "UserStatus.h"
#import "User.h"

@interface UserStatusDataManager : NSObject

+ (instancetype)sharedInstance;

- (UserStatus *)statusOnDate:(NSString *)date forUser:(User *)user;
- (UserStatus *)lastTreatmentStatusForUser:(User *)user;
- (void)cutAndRemoveAllFutureStatusHistory;
- (NSArray *)statusHistoryForUser:(User *)user;
- (void)updateStatusHistory:(UserStatus *)originalStatus to:(UserStatus *)status forUser:(User *)user;
- (void)createStatusHistory:(UserStatus *)status forUser:(User *)user;
- (void)deleteStatusHistory:(UserStatus *)status forUser:(User *)user;

@end
