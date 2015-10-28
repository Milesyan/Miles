//
//  Settings.h
//  emma
//
//  Created by Ryan Ye on 2/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"
#import "VariousPurposesConstants.h"

#define SETTINGS_KEY_PERIOD_LENGTH @"periodLength"
#define SETTINGS_KEY_CYCLE_LENGTH @"periodCycle"
#define SETTINGS_KEY_CHILDREN_NUMBER @"childrenNumber"
#define SETTINGS_KEY_PERIOD_REGULAR @"periodRegular"
#define SETTINGS_KEY_BIRTH_CONTROL @"birthControl"
#define SETTINGS_KEY_FIRST_PB @"firstPb"
#define SETTINGS_KEY_EXERCISE @"exercise"
#define SETTINGS_KEY_HEIGHT @"height"
#define SETTINGS_KEY_WEIGHT @"weight"
#define SETTINGS_KEY_BMI @"bmi"
#define SETTINGS_KEY_BIRTH_CONTROL @"birthControl"
#define SETTINGS_KEY_TTC_START @"ttcStart"
#define SETTINGS_KEY_TIME_PLANED_CONCEIVE @"timePlanedConceive"
#define SETTINGS_KEY_CURRENT_STATUS @"currentStatus"
#define SETTINGS_KEY_BACKGROUND_IMAGE @"backgroundImageUrl"
#define SETTINGS_KEY_MEDS @"meds"
#define SETTINGS_KEY_BIO @"bio"
#define SETTINGS_KEY_LOCATION @"location"
#define SETTINGS_KEY_HIDE_POSTS @"hidePosts"
#define SETTINGS_KEY_MFP_ACTIVITY_LEVEL @"mfpActivityLevel"
#define SETTINGS_KEY_MFP_ACTIVITY_FACTOR @"mfpActivityFactor"
#define SETTINGS_KEY_MFP_DAILY_CALORIE_GOAL @"mfpDailyCalorieGoal"
#define SETTINGS_KEY_MFP_DIARY_PRIVACY_SETTING @"mfpDiaryPrivacySetting"
#define SETTINGS_KEY_TREATMENT_TYPE @"fertilityTreatment"
#define SETTINGS_KEY_TREATMENT_STARTDATE @"treatmentStartdate"
#define SETTINGS_KEY_TREATMENT_ENDDATE @"treatmentEnddate"
#define SETTINGS_KEY_SAME_SEX_COUPLE @"sameSexCouple"
#define SETTINGS_KEY_FERTILITY_CLINIC @"fertilityClinic"
#define SETTINGS_KEY_FERTILITY_TEST @"fertilityTest"

#define TIME_PLANED_CONCEIVE_UNDECIDED 0
#define TIME_PLANED_CONCEIVE_NEVER -1
#define timePlanedConceiveUnit(timePlanedConceive) (timePlanedConceive >> 8)

#define OFFSET_EXERCISE_TARGET_DAILY_LOG 2

@class User;

@interface Settings : BaseModel

@property (nonatomic) BOOL pushToCalendar;
@property (nonatomic) int64_t notificationFlags;
@property (nonatomic) int16_t periodCycle;
@property (nonatomic) int16_t periodLength;
@property (nonatomic) int16_t timeZone;
@property (nonatomic) int16_t childrenNumber;
@property (nonatomic) float height;
@property (nonatomic) float weight;
@property (nonatomic) int16_t exercise;
@property (nonatomic, retain) NSString *firstPb;
@property (nonatomic, retain) User *user;
@property (nonatomic) int16_t currentStatus;
@property (nonatomic) int16_t allowFollowUp;
@property (nonatomic) int16_t receivePushNotification;
@property (nonatomic) int16_t timePlanedConceive;
@property (nonatomic) BOOL hasSeenShareDialog;
@property (nonatomic, retain) UIImage *backgroundImage;
@property (nonatomic, retain) NSDate *ttcStart;
@property (nonatomic, retain) NSString * backgroundImageUrl;
@property (nonatomic, retain) NSDictionary *meds;
@property (nonatomic, retain) NSString * bio;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * mfpActivityLevel;
@property (nonatomic) float mfpActivityFactor;
@property (nonatomic) int16_t mfpDailyCalorieGoal;
@property (nonatomic, retain) NSString * mfpDiaryPrivacySetting;
@property (nonatomic, retain) NSString * lastPregnantDate;

@property (nonatomic, retain) NSString * taxId;
@property (nonatomic, retain) NSString * shippingStreet;
@property (nonatomic, retain) NSString * shippingCity;
@property (nonatomic, retain) NSString * shippingState;
@property (nonatomic, retain) NSString * shippingZip;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic) int64_t birthControl;

@property (nonatomic, strong) NSDate *birthControlStart;
@property (nonatomic, assign) int16_t cycleRegularity;
@property (nonatomic, assign) int64_t diagnosedConditions;
@property (nonatomic, assign) int16_t liveBirthNumber;
@property (nonatomic, assign) int16_t miscarriageNumber;
@property (nonatomic, assign) int16_t tubalPregnancyNumber;
@property (nonatomic, assign) int16_t abortionNumber;
@property (nonatomic, assign) int16_t stillbirthNumber;
@property (nonatomic, assign) int16_t relationshipStatus;
@property (nonatomic, assign) int16_t partnerErection;
@property (nonatomic, copy) NSString *occupation;
@property (nonatomic, assign) int16_t insurance;
@property (nonatomic, assign) int64_t fertilityTreatment;
@property (nonatomic, assign) NSString * treatmentStartdate;
@property (nonatomic, assign) NSString * treatmentEnddate;
@property (nonatomic, assign) BOOL sameSexCouple;
@property (nonatomic, assign) int64_t infertilityDiagnosis;
@property (nonatomic, assign) int16_t spermOrEggDonation;
@property (nonatomic, assign) int16_t previousStatus;
@property (nonatomic, assign) int16_t ethnicity;
@property (nonatomic, assign) float waist;
@property (nonatomic, assign) int16_t testerone;
@property (nonatomic, assign) int16_t underwearType;
@property (nonatomic, assign) int16_t householdIncome;
@property (nonatomic, assign) NSString* homeZipcode;
@property (nonatomic, assign) int16_t hidePosts;
@property (nonatomic) int16_t predictionSwitch;


+ (NSDictionary *)attrMapper;
+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user;
+ (NSDictionary*)createPushRequestForNewUserWith:(NSDictionary*)onboardingData;
- (void)updateBackgroundImage:(UIImage *)originImage;
- (void)restoreBackgroundImage;
- (UIImage *)defaultBackgroundImage;
@end
