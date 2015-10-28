//
//  StatusHistory.h
//  emma
//
//  Created by ltebean on 15/6/17.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StatusHistory.h"

#define STATUS_TTC 0
#define STATUS_PREGNANT 2
#define STATUS_NON_TTC 3
#define STATUS_TREATMENT 4

@interface UserStatus : NSObject
@property (nonatomic) NSInteger status;
@property (nonatomic) NSInteger treatmentType;
@property (nonatomic, copy) NSDate *startDate;
@property (nonatomic, copy) NSDate *endDate;
@property (nonatomic, readonly) NSString *datesDescription;
@property (nonatomic, readonly) BOOL inTreatment;

+ (instancetype)instanceWithStatus:(NSInteger)status treatmentType:(NSInteger)treatmentType startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

+ (NSString *)shortDescriptionForTreatmentType:(NSInteger)treatmentType;
+ (NSString *)fullDescriptionForTreatmentType:(NSInteger)treatmentType;

- (BOOL)containsDate:(NSDate *)date;
- (NSString *)shortDescription;
- (NSString *)fullDescription;
@end
