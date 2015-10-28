//
//  MedManager.h
//  emma
//
//  Created by Eric Xu on 12/30/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

typedef NS_ENUM(NSInteger, MedicineSourceType) {
    MedicineSourceTypeDailyLog = 0,
    MedicineSourceTypeMedicalLog = 1,
    MedicineSourceTypeMedList = 2,
};

@interface Medicine : NSObject
@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *form;
@property (nonatomic) NSInteger total;
@property (nonatomic) NSInteger perDosage;
@property (nonatomic, strong) NSString *reminderUUID;
@property (nonatomic, assign) MedicineSourceType sourceType;

- (NSDictionary *)toData;
+ (Medicine *)fromData:(NSDictionary *)data;
@end


@class MedManager;

@protocol MedManagerDelegate <NSObject>
@optional
- (void)medManangerDidUpdateMedLog:(NSString *)medName withValue:(NSInteger)value;
@end


@interface MedManager : NSObject

@property (nonatomic, copy) NSString *date;
@property (nonatomic, weak) id<MedManagerDelegate> delegate;

@property (nonatomic, strong, readonly) NSArray *userAddedMeds;
@property (nonatomic, strong, readonly) NSArray *defaultFertilityMeds;

@property (nonatomic, strong, readonly) NSMutableDictionary *updatedMedLogs;
@property (nonatomic, strong, readonly) NSDictionary *medLogs;
@property (nonatomic, assign, readonly) BOOL hasUpdatesForMedLogs;
@property (nonatomic, assign, readonly) NSUInteger numberOfLogs;

+ (NSDictionary *)medLogsOnDate:(NSString *)date;

- (instancetype)initWithDate:(NSString *)date;
- (void)updateMedLog:(NSString *)medName withValue:(NSInteger)value;
- (void)saveUpdatedMedLogs;

- (void)medDeleted:(NSString *)medName;
- (void)medAdded:(NSString *)medName;
- (void)med:(NSString *)oldName updatedWithNewName:(NSString *)newName;


+ (NSArray *)medForms;
+ (NSArray *)medList;
+ (NSString *)getForm:(NSString *)medName;
+ (NSString *)unitOfPerTakeForForm:(NSString *)form withPlural:(BOOL)plural;
+ (NSString *)unitOfTotalInPackageForForm:(NSString *)form withPlural:(BOOL)plural;
+ (void)writeDrugs:(NSString *)raw;

+ (NSDictionary *)medsForUser:(User *)user;
+ (void)user:(User *)user upsertMed:(Medicine *)med;
+ (void)user:(User *)user removeMed:(NSString *)medId;
+ (Medicine *)userMedWithName:(NSString *)medName;

@end
