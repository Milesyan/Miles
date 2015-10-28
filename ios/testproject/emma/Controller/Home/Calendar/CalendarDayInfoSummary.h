//
//  CalendarAppearance.h
//  emma
//
//  Created by ltebean on 15/6/25.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "StatusHistory.h"
#import "UserStatus.h"

@interface DayInfo : NSObject 
@property (nonatomic) NSInteger backgroundColorHexValue;
@property (nonatomic) CGFloat fertileScore;
@property (nonatomic) BOOL shouldHaveFertileScore;
@property (nonatomic) DayType dayType;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, strong) UserStatus *userStatus;
@property (nonatomic, strong) User *user;
@property (nonatomic) NSInteger daysToNextCycle;
@property (nonatomic) NSInteger daysSinceCurrentCycle;
@property (nonatomic) NSInteger treatmentCycleDay;
@property (nonatomic, copy) NSString *textForPeriod;
@property (nonatomic, copy) NSString *textForPregancy;
@property (nonatomic, copy) NSString *textForChancesOfPregancy;
@property (nonatomic, copy) NSString *textForDaysToNextCycle;
@property (nonatomic, copy) NSString *textForDaysSinceCurrentCycle;
@property (nonatomic, copy) NSString *textForTreatmentCycleDay;
@end


@interface CalendarDayInfoSummary : NSObject
+ (DayInfo *)dayInfoForDate:(NSDate *)date;
@end
