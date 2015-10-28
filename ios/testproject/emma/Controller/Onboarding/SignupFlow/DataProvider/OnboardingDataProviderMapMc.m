//
//  OnboardingDataProviderAvoidPregnancy.m
//  emma
//
//  Created by Eric Xu on 12/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "OnboardingDataProviderMapMc.h"
#import "User.h"
#import "UserDailyData.h"
#import "Settings.h"
#import "Logging.h"

#define CHOICE_TAG_CYCLE_LENGHT 0
#define CHOICE_TAG_FIRST_PB 1

@implementation OnboardingDataProviderMapMc

#pragma mark - OnboardingDataProvider protocal
- (NSArray *)_answerKeys {
    return @[SETTINGS_KEY_CYCLE_LENGTH,
             SETTINGS_KEY_FIRST_PB];
}

- (NSArray *)_additionalAnswerKeysAtRow:(NSInteger)row {
    return nil;
}

- (NSString *)onboardingQuestionTitleForIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            return @"Average cycle length";
        case 1:
            return @"When's your last period?";
        default:
            return @"";
    }
}

- (NSString *)onboardingQuestionButtonTextForIndexPath:(NSIndexPath *)indexPath {
    id answer = [self answerForIndexPath:indexPath];
    switch (indexPath.row) {
        case 0:
            if (!answer) {
                return @"-- days";
            }
            else {
                return [NSString stringWithFormat:@"%d days", [answer intValue]];
            }
        case 1:
            if (!answer) {
                return @"M/D/Y";
            }
            else {
                NSArray *splitedDate = [((NSString*)answer) componentsSeparatedByString:@"/"];
                return [NSString stringWithFormat:@"%@/%@/%@", splitedDate[1], splitedDate[2], [((NSString*)splitedDate[0]) substringFromIndex:2]];
            }
        default:
            return @"";
    }
}

- (void)showChoiceSelectorForIndexPath:(NSIndexPath *)indexPath {
    id answer = [self answerForIndexPath:indexPath];
    switch (indexPath.row) {
        case CHOICE_TAG_CYCLE_LENGHT:
        {
            [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_START
                        withType:ONBOARDING_PICKER_CYCLE_LENGTH
                          answer:answer];
        
            int choosePosition    = CHOOSE_POSITION_CYCLE_LENGTH;
            DaysPicker *daysPicker = [[DaysPicker alloc] initWithChoose:choosePosition
                                                              title:@"How many days from the start of one period to the start of the next?"
                                                               default:(!answer ? 0 : [answer integerValue])
                                                                   min:CYCLE_LENGTH_MIN
                                                                   max:CYCLE_LENGTH_MAX];
            daysPicker.delegate = self;
            daysPicker.identifier = CHOICE_TAG_CYCLE_LENGHT;
            [daysPicker present];
        }
            break;
        case CHOICE_TAG_FIRST_PB:
        {
            OnboardingPeriodEditorViewController *periodViewController = [OnboardingPeriodEditorViewController instance];
            periodViewController.delegate = self;
            [periodViewController setAlwaysEnableNextButton:YES];
            UINavigationController *firstPeriodNavController = [[UINavigationController alloc] initWithRootViewController:periodViewController];
            UIView *view = [self.presenter.navigationItem.titleView snapshotViewAfterScreenUpdates:YES];
            periodViewController.navigationItem.titleView = view;
            [Logging syncLog:BTN_CLK_ONBOARDING_PERIOD eventData:@{}];
            [self.presenter presentViewController:firstPeriodNavController animated:YES completion:nil];

        }
            break;
        default:
            break;
    }
}

- (void)saveOnboardingDataForUser:(User *)currentUser {}

- (NSString *)segueIdentifierToNextStep {
    return @"personInfo";
}

- (NSString *)navigationTitle {
    return @"Step 2 - Menstrual cycle";
}

#pragma mark - Picker delegates and shower
- (void)daysPicker:(DaysPicker *)daysPicker didDismissWithDays:(NSInteger)days {
    
    [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                withType:ONBOARDING_PICKER_CYCLE_LENGTH
                  answer:@(days)];
    
    if (days == 0) {
        [self.storedAnswer removeObjectForKey:SETTINGS_KEY_CYCLE_LENGTH];
    } else {
        self.storedAnswer[SETTINGS_KEY_CYCLE_LENGTH] = @(days);
    }
    [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:CHOICE_TAG_CYCLE_LENGHT]];
}

- (void)firstPeriodSelector:(OnboardingPeriodEditorViewController *)firstPeriodSelector
       didDismissWithPeriod:(NSDictionary *)firstPeriod {
    NSDate *firstPb = (NSDate*)firstPeriod[@"begin"];
    NSDate *firstPe = (NSDate*)firstPeriod[@"end"];
    NSInteger pl0 = [Utils daysBeforeDate:firstPe sinceDate:firstPb];
    self.storedAnswer[SETTINGS_KEY_FIRST_PB] = [firstPb toDateLabel];
    self.storedAnswer[SETTINGS_KEY_PERIOD_LENGTH] = @(pl0);
    [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:CHOICE_TAG_FIRST_PB]];
}

#pragma mark - helper
- (NSIndexPath*)indexPathFromChoiceSelectorTag:(NSInteger)tag {
    return [NSIndexPath indexPathForRow:tag inSection:0];
}

@end
