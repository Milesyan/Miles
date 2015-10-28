//
//  DailyLogDataProviderMalePartner.m
//  emma
//
//  Created by ltebean on 15-3-24.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DailyLogDataProviderMalePartner.h"

@implementation DailyLogDataProviderMalePartner

- (NSArray *)fertilitySectionKeys {
    return @[
             DL_CELL_KEY_SECTION_SPERM_HEALTH,
             DL_CELL_KEY_INTERCOURSE,
             DL_CELL_KEY_ERECTION,
             DL_CELL_KEY_MASTURBATION,
             DL_CELL_KEY_HEAT_SOURCE,
             DL_CELL_KEY_FEVER
             ];
}

- (NSArray *)physicalSectionKeys {
    return @[
            DL_CELL_KEY_SECTION_PHYSICAL,
            DL_CELL_KEY_EXERCISE,
            DL_CELL_KEY_WEIGHT,
            DL_CELL_KEY_SLEEP,
            DL_CELL_KEY_SMOKE,
            DL_CELL_KEY_ALCOHOL,
            DL_CELL_KEY_PHYSICALDISCOMFORT
            ];
    
}

- (NSArray *)emotionalSectionKeys
{
    return @[
             DL_CELL_KEY_SECTION_EMOTIONAL,
             DL_CELL_KEY_STRESS_LEVEL,
             DL_CELL_KEY_MOODS
             ];
}

- (NSArray *)_dailyLogCellKeyOrderConfig {
    NSMutableArray * ary = [[NSMutableArray alloc] init];
    [ary addObjectsFromArray:[self fertilitySectionKeys]];
    [ary addObjectsFromArray:[self physicalSectionKeys]];
    [ary addObjectsFromArray:[self emotionalSectionKeys]];
    return [NSArray arrayWithArray:ary];
}

@end
