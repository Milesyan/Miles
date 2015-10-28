//
//  HealthProfileItem.m
//  emma
//
//  Created by Peng Gu on 10/13/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "HealthProfileItem.h"
#import "HealthProfileData.h"
#import "ExercisePicker.h"
#import "User.h"

@interface HealthProfileItem ()

@property (nonatomic, strong) id oldValue;

@end

@implementation HealthProfileItem


+ (instancetype)itemWithKey:(NSString *)key
{
    return [[HealthProfileItem alloc] initWithKey:key];
}


- (instancetype)initWithKey:(NSString *)key
{
    self = [super init];
    if (self) {
        self.key = key;
        [self updateDetails];
    }
    return self;
}


- (NSUInteger)completions
{
    if ([self.key isEqualToString:kHealthProfileItemPregnancyHistory]) {
        Settings *setting = [User currentUser].settings;
        NSUInteger number = 0;
        if (setting.liveBirthNumber >= 0) {
            number += 1;
        }
        if (setting.miscarriageNumber >= 0) {
            number += 1;
        }
        if (setting.tubalPregnancyNumber >= 0) {
            number += 1;
        }
        if (setting.abortionNumber >= 0) {
            number += 1;
        }
        if (setting.stillbirthNumber >= 0) {
            number += 1;
        }
        return number;
    }
    
    if (!self.details || [self.details isEqualToString:@"Choose"] || [self.details isEqualToString:@" "] || [self.details isEqualToString:@""]) {
        return 0;
    }
    return 1;
}


