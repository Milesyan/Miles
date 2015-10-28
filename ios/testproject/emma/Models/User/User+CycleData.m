//
//  User+CycleData.m
//  emma
//
//  Created by Peng Gu on 5/9/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "User+CycleData.h"
#import <GLPeriodEditor/GLCycleData.h>
#import "UserDailyData.h"

@implementation User (CycleData)


- (GLCycleData *)currentCycle
{
    NSInteger today = [[NSDate date] toDateIndex];
    
    if (!self.prediction || self.prediction.count < 2) {
        return nil;
    }
    for (NSInteger i=0; i<self.prediction.count-1; i++) {
        NSDictionary *currCycle = self.prediction[i];
        NSDictionary *nextCycle = self.prediction[i+1];
        
        NSDate *currBegin = [Utils dateWithDateLabel:[currCycle objectForKey:@"pb"]];
        NSDate *nextBegin = [Utils dateWithDateLabel:[nextCycle objectForKey:@"pb"]];
        
        NSInteger currBeginIndex = [currBegin toDateIndex];
        NSInteger nextBeginIndex = [nextBegin toDateIndex];
        
        if (currBeginIndex <= today && today < nextBeginIndex) {
            NSDate *pe = [Utils dateWithDateLabel:[currCycle objectForKey:@"pe"]];
            NSDate *fb = [Utils dateWithDateLabel:[currCycle objectForKey:@"fb"]];
            NSDate *fe = [Utils dateWithDateLabel:[currCycle objectForKey:@"fe"]];
            GLCycleData *cycleData = [GLCycleData dataWithPeriodBeginDate:currBegin periodEndDate:pe];
            if (fb && fe) {
                cycleData.fertileWindowBeginDate = fb;
                cycleData.fertileWindowEndDate = fe;
            }
            
            return cycleData;
        }
    }
    return nil;
}


- (GLCycleData *)nextCycle
{
    for (NSDictionary *p in self.prediction) {
        NSDate *pb = [Utils dateWithDateLabel:[p objectForKey:@"pb"]];
        NSDate *pe = [Utils dateWithDateLabel:[p objectForKey:@"pe"]];
        NSDate *fb = [Utils dateWithDateLabel:[p objectForKey:@"fb"]];
        NSDate *fe = [Utils dateWithDateLabel:[p objectForKey:@"fe"]];
        GLCycleData *cycleData = [GLCycleData dataWithPeriodBeginDate:pb periodEndDate:pe];
        if (fb && fe) {
            cycleData.fertileWindowBeginDate = fb;
            cycleData.fertileWindowEndDate = fe;
        }
        
        if (cycleData.isFuture) {
            return cycleData;
        }
    }
    return nil;
}



@end
