//
//  FertilityTest.h
//  emma
//
//  Created by Peng Gu on 7/14/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"

#define kFertilityTestClinic                  @"fertilityClinic"
#define kFertilityTestDoctorName              @"doctorName"
#define kFertilityTestNurseName               @"nurseName"

#define kFertilityTestCycleDayThreeBloodWork  @"cycleDayThreeBloodWork"
#define kFertilityTestVaginalUltrasound       @"vaginalUltrasound"
#define kFertilityTestOtherBloodTests         @"otherBloodTests"
#define kFertilityTestHysterosalpingogram     @"hysterosalpingogram"
#define kFertilityTestSalineSonogram          @"salineSonogram"
#define kFertilityTestHysteroscopy            @"hysteroscopy"
#define kFertilityTestGeneticTesting          @"geneticTesting"
#define kFertilityTestPrenatalScreening       @"prenatalScreening"
#define kFertilityTestMammogram               @"mammogram"
#define kFertilityTestPapsmear                @"papsmear"

#define kFertilityTestSemenAnalysis           @"semenAnalysis"
#define kFertilityTestSTIScreening            @"stiScreening"


typedef NS_ENUM(NSUInteger, FertilityClinic) {
    FertilityClinicNone = 0,
    FertilityClinicNoOne,
    FertilityClinicPrimaryCare,
    FertilityClinicOBAndGYN,
    FertilityClinicBostonIVF,
    FertilityClinicShadyGrove,
    FertilityClinicRMANY,
    FertilityClinicOther = 100
};


typedef NS_ENUM(NSUInteger, FertilityTestAnswer) {
    FertilityTestAnswerNone,
    FertilityTestAnswerNormal,
    FertilityTestAnswerAbnormal,
    FertilityTestAnswerNotYet,
    FertilityTestAnswerNotNeeded,
};

@class User;

@interface FertilityTest : BaseModel

@property (nonatomic) int16_t fertilityClinic;
@property (nonatomic, retain) NSString * doctorName;
@property (nonatomic, retain) NSString * nurseName;
@property (nonatomic) int16_t cycleDayThreeBloodWork;
@property (nonatomic) int16_t vaginalUltrasound;
@property (nonatomic) int16_t otherBloodTests;
@property (nonatomic) int16_t hysterosalpingogram;
@property (nonatomic) int16_t salineSonogram;
@property (nonatomic) int16_t hysteroscopy;
@property (nonatomic) int16_t geneticTesting;
@property (nonatomic) int16_t prenatalScreening;
@property (nonatomic) int16_t mammogram;
@property (nonatomic) int16_t papsmear;
@property (nonatomic) int16_t semenAnalysis;
@property (nonatomic) int16_t stiScreening;
@property (nonatomic, retain) User *user;

+ (NSArray *)allTestKeys;

+ (NSDictionary *)extractFertilityTestingDataFromOnboardingData:(NSDictionary *)onboardingData;

+ (instancetype)upsertWithServerData:(NSDictionary *)data;

@end