- (void)updateDetails
{
    User *user = [User currentUser];
    Settings *setting = user.settings;
    
    if ([self.key isEqualToString:kHealthProfileItemCycleLength]) {
        self.details = setting.periodCycle > 0 ? [NSString stringWithFormat:@"%d days", setting.periodCycle] : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemPeriodLength]){
        self.details = setting.periodLength > 0 ? [NSString stringWithFormat:@"%ld days", [Utils cycleLengthModelToDisplay:setting.periodLength]] : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemCycleRegularity]){
        self.details = setting.cycleRegularity > 0 ? [HealthProfileData descriptionForCycleRegularity:setting.cycleRegularity] : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemDiagnosedCondition]){
        NSUInteger number = [HealthProfileData numberOfDiagnosedConditionsForValue:setting.diagnosedConditions];
        self.details = number > 0 ? [NSString stringWithFormat:@"%ld logged", number] : @" ";
    }
    else if([self.key isEqualToString:kHealthProfileItemConsidering]){
        self.details = [[HealthProfileData consideringShortNames] objectForKey:@(setting.timePlanedConceive)];
    }
    else if([self.key isEqualToString:kHealthProfileItemBirthControl]){
        self.details = [[HealthProfileData birthControlShortNames] objectForKey:@(setting.birthControl)];
    }
    else if([self.key isEqualToString:kHealthProfileItemBirthControlStart]){
        self.details = setting.birthControlStart ? [setting.birthControlStart toReadableDate] : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemRelationshipStatus]){
        self.details = setting.relationshipStatus > 0 ? [HealthProfileData descriptionForRelationshipStatus:setting.relationshipStatus] : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemPartnerErection]){
        self.details = setting.partnerErection > 0 ? [HealthProfileData descriptionForErectionDifficulty:setting.partnerErection] : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemPhysicalActivity]){
        // hack to remove slight option
        if (setting.exercise == EXERCISE_SLIGHTLY) {
            [setting update:@"exercise" value:@(EXERCISE_LIGHTLY)];
            [user save];
        }
        self.details = setting.exercise > 0 ? [ExercisePicker titleForFullListIndex:[ExercisePicker indexOfValue:setting.exercise]] : @"Choose";
    }
    else if ([self.key isEqualToString:kHealthProfileItemEthnicity]) {
        self.details = setting.ethnicity > 0 ? [HealthProfileData descriptionForEthnicity:setting.ethnicity] : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemGender]){
        self.details = user.isFemale ? @"Female" : @"Male";
    }
    else if([self.key isEqualToString:kHealthProfileItemBirthDate]){
        self.details = user.birthday ? [user.birthday toReadableDate] : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemHeight]){
        self.details = setting.height > 0 ? [Utils displayTextForHeightInCM:setting.height] : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemOccupation]){
        // Fix a typo in old version
        if ([setting.occupation isEqualToString:@"Umemployed"]) {
            [setting update:@"occupation" value:@"Unemployed"];
            [user save];
        }
        self.details = (setting.occupation && ![setting.occupation isEqualToString:@""]) ? setting.occupation : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemInsurance]){
        self.details = setting.insurance > 0 ? [HealthProfileData descriptionForInsuranceType:setting.insurance] : @"Choose";
    }
    else if([self.key isEqualToString:kHealthProfileItemTTCStart]){
        if (!setting.ttcStart) {
            self.details = @"Choose";
            return;
        }
        NSArray *date = [[Utils ttcStartStringFromDate:setting.ttcStart] componentsSeparatedByString:@" "];
        NSString *number = [date firstObject];
        NSString *unit = [date lastObject];
        if ([unit isEqualToString:@"week"] || [unit isEqualToString:@"weeks"]) {
            unit = @"w";
        }
        else if ([unit isEqualToString:@"month"] || [unit isEqualToString:@"months"]) {
            unit = @"mo";
        }
        else if ([unit isEqualToString:@"years"] || [unit isEqualToString:@"year"]) {
            unit = @"y";
        }
        self.details = [NSString stringWithFormat:@"%@ %@", number, unit];
    } 
    else if([self.key isEqualToString:kHealthProfileItemTryingFor]){
        self.details = [HealthProfileData descriptionForChildrenNumber:setting.childrenNumber-1];
    } 
    else if([self.key isEqualToString:kHealthProfileItemInfertilityDiagnosis]){
        NSUInteger number = [HealthProfileData numberOfInfertilityCausesForValue:setting.infertilityDiagnosis];
        self.details = number > 0 ? [NSString stringWithFormat:@"%ld", number] : @" ";
    }
    else if ([self.key isEqualToString:kHealthProfileItemSpermOrEggDonation]) {
        self.details = setting.spermOrEggDonation > 0 ? [HealthProfileData descriptionForSpermOrEggDonation:setting.spermOrEggDonation] : @"Choose";
    }
    else if ([self.key isEqual:kHealthProfileItemWaist]) {
        BOOL isInch = [[Utils getDefaultsForKey:kUnitForHeight] isEqual:UNIT_INCH];
        NSUInteger waist = isInch ? [Utils inchesFromCm:setting.waist] : setting.waist;
        NSString *details = [NSString stringWithFormat:@"%ld %@", waist, (isInch ? @"in": @"cm")];
        self.details = setting.waist > 0 ? details : @"Choose";
    }
    else if ([self.key isEqual:kHealthProfileItemTesterone]) {
        self.details = setting.testerone > 0 ? [HealthProfileData descriptionForTesterone:setting.testerone] : @"Choose";
    }
    else if ([self.key isEqual:kHealthProfileItemUnderwearType]) {
        self.details = setting.underwearType > 0 ? [HealthProfileData descriptionForUnderwearType:setting.underwearType] : @"Choose";
    }
    else if ([self.key isEqual:kHealthProfileItemHouseholdIncome]) {
        self.details = setting.householdIncome > 0 ? [HealthProfileData descriptionForHouseholdIncome:setting.householdIncome] : @"Choose";
    }
    else if ([self.key isEqual:kHealthProfileItemHomeZipcode]) {
        self.details = setting.homeZipcode.length ? setting.homeZipcode : @" ";
    }
    else {
        self.details = @" ";
    }
}


- (void)configureCell:(UITableViewCell *)cell
{
    [self updateDetails];
    cell.textLabel.text = self.key;
    cell.detailTextLabel.text = self.details;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    if ([self.key isEqualToString:kHealthProfileItemGender]) {
        cell.imageView.image = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    else if ([self.key isEqualToString:kHealthProfileItemExportDataReport]) {
        cell.imageView.image = [UIImage imageNamed:@"me-pdf"];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        cell.imageView.image = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (IS_IPHONE_4 || IS_IPHONE_5) {
        if ([self.details isEqualToString:[HealthProfileData ethnicityOptions][EthnicityTypeAmericanNative]]) {
            cell.detailTextLabel.font = [Utils defaultFont:13];
        }
        else {
            cell.detailTextLabel.font = [Utils defaultFont:16];
        }
    }
}



@end
