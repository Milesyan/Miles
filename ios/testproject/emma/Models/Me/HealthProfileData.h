//
//  SettingsData.h
//  emma
//
//  Created by Jirong Wang on 4/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

// birth control value can not be changed,
// added in v3.5
#define SETTINGS_BC_NO_ANSWER             -1
#define SETTINGS_BC_NONE                   0
#define SETTINGS_BC_CONDOM                 1
#define SETTINGS_BC_WITHDRAWAL             2
#define SETTINGS_BC_FAM                    3
#define SETTINGS_BC_PILL                   4
#define SETTINGS_BC_IUD                    5
#define SETTINGS_BC_IMPLANT                6
#define SETTINGS_BC_VAGINAL_RING           7
#define SETTINGS_BC_SHOT                   8
#define SETTINGS_BC_PATCH         		   9
#define SETTINGS_BC_TUBAL_LIGATION		  10
#define SETTINGS_BC_DIAPHRAGM     		  11
#define SETTINGS_BC_CERVICAL_CAP  		  12
#define SETTINGS_BC_SPONGE        		  13
#define SETTINGS_BC_FEMALE_CONDOM 		  14
#define SETTINGS_BC_SPERMICIDE    		  15
#define SETTINGS_BC_ABSTINENCE    		  16

#define DAYS_AFTER_TREATMENT_CAN_PERIOD     21 // cycle day 22

#define SETTINGS_CONSIDERING_NO_ANSWER      0
#define SETTINGS_CONSIDERING_UNDECIDED      1
#define SETTINGS_CONSIDERING_12_MONTHS      2
#define SETTINGS_CONSIDERING_LATER          3
#define SETTINGS_CONSIDERING_NEVER          4

typedef NS_ENUM(NSUInteger, CycleRegularity) {
    CycleRegularityLessThan5days  = 1,
    CycleRegularity5daysTo15days  = 2,
    CycleRegularityMoreThan15days = 3,
    CycleRegularityNotSure        = 4
};


// diagnosed condition actually means health condition due to history reasons,
#define DiagnosedConditionsEnumStart 0
#define DiagnosedConditionsEnumEnd 17
typedef NS_ENUM(NSUInteger, DiagnosedCondition) {
    DiagnosedConditionNone                      = 1 << 0,
    DiagnosedConditionOvarianCyst               = 1 << 1,
    DiagnosedConditionPCOS                      = 1 << 2,
    DiagnosedConditionEndometriosis             = 1 << 3,
    DiagnosedConditionHPV                       = 1 << 4,
    DiagnosedConditionUterinePolyps             = 1 << 5,
    DiagnosedConditionUterineFibroids           = 1 << 6,
    DiagnosedConditionPelvicInflammatoryDisease = 1 << 7,
    DiagnosedConditionHormonalImbalance         = 1 << 8,
    DiagnosedConditionAdvancedOvarianAging      = 1 << 9,
    DiagnosedConditionBlockedTubes              = 1 << 10,
    DiagnosedConditionAnemia                    = 1 << 11,
    DiagnosedConditionDiabetes                  = 1 << 12,
    DiagnosedConditionHypertension              = 1 << 13,
    DiagnosedConditionIrritableBowelSyndrome    = 1 << 14,
    DiagnosedConditionChronicMigraines          = 1 << 15,
    DiagnosedConditionCancerAndItsTreatment     = 1 << 16,
};

#define DiagnosedConditionsMaleEnumStart 0
#define DiagnosedConditionsMaleEnumEnd 11
typedef NS_ENUM(NSUInteger, DiagnosedConditionPartner) {
    DiagnosedConditionPartnerNone                  = 1 << 0,
    DiagnosedConditionPartnerCeliacDisease         = 1 << 1,
    DiagnosedConditionPartnerEarlyOnset            = 1 << 2,
    DiagnosedConditionPartnerHerniaRepair          = 1 << 3,
    DiagnosedConditionPartnerUlcers                = 1 << 4,
    DiagnosedConditionPartnerSeizureDisorders      = 1 << 5,
    DiagnosedConditionPartnerMumps                 = 1 << 6,
    DiagnosedConditionPartnerGeneticDisorders      = 1 << 7,
    DiagnosedConditionPartnerCardiovascularDisease = 1 << 8,
    DiagnosedConditionPartnerDiabetes              = 1 << 9,
    DiagnosedConditionPartnerDepression            = 1 << 10,
};


