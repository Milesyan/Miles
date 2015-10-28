//
//  SettingsData.m
//  emma
//
//  Created by Jirong Wang on 4/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "HealthProfileData.h"
#import "User.h"

@implementation HealthProfileData


#pragma mark - trying for children
+ (NSArray *)tryingForChildrenOptions
{
    return @[@"", @"1st", @"2nd", @"3rd", @"4th", @"5th", @"6th", @"7th", @"8th", @"9th", @"10th"];
}


+ (NSString *)descriptionForChildrenNumber:(NSInteger)number
{
    if (number < 0) {
        return @"Choose";
    }
    else {
        return @(number).stringValue;
    }
}


#pragma mark - infertility Causes
+ (NSArray *)infertilityCausesOptions
{
    NSArray *options = @[@"Polycystic ovary syndrome (PCOS)", @"Ovulation disorder", @"Endometriosis", @"Uterine or cervical abnormalities", @"Fallopian tube damage or blockage", @"Primary ovarian insufficiency", @"Pelvic adhesions", @"Thyroid problems", @"Cancer and its treatment", @"Male tube blockages", @"Sperm problems", @"Sperm allergy", @"Combination infertility", @"Unexplained"];
    
    NSArray *maleOptions = @[@"Prior vasectomy", @"Major abdominal or pelvic surgery", @"Male tube blockages", @"Erectile dysfunction", @"Premature ejaculation", @"Retrograte ejaculation", @"Autoimmune disorder", @"Undescended testicles", @"Hormone imbalance/disorder", @"Cancer and its treatment", @"Infections/diseases", @"Testicular trauma or torsion", @"Sperm disorder", @"Sperm allergy", @"Combination infertility", @"Unexplained",];
    
    return [User currentUser].isMale ? maleOptions : options;
}


+ (NSIndexSet *)indexSetForInfertilityCausesValue:(int64_t)value
{
    BOOL isMale = [User currentUser].isMale;
    int start = isMale ? InfertilityCauseTypeMaleEnumStart : InfertilityCauseTypeEnumStart;
    int end = isMale ? InfertilityCauseTypeMaleEnumEnd : InfertilityCauseTypeEnumEnd;
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (int i = start; i < end; i++) {
        if ((value & (1 << i)) > 0) {
            [indexSet addIndex:(i-start)];
        }
    }
    return indexSet;
}


+ (int64_t)valueForInfertilityCausesInIndexSet:(NSIndexSet *)indexSet
{
    BOOL isMale = [User currentUser].isMale;
    int start = isMale ? InfertilityCauseTypeMaleEnumStart : InfertilityCauseTypeEnumStart;

    __block int64_t value = 0;
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        value = value | (1 << (idx+start));
    }];
    return value;
}


+ (NSUInteger)numberOfInfertilityCausesForValue:(int64_t)value
{
    return [[HealthProfileData indexSetForInfertilityCausesValue:value] count];
}


#pragma mark - health conditions
+ (NSArray *)diagnosedConditionOptions
{
    NSArray *options = @[@"None", @"Ovarian cyst(s)", @"PCOS", @"Endometriosis", @"HPV", @"Uterine polyps", @"Uterine fibroids", @"Pelvic inflammatory disease", @"Hormonal imbalance", @"Advanced ovarian aging", @"Blocked tubes", @"Anemia", @"Diabetes", @"Hypertension", @"Irritable Bowel Syndrome", @"Chronic migraines", @"Cancer and its treatment"];
    
    NSArray *maleOptions = @[@"None", @"Celiac disease", @"Early onset or delayed puberty", @"Hernia repair", @"Ulcers/psoriasis prescription drugs", @"Liver/renal disease or treatment", @"Mumps after puberty", @"Genetic disorders", @"Cardiovascular disease", @"Diabetes", @"Depression",];
    
    return [User currentUser].isMale ? maleOptions : options;
}


+ (NSIndexSet *)indexSetForDiagnosedConditionsValue:(int64_t)value
{
    BOOL isMale = [User currentUser].isMale;
    int start = isMale ? DiagnosedConditionsMaleEnumStart : DiagnosedConditionsEnumStart;
    int end = isMale ? DiagnosedConditionsMaleEnumEnd : DiagnosedConditionsEnumEnd;
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (int i = start; i < end; i++) {
        if ((value & (1 << i)) > 0) {
            [indexSet addIndex:(i-start)];
        }
    }
    return indexSet;
}


