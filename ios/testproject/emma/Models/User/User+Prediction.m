//
//  User+Prediction.m
//  emma
//
//  Created by ltebean on 15/8/28.
//  Copyright © 2015年 Upward Labs. All rights reserved.
//

#import "User+Prediction.h"
#import "Period.h"

@implementation User (Prediction)
- (void)turnOffPrediction
{
    [self.settings update:@"predictionSwitch" value:@(0)];
    [Period persistAllPeriodsBeforeTodayWithLatestPeriod:nil forUser:self];
    self.periodDirty = YES;
    self.dirty = YES;
    [self save];
}

- (void)turnOnPredictionWithLatestPeriod:(NSDictionary *)period
{
    [self.settings update:@"predictionSwitch" value:@(1)];
    [Period persistAllPeriodsBeforeTodayWithLatestPeriod:period forUser:self];
    self.periodDirty = YES;
    self.dirty = YES;
    [self save];
}
@end
