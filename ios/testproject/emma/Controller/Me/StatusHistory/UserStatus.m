//
//  StatusHistory.m
//  emma
//
//  Created by ltebean on 15/6/17.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "UserStatus.h"
#import <GLPeriodEditor/GLDateUtils.h>

@implementation UserStatus

- (instancetype)initWithStatus:(NSInteger)status treatmentType:(NSInteger)treatmentType beginDate:(NSDate *)startDate endDate:(NSDate *)endDate{
    self = [super init];
    if (self) {
        _status = status;
        _treatmentType = treatmentType;
        _startDate = [startDate copy];
        _endDate = [endDate copy];
    }
    return self;
}

+ (instancetype)instanceWithStatus:(NSInteger)status treatmentType:(NSInteger)treatmentType startDate:(NSDate *)beginDate endDate:(NSDate *)endDate
{
    return [[UserStatus alloc] initWithStatus:status treatmentType:treatmentType beginDate:beginDate endDate:endDate];
}


+ (NSString *)shortDescriptionForTreatmentType:(NSInteger)treatmentType
{
    if (treatmentType == TREATMENT_TYPE_IUI) {
        return @"IUI";
    } else if (treatmentType == TREATMENT_TYPE_IVF) {
        return @"IVF";
    } else if (treatmentType == TREATMENT_TYPE_MED) {
        return @"Med";
    } else if (treatmentType == TREATMENT_TYPE_PREPARING) {
        return @"Prep";
    } else {
        return @"";
    }
}

+ (NSString *)fullDescriptionForTreatmentType:(NSInteger)treatmentType
{
    if (treatmentType == TREATMENT_TYPE_IUI) {
        return @"Intrauterine Insemination (IUI)";
    } else if (treatmentType == TREATMENT_TYPE_IVF) {
        return @"In Vitro Fertilization (IVF)";
    } else if (treatmentType == TREATMENT_TYPE_MED) {
        return @"Intercourse with fertility med";
    } else if (treatmentType == TREATMENT_TYPE_PREPARING) {
        return @"Preparing for treatment";
    } else {
        return @"";
    }
}

- (BOOL)inTreatment
{
    return self.status == STATUS_TREATMENT && self.treatmentType != TREATMENT_TYPE_INTERVAL;
}


- (NSString *)shortDescription
{
    if (self.status == STATUS_TREATMENT) {
        return [UserStatus shortDescriptionForTreatmentType:self.treatmentType];
    } else if (self.status == STATUS_PREGNANT){
        return @"Preg";
    } else {
        return @"";
    }
}

- (NSString *)fullDescription
{
    if (self.status == STATUS_TREATMENT) {
        return [UserStatus fullDescriptionForTreatmentType:self.treatmentType];
    } else if (self.status == STATUS_PREGNANT){
        return @"Pregnant";
    } else {
        return @"";
    }
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    UserStatus *other = (UserStatus *)object;
    return (self.status == other.status  && self.treatmentType == other.treatmentType && [self.startDate isEqual:other.startDate]);
}

- (BOOL)containsDate:(NSDate *)date
{
    NSDate *d = [GLDateUtils cutDate:date];
    if ([d compare:[GLDateUtils cutDate:self.startDate]] == NSOrderedAscending) {
        return NO;
    }
    if ([d compare:[GLDateUtils cutDate:self.endDate]] == NSOrderedDescending) {
        return NO;
    }
    return YES;
}

- (NSString *)datesDescription
{
    if (!self.startDate || !self.endDate) {
        return @"";
    }
    NSCalendarUnit flags = NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear;
    NSDateComponents *beginDate = [[GLDateUtils calendar] components:flags fromDate:self.startDate];
    NSString *result = [NSString stringWithFormat:@"%@ %ld", [GLDateUtils monthText:beginDate.month], (long)beginDate.day];
    if (self.endDate) {
        NSDateComponents *endDate = [[GLDateUtils calendar] components:flags fromDate:self.endDate];
        return [NSString stringWithFormat:@"%@ - %@ %ld", result, [GLDateUtils monthText:endDate.month], (long)endDate.day];
    } else {
        return [NSString stringWithFormat:@"%@ - Today", result];

    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"status:%ld treatment:%ld dates:%@", (long)self.status, (long)self.treatmentType, [self datesDescription]];
}

- (id)copy
{
    return [UserStatus instanceWithStatus:self.status treatmentType:self.treatmentType startDate:self.startDate endDate:self.endDate];
}
@end
