//
//  DailyLogDataProviderNormaltrack.m
//  emma
//
//  Created by Xin Zhao on 13-11-22.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "DailyLogDataProviderTTC.h"

@implementation DailyLogDataProviderTTC

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
             DL_CELL_KEY_PERIOD_FLOW,
             DL_CELL_KEY_INTERCOURSE,
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
