//
//  MedicalLogItem.m
//  emma
//
//  Created by Peng Gu on 10/17/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "MedicalLogItem.h"
#import "User.h"
#import "HealthProfileData.h"
#import "MedicalLogBinaryCell.h"
#import <GLFoundation/GLGeneralPicker.h>
#import "Utils+DateTime.h"
#import "UserStatus.h"

@interface MedicalLogItem ()
@property (nonatomic, copy) NSString *unit;
@end


@implementation MedicalLogItem

@synthesize logValue = _logValue;


+ (instancetype)itemWithKey:(NSString *)key date:(NSString *)date
{
    return [[MedicalLogItem alloc] initWithKey:key date:date];
}

+ (instancetype)itemWithKey:(NSString *)key date:(NSString *)date treatmentType:(NSInteger)treatmentType
{
    MedicalLogItem *item = [[MedicalLogItem alloc] initWithKey:key date:date];
    item.treatmentType = treatmentType;
    return item;
}

- (instancetype)initWithKey:(NSString *)key date:(NSString *)date
{
    self = [super init];
    if (self) {
        self.key = key;
        self.date = date;
        self.medicalLog = [UserMedicalLog medicalLogWithKey:key date:date user:[User currentUser]];
        
        if (self.medicalLog) {
            self.logValue = self.medicalLog.dataValue;
        }
    }
    return self;
}


- (void)setKey:(NSString *)key
{
    _key = key;
    _name = nil;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@,   %@,   %@", _key, _logValue, _medicalLog.dataValue];
}

- (NSDate *)nsdate
{
    return [Utils dateWithDateLabel:self.date];
}

#pragma mark - values
- (void)saveToModel
{
    if (self.logValueChanged) {
        NSLog(@"save to model: %@", self);
        [self updateModelValue:self.logValue];
    }
}


- (void)updateModelValue:(NSString *)value
{
    if (!self.medicalLog) {
        self.medicalLog = [UserMedicalLog newInstance:[User currentUser].dataStore];
        self.medicalLog.date = self.date;
        self.medicalLog.dataKey = self.key;
        self.medicalLog.user = [User currentUser];
    }
    
    [self.medicalLog update:@"dataValue" value:value];
}


- (BOOL)logValueChanged
{
    if (!self.logValue && !self.medicalLog.dataValue) {
        return NO;
    }
    else if (self.logValue) {
        return ![self.logValue isEqualToString:self.medicalLog.dataValue];
    }
    else {
        return ![self.medicalLog.dataValue isEqualToString:self.logValue];
    }
}

@end












