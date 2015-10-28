//
//  DailyLogCellTypeStressLevel.h
//  emma
//
//  Created by Xin Zhao on 5/18/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeBase.h"

CG_INLINE NSString* stressLevelVal2Name(NSInteger val) {
    if (val <= 0) {
        return @"not";
    } else if (val <= 33) {
        return @"low";
    } else if (val <= 67) {
        return @"medium";
    } else {
        return @"high";
    }
    
}

@interface DailyLogCellTypeStressLevel : DailyLogCellTypeBase

@property (nonatomic)NSInteger dataValue;

@end
