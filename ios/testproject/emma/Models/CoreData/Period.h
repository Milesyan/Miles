//
//  Period.h
//  emma
//
//  Created by ltebean on 15/8/20.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "BaseModel.h"
#import "User.h"


#define FLAG_ADDED_BIT 2
#define FLAG_MODIFIED_BIT 3
#define FLAG_LATE_BIT 4
#define FLAG_TODAY_BIT 5
#define FLAG_ADDED_BY_DELETION_BIT 6
#define FLAG_SOURCE_DEFAULT 0
#define FLAG_SOURCE_PREDICTION 1
#define FLAG_SOURCE_USER_INPUT 2
#define FLAG_SOURCE_OLD_DAILYLOG 3

@interface Period : BaseModel
@property (nonatomic, strong) NSString *pb;
@property (nonatomic, strong) NSString *pe;
@property (nonatomic) int16_t flag;
@property (nonatomic, strong) User *user;
+ (void)resetWithAlive:(NSArray *)alive archived:(NSArray *)archived forUser:(User *)user;
+ (Period *)periodWithBeginDate:(NSString *)beginDate endDate:(NSString *)endDate forUser:(User *)user;
+ (void)persistAllPeriodsBeforeTodayWithLatestPeriod:(NSDictionary *)latestPeriod forUser:(User *)user;

- (void)remove;
- (void)setAddedByUser;
- (void)setModifiedByUser;
- (void)setAddedByDeletion;
- (void)setAddedByPrediction;
@end
