//
//  DailyLogDataProviderFemalePartner.m
//  emma
//
//  Created by ltebean on 15-3-24.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DailyLogDataProviderFemalePartner.h"

@implementation DailyLogDataProviderFemalePartner

- (NSArray *)physicalSectionKeys
{
    return @[
             DL_CELL_KEY_SECTION_PHYSICAL,
             DL_CELL_KEY_EXERCISE,
             DL_CELL_KEY_WEIGHT,
             DL_CELL_KEY_PHYSICALDISCOMFORT,
             DL_CELL_KEY_SLEEP,
             DL_CELL_KEY_SMOKE,
             DL_CELL_KEY_ALCOHOL
             ];

}

- (NSArray *)fertilitySectionKeys
{
    return @[
             DL_CELL_KEY_SECTION_FERTILITY,
             DL_CELL_KEY_PERIOD_FLOW,
             DL_CELL_KEY_INTERCOURSE,
             DL_CELL_KEY_CM,
             DL_CELL_KEY_BBT,
             DL_CELL_KEY_OVTEST,
             DL_CELL_KEY_PREGNANCYTEST,
             DL_CELL_KEY_CERVICAL
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
