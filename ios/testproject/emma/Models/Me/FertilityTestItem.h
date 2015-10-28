//
//  FertilityTestViewModel.h
//  emma
//
//  Created by Peng Gu on 7/9/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FertilityTest.h"


@interface FertilityTestItem : NSObject

@property (nonatomic, copy, readonly) NSString *testKey;

// question and answer are for View to display
@property (nonatomic, copy) NSString *question;
@property (nonatomic, copy) NSString *answer;
@property (nonatomic, assign) NSUInteger answerIndex;
@property (nonatomic, assign, readonly) BOOL hasValue;

@property (nonatomic, assign) BOOL isClinicItem;
@property (nonatomic, assign) BOOL isDoctorItem;
@property (nonatomic, assign) BOOL isNurseItem;
@property (nonatomic, copy, readonly) NSString *placeholderAnswerText;

+ (NSArray *)infoItems;
+ (NSArray *)testItems;
+ (NSArray *)partnerItems;

+ (NSArray *)fertilityClinicOptions;
+ (NSString *)shortDescriptionForFertilityClinic:(FertilityClinic)clinic;
+ (NSString *)descriptionForFertilityClinic:(FertilityClinic)clinic;

+ (NSArray *)testAnswerOptions;
+ (NSString *)descriptionForTestAnswer:(FertilityTestAnswer)answer;

- (void)savePickerResult:(NSUInteger)pickerIndex;
- (void)saveInputResult:(NSString *)inputString;

@end