// infertility causes actually means diagnosed conditions due to history reasons
#define InfertilityCauseTypeEnumStart 1
#define InfertilityCauseTypeEnumEnd 15
typedef NS_ENUM(NSUInteger, InfertilityCauseType) {
    InfertilityCauseTypePolycysticOvarySyndrome        = 1 << 1,
    InfertilityCauseTypeOvulationDisorder              = 1 << 2,
    InfertilityCauseTypeEndometriosis                  = 1 << 3,
    InfertilityCauseTypeUterineOrCervicalAbnormalities = 1 << 4,
    InfertilityCauseTypeFallopianTubeDamage            = 1 << 5,
    InfertilityCauseTypePrimaryOvarianInsufficiency    = 1 << 6,
    InfertilityCauseTypePelvicAdhesions                = 1 << 7,
    InfertilityCauseTypeThyroidProblems                = 1 << 8,
    InfertilityCauseTypeCancerAndItsTreatment          = 1 << 9,
    InfertilityCauseTypeMaleTubeBlockages              = 1 << 10,
    InfertilityCauseTypeSpermProblems                  = 1 << 11,
    InfertilityCauseTypeSpermAllergy                   = 1 << 12,
    InfertilityCauseTypeCombinationInfertility         = 1 << 13,
    InfertilityCauseTypeUnexplained                    = 1 << 14,
};


#define InfertilityCauseTypeMaleEnumStart 1
#define InfertilityCauseTypeMaleEnumEnd 17
typedef NS_ENUM(NSUInteger, InfertilityCauseTypePartner) {
    InfertilityCauseTypePartnerPriorVasectomy         = 1 << 1,
    InfertilityCauseTypePartnerMajorAbdominal         = 1 << 2,
    InfertilityCauseTypePartnerMaleTubeBlockages      = 1 << 3,
    InfertilityCauseTypePartnerErectileDysfunction    = 1 << 4,
    InfertilityCauseTypePartnerPrematureEjaculation   = 1 << 5,
    InfertilityCauseTypePartnerRetrograteEjaculation  = 1 << 6,
    InfertilityCauseTypePartnerAutoimmuneDisorder     = 1 << 7,
    InfertilityCauseTypePartnerUndescendedTesticles   = 1 << 8,
    InfertilityCauseTypePartnerHormoneImbalance       = 1 << 9,
    InfertilityCauseTypePartnerCancer                 = 1 << 10,
    InfertilityCauseTypePartnerInfections             = 1 << 11,
    InfertilityCauseTypePartnerTesticularTrauma       = 1 << 12,
    InfertilityCauseTypePartnerSpermDisorder          = 1 << 13,
    InfertilityCauseTypePartnerSpermAllergy           = 1 << 14,
    InfertilityCauseTypePartnerCombinationInfertility = 1 << 15,
    InfertilityCauseTypePartnerUnexplained            = 1 << 16,
};


typedef NS_ENUM(NSUInteger, Testerone) {
    TesteroneYES = 1,
    TesteroneNO = 2,
    TesteroneDonotKnow = 3,
};


typedef NS_ENUM(NSUInteger, UnderwearType) {
    UnderwearTypeBoxers      = 1,
    UnderwearTypeBriefs      = 2,
    UnderwearTypeBoxerBriefs = 3,
    UnderwearTypeCombination = 4,
    UnderwearTypeOther       = 5,
    UnderwearTypeNone        = 6,
};


typedef NS_ENUM(NSUInteger, HouseholdIncome) {
    HouseholdIncomeLevelOne   = 1,
    HouseholdIncomeLevelTwo   = 2,
    HouseholdIncomeLevelThree = 3,
    HouseholdIncomeLevelFour  = 4,
    HouseholdIncomeLevelFive  = 5,
    HouseholdIncomeLevelSix   = 6,
    HouseholdIncomeLevelSeven = 7,
};


typedef NS_ENUM(NSUInteger, RelationshipStatus) {
    RelationshipStatusSingle = 1,
    RelationshipStatusInRelationship = 2,
    RelationshipStatusEngaged = 3,
    RelationshipStatusMarried = 4
};


typedef NS_ENUM(NSUInteger, ErectionDifficulty) {
    ErectionDifficultyNo = 1,
    ErectionDifficultyOccasionally = 2,
    ErectionDifficultyYES = 3
};


