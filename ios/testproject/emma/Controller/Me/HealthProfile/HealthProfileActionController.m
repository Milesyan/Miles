//
//  HealthProfileActionController.m
//  emma
//
//  Created by Peng Gu on 3/24/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "HealthProfileActionController.h"
#import "HealthProfileDataController.h"
#import "HealthProfileData.h"
#import "HealthProfileItem.h"
#import "User.h"
#import "ExportReportDialog.h"

#import "BirthdayPicker.h"
#import "DaysPicker.h"
#import "ExercisePicker.h"
#import "HeightPicker.h"
#import "BirthdayPicker.h"
#import "TTCStartTimePicker.h"
#import "ChildrenNumberPicker.h"
#import "EthnicityPicker.h"
#import "WaistPicker.h"

#import "HealthKitManager.h"

#import <BlocksKit/UIAlertView+BlocksKit.h>

#import <GLFoundation/GLGeneralPicker.h>
#import <GLFoundation/GLPickerViewController.h>


@interface HealthProfileActionController () <DaysPickerDelegate, DatePickerDelegate, UIActionSheetDelegate, TTCStartTimerPickerDelegate, ChildrenNumberPickerDelegate>

@property (nonatomic, weak) HealthProfileDataController *dataController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) User *user;

@property (strong, nonatomic) BirthdayPicker *birthdayPicker;
@property (strong, nonatomic) UIActionSheet *genderActionSheet;
@property (strong, nonatomic) DaysPicker *periodCyclePicker;
@property (strong, nonatomic) DaysPicker *periodLengthPicker;
@property (strong, nonatomic) ExercisePicker *exercisePicker;
@property (strong, nonatomic) HeightPicker *heightPicker;
@property (strong, nonatomic) BirthdayPicker *birthControlStartDatePicker;
@property (strong, nonatomic) EthnicityPicker *ethnicityPicker;
@property (strong, nonatomic) WaistPicker *waistPicker;

@property (strong, nonatomic) NSDictionary *actionMapping;

@end


@implementation HealthProfileActionController

- (instancetype)initWithTableView:(UITableView *)tableView
                   dataController:(HealthProfileDataController *)dataController
{
    self = [super init];
    if (self) {
        _tableView = tableView;
        _dataController = dataController;
        _user = [User currentUser];
        
        _actionMapping = @{
            kHealthProfileItemCycleLength: NSStringFromSelector(@selector(updatePeriodCycle)),
            kHealthProfileItemPeriodLength: NSStringFromSelector(@selector(updatePeriodLength)),
            kHealthProfileItemCycleRegularity: NSStringFromSelector(@selector(updateCycleRegularity)),
            kHealthProfileItemBirthControl: NSStringFromSelector(@selector(updateBirthControl)),
            kHealthProfileItemBirthControlStart: NSStringFromSelector(@selector(updateBirthControlStart)),
            kHealthProfileItemRelationshipStatus: NSStringFromSelector(@selector(updateRelationshipStatus)),
            kHealthProfileItemPartnerErection: NSStringFromSelector(@selector(updateErectionDifficulty)),
            kHealthProfileItemPhysicalActivity: NSStringFromSelector(@selector(updateExercise)),
            kHealthProfileItemEthnicity: NSStringFromSelector(@selector(updateEthnicity)),
            kHealthProfileItemGender: NSStringFromSelector(@selector(updateGender)),
            kHealthProfileItemBirthDate: NSStringFromSelector(@selector(updateBirthday)),
            kHealthProfileItemHeight: NSStringFromSelector(@selector(updateHeight)),
            kHealthProfileItemOccupation: NSStringFromSelector(@selector(updateOccupation)),
            kHealthProfileItemInsurance: NSStringFromSelector(@selector(updateInsurance)),
            kHealthProfileItemTTCStart: NSStringFromSelector(@selector(updateTTCStartTime)),
            kHealthProfileItemTryingFor: NSStringFromSelector(@selector(updateChildrenNumber)),
            kHealthProfileItemSpermOrEggDonation: NSStringFromSelector(@selector(updateSpermEggDonation)),
            kHealthProfileItemConsidering: NSStringFromSelector(@selector(updateConsidering)),
            kHealthProfileItemWaist: NSStringFromSelector(@selector(updateWasit)),
            kHealthProfileItemTesterone: NSStringFromSelector(@selector(updateTesterone)),
            kHealthProfileItemUnderwearType: NSStringFromSelector(@selector(updateUnderwearType)),
            kHealthProfileItemHouseholdIncome: NSStringFromSelector(@selector(updateHouseholdIncome)),
            kHealthProfileItemHomeZipcode: NSStringFromSelector(@selector(updateHomeZipcode)),
        };
    
    }
    return self;
}


