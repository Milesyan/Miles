//
//  HealthProfileDataSource.m
//  emma
//
//  Created by Peng Gu on 10/11/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "HealthProfileDataController.h"
#import "HealthProfileItem.h"
#import "HealthProfileData.h"
#import "User.h"

@interface HealthProfileDataController ()

@property (nonatomic, strong) NSDictionary *items;

@end


@implementation HealthProfileDataController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self reloadItems];
    }
    return self;
}


- (void)reloadItems
{
    self.items = [HealthProfileDataController itemsForCurrentStatus];
}


#pragma mark - items
+ (CGFloat)completionRate
{
    NSDictionary *items = [self itemsForCurrentStatus];
    
    CGFloat count = 0;
    CGFloat total = 0;
    for (NSNumber *key in items) {
        NSArray *itemsInSection = items[key];
        count += [[itemsInSection valueForKeyPath:@"@sum.completions"] integerValue];
        total += itemsInSection.count;
    }
    
    // for extra items in pregnancy history
    // Now, there are 5 items in pregnancy history, so we need add 4 more
    if ([User currentUser].isPrimaryOrSingleMom) {
        total += 4;
    }
    
    NSLog(@"%f, %f, %f", count, total, count / total);
    return MIN(count / total, 1) ;
}


+ (NSDictionary *)itemsForCurrentStatus
{
    User *user = [User currentUser];
    
    if ([user.gender isEqual:MALE]) {
        return @{
                 @(0):@[
                         [HealthProfileItem itemWithKey:kHealthProfileItemBirthDate],
                         [HealthProfileItem itemWithKey:kHealthProfileItemGender],
                         [HealthProfileItem itemWithKey:kHealthProfileItemEthnicity],
                         [HealthProfileItem itemWithKey:kHealthProfileItemHeight],
                         [HealthProfileItem itemWithKey:kHealthProfileItemWaist],
                         [HealthProfileItem itemWithKey:kHealthProfileItemPhysicalActivity]],
                 
                 @(1):@[
                         [HealthProfileItem itemWithKey:kHealthProfileItemDiagnosedCondition],
                         [HealthProfileItem itemWithKey:kHealthProfileItemInfertilityDiagnosis],
                         //                            [HealthProfileItem itemWithKey:kHealthProfileItemTesterone],
                         [HealthProfileItem itemWithKey:kHealthProfileItemUnderwearType]],
                 
                 @(2):@[
                         [HealthProfileItem itemWithKey:kHealthProfileItemOccupation],
                         [HealthProfileItem itemWithKey:kHealthProfileItemHouseholdIncome],
                         [HealthProfileItem itemWithKey:kHealthProfileItemInsurance],
                         [HealthProfileItem itemWithKey:kHealthProfileItemHomeZipcode]],
                 };
    }
    
    if (user.isSecondary && user.isFemale) {
        return @{
                 @(0):@[
                         [HealthProfileItem itemWithKey:kHealthProfileItemBirthDate],
                         [HealthProfileItem itemWithKey:kHealthProfileItemGender]]
                 };
    }
    
    Settings *setting = [User currentUser].settings;
    int16_t status = setting.currentStatus == AppPurposesAlreadyPregnant ? setting.previousStatus : setting.currentStatus;
    
    if (status == AppPurposesTTCWithTreatment) {
        return  @{     @(0): [self sexItems],
                       @(1): [self fertilityItems],
                       @(2): [self cycleItems],
                       @(3): [self conditionItems],
                       @(4): [self workItems],
                       @(5): [self generalItems]};
    }
    else if (status == AppPurposesTTC || status == AppPurposesAlreadyPregnant) {
        return @{      @(0): [self sexItems],
                       @(1): [self cycleItems],
                       @(2): [self conditionItems],
                       @(3): [self workItems],
                       @(4): [self generalItems]};
    }
    else {
        return  @{     @(0): [self cycleItems],
                       @(1): [self sexItems],
                       @(2): [self conditionItems],
                       @(3): [self workItems],
                       @(4): [self generalItems]};
    }
}


