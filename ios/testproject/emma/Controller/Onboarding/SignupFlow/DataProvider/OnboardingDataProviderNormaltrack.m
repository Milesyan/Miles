//
//  OnboardingDataProviderNormaltrack.m
//  emma
//
//  Created by Xin Zhao on 13-11-20.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "OnboardingDataProviderNormalTrack.h"
#import "User.h"
#import "UserDailyData.h"
#import "Settings.h"
#import "HeightPicker.h"
#import "WeightPicker.h"
#import "HealthProfileData.h"

#define CHOICE_TAG_REGULAR_PERIOD 0
#define CHOICE_TAG_BIRTH_CONTROL 1
#define CHOICE_TAG_CYCLE_LENGHT 2
#define CHOICE_TAG_PERIOD_LENGTH 3

#define AC_TAG_BMI_UNIT 10

#define TIME_PLANED_CONCEIVE_ITEMS @[@"I’m undecided", @"In the next 12 months",\
    @"Later in the future", @"No, never"]
#define TIME_PLANED_CONCEIVE_ITEMS_IN_BUTTON @[@"Undecided", @"12 months",\
    @"Later", @"Never"]

@implementation OnboardingDataProviderNormalTrack

#pragma mark - OnboardingDataProvider protocal
- (NSArray *)_answerKeys {
    return @[
             SETTINGS_KEY_BIRTH_CONTROL,
             SETTINGS_KEY_WEIGHT
             ];
}

- (NSString *)_additionalAnswerKeysAtRow:(NSInteger)row {
    NSString * key = [[self _answerKeys] objectAtIndex:row];
    if ([key isEqualToString:SETTINGS_KEY_WEIGHT]) {
        return SETTINGS_KEY_HEIGHT;
    }
    return nil;
}

- (NSString *)onboardingQuestionTitleForIndexPath:(NSIndexPath *)indexPath {
    NSString * key = [[self _answerKeys] objectAtIndex:indexPath.row];

    if ([key isEqualToString:SETTINGS_KEY_WEIGHT]) {
        return @"What is your BMI? Tell us your weight & height to find out!";
    } else if ([key isEqualToString:SETTINGS_KEY_BIRTH_CONTROL]) {
        return @"What is your method of birth control?";
    }
    return @"";
}

- (NSString *)onboardingQuestionButtonTextForIndexPath:(NSIndexPath *)indexPath {
    NSString * key = [[self _answerKeys] objectAtIndex:indexPath.row];
    id answer = [self answerForIndexPath:indexPath];

    if ([key isEqualToString:SETTINGS_KEY_WEIGHT]) {
        return [self _weightButtonTextWithAnswer:answer];
    } else if ([key isEqualToString:SETTINGS_KEY_BIRTH_CONTROL]) {
        return [self _birthControlButtonTextWithAnswer:answer];
    }
    return @"";
}

- (void)showChoiceSelectorForIndexPath:(NSIndexPath *)indexPath {
    NSString * key = [[self _answerKeys] objectAtIndex:indexPath.row];
    id answer = [self answerForIndexPath:indexPath];
    if ([key isEqualToString:SETTINGS_KEY_WEIGHT]) {
        [self _showWeightPickerWithAnswer:answer
                              atIndexPath:indexPath];
    } else if ([key isEqualToString:SETTINGS_KEY_BIRTH_CONTROL]) {
        [self _showBirthControlPickerWithAnswer:answer
                                    atIndexPath:indexPath];
    }
}

- (void)showAdditionalChoiceSelectorForIndexPath:(NSIndexPath *)indexPath {
    NSString * key = [[self _answerKeys] objectAtIndex:indexPath.row];
    if ([SETTINGS_KEY_WEIGHT isEqual:key]) {
        [self _showHeightPickerWithAnswer:self.storedAnswer[SETTINGS_KEY_HEIGHT]
                              atIndexPath:indexPath];
    }
}

#pragma mark - birth control
- (NSString *)_birthControlButtonTextWithAnswer:(id)answer {
    if (answer) {
        return [[HealthProfileData birthControlShortNames] objectForKey:answer];
    }
    return @"Choose";
}

- (void)_showBirthControlPickerWithAnswer:(id)answer
                              atIndexPath:(NSIndexPath *)indexPath {
    int choosePosition    = CHOOSE_POSITION_BIRTH_CONTROL;
    NSInteger selectedRow;
    if (answer) {
        selectedRow = [[HealthProfileData birthControlKeys] indexOfObject:answer];
        if (selectedRow >= choosePosition) {
            selectedRow += 1;
        }
    } else {
        selectedRow = choosePosition;
    }
    
    NSMutableArray * rows = [[NSMutableArray alloc] init];
    [rows addObjectsFromArray:[NSArray arrayWithArray:[HealthProfileData birthControlItems]]];
    [rows insertObject:@"(Choose)" atIndex:choosePosition];
    
    [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_START
                withType:ONBOARDING_PICKER_BIRTH_CONTROL_METHOD
                  answer:answer];
    
    @weakify(self);
    [GLGeneralPicker presentSimplePickerWithTitle:@"Birth control?" rows:rows
        selectedRow:selectedRow showCancel:NO withAnimation:NO
        doneCompletion:^(NSInteger row, NSInteger comp) {
        @strongify(self);
        [self _birthControlSelectedRow:row atIndexPath:indexPath];
    } cancelCompletion:nil];
}

- (void)_birthControlSelectedRow:(NSInteger)row atIndexPath:(NSIndexPath *)indexPath {
    int choosePosition    = CHOOSE_POSITION_BIRTH_CONTROL;
    if (row == choosePosition) {
        [self.storedAnswer removeObjectForKey:SETTINGS_KEY_BIRTH_CONTROL];
        [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:indexPath.row]];
        
        [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                    withType:ONBOARDING_PICKER_BIRTH_CONTROL_METHOD
                      answer:nil];
    } else {
        NSInteger _row;
        if (row < choosePosition) {
            _row = row;
        } else {
            _row = row - 1;
        }
        // NSInteger _row = (row-1) % [HealthProfileData birthControlItems].count;
        NSNumber * answer = [[HealthProfileData birthControlKeys] objectAtIndex:_row];
        self.storedAnswer[SETTINGS_KEY_BIRTH_CONTROL] = answer;
        [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:indexPath.row]];
        
        [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                    withType:ONBOARDING_PICKER_BIRTH_CONTROL_METHOD
                      answer:answer];
    }
}

- (void)saveOnboardingDataForUser:(User *)currentUser {}

- (NSString *)navigationTitle {
    return @"Step 1 - Avoiding pregnancy";
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

#pragma mark - helper
- (NSIndexPath*)indexPathFromChoiceSelectorTag:(NSInteger)tag {
    return [NSIndexPath indexPathForRow:tag inSection:0];
}

- (NSInteger)choiceSelectorTagFromIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row;
}

- (NSInteger)numberOfQuestions {
    return [[self _answerKeys] count];
}

@end
