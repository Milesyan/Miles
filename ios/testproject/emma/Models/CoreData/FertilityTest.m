//
//  FertilityTest.m
//  emma
//
//  Created by Peng Gu on 7/14/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "FertilityTest.h"
#import "User.h"

#import <BlocksKit/NSDictionary+BlocksKit.h>

@implementation FertilityTest

@dynamic fertilityClinic;
@dynamic doctorName;
@dynamic nurseName;
@dynamic cycleDayThreeBloodWork;
@dynamic vaginalUltrasound;
@dynamic otherBloodTests;
@dynamic hysterosalpingogram;
@dynamic salineSonogram;
@dynamic hysteroscopy;
@dynamic geneticTesting;
@dynamic prenatalScreening;
@dynamic mammogram;
@dynamic papsmear;
@dynamic semenAnalysis;
@dynamic stiScreening;
@dynamic user;

#pragma mark - keys & questions

+ (NSDictionary *)attrMapper
{
    return @{
             @"fertility_clinic"           : @"fertilityClinic",
             @"doctor_name"                : @"doctorName",
             @"nurse_name"                 : @"nurseName",
             
             @"cycle_day_three_blood_work" : @"cycleDayThreeBloodWork",
             @"vaginal_ultrasound"         : @"vaginalUltrasound",
             @"other_blood_tests"          : @"otherBloodTests",
             @"hysterosalpingogram"        : @"hysterosalpingogram",
             @"saline_sonogram"            : @"salineSonogram",
             @"hysteroscopy"               : @"hysteroscopy",
             @"genetic_testing"            : @"geneticTesting",
             @"prenatal_screening"         : @"prenatalScreening",
             @"mammogram"                  : @"mammogram",
             @"papsmear"                   : @"papsmear",
             
             @"semen_analysis"             : @"semenAnalysis",
             @"sti_screening"              : @"stiScreening",
             };
}


+ (NSArray *)allTestKeys
{
    NSDictionary *clientToServerKeyMapping = [Utils inverseDict:[self attrMapper]];
    NSArray *allKeys = clientToServerKeyMapping.allKeys;
    return allKeys;
}


+ (NSDictionary *)extractFertilityTestingDataFromOnboardingData:(NSDictionary *)onboardingData
{
    NSDictionary *clientToServerKeyMapping = [Utils inverseDict:[self attrMapper]];
    NSArray *allKeys = clientToServerKeyMapping.allKeys;
    
    NSMutableDictionary *returnData = [NSMutableDictionary dictionary];
    
    for (NSString *clientKey in onboardingData) {
        if ([allKeys containsObject:clientKey]) {
            NSString *serverKey = clientToServerKeyMapping[clientKey];
            returnData[serverKey] = onboardingData[clientKey];
        }
    }
    return returnData;
}


- (NSDictionary *)attrMapper
{
    return [FertilityTest attrMapper];
}


#pragma mark - Core data
+ (instancetype)upsertWithServerData:(NSDictionary *)data
{
    User *user = [User currentUser];
    FertilityTest *fertilityTest = user.fertilityTest;
    if (!fertilityTest) {
        fertilityTest = [FertilityTest newInstance:user.dataStore];
        fertilityTest.user = user;
    }
    [fertilityTest updateAttrsFromServerData:data];
    NSLog(@"upsert fertility test with server data: %@", data);
    
    return fertilityTest;
}


- (void)setDirty:(BOOL)dirty
{
    [super setDirty:dirty];
    if (dirty) {
        self.user.dirty = YES;
    }
}



@end