- (void)performActionForItem:(HealthProfileItem *)item
{
    NSString *actionName = [self.actionMapping objectForKey:item.key];
    if (actionName) {
        // ARC will complain if using performSelector
        // [self performSelector:NSSelectorFromString(actionName)];
        
        SEL selector = NSSelectorFromString(actionName);
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(self, selector);

        return;
    }

    if([item.key isEqualToString:kHealthProfileItemDiagnosedCondition]){
        [self performSegueWithIdentifier:@"DiagnosedConditionSegue"];
    }
    else if([item.key isEqualToString:kHealthProfileItemPregnancyHistory]){
        [self performSegueWithIdentifier:@"PregnancyHistorySegue"];
    }
    else if([item.key isEqualToString:kHealthProfileItemInfertilityDiagnosis]){
        [self performSegueWithIdentifier:@"InfertilityCausesSegue"];
    }
    else if ([item.key isEqualToString:kHealthProfileItemExportDataReport]) {
        [Logging log:BTN_CLK_HELP_EXPORT];
        [[[ExportReportDialog alloc] initWithUser:[User currentUser]] present];
    }
}


- (void)performSegueWithIdentifier:(NSString *)identifier
{
    if ([self.delegate respondsToSelector:@selector(actionControllerNeedsToPerformSegue:)]) {
        [self.delegate actionControllerNeedsToPerformSegue:identifier];
    }
}


#pragma mark - Save
- (void)save
{
    [self.user save];
    [self.user pushToServer];
    
    [self publish:EVENT_USER_SETTINGS_UPDATED];
    
    if ([self.delegate respondsToSelector:@selector(actionControllerDidSaveUpdate)]) {
        [self.delegate actionControllerDidSaveUpdate];
    }
}


- (void)logButtonClickWithName:(NSString *)name
                         value:(CGFloat)value
                additionalInfo:(NSString *)info
{
    NSDictionary *data = @{
                           @"health_profile_name": name,
                           @"click_type": CLICK_TYPE_INPUT,
                           @"select_value": @(value),
                           @"additional_info": info ? info : @"" };
    [Logging log:BTN_CLK_HEALTH_PROFILE_ITEM eventData:data];
}


#pragma mark - update waist
- (void)updateWasit
{
    NSUInteger currWaist = [User currentUser].settings.waist;
    self.waistPicker = [[WaistPicker alloc] init];
    [self.waistPicker presentWithWaistInCM:currWaist
                          withDoneCallback:^(float waist) {
                              
                              [self logButtonClickWithName:HEALTH_PROFILE_ITEM_WAIST
                                                     value:waist
                                            additionalInfo:@"done"];
                              
                              [self.user.settings update:@"waist" floatValue:waist];
                              [self save];
                          } cancelCallback:^(float waist) {
                              [self logButtonClickWithName:HEALTH_PROFILE_ITEM_WAIST
                                                     value:waist
                                            additionalInfo:@"cancel"];
                          }];
}


