//
//  WelcomeViewDataProvider.h
//  emma
//
//  Created by Xin Zhao on 13-11-20.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

#define DATA_KEY_ATTEMPS @"attemps"
#define DATA_KEY_LAST_BEGIN @"lastBegin"

#define BMIUnitImperial @"IN/LB"
#define BMIUnitMetric @"CM/KG"

/*
 #define CHOOSE_POSITION_BIRTH_CONTROL   0
 #define CHOOSE_POSITION_CYCLE_LENGTH   6
 #define CHOOSE_POSITION_CHILDREN   0
 #define CHOOSE_POSITION_HOW_LONG_TTC  6
 #define CHOOSE_POSITION_WEIGHT_KG   46
 #define CHOOSE_POSITION_WEIGHT_LB   100
 #define CHOOSE_POSITION_HEIGHT_CM   49
 #define CHOOSE_POSITION_HEIGHT_FEET   1
 #define CHOOSE_POSITION_HEIGHT_INCH   7
 */

#define CHOOSE_POSITION_BIRTH_CONTROL  0
#define CHOOSE_POSITION_CYCLE_LENGTH   6
#define CHOOSE_POSITION_CHILDREN       0
#define CHOOSE_POSITION_HOW_LONG_TTC   6
#define CHOOSE_POSITION_WEIGHT_KG   46
#define CHOOSE_POSITION_WEIGHT_LB   100
#define CHOOSE_POSITION_HEIGHT_CM   49
#define CHOOSE_POSITION_HEIGHT_FEET   0
#define CHOOSE_POSITION_HEIGHT_INCH   0


@protocol OnboardingDataProviderProtocol <NSObject>
- (id)answerForIndexPath:(NSIndexPath *)indexPath;
- (id)additionalAnswerForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)hasAdditionalButtonForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)onboardingQuestionTitleForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)onboardingQuestionButtonTextForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)onboardingQuestionAdditionalButtonTextForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)assistantInfoForIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)numberOfQuestions;
- (BOOL)containsKey:(NSString *)key;
- (void)showChoiceSelectorForIndexPath:(NSIndexPath *)indexPath;
- (void)showAdditionalChoiceSelectorForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)allAnswered;
- (void)saveOnboardingDataForUser:(User *)user;
- (NSString *)navigationTitle;
- (NSString *)segueIdentifierToNextStep;
@end

@protocol OnboardingDataReceiver

- (void)onDataUpdatedIndexPath:(NSIndexPath *)indexPath;

@end

@interface OnboardingDataProvider : NSObject <OnboardingDataProviderProtocol> {}
@property (nonatomic, strong) id<OnboardingDataReceiver> receiver;
@property (nonatomic, strong) UIViewController *presenter;
@property (nonatomic, strong) NSMutableDictionary *storedAnswer;

@property (nonatomic, assign) NSUInteger currentPurpose;

- (void)logPickerEvent:(NSString *)event withType:(NSString *)pickerType answer:(id)answer;

- (NSIndexPath*)indexPathFromChoiceSelectorTag:(NSInteger)tag;
@end