//
//  HealthProfileItem.h
//  emma
//
//  Created by Peng Gu on 10/13/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

/* 
 * we need restructure this file
 * It should be a config file like "settings. So, everytime you want 
 * to add a new one to health profile, it should be a config change
 */

#import <Foundation/Foundation.h>

#define kHealthProfileItemCycleLength @"Default or initial cycle length"
#define kHealthProfileItemPeriodLength @"Average period length"
#define kHealthProfileItemCycleRegularity @"Cycle regularity"
#define kHealthProfileItemDiagnosedCondition @"Health conditions"
#define kHealthProfileItemPregnancyHistory @"History of previous pregnancies"
#define kHealthProfileItemBirthControl @"Birth control"
#define kHealthProfileItemBirthControlStart @"Birth control start date"
#define kHealthProfileItemRelationshipStatus @"Relationship status"
#define kHealthProfileItemPartnerErection @"Partner erectile dysfunction?"
#define kHealthProfileItemPhysicalActivity @"Physical activity"
#define kHealthProfileItemEthnicity @"Ethnicity"
#define kHealthProfileItemGender @"Gender"
#define kHealthProfileItemBirthDate @"Birth Date"
#define kHealthProfileItemHeight @"Height"
#define kHealthProfileItemOccupation @"Occupation"
#define kHealthProfileItemInsurance @"Insurance"
#define kHealthProfileItemTTCStart @"How long have you been TTC?"
#define kHealthProfileItemTryingFor @"How many children?"
#define kHealthProfileItemInfertilityDiagnosis @"Diagnosed infertility causes"
#define kHealthProfileItemSpermOrEggDonation @"Sperm/Egg Donation?"
#define kHealthProfileItemExportDataReport @"Export Data Report"
#define kHealthProfileItemConsidering @"Consider conceiving"

// Partner
#define kHealthProfileItemWaist @"Waist size"
#define kHealthProfileItemTesterone @"Testosterone"
#define kHealthProfileItemUnderwearType @"Underwear Type"
#define kHealthProfileItemHouseholdIncome @"Household Income"
#define kHealthProfileItemHomeZipcode @"Home Zipcode"


@interface HealthProfileItem : NSObject

@property (nonatomic, assign, readonly) NSUInteger completions;

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *details;

+ (instancetype)itemWithKey:(NSString *)key;
- (void)configureCell:(UITableViewCell *)cell;

@end