#pragma mark - update zipcode
- (void)updateHomeZipcode
{
    UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:@"Home zipcode"];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    
    NSString *zipcode = [User currentUser].settings.homeZipcode;
    if (zipcode.length > 0) {
        textField.text = zipcode;
    }
    
    [alertView bk_setCancelButtonWithTitle:@"Done" handler:^{
        NSString *text = textField.text;
        
        [self logButtonClickWithName:HEALTH_PROFILE_ITEM_HOMEZIPCODE
                               value:0
                      additionalInfo:zipcode];
        
        if (![text isEqual:zipcode]) {
            [self.user.settings update:@"homeZipcode" value:text];
            [self save];
        }
    }];
    
    [alertView show];
}



#pragma mark - update testerone
- (void)updateTesterone
{
    [self presentPickerWithTitle:nil
                             key:@"testerone"
                            rows:[HealthProfileData testerOptions]];
}


#pragma mark - update underwear
- (void)updateUnderwearType
{
    [self presentPickerWithTitle:nil
                             key:@"underwearType"
                            rows:[HealthProfileData underwearOptions]];
}


#pragma mark - update household income
- (void)updateHouseholdIncome
{
    [self presentPickerWithTitle:nil
                             key:@"householdIncome"
                            rows:[HealthProfileData householdIncomeOptions]];
}


#pragma mark - Update Cycle and Period Length
- (void)updatePeriodLength
{
    self.periodLengthPicker = [[DaysPicker alloc] initWithTitle:@"How long does your period usually last?"
                                                        default:[Utils cycleLengthModelToDisplay:self.user.settings.periodLength]
                                                            min:PERIOD_LENGTH_MIN
                                                            max:PERIOD_LENGTH_MAX];
    self.periodLengthPicker.delegate = self;
    [self.periodLengthPicker present];
}


- (void)updatePeriodCycle
{
    self.periodCyclePicker = [[DaysPicker alloc] initWithTitle:@"How many days from the start of one period to the start of the next?"
                                                       default:self.user.settings.periodCycle
                                                           min:CYCLE_LENGTH_MIN
                                                           max:CYCLE_LENGTH_MAX];
    self.periodCyclePicker.delegate = self;
    [self.periodCyclePicker present];
}


