//
//  VariosPurposesDataProviderManager.m
//  emma
//
//  Created by Xin Zhao on 13-11-20.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "DailyLogDataProviderAvoidPregnancy.h"
#import "DailyLogDataProviderNormalTrack.h"
#import "DailyLogDataProviderTTC.h"
#import "DailyLogDataProviderTTCFT.h"
#import "DailyLogDataProviderMalePartner.h"
#import "DailyLogDataProviderFemalePartner.h"
#import "OnboardingDataProviderMakeUpNormalTrack.h"
#import "OnboardingDataProviderMakeUpTTC.h"
#import "OnboardingDataProviderMapMc.h"
#import "OnboardingDataProviderNormalTrack.h"
#import "OnboardingDataProviderTTC.h"
#import "VariousPurposesDataProviderFactory.h"
#import "OnboardingDataProviderTreatment.h"
#import "UserStatusDataManager.h"

@implementation VariousPurposesDataProviderFactory

+ (Class)onboardingDataProviderAtStep:(NSInteger)step {
    NSDictionary *allProviders = @{
        @(AppPurposesTTC): @[
            [OnboardingDataProviderTTC class],
            [OnboardingDataProviderMapMc class]
            ],
        @(AppPurposesNormalTrack): @[
            [OnboardingDataProviderNormalTrack class],
            [OnboardingDataProviderMapMc class]
            ],
        @(AppPurposesAvoidPregnant): @[
            [OnboardingDataProviderNormalTrack class],
            [OnboardingDataProviderMapMc class]
            ],
        @(AppPurposesTTCWithTreatment): @[
            [OnboardingDataProviderTreatment class],
            [OnboardingDataProviderMapMc class]
            ]
        };
    NSInteger appPurpose = AppPurposesTTC;
    NSDictionary *setting = [Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS];
    NSNumber *val = setting[SETTINGS_KEY_CURRENT_STATUS];
    if (val) {
        appPurpose = [val integerValue];
    }

    if(appPurpose != AppPurposesTTC && appPurpose != AppPurposesNormalTrack && appPurpose != AppPurposesAvoidPregnant && appPurpose != AppPurposesTTCWithTreatment) {
        appPurpose = AppPurposesTTC;
    }
    NSArray *providers = allProviders[@(appPurpose)];
    NSInteger index = step - 1;
    if (index < 0 || index > providers.count) {
        return [OnboardingDataProviderMapMc class];
    } else {
        return providers[index];
    }
}

+ (OnboardingDataProvider *)
        generateOnboardingDataProviderAtStep:(NSInteger)stepInOnboarding
        withReceiver:(id<OnboardingDataReceiver>)receiver
        storedAnser:(NSDictionary *)storedAnswer
        presenter:(UIViewController *)presenter{
    Class providerClass = [VariousPurposesDataProviderFactory onboardingDataProviderAtStep:stepInOnboarding];
    OnboardingDataProvider *result = [[providerClass alloc] init];
    result.receiver = receiver;
    result.storedAnswer = [storedAnswer mutableCopy];
    result.presenter = presenter;
    return result;
}

+ (OnboardingDataProvider *)
        generateMakeUpDataProviderWithReceiver:(id<OnboardingDataReceiver>)receiver
        storedAnser:(NSDictionary *)storedAnswer
        presenter:(UIViewController *)presenter
        targetPurpose:(AppPurposes)purpose {
    
    OnboardingDataProvider *result = nil;
    if (AppPurposesTTC == purpose) {
        result = [[OnboardingDataProviderMakeUpTTC alloc] init];
    }
    else if (purpose == AppPurposesAvoidPregnant) {
        result = [[OnboardingDataProviderMakeUpNormalTrack alloc] init];
    } else if (purpose == AppPurposesTTCWithTreatment) {
        result = [[OnboardingDataProviderTreatment alloc] init];
        OnboardingDataProviderTreatment * fertilityR = (OnboardingDataProviderTreatment *)result;
        fertilityR.isChangeStatus = YES;
    }
    result.receiver = receiver;
    result.storedAnswer = [storedAnswer mutableCopy];
    result.presenter = presenter;
    return result;
    
}

+ (Class)dailyLogDataProviderForDate:(NSDate *)date {
    User *currentUser = [User currentUser];
    if (currentUser && [currentUser isMale]) {
        return [DailyLogDataProviderMalePartner class];
    }
    
    User *user = [User userOwnsPeriodInfo];
    if (user) {
        UserStatus *statusHistory = [[UserStatusDataManager sharedInstance] statusOnDate:[date toDateLabel] forUser:user];
        if (statusHistory.status == STATUS_NON_TTC) {
            return [DailyLogDataProviderAvoidPregnancy class];
        }
        else if (statusHistory.status == STATUS_TTC) {
            return [DailyLogDataProviderTTC class];
        }
        else if (statusHistory.status == STATUS_TREATMENT) {
            return [DailyLogDataProviderTTCFT class];
        }
        else {
            return [DailyLogDataProviderTTC class];
        }
    }
    return [DailyLogDataProviderTTC class];
}

+ (DailyLogDataProvider *)generateDailyLogDataProviderWithReceiver:(id<DailyLogDataReceiver>)receiver date:(NSDate *)date abstract:(NSDictionary *)abstract{
    Class providerClass = [VariousPurposesDataProviderFactory dailyLogDataProviderForDate:date];
    DailyLogDataProvider *result = [[providerClass alloc] init];
    result.receiver = receiver;
    result.abstract = abstract;
    [result fetchHiddenLogKeysFromDefaults];
    return result;
}
@end
