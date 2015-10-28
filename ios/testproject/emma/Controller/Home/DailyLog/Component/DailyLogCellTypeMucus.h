//
//  DailyLogCellTypeMucus.h
//  emma
//
//  Created by Ryan Ye on 4/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogConstants.h"
#import "DailyLogCellTypeBase.h"

CG_INLINE NSString* textureVal2Name(NSInteger val) {
    if (val <= CM_TEXTURE_NO) {
        return @"not set";
    } else if (val <= CM_TEXTURE_STICKY - 5) {
        return @"dry";
    } else if (val <= CM_TEXTURE_WATERY - 5) {
        return @"sticky";
    } else if (val <= CM_TEXTURE_EGGWHITE - 5) {
        return @"watery";
    } else if (val <= CM_TEXTURE_CREAMY - 5) {
        return @"eggwhite";
    } else {
        return @"creamy";
    }
}

CG_INLINE NSString* amountVal2Name(NSInteger val) {
    if (val <= CM_WETNESS_NO) {
        return @"not set";
    } else if (val <= 33) {
        return @"light";
    } else if (val <= 66) {
        return @"medium";
    } else {
        return @"heavy";
    }
}

@interface DailyLogCellTypeMucus : DailyLogCellTypeBase
@property (nonatomic)NSInteger dataValue;
@end
