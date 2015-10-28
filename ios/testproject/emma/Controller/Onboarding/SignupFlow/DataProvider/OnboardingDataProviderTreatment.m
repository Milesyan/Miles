//
//  OnboardingDataProviderFertility.m
//  emma
//
//  Created by Jirong Wang on 10/31/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "OnboardingDataProviderTreatment.h"
#import "ChildrenNumberPicker.h"
#import "Utils+DateTime.h"
#import "TTCStartTimePicker.h"
#import "TreatmentStartPicker.h"
#import <GLGeneralPicker.h>
#import "HealthProfileData.h"
#import "UserStatus.h"
#import "FertilityTestItem.h"

#define Q_ORDER_CLINIC 0
// note, currently, we can not change the order,
// because we do not implement "expandable logic" for none-last cell
#define Q_ORDER_TREATMENT_TYPE 1
#define Q_ORDER_TREATMENT_STARTDATE 2
#define Q_ORDER_TREATMENT_ENDDATE 3
#define Q_ORDER_TTC   4
#define Q_ORDER_CHILDREN 5



@interface OnboardingDataProviderTreatment() <OnboardingDataProviderProtocol, TTCStartTimerPickerDelegate, ChildrenNumberPickerDelegate, DatePickerDelegate, UIActionSheetDelegate>

@end

@implementation OnboardingDataProviderTreatment

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
        self.isChangeStatus = NO;
    }
    return self;
}

#pragma mark - OnboardingDataProvider protocal
- (NSArray *)_answerKeys {
    NSDictionary * question_orders = @{
        @(Q_ORDER_CLINIC): SETTINGS_KEY_FERTILITY_CLINIC,
        @(Q_ORDER_TTC): SETTINGS_KEY_TTC_START,
        @(Q_ORDER_CHILDREN): SETTINGS_KEY_CHILDREN_NUMBER,
        @(Q_ORDER_TREATMENT_TYPE): SETTINGS_KEY_TREATMENT_TYPE,
        @(Q_ORDER_TREATMENT_STARTDATE): SETTINGS_KEY_TREATMENT_STARTDATE,
        @(Q_ORDER_TREATMENT_ENDDATE): SETTINGS_KEY_TREATMENT_ENDDATE,
        //@(Q_ORDER_SAME_SEX_ORDER) : SETTINGS_KEY_SAME_SEX_COUPLE
    };
    
    NSMutableArray * keys = [[NSMutableArray alloc] init];
    for (int i=0; i < [question_orders count]; i++) {
        [keys addObject:question_orders[@(i)]];
    }
    return keys;
}

- (NSString *)_answerKeysAtRow:(NSInteger)row {
    NSArray *answerKeys = [self _answerKeys];
    return row < [answerKeys count] ? answerKeys[row] : nil;
}

- (id)answerForIndexPath:(NSIndexPath *)indexPath {
    return self.storedAnswer[[self _answerKeysAtRow:indexPath.row]];
}

- (BOOL)hasAdditionalButtonForIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSString *)onboardingQuestionTitleForIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case Q_ORDER_TTC:
            return @"How long have you been trying to conceive?";
        case Q_ORDER_CHILDREN:
            return @"How many children do you have?";
        case Q_ORDER_TREATMENT_TYPE:
            return @"What fertility treatment are you using now?";
        case Q_ORDER_TREATMENT_STARTDATE:
            return @"Start date for your current or upcoming treatment cycle?";
        case Q_ORDER_TREATMENT_ENDDATE:
            return @"End date for your current or upcoming treatment cycle?";
        case Q_ORDER_CLINIC:
            return @"Who are you seeing to help with your fertility journey?";
        default:
            return @"";
    }
}