- (void)daysPicker:(DaysPicker *)daysPicker didDismissWithDays:(NSInteger)days {
    if (daysPicker == self.periodLengthPicker) {
        NSInteger value = [Utils cycleLengthDisplayToModel:days];
        [self.user.settings update:@"periodLength" value:@(value)];
        [self logButtonClickWithName:HEALTH_PROFILE_ITEM_PERIODLENGTH value:value additionalInfo:nil];
    }
    else {
        [self.user.settings update:@"periodCycle" value:@(days)];
        [self logButtonClickWithName:HEALTH_PROFILE_ITEM_CYCLELENGTH value:days additionalInfo:nil];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Glow only uses your ‘Average Cycle length’ for your very first cycle on Glow. Changing this will not affect Glow’s future cycle prediction." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    [self save];
}


- (void)updateCycleRegularity
{
    [self presentPickerWithTitle:nil
                             key:@"cycleRegularity"
                            rows:[HealthProfileData cycleRegularityOptions]];
}


#pragma mark - Update Considering
- (void)updateConsidering {
    
    int answer = self.user.settings.timePlanedConceive;
    NSInteger selectedRow = answer ? [[HealthProfileData consideringKeys] indexOfObject:@(answer)] : 0;
    // may be not found
    if (selectedRow > [HealthProfileData consideringKeys].count) {
        selectedRow = 0;
    }
    
    [GLGeneralPicker presentCancelableSimplePickerWithTitle:@"Consider conceiving?"
                                                       rows:[HealthProfileData consideringItems]
                                                selectedRow:(int)selectedRow
                                                  doneTitle:@"Done"
                                                 showCancel:YES
                                              withAnimation:YES
                                             doneCompletion:^(NSInteger row, NSInteger comp) {

                                                [self logButtonClickWithName:HEALTH_PROFILE_ITEM_CONSIDERING
                                                                       value:row
                                                              additionalInfo:@"done"];
                                                 
                                                 if (row != selectedRow) {
                                                     [self.user.settings update:@"timePlanedConceive"
                                                                          value:[[HealthProfileData consideringKeys]  objectAtIndex:row]];
                                                     [self save];
                                                 }
                                             }
                                           cancelCompletion:^(NSInteger row, NSInteger comp) {
                                                [self logButtonClickWithName:HEALTH_PROFILE_ITEM_CONSIDERING
                                                                       value:row
                                                              additionalInfo:@"cancel"];
                                           }];
}

#pragma mark - Update Birth Control
- (void)updateBirthControl
{
    int64_t currentBc = self.user.settings.birthControl;
    NSInteger selectedRow = currentBc ? [[HealthProfileData birthControlKeys] indexOfObject:@(currentBc)] : 0;
    // may be not found
    if (selectedRow > [HealthProfileData birthControlKeys].count) {
        selectedRow = 0;
    }
    
    NSArray *rows = [HealthProfileData birthControlItems];
    [GLGeneralPicker presentSimplePickerWithTitle:@"Birth control?"
                                             rows:rows
                                      selectedRow:(int)selectedRow
                                       showCancel:NO
                                    withAnimation:NO
                                   doneCompletion:^(NSInteger row, NSInteger comp) {
                                       [self logButtonClickWithName:HEALTH_PROFILE_ITEM_BIRTHCONTROL
                                                              value:row
                                                     additionalInfo:@"done"];
                                       
                                       if ((selectedRow == 0) || (row != selectedRow)) {
                                           [self _birthControlSelectedRow:row];
                                       }
                                   } cancelCompletion:^(NSInteger row, NSInteger comp) {
                                       [self logButtonClickWithName:HEALTH_PROFILE_ITEM_BIRTHCONTROL
                                                              value:row
                                                     additionalInfo:@"cancel"];
                                   }];
}


- (void)_birthControlSelectedRow:(NSInteger)row
{
    NSInteger _row = row % [HealthProfileData birthControlItems].count;
    [self.user.settings update:@"birthControl" value:[[HealthProfileData birthControlKeys] objectAtIndex:_row]];
    [self.dataController reloadItems];
    [self save];
    [Reminder updateByPurposeChanged];
}


#pragma mark - Update Birth Control and Birthday Date
- (void)updateBirthControlStart
{
    self.birthControlStartDatePicker = [[BirthdayPicker alloc] init];
    self.birthControlStartDatePicker.delegate = self;
    [[GLPickerViewController sharedInstance] presentWithContentController:self.birthControlStartDatePicker];
    
    //    self.birthControlStartDatePicker.datePicker.minimumDate = [self.user.birthday dateByAddingTimeInterval:(18 * ((int)(60*60*24*365.2425)))];
    self.birthControlStartDatePicker.datePicker.maximumDate = [NSDate date];
    
    NSDate *date = self.user.settings.birthControlStart;
    if (!date) {
        date = [NSDate date];
    }
    self.birthControlStartDatePicker.date = date;
    
    self.birthControlStartDatePicker.titleLabel.text = @"Enter your birth control start date";
    self.birthControlStartDatePicker.title = @"Enter your birth control start date";
}


- (void)updateBirthday
{
    self.birthdayPicker = [[BirthdayPicker alloc] init];
    self.birthdayPicker.delegate = self;
    [[GLPickerViewController sharedInstance] presentWithContentController:self.birthdayPicker];
    self.birthdayPicker.date = self.user.birthday;
}


- (void)datePicker:(BaseDatePicker *)datePicker didDismissWithDate:(NSDate *)date
{
    if (datePicker == self.birthdayPicker) {
        [self.user update:USERINFO_KEY_BIRTHDAY value:date];
        [self logButtonClickWithName:HEALTH_PROFILE_ITEM_BIRTHDATE
                               value:[date timeIntervalSince1970]
                      additionalInfo:nil];
    }
    else if (datePicker == self.birthControlStartDatePicker) {
        [self.user.settings update:@"birthControlStart" value:date];
        [self logButtonClickWithName:HEALTH_PROFILE_ITEM_BIRTHCONTROLSTART
                               value:[date timeIntervalSince1970]
                      additionalInfo:nil];
    }
    
    [self save];
}


#pragma mark - update relation status
- (void)updateRelationshipStatus
{
    [self presentPickerWithTitle:nil
                             key:@"relationshipStatus"
                            rows:[HealthProfileData relationshipStatusOptions]];
}


- (void)updateErectionDifficulty
{
    [self presentPickerWithTitle:nil
                             key:@"partnerErection"
                            rows:[HealthProfileData erectionDifficultyOptions]];
}


#pragma mark - update occupation
- (void)updateOccupation
{
    NSArray *options = [HealthProfileData occupationOptions];
    NSInteger selectedRow = [options indexOfObject:self.user.settings.occupation];
    [GLGeneralPicker presentCancelableSimplePickerWithTitle:nil
                                                       rows:options
                                                selectedRow:(int)selectedRow
                                                  doneTitle:@"Done"
                                                 showCancel:YES
                                              withAnimation:YES
                                             doneCompletion:^(NSInteger row, NSInteger comp) {
                                                 [self logButtonClickWithName:HEALTH_PROFILE_ITEM_OCCUPATION
                                                                        value:row
                                                               additionalInfo:@"done"];
                                                 
                                                 if (row != selectedRow) {
                                                     [self.user.settings update:@"occupation" value:[options objectAtIndex:row]];
                                                     [self save];
                                                 }
                                             }
                                           cancelCompletion:^(NSInteger row, NSInteger comp) {
                                               [self logButtonClickWithName:HEALTH_PROFILE_ITEM_OCCUPATION
                                                                      value:row
                                                             additionalInfo:@"cancel"];
                                           }];
}


#pragma mark - update insurance
- (void)updateInsurance
{
    NSString *key = @"insurance";
    NSInteger selectedRow = [[self.user.settings valueForKey:key] integerValue];
    selectedRow = [HealthProfileData indexForInsuranceType:selectedRow];
    
    [GLGeneralPicker presentCancelableSimplePickerWithTitle:nil
                                                       rows:[HealthProfileData insuranceOptions]
                                                selectedRow:(int)selectedRow
                                                  doneTitle:@"Done"
                                                 showCancel:YES
                                              withAnimation:YES
                                             doneCompletion:^(NSInteger row, NSInteger comp) {
                                                 row = [HealthProfileData insuranceTypeForIndex:row];
                                                 
                                                 [self logButtonClickWithName:key
                                                                        value:row
                                                               additionalInfo:@"done"];
                                                 
                                                 if (row != selectedRow) {
                                                     [self.user.settings update:key intValue:row];
                                                     [self save];
                                                 }
                                             } cancelCompletion:^(NSInteger row, NSInteger comp) {
                                                 row = [HealthProfileData insuranceTypeForIndex:row];
                                                 
                                                 [self logButtonClickWithName:key
                                                                        value:row
                                                               additionalInfo:@"cancel"];
                                             }];
}


#pragma mark - update ethnicity
- (void)updateEthnicity
{
    if (!self.ethnicityPicker) {
        self.ethnicityPicker = [[EthnicityPicker alloc] init];
    }
    
    NSInteger selectedRow = self.user.settings.ethnicity;
    NSString *key = @"ethnicity";
    
    [self.ethnicityPicker presentWithOptions:[HealthProfileData ethnicityOptions]
                                 selectedRow:selectedRow
                                  doneAction:^(NSInteger row, NSInteger comp) {
                                      [self logButtonClickWithName:key
                                                             value:row
                                                    additionalInfo:@"done"];
                                      
                                      if (row != selectedRow) {
                                          [self.user.settings update:key intValue:row];
                                          [self save];
                                      }
                                  } cancelAction:^(NSInteger row, NSInteger comp) {
                                      [self logButtonClickWithName:key
                                                             value:row
                                                    additionalInfo:@"cancel"];
                                  }];
}

#pragma mark - update gender
- (void)updateGender
{
//    [GLGeneralPicker presentCancelableSimplePickerWithTitle:nil
//                                                       rows:@[@"Male", @"Female"]
//                                                selectedRow:self.user.isFemale
//                                                  doneTitle:@"Done"
//                                                 showCancel:YES
//                                              withAnimation:YES
//                                             doneCompletion:^(NSInteger row, NSInteger comp) {
//                                                 
//                                                 BOOL isFemale = row == 0 ? NO : YES;
//                                                 if (isFemale != self.user.isFemale) {
//                                                     [self presentChangeGenderAlert:isFemale];
//                                                 }
//                                                 
//                                             } cancelCompletion:^(NSInteger row, NSInteger comp) {
//                                                 
//                                             }];
}


- (void)presentChangeGenderAlert:(BOOL)isFemale
{
    NSString *msg = @"Changing your gender will update your daily log questions accordingly."
    "If you need to switch accounts with your partner, please contact us instead at support@glowing.com.";
    
    [UIAlertView bk_showAlertViewWithTitle:@"Please note"
                                   message:msg
                         cancelButtonTitle:@"Cancel"
                         otherButtonTitles:@[@"Change"]
                                   handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                       if (buttonIndex != alertView.cancelButtonIndex) {
                                           [self userDidSelectGender:isFemale];
                                       }
                                   }];
}


