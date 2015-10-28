//
//  MedicalLogItem.h
//  emma
//
//  Created by Peng Gu on 10/17/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserMedicalLog.h"

@class MedicalLogItem;


@interface MedicalLogItem : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *date;
@property (nonatomic, readonly) NSDate *nsdate;
@property (nonatomic, assign) BOOL isMedicationItem;
@property (nonatomic, assign) BOOL isUserCreatedMedication;
@property (nonatomic, assign) NSInteger treatmentType;

@property (nonatomic, strong) NSString *logValue;
@property (nonatomic, readonly, assign) BOOL logValueChanged;

@property (nonatomic, strong) UserMedicalLog *medicalLog;


+ (instancetype)itemWithKey:(NSString *)key date:(NSString *)date;
+ (instancetype)itemWithKey:(NSString *)key date:(NSString *)date treatmentType:(NSInteger)treatmentType;

- (instancetype)initWithKey:(NSString *)key date:(NSString *)date;

- (void)saveToModel;
- (void)updateModelValue:(NSString *)value;


@end