- (NSString *)onboardingQuestionButtonTextForIndexPath:(NSIndexPath *)indexPath {
    id answer = [self answerForIndexPath:indexPath];
    switch (indexPath.row) {
        case Q_ORDER_TTC: {
            if (!answer) {
                return @"Choose";
            }
            return [Utils ttcStartStringFromDate:answer];
        }
        case Q_ORDER_CHILDREN: {
            int number = [answer intValue];
            if (!number) {
                return @"Choose";
            }
            else {
                return [NSString stringWithFormat:@"%d", number - 1];
            }
        }
        case Q_ORDER_TREATMENT_TYPE: {
            if (!answer) {
                return @"Choose";
            }
            else if ([answer intValue] == 1) {
                return @"Med";
            }
            else if ([answer intValue] == 2) {
                return @"IUI";
            }
            else if ([answer intValue] == 3) {
                return @"IVF";
            }
            else if ([answer intValue] == 4) {
                return @"Prep";
            }
            else {
                return @"Choose";
            }
        }
        case Q_ORDER_TREATMENT_STARTDATE: {
            NSString * dateLabel = [self.storedAnswer objectForKey:SETTINGS_KEY_TREATMENT_STARTDATE];
            if (!dateLabel) {
                return @"Choose";
            } else {
                NSDate * treatmentStart = [Utils dateWithDateLabel:dateLabel]   ;
                return [treatmentStart toReadableDate];
            }
        }
        case Q_ORDER_TREATMENT_ENDDATE: {
            NSString * dateLabel = [self.storedAnswer objectForKey:SETTINGS_KEY_TREATMENT_ENDDATE];
            if (!dateLabel) {
                return @"Choose";
            } else {
                NSDate * treatmentEnd = [Utils dateWithDateLabel:dateLabel]   ;
                return [treatmentEnd toReadableDate];
            }
        }
        case Q_ORDER_CLINIC: {
            NSNumber *clinicValue = [self.storedAnswer objectForKey:SETTINGS_KEY_FERTILITY_CLINIC];
            if (clinicValue) {
                return [FertilityTestItem shortDescriptionForFertilityClinic:clinicValue.integerValue];
            }
            return @"Choose";
        }
        default:
            return @"";
    }
}

#pragma mark - show pickers

- (BOOL)hasSelectedTreatmentType
{
    NSNumber *treatmentType = [self.storedAnswer objectForKey:SETTINGS_KEY_TREATMENT_TYPE];
    if (treatmentType && treatmentType.integerValue > 0) {
        return YES;
    }
    return NO;
}

- (NSInteger)numberOfQuestions
{
    NSInteger count = [self _answerKeys].count;
    return count;
}

- (BOOL)shouldHideQuestionAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.hasSelectedTreatmentType && (indexPath.row == 3 || indexPath.row == 4)) {
        return YES;
    }
    return NO;
}

- (BOOL)isNatural {
    return ([self numberOfQuestions] < [[self _answerKeys] count]);
}

- (BOOL)allAnswered {
    for (NSInteger i = 0; i < [self numberOfQuestions]; i++) {
        NSString *answerKey = [self _answerKeysAtRow:i];
        if (answerKey && self.storedAnswer[answerKey] == nil) {
            return NO;
        }
    }
    return YES;
}

- (void)showChoiceSelectorForIndexPath:(NSIndexPath *)indexPath {
    id answer = [self answerForIndexPath:indexPath];
    switch (indexPath.row) {
        case Q_ORDER_TTC: {
            
            [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_START
                        withType:ONBOARDING_PICKER_TTC_START_TIME
                          answer:answer];
            
            int choosePosition    = CHOOSE_POSITION_HOW_LONG_TTC;
            TTCStartTimePicker *ttcPicker = [[TTCStartTimePicker alloc] initWithChoose:choosePosition length:
                                             (answer ? [Utils ttcStartStringFromDate:answer] : nil)];
            ttcPicker.delegate = self;
            [ttcPicker present];
        }
            break;
        case Q_ORDER_CHILDREN: {
            [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_START
                        withType:ONBOARDING_PICKER_CHILDREN_NUMBER
                          answer:answer];
            
            int choosePosition    = CHOOSE_POSITION_CHILDREN;
            ChildrenNumberPicker *childrenNumberPicker =
            [[ChildrenNumberPicker alloc] initWithChoose:choosePosition number:[answer integerValue] - 1];
            childrenNumberPicker.delegate = self;
            [childrenNumberPicker present];
        }
            break;
        case Q_ORDER_TREATMENT_TYPE: {
            [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_START
                        withType:ONBOARDING_PICKER_FERTILITY_TREATMENT_TYPE
                          answer:answer];
            
            [self _showTreatmentPickerWithAnswer:answer atIndexPath:indexPath];
        }
            break;
        case Q_ORDER_TREATMENT_STARTDATE: {
            [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_START
                        withType:ONBOARDING_PICKER_FERTILITY_TREATMENT_START_DATE
                          answer:answer];
            
            [self _showTreatmentStartDatePickerWithAnswer:answer atIndexPath:indexPath];
        }
        case Q_ORDER_TREATMENT_ENDDATE: {
            [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_END
                        withType:ONBOARDING_PICKER_FERTILITY_TREATMENT_END_DATE
                          answer:answer];
            [self _showTreatmentEndDatePickerWithAnswer:answer atIndexPath:indexPath];
        }
        case Q_ORDER_CLINIC: {
            // TODO: add logging
            [self _showFertilityClinicPickerWithAnswer:answer atIndexPath:indexPath];
        }
            break;
        default:
            break;
    }
}

