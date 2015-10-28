//
//  DailyLogDataProviderAvoidPregnancy.m
//  emma
//
//  Created by Eric Xu on 12/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogDataProviderAvoidPregnancy.h"

#define DL_CELL_KEY_SECTION_PHYSICAL  @"PhysicalSection"
#define DL_CELL_KEY_SECTION_EMOTIONAL @"EmotionalSection"
#define DL_CELL_KEY_SECTION_FERTILITY @"FertilitySection"

@implementation DailyLogDataProviderAvoidPregnancy

- (NSArray *)physicalSectionKeys {
    if ([self.abstract[DAILYLOG_DP_ABSTRACT_IS_FEMALE] boolValue]) {
        return @[
                 DL_CELL_KEY_SECTION_PHYSICAL,
                 DL_CELL_KEY_EXERCISE,
                 DL_CELL_KEY_WEIGHT,
                 DL_CELL_KEY_SLEEP,
                 DL_CELL_KEY_SMOKE,
                 DL_CELL_KEY_ALCOHOL,
                 DL_CELL_KEY_PHYSICALDISCOMFORT
                 ];
    } else {
        return @[
                 DL_CELL_KEY_SECTION_PHYSICAL,
                 DL_CELL_KEY_EXERCISE,
                 DL_CELL_KEY_PHYSICALDISCOMFORT,
                 DL_CELL_KEY_SLEEP,
                 DL_CELL_KEY_SMOKE,
                 DL_CELL_KEY_ALCOHOL
                 ];
    }
}

- (NSArray *)fertilitySectionKeys {
    return @[
             DL_CELL_KEY_SECTION_FERTILITY,
             DL_CELL_KEY_INTERCOURSE,
             DL_CELL_KEY_PERIOD_FLOW,
             DL_CELL_KEY_CM,
             DL_CELL_KEY_BBT,
             DL_CELL_KEY_OVTEST,
             DL_CELL_KEY_PREGNANCYTEST,
             DL_CELL_KEY_CERVICAL
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
