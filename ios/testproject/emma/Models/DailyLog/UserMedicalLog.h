//
//  UserMedicalLog.h
//  emma
//
//  Created by Peng Gu on 10/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"


#define kMedItemTreatmentHeader @"treatmentHeader"
#define kMedItemBloodWork @"bloodWork"
#define kMedItemEstrogenLevel @"estrogenLevel"
#define kMedItemProgesteroneLevel @"progesteroneLevel"
#define kMedItemLuteinizingHormoneLevel @"luteinizingHormoneLevel"

#define kMedItemUltrasound @"ultrasound"
#define kMedItemFolliclesNumber @"folliclesNumber"
#define kMedItemFolliclesSize @"folliclesSize"
#define kMedItemUterineLiningThickness @"uterineLiningThickness"
#define kMedItemEndometrialPattern @"endometrialPattern"

#define kMedItemHCGTriggerShot @"hCGTriggerShot"
#define kMedItemHCGTriggerShotTime @"hCGTriggerShotTime"

#define kMedItemInsemination @"insemination"

#define kMedItemEggRetrieval @"eggRetrieval"
#define kMedItemEggRetrievalNumber @"eggRetrievalNumber"
#define kMedItemFreezeEmbryosFuture @"embryosFrozen"

#define kMedItemEmbryosFrozenNumber @"embryosFrozenNumber"

#define kMedItemEmbryosTransfer @"embryosTransfer"
#define kMedItemEmbryosTransferNumber @"embryosTransferNumber"
#define kMedItemFreshOrFrozenEmbryos @"freshOrFrozenEmbryos"

#define kMedItemMedicationHeader @"medicationHeader"
#define kMedItemMedication @"medication"
#define kMedItemAddMedication @"addNewMedication"

#define kMedicationItemKeyPrefix @"Medication:"


typedef NS_ENUM(NSUInteger, BinaryValueType) {
    BinaryValueTypeNone,
    BinaryValueTypeYes,
    BinaryValueTypeNo
};


typedef NS_ENUM(NSUInteger, EndometrialPatternType) {
    EndometrialPatternTypeNone,
    EndometrialPatternTypeIsoechoic,
    EndometrialPatternTypeTrilaminar
};


@class User;


@interface UserMedicalLog : BaseModel

@property (nonatomic, retain) NSString * dataKey;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSString * dataValue;
@property (nonatomic, retain) User *user;


+ (instancetype)upsertWithServerData:(NSDictionary *)data forUser:(User *)user;
+ (NSSet *)medicalLogsOnDate:(NSString *)date forUser:(User *)user;
+ (NSSet *)medicalLogsForKey:(NSString *)key user:(User *)user;
+ (UserMedicalLog *)medicalLogWithKey:(NSString *)key date:(NSString *)date user:(User *)user;

+ (NSArray *)dateLabelsForMedicationLogsInMonth:(NSDate *)date;
+ (BOOL)user:(User *)user hasMedicationLogsOnDate:(NSString *)date;
+ (BOOL)user:(User *)user hasMedicalLogsOnDate:(NSString *)date;

+ (NSArray *)hcgTriggerShotDateIndexes;
+ (NSArray *)hcgTriggerShotDateIndexesAdvance;
+ (BOOL)isDateIndexWithinHcgTriggerShotDates:(NSInteger)dateIndex;

@end





