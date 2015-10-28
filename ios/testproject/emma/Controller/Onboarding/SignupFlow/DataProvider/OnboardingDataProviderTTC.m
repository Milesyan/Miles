//
//  OnboardingDataProviderTTC.m
//  emma
//
//  Created by Eric Xu on 12/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "OnboardingDataProviderTTC.h"
#import "User.h"
#import "UserDailyData.h"
#import "Settings.h"
#import "HeightPicker.h"
#import "WeightPicker.h"
#import "BooleanPicker.h"
#import "ChildrenNumberPicker.h"
#import "DaysPicker.h"
#import "TTCStartTimePicker.h"

#define CHOICE_TAG_ATTEMPT_LENGTH 0
#define CHOICE_TAG_CHILDREN_NUMBER 1
#define CHOICE_TAG_CYCLE_LENGHT 2
#define CHOICE_TAG_PERIOD_LENGTH 3

#define AC_TAG_BMI_UNIT 10

@interface OnboardingDataProviderTTC () <OnboardingDataProviderProtocol, TTCStartTimerPickerDelegate, ChildrenNumberPickerDelegate, UIActionSheetDelegate>

@end

@implementation OnboardingDataProviderTTC

#pragma mark - OnboardingDataProvider protocal
- (NSArray *)_answerKeys {
    return @[SETTINGS_KEY_TTC_START,
            SETTINGS_KEY_CHILDREN_NUMBER,
            SETTINGS_KEY_WEIGHT];
}

- (NSString *)_answerKeysAtRow:(NSInteger)row {
    NSArray *answerKeys = [self _answerKeys];
    return row < [answerKeys count] ? answerKeys[row] : nil;
}

- (NSString *)_additionalAnswerKeysAtRow:(NSInteger)row {
    NSString * key = [[self _answerKeys] objectAtIndex:row];
    if ([key isEqualToString:SETTINGS_KEY_WEIGHT]) {
        return SETTINGS_KEY_HEIGHT;
    }
    return nil;
}

- (id)answerForIndexPath:(NSIndexPath *)indexPath {
    return self.storedAnswer[[self _answerKeysAtRow:indexPath.row]];
}

- (id)additionalAnswerForIndexPath:(NSIndexPath *)indexPath {
    return self.storedAnswer[[self _additionalAnswerKeysAtRow:indexPath.row]];
}

- (BOOL)hasAdditionalButtonForIndexPath:(NSIndexPath *)indexPath {
    return [self _additionalAnswerKeysAtRow:indexPath.row] != nil;
}

- (NSString *)onboardingQuestionTitleForIndexPath:(NSIndexPath *)indexPath {
    NSString * key = [[self _answerKeys] objectAtIndex:indexPath.row];
    if ([key isEqualToString:SETTINGS_KEY_TTC_START]) {
        return @"How long have you been trying to conceive?";
    } else if ([key isEqualToString:SETTINGS_KEY_CHILDREN_NUMBER]) {
        return @"How many children do you have?";
    } else if ([key isEqualToString:SETTINGS_KEY_WEIGHT]) {
        return @"What is your BMI? Tell us your weight & height to find out!";
    }
    return @"";
}

- (NSString *)onboardingQuestionButtonTextForIndexPath:(NSIndexPath *)indexPath {
    NSString * key = [[self _answerKeys] objectAtIndex:indexPath.row];
    id answer = [self answerForIndexPath:indexPath];
    if ([key isEqualToString:SETTINGS_KEY_TTC_START]) {
        if (!answer) {
            return @"Choose";
        }
        return [Utils ttcStartStringFromDate:answer];
    } else if ([key isEqualToString:SETTINGS_KEY_CHILDREN_NUMBER]) {
        NSInteger number = [answer integerValue];
        if (!number) {
            return @"Choose";
        }
        else {
            return [NSString stringWithFormat:@"%ld", number - 1];
        }
    } else if ([key isEqualToString:SETTINGS_KEY_WEIGHT]) {
        return [self _weightButtonTextWithAnswer:answer];
        
    }
    return @"";
}

- (NSString *)onboardingQuestionAdditionalButtonTextForIndexPath:
        (NSIndexPath *)indexPath {
    if ([self _additionalAnswerKeysAtRow:indexPath.row] != nil) {
        return [self _heightButtonTextWithAnswer:
                [self additionalAnswerForIndexPath:indexPath]];
    }
    return nil;
}


