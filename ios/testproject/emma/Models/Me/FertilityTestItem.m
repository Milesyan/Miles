//
//  FertilityTestViewModel.m
//  emma
//
//  Created by Peng Gu on 7/9/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "FertilityTestItem.h"
#import "FertilityTest.h"
#import "User.h"
#import <BlocksKit/NSArray+BlocksKit.h>

@interface FertilityTestItem ()


@end


@implementation FertilityTestItem

@synthesize answer = _answer;


+ (NSArray *)infoItems
{
    NSArray *keys = @[kFertilityTestClinic, kFertilityTestDoctorName, kFertilityTestNurseName];
    return [keys bk_map:^id(id obj) {
        return [[FertilityTestItem alloc] initWithTestKey:obj];
    }];
}


+ (NSArray *)testItems
{
    NSArray *keys = @[ kFertilityTestCycleDayThreeBloodWork, kFertilityTestVaginalUltrasound, kFertilityTestOtherBloodTests,
                       kFertilityTestHysterosalpingogram, kFertilityTestSalineSonogram, kFertilityTestHysteroscopy,
//                       kFertilityTestGeneticTesting, kFertilityTestPrenatalScreening, kFertilityTestMammogram,
                       kFertilityTestGeneticTesting, kFertilityTestMammogram,
                       kFertilityTestPapsmear];
    return [keys bk_map:^id(id obj) {
        return [[FertilityTestItem alloc] initWithTestKey:obj];
    }];
}


+ (NSArray *)partnerItems
{
    NSArray *keys = @[kFertilityTestSemenAnalysis, kFertilityTestSTIScreening];
    return [keys bk_map:^id(id obj) {
        return [[FertilityTestItem alloc] initWithTestKey:obj];
    }];
}


+ (NSString *)questionForKey:(NSString *)key
{
    if (!key) {
        return nil;
    }
    
    NSDictionary *map = @{
                          kFertilityTestClinic: @"Who are you seeing?",
                          kFertilityTestDoctorName: @"Doctor",
                          kFertilityTestNurseName: @"Nurse",
                          
                          kFertilityTestCycleDayThreeBloodWork: @"Cycle day 3 blood work",
                          kFertilityTestVaginalUltrasound: @"Vaginal ultrasound",
                          kFertilityTestOtherBloodTests: @"Other blood tests",
                          kFertilityTestHysterosalpingogram: @"Hysterosalpingogram",
                          kFertilityTestSalineSonogram: @"Saline sonohysterogram",
                          kFertilityTestHysteroscopy: @"Hysteroscopy",
                          kFertilityTestGeneticTesting: @"Genetic testing",
                          kFertilityTestPrenatalScreening: @"Prenatal screening",
                          kFertilityTestMammogram: @"Mammogram (Age > 40)",
                          kFertilityTestPapsmear: @"Pap smear",
                          kFertilityTestSemenAnalysis: @"Semen analysis",
                          kFertilityTestSTIScreening: @"STI screening"
                          };
    return map[key];
}


+ (NSArray *)fertilityClinicOptions
{
    return @[@"", @"No one", @"Primary care/other doctor", @"OB/GYN",
             @"Boston IVF", @"Shady Grove Fertility", @"RMA of New York",
             @"Other fertility clinic"];
}


+ (NSString *)shortDescriptionForFertilityClinic:(FertilityClinic)clinic
{
    if (clinic == FertilityClinicOther) {
        return @"Other clinic";
    }
    
    return @[@"", @"No one", @"PCP/other", @"OB/GYN", @"BIVF",
             @"SGF", @"RMA NY"][clinic];
}


+ (NSString *)descriptionForFertilityClinic:(FertilityClinic)clinic
{
    if (clinic == FertilityClinicOther) {
        return @"Other fertility clinic";
    }
    
    return [self fertilityClinicOptions][clinic];
}


+ (NSArray *)testAnswerOptions
{
    return @[@"", @"Normal", @"Abnormal", @"Not yet", @"Not needed"];
}


+ (NSString *)descriptionForTestAnswer:(FertilityTestAnswer)answer
{
    return [self testAnswerOptions][answer];
}


- (instancetype)initWithTestKey:(NSString *)key
{
    self = [super init];
    if (self) {
        _testKey = key;
    }
    return self;
}


- (NSString *)question
{
    return [FertilityTestItem questionForKey:self.testKey];
}


- (NSString *)answer
{
    BOOL stringValue = self.isNurseItem || self.isDoctorItem;
    
    // no record yet
    FertilityTest *fertilityTest = [User currentUser].fertilityTest;
    if (!fertilityTest) {
        return stringValue ? @"" : @"Choose";
    }
    
    // haven't answered this question yet
    id value = [fertilityTest valueForKey:self.testKey];
    if (!value) {
        return stringValue ? @"" : @"Choose";
    }
    
    //
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        NSUInteger index = [value integerValue];
        
        if (index == 0) {
            return @"Choose";
        }
        
        if (self.isClinicItem) {
            return [FertilityTestItem shortDescriptionForFertilityClinic:index];
        }
        return [FertilityTestItem descriptionForTestAnswer:index];
    }
    return @"";
}


- (BOOL)hasValue
{
    NSString *answer = self.answer;
    return ([answer isEqual:@""] || [answer isEqual:@"Choose"]) ? NO : YES;
}


- (NSUInteger)answerIndex
{
    FertilityTest *fertilityTest = [User currentUser].fertilityTest;
    id value = [fertilityTest valueForKey:self.testKey];
    if (!value) {
        return 0;
    }
    return [value integerValue];
}


- (void)saveInputResult:(NSString *)inputString
{
    [self saveTestResult:inputString];
}


- (void)savePickerResult:(NSUInteger)pickerIndex
{
    [self saveTestResult:@(pickerIndex)];
}


- (void)saveTestResult:(id)testResult
{
    if (!testResult) {
        return;
    }
    
    User *user = [User currentUser];
    FertilityTest *test = user.fertilityTest;
    if (!test) {
        test = [FertilityTest newInstance:user.dataStore];
        test.user = user;
    }
    [test update:self.testKey value:testResult];
}


- (BOOL)isClinicItem
{
    return [self.testKey isEqualToString:kFertilityTestClinic];
}


- (BOOL)isDoctorItem
{
    return [self.testKey isEqualToString:kFertilityTestDoctorName];
}


- (BOOL)isNurseItem
{
    return [self.testKey isEqualToString:kFertilityTestNurseName];
}


- (NSString *)placeholderAnswerText
{
    if (self.isDoctorItem) {
        return @"Enter doctor's name";
    }
    else if (self.isNurseItem) {
        return @"Enter nurse's name";
    }
    return @"Choose";
}



@end