- (void)_showFertilityClinicPickerWithAnswer:(NSNumber *)answer atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *rows = [[FertilityTestItem fertilityClinicOptions] mutableCopy];
    NSUInteger selectedRow = [self.storedAnswer[SETTINGS_KEY_FERTILITY_CLINIC] integerValue];
    
    if (selectedRow > rows.count - 1) {
        selectedRow = rows.count - 1;
    }
    
    [GLGeneralPicker presentSimplePickerWithTitle:@""
                                             rows:rows
                                      selectedRow:(int)selectedRow
                                       showCancel:NO
                                    withAnimation:NO
                                   doneCompletion:^(NSInteger row, NSInteger comp) {
                                       
                                       NSInteger clinic = row == rows.count - 1 ? FertilityClinicOther : row;
                                       NSDictionary *data = @{@"selected_clinic": @(clinic)};
                                       [Logging log:BTN_CLK_FTONBOARDING_FERTILITY_CLINIC eventData:data];
                                       
                                       if (row == 0) {
                                           [self.storedAnswer removeObjectForKey:SETTINGS_KEY_FERTILITY_CLINIC];
                                       }
                                       else {
                                           self.storedAnswer[SETTINGS_KEY_FERTILITY_CLINIC] = @(clinic);
                                       }
                                       
                                       [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:Q_ORDER_CLINIC]];
                                    
                                   } cancelCompletion:nil];
}


- (void)_showTreatmentPickerWithAnswer:(NSNumber *)answer atIndexPath:(NSIndexPath *)indexPath {
    // answer
    //   1 - Natural with medication
    //   2 - Intrauterine Insemination (IUI)
    //   3 - In Vitro Fertilization (IVF)
    
    NSArray *options = @[@(TREATMENT_TYPE_PREPARING), @(TREATMENT_TYPE_MED), @(TREATMENT_TYPE_IUI), @(TREATMENT_TYPE_IVF)];
    

    NSMutableArray *rows = [NSMutableArray array];
    [rows addObject:@"(Choose)"];
    for (NSNumber *option in options) {
        [rows addObject:[UserStatus fullDescriptionForTreatmentType:[option integerValue]]];
    }

    NSInteger treatmentType = [self.storedAnswer[SETTINGS_KEY_TREATMENT_TYPE] integerValue];
    NSInteger selectedRow = [options indexOfObject:@(treatmentType)] + 1;

    @weakify(self);
    [GLGeneralPicker presentSimplePickerWithTitle:@"Fertility treatment"
                                             rows:rows
                                      selectedRow:(int)selectedRow
                                       showCancel:NO
                                    withAnimation:NO
                                   doneCompletion:^(NSInteger row, NSInteger comp) {
        @strongify(self);
                                       
       [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                   withType:ONBOARDING_PICKER_FERTILITY_TREATMENT_TYPE
                     answer:@(row)];
                                       
        if (row == 0) {
            [self.storedAnswer removeObjectForKey:SETTINGS_KEY_TREATMENT_TYPE];
        } else {
            self.storedAnswer[SETTINGS_KEY_TREATMENT_TYPE] = options[row - 1];
        }

        NSDictionary *eventData = @{@"treatment_type": row == 0 ? @(0) : self.storedAnswer[SETTINGS_KEY_TREATMENT_TYPE]};
        [Logging log:BTN_CLK_ONBOARDING_TREATMENT_TYPE eventData:eventData];

        [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:Q_ORDER_TREATMENT_TYPE]];
    } cancelCompletion:nil];
}