- (NSString *)_weightButtonTextWithAnswer:(id)answer {
    if (answer && [answer intValue] > 0) {
        return [Utils displayTextForWeightInKG:[answer floatValue]];
    }
    return @"Weight";
}

- (NSString *)_heightButtonTextWithAnswer:(id)answer {
    if (answer && [answer intValue] > 0) {
        return [Utils displayTextForHeightInCM:[answer floatValue]];
    }
    return @"Height";
}

- (NSInteger)numberOfQuestions {
    return [[self _answerKeys] count];
}

- (void)showChoiceSelectorForIndexPath:(NSIndexPath *)indexPath {
    
    NSString * key = [[self _answerKeys] objectAtIndex:indexPath.row];
    id answer = [self answerForIndexPath:indexPath];

    if ([key isEqualToString:SETTINGS_KEY_TTC_START]) {
        [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_START withType:ONBOARDING_PICKER_TTC_START_TIME answer:answer];
        
        int choosePosition    = CHOOSE_POSITION_HOW_LONG_TTC;
        TTCStartTimePicker *ttcPicker = [[TTCStartTimePicker alloc] initWithChoose:choosePosition length:
                                         (answer ? [Utils ttcStartStringFromDate:answer] : nil)];
        ttcPicker.delegate = self;
        [ttcPicker present];
    }
    else if ([key isEqualToString:SETTINGS_KEY_CHILDREN_NUMBER]) {
        [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_START withType:ONBOARDING_PICKER_CHILDREN_NUMBER answer:answer];
        
        int choosePosition    = CHOOSE_POSITION_CHILDREN;
        ChildrenNumberPicker *childrenNumberPicker =
        [[ChildrenNumberPicker alloc] initWithChoose:choosePosition number:[answer integerValue] - 1];
        childrenNumberPicker.delegate = self;
        [childrenNumberPicker present];
    }
    else if ([key isEqualToString:SETTINGS_KEY_WEIGHT]) {
        [self _showWeightPickerWithAnswer:answer
                              atIndexPath:indexPath];
    }
}



- (void)_showWeightPickerWithAnswer:(id)answer
                        atIndexPath:(NSIndexPath *)indexPath {
    float w = self.storedAnswer[SETTINGS_KEY_WEIGHT]
            ? [self.storedAnswer[SETTINGS_KEY_WEIGHT] floatValue]
            : 0;
    
    int kgPosition    = CHOOSE_POSITION_WEIGHT_KG;
    int lbPosition    = CHOOSE_POSITION_WEIGHT_LB;
    WeightPicker *weightPicker = [[WeightPicker alloc] initWithChoose:kgPosition and:lbPosition];

    [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_START withType:ONBOARDING_PICKER_WEIGHT answer:answer];
    
    @weakify(self);
    [weightPicker presentWithWeightInKG:w
            andCallback:^(float w) {
                @strongify(self);
                
                [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE withType:ONBOARDING_PICKER_WEIGHT answer:@(w)];
                
                if (w == 0) {
                    [self.storedAnswer removeObjectForKey:SETTINGS_KEY_WEIGHT];
                    [Utils setDefaultsForKey:DEFAULTS_PREVIOUS_WEIGHT withValue:nil];
                } else {
                    self.storedAnswer[SETTINGS_KEY_WEIGHT] = @(w);
                    [Utils setDefaultsForKey:DEFAULTS_PREVIOUS_WEIGHT withValue:@(w)];
                }
                [self.receiver onDataUpdatedIndexPath:
                        [self indexPathFromChoiceSelectorTag:
                        indexPath.row]];
            }];
}

- (void)_showHeightPickerWithAnswer:(id)answer
                        atIndexPath:(NSIndexPath *)indexPath {
    float h = self.storedAnswer[SETTINGS_KEY_HEIGHT]
            ? [self.storedAnswer[SETTINGS_KEY_HEIGHT] floatValue]
            : 0;

    int cmPosition      = CHOOSE_POSITION_HEIGHT_CM;
    int feetPosition    = CHOOSE_POSITION_HEIGHT_FEET;
    int inchPosition    = CHOOSE_POSITION_HEIGHT_INCH;
    
    [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_START withType:ONBOARDING_PICKER_HEIGHT answer:answer];
    
    HeightPicker *heightPicker = [[HeightPicker alloc] initWithChoose:cmPosition feetPosition:feetPosition inchPosition:inchPosition];
    @weakify(self);
    [heightPicker presentWithHeightInCM:h
            andCallback:^(float h) {
                @strongify(self);
                
                [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE withType:ONBOARDING_PICKER_HEIGHT answer:@(h)];
                
                if (h == 0) {
                    [self.storedAnswer removeObjectForKey:SETTINGS_KEY_HEIGHT];
                } else {
                    self.storedAnswer[SETTINGS_KEY_HEIGHT] = @(h);
                }
                [self.receiver onDataUpdatedIndexPath:
                        [self indexPathFromChoiceSelectorTag:
                        indexPath.row]];
            }];
}