typedef NS_ENUM(NSUInteger, InsuranceType) {
    InsuranceTypeHMOAndEPO = 1,
    InsuranceTypePPOAndPOS = 2,
    InsuranceTypeOther = 3,
    InsuranceTypeNone = 4,
    InsuranceTypeHSA = 5,
    InsuranceTypeMedicare = 6,
};


typedef NS_ENUM(NSUInteger, FertilityTreatmentType) {
    FertilityTreatmentTypeMedications = 1,
    FertilityTreatmentTypeIUI = 2,
    FertilityTreatmentTypeIVF = 3,
    FertilityTreatmentTypePreparing = 4,
};


typedef NS_ENUM(NSUInteger, SpermOrEggDonationType) {
    SpermOrEggDonationTypeNone = 0,
    SpermOrEggDonationTypeSpermDonation = 1,
    SpermOrEggDonationTypeEggDonation = 2,
    SpermOrEggDonationTypeBoth = 3,
    SpermOrEggDonationTypeNeither = 4,
};


typedef NS_ENUM(NSUInteger, EthnicityType) {
    EthnicityTypeNone   = 0,
    EthnicityTypeAmericanNative = 1,
    EthnicityTypeAsian = 2,
    EthnicityTypeBlack = 3,
    EthnicityTypeHispanic = 4,
    EthnicityTypeWhite = 5,
    EthnicityTypeOther = 6
};


@interface HealthProfileData : NSObject

+ (NSArray *)cycleRegularityOptions;
+ (NSArray *)relationshipStatusOptions;
+ (NSArray *)erectionDifficultyOptions;
+ (NSArray *)occupationOptions;
+ (NSArray *)insuranceOptions;
+ (NSArray *)tryingForChildrenOptions;
+ (NSArray *)spermOrEggDonationOptions;
+ (NSArray *)ethnicityOptions;
+ (NSArray *)testerOptions;
+ (NSArray *)underwearOptions;
+ (NSArray *)householdIncomeOptions;

+ (NSString *)descriptionForChildrenNumber:(NSInteger)number;
+ (NSString *)descriptionForInsuranceType:(InsuranceType)type;
+ (NSString *)descriptionForErectionDifficulty:(ErectionDifficulty)type;
+ (NSString *)descriptionForRelationshipStatus:(RelationshipStatus)type;
+ (NSString *)descriptionForCycleRegularity:(CycleRegularity)type;
+ (NSString *)descriptionForFertilityTreatmentType:(FertilityTreatmentType)type;
+ (NSString *)shortDescriptionForFertilityTreatmentType:(FertilityTreatmentType)type;
+ (NSString *)descriptionForSpermOrEggDonation:(SpermOrEggDonationType)type;
+ (NSString *)descriptionForEthnicity:(EthnicityType)type;
+ (NSString *)descriptionForTesterone:(Testerone)type;
+ (NSString *)descriptionForUnderwearType:(UnderwearType)type;
+ (NSString *)descriptionForHouseholdIncome:(HouseholdIncome)type;

+ (NSInteger)indexForInsuranceType:(InsuranceType)type;
+ (InsuranceType)insuranceTypeForIndex:(NSInteger)index;

#pragma mark - health conditions
+ (NSArray *)diagnosedConditionOptions;
+ (int64_t)valueForDiagnosedConditionsInIndexSet:(NSIndexSet *)indexSet;
+ (NSIndexSet *)indexSetForDiagnosedConditionsValue:(int64_t)value;
+ (NSArray *)diagnosedConditionsForValue:(int64_t)value;
+ (NSUInteger)numberOfDiagnosedConditionsForValue:(int64_t)value;


#pragma mark - diagnosed causes
+ (NSArray *)infertilityCausesOptions;
+ (NSIndexSet *)indexSetForInfertilityCausesValue:(int64_t)value;
+ (int64_t)valueForInfertilityCausesInIndexSet:(NSIndexSet *)indexSet;
+ (NSUInteger)numberOfInfertilityCausesForValue:(int64_t)value;

#pragma mark - considering (for !TTC)
+ (NSDictionary *)consideringNames;
+ (NSDictionary *)consideringShortNames;
+ (NSArray *)consideringKeys;
+ (NSArray *)consideringItems;

#pragma mark - birth control
+ (NSDictionary *)birthControlNames;
+ (NSDictionary *)birthControlShortNames;
+ (NSArray *)birthControlKeys;
+ (NSArray *)birthControlItems;

@end














