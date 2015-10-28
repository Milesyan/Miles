//
//  DailyLogDataProvider.h
//  emma
//
//  Created by Xin Zhao on 13-11-22.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "UserDailyData.h"

#define DAILYLOG_DP_ABSTRACT_IS_FEMALE @"dailylog_dp_abstract_is_female"
#define DAILYLOG_DP_ABSTRACT_MEDS @"dailylog_dp_abstract_meds"
#define DAILYLOG_DP_ABSTRACT_UID @"dailylog_dp_abstract_uid"

typedef enum {
    DailyLogCellStatusNormal,
    DailyLogCellStatusEditing
} DailyLogCellStatus;

@protocol DailyLogDataProviderProtocol <NSObject>

- (NSIndexPath *)indexPathForDailyLogCellKey:(DailyLogCellKey)cellKey;
- (DailyLogCellKey)dailyLogCellKeyForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)_dailyLogCellKeyOrderConfig;
- (NSArray *)dailyLogCellKeyOrder;
- (NSArray *)dailyLogCellKeyOrderWithMeds;
- (NSInteger)indexOfMedicineForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)nameOfMedicineForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)canHideRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isCellHiddenWith:(DailyLogCellKey)key;
- (BOOL)isCellHiddenAtIndexPath:(NSIndexPath *)indexPath;
- (void)hideCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)unhideCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)fetchHiddenLogKeysFromDefaults;

@end

@protocol DailyLogDataReceiver

@end

@interface DailyLogDataProvider : NSObject <DailyLogDataProviderProtocol>

@property (nonatomic, strong) id<DailyLogDataReceiver> receiver;
@property (nonatomic, strong) NSDictionary *abstract;
@property (nonatomic, strong) NSMutableSet *hiddenLogKeys;
@property (nonatomic, strong) NSMutableSet *newlyHiddenLogKeys;
@property (nonatomic, strong) NSMutableSet *newlyShownLogKeys;
@property (nonatomic, assign) BOOL isEditing;

+ (NSDictionary *)generateAbatractForUser:(User *)user dailyData:(UserDailyData *)dailyData;
- (void)setIsEditing:(BOOL)isEditing;
- (NSString *)rowEditingSummary;
- (void)refreshMedsAbstractForUser:(User *)user dailyData:(UserDailyData *)dailyData;

- (NSArray *)physicalSectionKeys;
- (NSArray *)emotionalSectionKeys;
- (NSArray *)fertilitySectionKeys;

@end