+ (int64_t)valueForDiagnosedConditionsInIndexSet:(NSIndexSet *)indexSet
{
    BOOL isMale = [User currentUser].isMale;
    int start = isMale ? DiagnosedConditionsMaleEnumStart : DiagnosedConditionsEnumStart;
    
    __block int64_t value = 0;
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        value = value | (1 << (idx+start));
    }];
    return value;
}


+ (NSArray *)diagnosedConditionsForValue:(int64_t)value
{
    BOOL isMale = [User currentUser].isMale;
    int start = isMale ? DiagnosedConditionsMaleEnumStart : DiagnosedConditionsEnumStart;
    int end = isMale ? DiagnosedConditionsMaleEnumEnd : DiagnosedConditionsEnumEnd;
    
    NSMutableArray *conditions = [NSMutableArray array];
    for (int i = start; i < end; i++) {
        DiagnosedCondition condition = (1 << i);
        if ((value & condition) > 0) {
            [conditions addObject:@(condition)];
        }
    }
    return conditions;
}


+ (NSUInteger)numberOfDiagnosedConditionsForValue:(int64_t)value
{
    return [[HealthProfileData diagnosedConditionsForValue:value] count];
}


#pragma mark - insurance
+ (NSString *)descriptionForInsuranceType:(InsuranceType)type
{
    NSInteger index = [self indexForInsuranceType:type];
    return [self insuranceOptions][index];
}


+ (NSArray *)insuranceOptions
{
    return @[@"", @"HMO/EPO", @"PPO/POS", @"High Deductible with HSA", @"Medicare / Medicaid", @"Other", @"None"];
}

+ (NSInteger)indexForInsuranceType:(InsuranceType)type
{
    NSInteger index = type;
    if (type == InsuranceTypeOther || type == InsuranceTypeNone) {
        index += 2;
    }
    else if (type == InsuranceTypeHSA || type == InsuranceTypeMedicare) {
        index -= 2;
    }
    return index;
}

+ (InsuranceType)insuranceTypeForIndex:(NSInteger)index
{
    InsuranceType type = index;
    if (index == 5 || index == 6) {
        type -= 2;
    }
    else if (index == 3 || index == 4) {
        type += 2;
    }
    return type;
}


#pragma mark - Ethnicity
+ (NSArray *)ethnicityOptions
{
    return @[@"", @"American Indian / Alaskan Native", @"Asian / Pacific Islander",
             @"Black / African American", @"Hispanic / Latino", @"White / Caucasian", @"Other"];
}


+ (NSString *)descriptionForEthnicity:(EthnicityType)type
{
    return [self ethnicityOptions][type];
}


#pragma mark - testerone
+ (NSArray *)testerOptions
{
    return @[@"", @"Yes", @"No", @"I don't know"];
}


+ (NSString *)descriptionForTesterone:(Testerone)type
{
    return [self testerOptions][type];
}


#pragma mark - underwear 
+ (NSArray *)underwearOptions
{
    return @[@"", @"Boxers", @"Briefs", @"Boxer-briefs", @"Combination of the above", @"Other", @"None"];
}


+ (NSString *)descriptionForUnderwearType:(UnderwearType)type
{
    if (type == UnderwearTypeCombination) {
        return @"Combination";
    }
    
    return [self underwearOptions][type];
}


#pragma mark - household income
+ (NSArray *)householdIncomeOptions
{
    return @[@"", @"Up to $9,075", @"$9,076 to $36,900",
             @"$36,901 to $89,350", @"$89,351 to $186,350", @"$186,351 to $405,100",
             @"$405,101 to $406,750", @"$406,751 or more"];
}


+ (NSString *)descriptionForHouseholdIncome:(HouseholdIncome)type
{
    return [self householdIncomeOptions][type];
}


#pragma mark - occupation

+ (NSArray *)occupationOptions
{
    return @[@"", @"Employed", @"Self-employed", @"Homemaker", @"Unemployed", @"Student", @"Retired"];
}


#pragma mark - erection difficulty
+ (NSString *)descriptionForErectionDifficulty:(ErectionDifficulty)type
{
    switch (type) {
        case ErectionDifficultyNo:
            return @"No";
        case ErectionDifficultyOccasionally:
            return @"Occasionally";
        case ErectionDifficultyYES:
            return @"Yes";
        default:
            return nil;
    }
}


+ (NSArray *)erectionDifficultyOptions
{
    return @[@"", @"No", @"Occasionally", @"Yes"];
}