- (void)userDidSelectGender:(BOOL)isFemale
{
    self.tableView.userInteractionEnabled = NO;
    
    [[User currentUser] updateGender:isFemale
                          completion:^(BOOL success, NSString *errorMessage) {
                              
                              self.tableView.userInteractionEnabled = YES;
                              
                              if (success) {
                                  NSString *value = isFemale ? FEMALE : MALE;
                                  [self.user update:USERINFO_KEY_GENDER value:value];
                                  
                                  [self.dataController reloadItems];
                                  [self save];
                                  
                                  [self logButtonClickWithName:HEALTH_PROFILE_ITEM_GENDER
                                                         value:0
                                                additionalInfo:value];
                              }
                              else {
                                  [UIAlertView bk_showAlertViewWithTitle:@"Change Gender Failed"
                                                                 message:errorMessage
                                                       cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                                           
                                                       }];
                              }
    }];
}


#pragma mark - Update height
- (void)updateHeight
{
    if (!self.heightPicker) {
        self.heightPicker = [[HeightPicker alloc] init];
    }
    
    [self.heightPicker presentWithHeightInCM:self.user.settings.height
                                 andCallback:^(float h) {
                                     [self logButtonClickWithName:HEALTH_PROFILE_ITEM_HEIGHT
                                                            value:0
                                                   additionalInfo:[NSString stringWithFormat:@"%f", h]];
                                     
                                     if (h != self.user.settings.height) {
                                         [[HealthKitManager sharedInstance] pushHeight:h];
                                         [self.user.settings update:USERINFO_KEY_HEIGHT floatValue:h];
                                         [self save];
                                     }
                                 }];
}


