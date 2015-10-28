//
//  OnboardingDataProvider.m
//  emma
//
//  Created by Xin Zhao on 13-11-20.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "OnboardingDataProvider.h"
#import "HealthProfileData.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
// No need to implement any protocol function here. This is a virtual class which is forbidden to use.
@implementation OnboardingDataProvider
#pragma clang diagnostic pop

- (NSString *)navigationTitle {
    return nil;
}

- (NSString *)segueIdentifierToNextStep {
    return nil;
}

- (NSString *)onboardingQuestionAdditionalButtonTextForIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (id)additionalAnswerForIndexPath:(NSIndexPath *)indexPath {
    return nil;
}


- (BOOL)hasAdditionalButtonForIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSString *)assistantInfoForIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSIndexPath*)indexPathFromChoiceSelectorTag:(NSInteger)tag {
    return [NSIndexPath indexPathForRow:tag inSection:0];
}

- (BOOL)containsKey:(NSString *)key {
    return NO;
}

- (void)logPickerEvent:(NSString *)event withType:(NSString *)pickerType answer:(id)answer
{
    NSString *value = @"choose";
    if (answer) {
        NSInteger intValue = 0;
        if ([answer isKindOfClass:[NSNumber class]]) {
            intValue = [answer intValue];
        }
        
        if ([pickerType isEqualToString:ONBOARDING_PICKER_WEIGHT] && intValue > 0) {
            value = [Utils displayTextForWeightInKG:[answer floatValue]];
        }
        else if ([pickerType isEqualToString:ONBOARDING_PICKER_HEIGHT] && intValue > 0) {
            value = [Utils displayTextForHeightInCM:[answer floatValue]];
        }
        else if ([pickerType isEqualToString:ONBOARDING_PICKER_CHILDREN_NUMBER] && intValue > 0) {
            value = [NSString stringWithFormat:@"%ld", [answer integerValue] - 1];
        }
        else if ([pickerType isEqualToString:ONBOARDING_PICKER_TTC_START_TIME]) {
            value = [Utils ttcStartStringFromDate:answer];
        }
        else if ([pickerType isEqualToString:ONBOARDING_PICKER_BIRTH_CONTROL_METHOD]) {
            value = [[HealthProfileData birthControlShortNames] objectForKey:answer];
        }
        else if ([pickerType isEqualToString:ONBOARDING_PICKER_CYCLE_LENGTH] && intValue > 0) {
            value = [NSString stringWithFormat:@"%d days", [answer intValue]];
        }
        else if ([pickerType isEqualToString:ONBOARDING_PICKER_FERTILITY_TREATMENT_TYPE]) {
            if (intValue == 1) {
                value = @"Natural";
            }
            else if (intValue == 2) {
                value = @"IUI";
            }
            else if (intValue == 3) {
                value = @"IVF";
            }
            else {
                value = @"choose";
            }
        }
        else if ([pickerType isEqualToString:ONBOARDING_PICKER_FERTILITY_TREATMENT_START_DATE]) {
            value = answer;
        }
        else if ([pickerType isEqualToString:ONBOARDING_PICKER_FERTILITY_TREATMENT_END_DATE]) {
            value = answer;
        }
    }
    
    NSDictionary *data = @{@"picker_type": pickerType,
                           @"value": value,
                           @"chosen_journey": @(self.currentPurpose)};
    [Logging syncLog:event eventData:data];
}
@end