#pragma mark - relationship status
+ (NSString *)descriptionForRelationshipStatus:(RelationshipStatus)type
{
    switch (type) {
        case RelationshipStatusEngaged:
            return @"Engaged";
        case RelationshipStatusInRelationship:
            return @"In a relationship";
        case RelationshipStatusMarried:
            return @"Married";
        case RelationshipStatusSingle:
            return @"Single";
        default:
            return nil;
    }
}

+ (NSArray *)relationshipStatusOptions
{
    return @[@"", @"Single", @"In a relationship", @"Engaged", @"Married"];
}


#pragma mark - cycle regularity
+ (NSString *)descriptionForCycleRegularity:(CycleRegularity)type
{
    switch (type) {
        case CycleRegularityLessThan5days:
            return @"Regular";
        case CycleRegularity5daysTo15days:
            return @"Irregular";
        case CycleRegularityMoreThan15days:
            return @"Very Irregular";
        case CycleRegularityNotSure:
            return @"Not sure";
        default:
            return nil;
    }
}


+ (NSArray *)cycleRegularityOptions
{
    return @[@"", @"Regular (variation < 5 days)", @"Irregular (5-15 days)", @"Very Irregular (> 15 days)", @"I'm not sure"];
}

#pragma mark - fertility treatment 
+ (NSArray *)fertilityTreatmentOptions
{
    return @[@"", @"Natural with medications", @"Start new In Vitro Fertilization", @"Start new Intrauterine Insemination"];
}

+ (NSString *)descriptionForFertilityTreatmentType:(FertilityTreatmentType)type
{
    if (type == FertilityTreatmentTypeMedications) {
        return @"Natural with Medications";
    }
    else if (type == FertilityTreatmentTypeIVF) {
        return @"In Vitro Fertilization (IVF)";
    }
    else if (type == FertilityTreatmentTypeIUI) {
        return @"Intrauterine Insemination (IUI)";
    }
    else {
        return @"";
    }
}

+ (NSString *)shortDescriptionForFertilityTreatmentType:(FertilityTreatmentType)type
{
    if (type == FertilityTreatmentTypeMedications) {
        return @"Med";
    }
    else if (type == FertilityTreatmentTypeIVF) {
        return @"IVF";
    }
    else if (type == FertilityTreatmentTypeIUI) {
        return @"IUI";
    }
    else if (type == FertilityTreatmentTypePreparing) {
        return @"Prep";
    }
    else {
        return @"";
    }
}

#pragma mark - 
+ (NSArray *)spermOrEggDonationOptions
{
    return @[@"", @"Sperm donation", @"Egg donation", @"Both", @"Neither"];
}


+ (NSString *)descriptionForSpermOrEggDonation:(SpermOrEggDonationType)type
{
    if (type == SpermOrEggDonationTypeSpermDonation) {
        return @"Sperm";
    }
    else if (type == SpermOrEggDonationTypeEggDonation) {
        return @"Egg";
    }
    else if (type == SpermOrEggDonationTypeBoth) {
        return @"Both";
    }
    else if (type == SpermOrEggDonationTypeNeither) {
        return @"Neither";
    }
    
    return @"";
}

#pragma mark - Considering (for !TTC)
+ (NSDictionary *)consideringNames {
    return @{
             @(SETTINGS_CONSIDERING_NO_ANSWER): @"(Choose)",
             @(SETTINGS_CONSIDERING_UNDECIDED): @"I’m undecided",
             @(SETTINGS_CONSIDERING_12_MONTHS): @"In the next 12 months",
             @(SETTINGS_CONSIDERING_LATER): @"Later in the future",
             @(SETTINGS_CONSIDERING_NEVER): @"No, never"
             };
}

+ (NSDictionary *)consideringShortNames {
    return @{
             @(SETTINGS_CONSIDERING_NO_ANSWER): @"Choose",
             @(SETTINGS_CONSIDERING_UNDECIDED): @"Undecided",
             @(SETTINGS_CONSIDERING_12_MONTHS): @"12 months",
             @(SETTINGS_CONSIDERING_LATER): @"Later",
             @(SETTINGS_CONSIDERING_NEVER): @"Never"
             };
}

+ (NSArray *)consideringKeys {
    return @[
             @(SETTINGS_CONSIDERING_NO_ANSWER),
             @(SETTINGS_CONSIDERING_UNDECIDED),
             @(SETTINGS_CONSIDERING_12_MONTHS),
             @(SETTINGS_CONSIDERING_LATER),
             @(SETTINGS_CONSIDERING_NEVER)
             ];
}