#pragma mark - update exercise
- (void)updateExercise
{
    if (!self.exercisePicker) {
        self.exercisePicker = [[ExercisePicker alloc] init];
        self.exercisePicker.target = TARGET_SETTING;
    }
    
    //row 0->4
    //val 1->5
    NSInteger selectedRow = 2;
    if (self.user.settings.exercise > 0) {
        selectedRow = [ExercisePicker indexOfValue:self.user.settings.exercise];
    }
    [self.exercisePicker presentWithSelectedRow:selectedRow
                                   inComponents:0
                               withDoneCallback:^(NSInteger row, NSInteger comp) {
                                   [self logButtonClickWithName:HEALTH_PROFILE_ITEM_PHYSICALACTIVITY
                                                          value:row
                                                 additionalInfo:@"done"];
                                   
                                   [self.user.settings update:USERINFO_KEY_EXERCISE value:@([ExercisePicker valueForFullListIndex:row])];
                                   [self save];
                               }
                              andCancelCallback:^(NSInteger row, NSInteger comp) {
                                  [self logButtonClickWithName:HEALTH_PROFILE_ITEM_PHYSICALACTIVITY
                                                         value:row
                                                additionalInfo:@"cancel"];
                              }];
}


#pragma mark - update ttc
- (void)updateTTCStartTime
{
    NSString *length = self.user.settings.ttcStart ? [Utils ttcStartStringFromDate:self.user.settings.ttcStart] : @"6 months";
    TTCStartTimePicker *ttcPicker = [[TTCStartTimePicker alloc] initWithChoose:6 length:length];
    ttcPicker.delegate = self;
    [ttcPicker present];
}


