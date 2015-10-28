//
//  VariosPurposesDataProviderManager.h
//  emma
//
//  Created by Xin Zhao on 13-11-20.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OnboardingDataProvider.h"
#import "DailyLogDataProvider.h"
#import "VariousPurposesConstants.h"

@interface VariousPurposesDataProviderFactory : NSObject

+ (OnboardingDataProvider *)generateOnboardingDataProviderAtStep:(NSInteger)stepInOnboarding withReceiver:(id<OnboardingDataReceiver>)receiver storedAnser:(NSDictionary *)storedAnswer presenter:(UIViewController *)presenter;
+ (OnboardingDataProvider *)
        generateMakeUpDataProviderWithReceiver:(id<OnboardingDataReceiver>)receiver
        storedAnser:(NSDictionary *)storedAnswer
        presenter:(UIViewController *)presenter
        targetPurpose:(AppPurposes)purpose;
+ (DailyLogDataProvider *)generateDailyLogDataProviderWithReceiver:(id<DailyLogDataReceiver>)receiver date:(NSDate *)date abstract:(NSDictionary *)abstract;

@end
