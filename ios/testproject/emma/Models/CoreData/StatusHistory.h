//
//  UserStatus.h
//  emma
//
//  Created by ltebean on 15/6/16.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "BaseModel.h"
#import "User.h"
#import "VariousPurposesConstants.h"
#import "HealthProfileData.h"

#define TREATMENT_TYPE_INTERVAL 0
#define TREATMENT_TYPE_MED 1
#define TREATMENT_TYPE_IUI 2
#define TREATMENT_TYPE_IVF 3
#define TREATMENT_TYPE_PREPARING 4

@interface StatusHistory : BaseModel
@property (nonatomic) int16_t treatmentType;
@property (nonatomic) int16_t status;
@property (nonatomic, strong) NSString *startDate;
@property (nonatomic, strong) NSString *endDate;
@property (nonatomic, strong) User *user;

+ (NSArray *)allHistoryForUser:(User *)user;
+ (NSArray *)treatmentHistoryForUser:(User *)user;
+ (StatusHistory *)historyOnDate:(NSString *)date forUser:(User *)user;
+ (NSArray *)modifiedHistoryForUser:(User *)user;
+ (NSArray *)historyBetweenDate:(NSString *)startDate andDate:(NSString *)endDate forUser:(User *)user;
+ (StatusHistory *)historyWithStartDate:(NSString *)startDate endDate:(NSString *)endDate forUser:(User *)user;
+ (void)resetWithServerData:(NSArray *)serverData forUser:(User *)user;
+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user;
- (void)remove;
@end