- (NSString *)_BMIText {
    if ([self.storedAnswer[SETTINGS_KEY_HEIGHT] intValue] &&
            [self.storedAnswer[SETTINGS_KEY_WEIGHT] intValue]) {
        CGFloat bmi =
                [Utils calculateBmiWithHeightInCm:
                [self.storedAnswer[SETTINGS_KEY_HEIGHT] floatValue]
                weightInKg:[self.storedAnswer[SETTINGS_KEY_WEIGHT]
                floatValue]];
        return [NSString stringWithFormat:@"Your BMI: %.2f", bmi];
    }
    return @"Your BMI: --";
}

- (void)showAdditionalChoiceSelectorForIndexPath:(NSIndexPath *)indexPath {
    NSString * key = [[self _answerKeys] objectAtIndex:indexPath.row];
    if ([key isEqualToString:SETTINGS_KEY_WEIGHT]) {
        [self _showHeightPickerWithAnswer:
                self.storedAnswer[SETTINGS_KEY_HEIGHT] atIndexPath:indexPath];
    }
}

- (BOOL)allAnswered {
    for (NSInteger i = 0; i < [self numberOfQuestions]; i++) {
        NSString *answerKey = [self _answerKeysAtRow:i];
        if (answerKey && self.storedAnswer[answerKey] == nil) {
            return NO;
        }
        NSString *additionalAnswerKey = [self _additionalAnswerKeysAtRow:i];
        if (additionalAnswerKey &&
                self.storedAnswer[additionalAnswerKey] == nil) {
            return NO;
        }
    }
    return YES;
}

- (void)saveOnboardingDataForUser:(User *)currentUser {
}

- (NSString *)navigationTitle {
    return @"Step 1 - Trying to conceive";
}

- (NSString *)segueIdentifierToNextStep {
    return @"step1ToStep2";
}

- (NSString *)assistantInfoForIndexPath:(NSIndexPath *)indexPath {
    NSString * key = [[self _answerKeys] objectAtIndex:indexPath.row];
    if ([key isEqualToString:SETTINGS_KEY_WEIGHT]) {
        return [self _BMIText];
    }
    return nil;
}

- (BOOL)containsKey:(NSString *)key {
    return [[self _answerKeys] containsObject:key];
}

#pragma mark - Picker delegates and shower
- (void)TTCStartTimePicker:(TTCStartTimePicker *)picker didDismissWithLength:(NSString *)length
{
    if ([Utils isEmptyString:length]) {
        [self.storedAnswer removeObjectForKey:SETTINGS_KEY_TTC_START];
        [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                    withType:ONBOARDING_PICKER_TTC_START_TIME
                      answer:nil];
    } else {
        self.storedAnswer[SETTINGS_KEY_TTC_START] = [Utils dateFromTtcStartString:length];
        [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                    withType:ONBOARDING_PICKER_TTC_START_TIME
                      answer:[Utils dateFromTtcStartString:length]];
    }
    [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag: CHOICE_TAG_ATTEMPT_LENGTH]];
}

- (void)childrenNumberPicker:(ChildrenNumberPicker *)picker
        didDismissWithNumber:(NSInteger)num {
    
    [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                withType:ONBOARDING_PICKER_CHILDREN_NUMBER
                  answer:@(num+1)];
    
    if (num < 0) {
        [self.storedAnswer removeObjectForKey:SETTINGS_KEY_CHILDREN_NUMBER];
    } else {
        self.storedAnswer[SETTINGS_KEY_CHILDREN_NUMBER] = @(num+1);
    }
    [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:
            CHOICE_TAG_CHILDREN_NUMBER]];
}

#pragma mark - UIActionSheet delegates
- (void)actionSheet:(UIActionSheet *)actionSheet
        didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:
            actionSheet.tag]];
}

#pragma mark - helper
- (NSIndexPath*)indexPathFromChoiceSelectorTag:(NSInteger)tag {
    return [NSIndexPath indexPathForRow:tag inSection:0];
}

- (NSInteger)choiceSelectorTagFromIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row;
}

@end
