//
//  UserDailyData+CervicalPosition.m
//  emma
//
//  Created by Peng Gu on 7/28/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UserDailyData+CervicalPosition.h"

#define CervicalPositionOldValueFirmAndLow 1
#define CervicalPositionOldValueSoftAndHigh 2


@implementation UserDailyData (CervicalPosition)


+ (uint64_t)getCervicalPositionNewValueFromOldValue:(uint64_t)oldValue
{
    if (oldValue == CervicalPositionOldValueFirmAndLow) {
        uint64_t firm = (CervicalPositionFirmnessStatusFirm << CervicalPositionFirmness);
        uint64_t height = (CervicalPositionHeightStatusLow << CervicalPositionHeight);
        uint64_t open = (CervicalPositionOpennessStatusClosed << CervicalPositionOpenness);
        return  firm + height + open + CervicalPositionOldValueFirmAndLow;
    }
    
    uint64_t firm = (CervicalPositionFirmnessStatusSoft << CervicalPositionFirmness);
    uint64_t height = (CervicalPositionHeightStatusHigh << CervicalPositionHeight);
    uint64_t open = (CervicalPositionOpennessStatusOpen << CervicalPositionOpenness);
    return firm + height + open + CervicalPositionOldValueSoftAndHigh;
}


+ (NSDictionary *)getCervicalPositionStatusFromValue:(uint64_t)value
{
    NSMutableDictionary *cervical = [NSMutableDictionary dictionary];
    
    for (NSNumber *cp in CervicalPositionAllTypes) {
        uint64_t cpIndex = [cp unsignedLongLongValue];
        uint64_t level = (value >> cpIndex) & 0xf;
        cervical[cp] = @(level);
    }
    
    return cervical;
}


+ (uint64_t)getCervicalValueFromStatus:(NSDictionary *)status
{
    NSArray *allStatusTypes = CervicalPositionAllTypes.allKeys;
    uint64_t value = 0;
    
    for (NSNumber *each in status) {
        uint64_t level = [status[each] unsignedLongLongValue];
        if ([allStatusTypes containsObject:each] && level > 0) {
            value += (level << each.unsignedLongLongValue);
        }
    }
    return value;
}


+ (NSString *)statusDescriptionForCervicalStatus:(NSDictionary *)status seperateBy:(NSString *)seperator
{
    NSMutableArray *names = [NSMutableArray array];
    
    for (NSNumber *each in [status.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        uint64_t level = [status[each] unsignedLongLongValue];
        if (level > 0) {
            NSString *name = [self statusTitleForCervicalPosition:[each unsignedLongLongValue] statusValue:level];
            [names addObject:name];
        }
    }
    
    if (!seperator) {
        seperator = @", ";
    }
    
    return [names componentsJoinedByString:seperator];
}


+ (NSString *)statusTitleForCervicalPosition:(CervicalPositionType)type statusValue:(uint64_t)statusValue
{
    if (statusValue == 0) {
        return @"";
    }
    
    if (type == CervicalPositionHeight) {
        if (statusValue == CervicalPositionHeightStatusHigh) {
            return @"High";
        }
        else if (statusValue == CervicalPositionHeightStatusMed) {
            return @"Med";
        }
        else if (statusValue == CervicalPositionHeightStatusLow) {
            return @"Low";
        }
    }
    else if (type == CervicalPositionOpenness) {
        if (statusValue == CervicalPositionOpennessStatusOpen) {
            return @"Open";
        }
        else if (statusValue == CervicalPositionOpennessStatusMed) {
            return @"Med";
        }
        else if (statusValue == CervicalPositionOpennessStatusClosed) {
            return @"Closed";
        }
    }
    else if (type == CervicalPositionFirmness) {
        if (statusValue == CervicalPositionFirmnessStatusFirm) {
            return @"Firm";
        }
        else if (statusValue == CervicalPositionFirmnessStatusMed) {
            return @"Med";
        }
        else if (statusValue == CervicalPositionFirmnessStatusSoft) {
            return @"Soft";
        }
    }

    return @"";
}


- (NSDictionary *)getCervicalPositionStatus
{
    return [UserDailyData getCervicalPositionStatusFromValue:self.cervical];
}


- (NSString *)getCervixDescription
{
    NSString *description = [UserDailyData statusDescriptionForCervicalStatus:[self getCervicalPositionStatus]
                                                                   seperateBy:nil];
    
    NSRange lastComma = [description rangeOfString:@"," options:NSBackwardsSearch];
    if(lastComma.location != NSNotFound) {
        description = [description stringByReplacingCharactersInRange:lastComma withString:@" and"];
    }
    
    return description;
}


@end