+ (NSArray *)cycleItems
{
    return @[[HealthProfileItem itemWithKey:kHealthProfileItemCycleLength],
             [HealthProfileItem itemWithKey:kHealthProfileItemPeriodLength],
             [HealthProfileItem itemWithKey:kHealthProfileItemCycleRegularity]];
}


+ (NSArray *)sexItems
{
    Settings *setting = [User currentUser].settings;
    int16_t status = (setting.currentStatus == AppPurposesAlreadyPregnant) ? setting.previousStatus : setting.currentStatus;
    NSMutableArray *items = [NSMutableArray array];
    if (status == AppPurposesAvoidPregnant || status == AppPurposesNormalTrack) {
        [items addObject:[HealthProfileItem itemWithKey:kHealthProfileItemBirthControl]];
        if ((setting.birthControl != SETTINGS_BC_NONE) &&
            (setting.birthControl != SETTINGS_BC_NO_ANSWER)) {
            [items addObject:[HealthProfileItem itemWithKey:kHealthProfileItemBirthControlStart]];
        };
        [items addObject:[HealthProfileItem itemWithKey:kHealthProfileItemRelationshipStatus]];
        [items addObject:[HealthProfileItem itemWithKey:kHealthProfileItemConsidering]];
    }
    else {
        [items addObject:[HealthProfileItem itemWithKey:kHealthProfileItemTTCStart]];
        [items addObject:[HealthProfileItem itemWithKey:kHealthProfileItemTryingFor]];
        [items addObject:[HealthProfileItem itemWithKey:kHealthProfileItemRelationshipStatus]];
    }
    
    if (setting.relationshipStatus == RelationshipStatusInRelationship ||
        setting.relationshipStatus == RelationshipStatusEngaged ||
        setting.relationshipStatus == RelationshipStatusMarried) {
        [items addObject:[HealthProfileItem itemWithKey:kHealthProfileItemPartnerErection]];
    }
    return items;
}


+ (NSArray *)conditionItems
{
    return @[[HealthProfileItem itemWithKey:kHealthProfileItemDiagnosedCondition],
             [HealthProfileItem itemWithKey:kHealthProfileItemPregnancyHistory]];
}


+ (NSArray *)workItems
{
    return @[[HealthProfileItem itemWithKey:kHealthProfileItemOccupation],
             [HealthProfileItem itemWithKey:kHealthProfileItemInsurance]];
}


+ (NSArray *)generalItems
{
    return @[ [HealthProfileItem itemWithKey:kHealthProfileItemPhysicalActivity],
              [HealthProfileItem itemWithKey:kHealthProfileItemEthnicity],
              [HealthProfileItem itemWithKey:kHealthProfileItemBirthDate],
              [HealthProfileItem itemWithKey:kHealthProfileItemHeight]];
}


+ (NSArray *)fertilityItems
{
    Settings *setting = [User currentUser].settings;
    int16_t status = (setting.currentStatus == AppPurposesAlreadyPregnant) ? setting.previousStatus : setting.currentStatus;
    
    if (status != AppPurposesTTCWithTreatment) {
        return @[];
    }

    int16_t treatment = setting.fertilityTreatment;
    if (treatment == FertilityTreatmentTypeIVF || treatment == FertilityTreatmentTypeIUI) {
        return @[
                 [HealthProfileItem itemWithKey:kHealthProfileItemSpermOrEggDonation],
                 [HealthProfileItem itemWithKey:kHealthProfileItemInfertilityDiagnosis]];
    }
    
    return @[
             [HealthProfileItem itemWithKey:kHealthProfileItemInfertilityDiagnosis]];
}


+ (NSArray *)miscItems
{
    return @[[HealthProfileItem itemWithKey:kHealthProfileItemExportDataReport]];
}


#pragma mark -
- (NSArray *)itemsInSection:(NSUInteger)section
{
    if (section < self.items.count) {
        return self.items[@(section)];
    }
    return @[];
}


- (NSUInteger)numberOfSections
{
    return self.items.count;
}


- (NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    return [[self itemsInSection:section] count];
}


- (HealthProfileItem *)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self itemsInSection:indexPath.section] objectAtIndex:indexPath.row];
}


@end









