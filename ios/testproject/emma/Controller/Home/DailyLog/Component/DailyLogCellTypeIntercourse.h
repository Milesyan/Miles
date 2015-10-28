//
//  DailyLogCellTypeIntercourse.h
//  emma
//
//  Created by Ryan Ye on 4/7/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeExpandable.h"

#define LOG_VAL_INTERCOURSE_ORGASM_CHECK 0x10
#define LOG_VAL_INTERCOURSE_ORGASM_CROSS 0x20

@interface DailyLogCellTypeIntercourse : DailyLogCellTypeExpandable
@property (nonatomic, strong) NSArray *extraExclusiveButtons;
@property (nonatomic) BOOL purposeTTC;
@end
