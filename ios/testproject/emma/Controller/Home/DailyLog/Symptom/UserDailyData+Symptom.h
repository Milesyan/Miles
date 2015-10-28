//
//  UserDailyData+Symptom.h
//  emma
//
//  Created by Peng Gu on 7/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UserDailyData.h"
#import "DailyLogConstants.h"

#define SYMPTOM_KEYS @[@"physicalSymptom1", @"physicalSymptom2", @"emotionalSymptom1", @"emotionalSymptom2"]

@interface UserDailyData (Symptom)


#pragma mark - New symptom value to old value
+ (int64_t)getPhysicalDiscomfortFromPhysicalSymptomOne:(uint64_t)symptom1 symptomTwo:(uint64_t)symptom2;
+ (int64_t)getMoodsFromEmotionalSymptomOne:(uint64_t)symptom1 symptomTwo:(uint64_t)symptom2;


#pragma mark - Convert Old Value to New Symptom Value
+ (void)convertPhysicalDiscomfortToSymptom:(uint64_t)discomfort
                                completion:(void (^)(uint64_t physicalSymptom1, uint64_t physicalSymptom2))completion;

+ (void)convertMoodsToSymptom:(uint64_t)moods
                   completion:(void (^)(uint64_t emotionalSymptom1, uint64_t emotionalSymptom2))completion;


#pragma mark - Symptoms/Value
+ (void)convertSymptomsToValues:(NSDictionary *)symptoms
                           type:(SymptomType)type
                     completion:(void (^)(uint64_t sympValue1, uint64_t sympValue2))completion;

+ (NSDictionary *)getSymptomsFromFieldOneValue:(uint64_t)value1
                                 fieldTwoValue:(uint64_t)value2
                                          type:(SymptomType)type;

+ (uint64_t)removeSymptom:(uint64_t)symptom fromValue:(uint64_t)value;
+ (BOOL)symptom:(uint64_t)symptom inValue:(uint64_t)value;


#pragma mark - Helpers
- (NSDictionary *)getPhysicalSymptoms;
- (NSDictionary *)getEmotionalSymptoms;


@end