+ (NSArray *)consideringItems {
    NSMutableArray * dict = [[NSMutableArray alloc] init];
    for (NSNumber * x in [HealthProfileData consideringKeys]) {
        [dict addObject:[[HealthProfileData consideringNames] objectForKey:x]];
    }
    
    return dict;
}

#pragma mark - Birth control
+ (NSDictionary *)birthControlNames {
    return @{
             @(SETTINGS_BC_CONDOM): @"Condom",
             @(SETTINGS_BC_WITHDRAWAL): @"Withdrawal",
             @(SETTINGS_BC_FAM): @"Fertility awareness method",
             @(SETTINGS_BC_PILL): @"Pill",
             @(SETTINGS_BC_IUD): @"IUD",
             @(SETTINGS_BC_IMPLANT): @"Implant",
             @(SETTINGS_BC_VAGINAL_RING): @"Vaginal ring",
             @(SETTINGS_BC_SHOT): @"Shot",
             
             @(SETTINGS_BC_PATCH):         	@"Patch",
             @(SETTINGS_BC_TUBAL_LIGATION):	@"Tubal ligation",
             @(SETTINGS_BC_DIAPHRAGM):     	@"Diaphragm",
             @(SETTINGS_BC_CERVICAL_CAP):  	@"Cervical cap",
             @(SETTINGS_BC_SPONGE):        	@"Sponge",
             @(SETTINGS_BC_FEMALE_CONDOM): 	@"Female condom",
             @(SETTINGS_BC_SPERMICIDE):    	@"Spermicide",
             @(SETTINGS_BC_ABSTINENCE):    	@"Abstinence",
             @(SETTINGS_BC_NONE):  @"None",
             };
}

+ (NSDictionary *)birthControlShortNames {
    return @{
             @(SETTINGS_BC_CONDOM): @"Condom",
             @(SETTINGS_BC_WITHDRAWAL): @"Withdrawal",
             @(SETTINGS_BC_FAM): @"FAM",
             @(SETTINGS_BC_PILL): @"Pill",
             @(SETTINGS_BC_IUD): @"IUD",
             @(SETTINGS_BC_IMPLANT): @"Implant",
             @(SETTINGS_BC_VAGINAL_RING): @"Vaginal ring",
             @(SETTINGS_BC_SHOT): @"Shot",
             
             @(SETTINGS_BC_PATCH):         	@"Patch",
             @(SETTINGS_BC_TUBAL_LIGATION):	@"Tubes tied",
             @(SETTINGS_BC_DIAPHRAGM):     	@"Diaphragm",
             @(SETTINGS_BC_CERVICAL_CAP):  	@"Cervical cap",
             @(SETTINGS_BC_SPONGE):        	@"Sponge",
             @(SETTINGS_BC_FEMALE_CONDOM): 	@"F. condom",
             @(SETTINGS_BC_SPERMICIDE):    	@"Spermicide",
             @(SETTINGS_BC_ABSTINENCE):    	@"Abstinence",
             @(SETTINGS_BC_NONE):  @"None",
             };
}

+ (NSArray *)birthControlKeys {
    return @[
                @(SETTINGS_BC_CONDOM),
                @(SETTINGS_BC_WITHDRAWAL),
                @(SETTINGS_BC_PILL),
                @(SETTINGS_BC_IMPLANT),
                @(SETTINGS_BC_IUD),
                @(SETTINGS_BC_VAGINAL_RING),
                @(SETTINGS_BC_PATCH),
                @(SETTINGS_BC_SHOT),
                @(SETTINGS_BC_SPERMICIDE),
                @(SETTINGS_BC_TUBAL_LIGATION),
                @(SETTINGS_BC_DIAPHRAGM),
                @(SETTINGS_BC_SPONGE),
                @(SETTINGS_BC_CERVICAL_CAP),
                @(SETTINGS_BC_FEMALE_CONDOM),
                @(SETTINGS_BC_FAM),
                @(SETTINGS_BC_ABSTINENCE),
                @(SETTINGS_BC_NONE),
             ];
}

+ (NSArray *)birthControlItems {
    
    NSMutableArray * dict = [[NSMutableArray alloc] init];
    for (NSNumber * x in [HealthProfileData birthControlKeys]) {
        [dict addObject:[[HealthProfileData birthControlNames] objectForKey:x]];
    }
    
    return dict;
}


@end