- (void)TTCStartTimePicker:(TTCStartTimePicker *)picker didDismissWithLength:(NSString *)length
{
    NSDate *date = [Utils dateFromTtcStartString:length];
    
    [self logButtonClickWithName:HEALTH_PROFILE_ITEM_TTCSTART
                           value:[date timeIntervalSince1970]
                  additionalInfo:[date toDateLabel]];
    
    [self.user.settings update:@"ttcStart" value:date];
    [self save];
}


#pragma mark - children number
- (void)updateChildrenNumber
{
    NSUInteger selectedRow = MAX(0, self.user.settings.childrenNumber - 1);
    ChildrenNumberPicker *childrenNumberPicker = [[ChildrenNumberPicker alloc] initWithNumber:selectedRow];
    childrenNumberPicker.delegate = self;
    [childrenNumberPicker present];
}


- (void)childrenNumberPicker:(ChildrenNumberPicker *)picker didDismissWithNumber:(NSInteger)num
{
    [self logButtonClickWithName:HEALTH_PROFILE_ITEM_TRYINGFOR
                           value:num
                  additionalInfo:nil];
    
    [self.user.settings update:@"childrenNumber" intValue:num + 1];
    [self save];
}


#pragma mark - fertility treatment
- (void)updateSpermEggDonation
{
    [self presentPickerWithTitle:nil key:@"spermOrEggDonation" rows:[HealthProfileData spermOrEggDonationOptions]];
}


- (void)presentPickerWithTitle:(NSString *)title key:(NSString *)key rows:(NSArray *)rows
{
    NSInteger selectedRow = [[self.user.settings valueForKey:key] integerValue];
    BOOL needToResetItems = [@[@"fertilityTreatment", @"relationshipStatus"] containsObject:key];
    
    [GLGeneralPicker presentCancelableSimplePickerWithTitle:title
                                                       rows:rows
                                                selectedRow:(int)selectedRow
                                                  doneTitle:@"Done"
                                                 showCancel:YES
                                              withAnimation:YES
                                             doneCompletion:^(NSInteger row, NSInteger comp) {
                                                 [self logButtonClickWithName:key
                                                                        value:row
                                                               additionalInfo:@"done"];
                                                 
                                                 if (row != selectedRow) {
                                                     [self.user.settings update:key intValue:row];
                                                     
                                                     if (needToResetItems) {
                                                         [self.dataController reloadItems];
                                                     }
                                                     [self save];
                                                 }
                                             } cancelCompletion:^(NSInteger row, NSInteger comp) {
                                                 [self logButtonClickWithName:key
                                                                        value:row
                                                               additionalInfo:@"cancel"];
                                             }];
}


@end
