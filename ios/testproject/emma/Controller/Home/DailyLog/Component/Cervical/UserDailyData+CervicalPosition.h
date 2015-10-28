//
//  UserDailyData+CervicalPosition.h
//  emma
//
//  Created by Peng Gu on 7/28/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//
#import "DailyLogConstants.h"
#import "UserDailyData.h"

typedef NS_ENUM(uint64_t, CervicalPositionHeightStatus) {
    CervicalPositionHeightStatusNone = 0,
    CervicalPositionHeightStatusHigh = CERVICAL_POSITION_HIGH,
    CervicalPositionHeightStatusMed  = CERVICAL_POSITION_MEDIAN,
    CervicalPositionHeightStatusLow  = CERVICAL_POSITION_LOW
};


typedef NS_ENUM(uint64_t, CervicalPositionOpennessStatus) {
    CervicalPositionOpennessStatusNone = 0,
    CervicalPositionOpennessStatusOpen = CERVICAL_POSITION_HIGH,
    CervicalPositionOpennessStatusMed  = CERVICAL_POSITION_MEDIAN,
    CervicalPositionOpennessStatusClosed = CERVICAL_POSITION_LOW
};


typedef NS_ENUM(uint64_t, CervicalPositionFirmnessStatus) {
    CervicalPositionFirmnessStatusNone = 0,
    CervicalPositionFirmnessStatusSoft = CERVICAL_POSITION_HIGH,
    CervicalPositionFirmnessStatusMed  = CERVICAL_POSITION_MEDIAN,
    CervicalPositionFirmnessStatusFirm = CERVICAL_POSITION_LOW
};


typedef NS_ENUM(uint64_t, CervicalPositionType) {
    CervicalPositionHeight   = CERVICAL_POSITION_HEIGHT,
    CervicalPositionOpenness = CERVICAL_POSITION_OPENNESS,
    CervicalPositionFirmness = CERVICAL_POSITION_FIRMNESS
};


#define CervicalPositionAllTypes @{\
    @(CERVICAL_POSITION_HEIGHT): @"Height",\
    @(CERVICAL_POSITION_OPENNESS): @"Openness",\
    @(CERVICAL_POSITION_FIRMNESS): @"Firmness"\
}


@interface UserDailyData (CervicalPosition)

+ (uint64_t)getCervicalPositionNewValueFromOldValue:(uint64_t)oldValue;

+ (NSDictionary *)getCervicalPositionStatusFromValue:(uint64_t)value;
+ (uint64_t)getCervicalValueFromStatus:(NSDictionary *)status;

+ (NSString *)statusDescriptionForCervicalStatus:(NSDictionary *)status seperateBy:(NSString *)seperator;
+ (NSString *)statusTitleForCervicalPosition:(CervicalPositionType)type statusValue:(uint64_t)statusValue;


- (NSDictionary *)getCervicalPositionStatus;
- (NSString *)getCervixDescription;

@end