- (void)_showTreatmentStartDatePickerWithAnswer:(NSString *)answer atIndexPath:(NSIndexPath *)indexPath {
    NSString *endDate = self.storedAnswer[SETTINGS_KEY_TREATMENT_ENDDATE];
    NSDate *maximumDate = endDate ? [Utils dateWithDateLabel:endDate] : nil;
    TreatmentStartPicker * datePicker = [[TreatmentStartPicker alloc] initWithMinimumDate:nil maximumDate:maximumDate];
    datePicker.type = TYPE_START_DATE;
    datePicker.delegate = self;
    [datePicker present];
    if (answer) {
        NSDate * d = [Utils dateWithDateLabel:answer];
        [datePicker setDate:d];
    }
}

- (void)_showTreatmentEndDatePickerWithAnswer:(NSString *)answer atIndexPath:(NSIndexPath *)indexPath {
    NSString *startDate = self.storedAnswer[SETTINGS_KEY_TREATMENT_STARTDATE];
    NSDate *minimumDate = startDate ? [Utils dateWithDateLabel:startDate] : nil;
    TreatmentStartPicker * datePicker = [[TreatmentStartPicker alloc] initWithMinimumDate:minimumDate maximumDate:nil];
    datePicker.type = TYPE_END_DATE;
    datePicker.delegate = self;
    [datePicker present];
    if (answer) {
        NSDate * d = [Utils dateWithDateLabel:answer];
        [datePicker setDate:d];
    }
}

#pragma mark - Picker delegates and shower
- (void)TTCStartTimePicker:(TTCStartTimePicker *)picker didDismissWithLength:(NSString *)length
{
    if ([Utils isEmptyString:length]) {
        [self.storedAnswer removeObjectForKey:SETTINGS_KEY_TTC_START];
        [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                    withType:ONBOARDING_PICKER_TTC_START_TIME
                      answer:nil];
    }
    else {
        self.storedAnswer[SETTINGS_KEY_TTC_START] = [Utils dateFromTtcStartString:length];
        [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                    withType:ONBOARDING_PICKER_TTC_START_TIME
                      answer:[Utils dateFromTtcStartString:length]];
    }
    [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:Q_ORDER_TTC]];
}

- (void)childrenNumberPicker:(ChildrenNumberPicker *)picker
        didDismissWithNumber:(NSInteger)num
{
    [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                withType:ONBOARDING_PICKER_CHILDREN_NUMBER
                  answer:@(num+1)];
    
    if (num < 0) {
        [self.storedAnswer removeObjectForKey:SETTINGS_KEY_CHILDREN_NUMBER];
    } else {
        self.storedAnswer[SETTINGS_KEY_CHILDREN_NUMBER] = @(num+1);
    }
    [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:Q_ORDER_CHILDREN]];
}

- (void)datePicker:(TreatmentStartPicker *)datePicker didDismissWithDate:(NSDate *)date {
    /* 
     * We save string instead of date
     */
    
    if (datePicker.type == TYPE_START_DATE) {
        [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                    withType:ONBOARDING_PICKER_FERTILITY_TREATMENT_START_DATE
                      answer:[date toDateLabel]];
        
        self.storedAnswer[SETTINGS_KEY_TREATMENT_STARTDATE] = [date toDateLabel];
        [Logging log:BTN_CLK_ONBOARDING_TREATMENT_START_DATE];
        [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:Q_ORDER_TREATMENT_STARTDATE]];
    } else {
        [self logPickerEvent:BTN_CLK_ONBOARDING_PICKER_DONE
                    withType:ONBOARDING_PICKER_FERTILITY_TREATMENT_END_DATE
                      answer:[date toDateLabel]];
        
        self.storedAnswer[SETTINGS_KEY_TREATMENT_ENDDATE] = [date toDateLabel];
        [Logging log:BTN_CLK_ONBOARDING_TREATMENT_END_DATE];
        [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:Q_ORDER_TREATMENT_ENDDATE]];
    }
    
}

- (NSIndexPath*)indexPathFromChoiceSelectorTag:(NSInteger)tag {
    return [NSIndexPath indexPathForRow:tag inSection:0];
}

- (NSString *)navigationTitle {
    if (self.isChangeStatus) {
        return @"Additional info";
    } else {
        return @"Step 1 - Fertility treatments";
    }
}

- (NSString *)segueIdentifierToNextStep
{
    return @"step1ToStep2";
}

@end
