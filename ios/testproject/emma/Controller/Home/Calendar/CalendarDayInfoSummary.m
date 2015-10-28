//
//  CalendarAppearance.m
//  emma
//
//  Created by ltebean on 15/6/25.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "CalendarDayInfoSummary.h"
#import "UserStatusDataManager.h"
#import "UserMedicalLog.h"
#import <GLPeriodEditor/GLDateUtils.h>

@implementation DayInfo

- (DayType)dayType
{
    if (_dayType) {
        return _dayType;
    }
    _dayType = [self.user predictionForDate:self.date];
    return _dayType;
}

- (UserStatus *)userStatus
{
    if (_userStatus) {
        return _userStatus;
    }
    _userStatus = [[UserStatusDataManager sharedInstance] statusOnDate:[self.date toDateLabel] forUser:self.user];
    return _userStatus;
}

- (NSInteger)daysToNextCycle
{
    if (_daysToNextCycle) {
        return _daysToNextCycle;
    }
    NSString * todayLabel = [Utils dailyDataDateLabel:self.date];
    NSInteger pbIndex = [[Utils findFirstPbIndexBefore:todayLabel inPrediction:self.user.prediction] integerValue] + 1;
    if (pbIndex >= self.user.prediction.count) {
        _daysToNextCycle = -1;
    } else {
        NSInteger days = [Utils daysBeforeDateLabel:self.user.prediction[pbIndex][@"pb"] sinceDateLabel:todayLabel];
        _daysToNextCycle = days;
    }
    return _daysToNextCycle;
}

- (NSInteger)daysSinceCurrentCycle {
    if (_daysSinceCurrentCycle) {
        return _daysSinceCurrentCycle;
    }
    NSString *selectedDateLabel = [Utils dailyDataDateLabel:self.date];
    NSInteger pbIndex = [[Utils findFirstPbIndexBefore:selectedDateLabel inPrediction:self.user.prediction] integerValue];
    if (9999 == pbIndex || pbIndex < 0) {
        _daysSinceCurrentCycle = -1;
    } else {
        _daysSinceCurrentCycle = [Utils daysBeforeDateLabel:[self.date toDateLabel] sinceDateLabel:self.user.prediction[pbIndex][@"pb"]] + 1;
    }
    return _daysSinceCurrentCycle;
}


- (NSInteger)treatmentCycleDay
{
    if (_treatmentCycleDay) {
        return _treatmentCycleDay;
    }
    if (self.userStatus.inTreatment && self.userStatus.treatmentType != TREATMENT_TYPE_MED) {
        _treatmentCycleDay = [GLDateUtils daysBetween:self.userStatus.startDate and:self.date] + 1;
    } else {
        _treatmentCycleDay = -1;
    }
    return _treatmentCycleDay;
}

- (BOOL)shouldHaveFertileScore
{
    if (_shouldHaveFertileScore) {
        return _shouldHaveFertileScore;
    }
    _shouldHaveFertileScore = self.user.shouldHaveFertileScore;
    return _shouldHaveFertileScore;
}

- (CGFloat)fertileScore
{
    if (_fertileScore) {
        return _fertileScore;
    }
    _fertileScore = [self.user fertileScoreOfDate:self.date];
    return _fertileScore;
}

- (NSInteger)backgroundColorHexValue
{
    if (_backgroundColorHexValue) {
        return _backgroundColorHexValue;
    }
    // IUI, IVF logic
    if (self.userStatus.treatmentType == TREATMENT_TYPE_IUI || self.userStatus.treatmentType == TREATMENT_TYPE_IVF) {
        NSInteger dateIndex = [Utils dateToIntFrom20130101:self.date];
        if ([UserMedicalLog isDateIndexWithinHcgTriggerShotDates:dateIndex]) {
            _backgroundColorHexValue = GLOW_COLOR_GREEN_HEX_VALUE;
        } else if (self.dayType == kDayPeriod) {
            _backgroundColorHexValue = GLOW_COLOR_PINK_HEX_VALUE;
        } else {
            _backgroundColorHexValue = GLOW_COLOR_PURPLE_HEX_VALUE;
        }
        return _backgroundColorHexValue;
    }
    
    // others
    if (self.dayType == kDayPeriod) {
        _backgroundColorHexValue = GLOW_COLOR_PINK_HEX_VALUE;
    } else if (self.dayType == kDayFertile) {
        if (self.user.shouldHaveFertileScore) {
            _backgroundColorHexValue = GLOW_COLOR_GREEN_HEX_VALUE;
        }
        else {
            _backgroundColorHexValue = GLOW_COLOR_PURPLE_HEX_VALUE;
        }
    } else if (self.dayType == kDayHistoricalPeriod) {
        _backgroundColorHexValue = GLOW_COLOR_PINK_HEX_VALUE;
    } else {
        _backgroundColorHexValue = GLOW_COLOR_PURPLE_HEX_VALUE;
    }
    return _backgroundColorHexValue;
}

- (NSString *)textForPeriod
{
    if (_textForPeriod) {
        return _textForPeriod;
    }
    if (self.dayType == kDayPeriod) {
        _textForPeriod = [self textForPeriod:self.date];
    } else {
        _textForPeriod = nil;
    }
    return _textForPeriod;
}

- (NSString *)textForPregancy
{
    if (_textForPregancy) {
        return _textForPregancy;
    }
    if (self.userStatus.status == STATUS_PREGNANT) {
        _textForPregancy = [self textForPregancy:self.date];
    } else {
        _textForPregancy = nil;
    }
    return _textForPregancy;
}

- (NSString *)textForChancesOfPregancy
{
    if (_textForChancesOfPregancy) {
        return _textForChancesOfPregancy;
    }
    BOOL inTreatment = self.userStatus.inTreatment && self.userStatus.treatmentType != TREATMENT_TYPE_MED;
    BOOL inPregnant = self.userStatus.status == STATUS_PREGNANT;
    if (self.shouldHaveFertileScore && !inTreatment && !inPregnant) {
         _textForChancesOfPregancy = [self textForChanceOfPregnancy:self.fertileScore dayType:self.dayType status:self.userStatus.status];
    } else {
         _textForChancesOfPregancy = nil;
    }
    return _textForChancesOfPregancy;
}

- (NSString *)textForDaysToNextCycle
{
    if (_textForDaysToNextCycle) {
        return _textForDaysToNextCycle;
    }
    if (self.daysToNextCycle > 0) {
        _textForDaysToNextCycle =  [self textForDaysToNextCycle:self.daysToNextCycle status:self.userStatus.status];
    } else {
        _textForDaysToNextCycle = nil;
    }
    return _textForDaysToNextCycle;
}

- (NSString *)textForDaysSinceCurrentCycle
{
    if (_textForDaysSinceCurrentCycle) {
        return _textForDaysSinceCurrentCycle;
    }
    if (self.daysSinceCurrentCycle > 0) {
        _textForDaysSinceCurrentCycle = [self textForDaysSinceCurrentCycle:self.daysSinceCurrentCycle status:self.userStatus.status];
    } else {
        _textForDaysSinceCurrentCycle = nil;
    }
    return _textForDaysSinceCurrentCycle;
}


- (NSString *)textForTreatmentCycleDay
{
    if (_textForTreatmentCycleDay) {
        return _textForTreatmentCycleDay;
    }
    if (self.treatmentCycleDay > 0) {
        _textForTreatmentCycleDay = [self textForTreatmentCycleDay:self.treatmentCycleDay];
    } else {
        _textForTreatmentCycleDay = nil;
    }
    return _textForTreatmentCycleDay;
}


- (NSString *)textForPeriod:(NSDate *)date {
    NSInteger idx = [date timeIntervalSince1970] / 86400;
    NSArray *textList;
    if ([User currentUser].isSecondary) {
        textList = @[@"Period Day\nHold her\n ",
                     @"Period Day\nCompliment her\n ",
                     @"Period Day\nComfort her\n ",
                     @"Period Day\nTalk to her\n ",
                     @"Period Day\nMake her smile\n "];
    } else {
        textList = @[@"Period Day\nIndulge yourself\n ",
                     @"Period Day\nPamper yourself\n ",
                     @"Period Day\nSnuggle away\n ",
                     @"Period Day\nEat well\n ",
                     @"Period Day\nStay hydrated\n "];
    }
    return [textList objectAtIndex:idx % 5];
}

- (NSString *)textForPregancy:(NSDate *)date {
    NSInteger idx = [date timeIntervalSince1970] / 86400;
    NSArray *textList = @[@"Woo hoo!\nTotally preggers!\n ",
                          @"Baby on Board!\n \n ",
                          @"Expecting\na tiny miracle!\n ",
                          @"Bun in the oven!\n \n ",
                          @"Eating for two!\n \n ",
                          @"On stork watch!\n \n ",
                          @"BFP! BFP! BFP!\n \n "];
    return [textList objectAtIndex:idx % 7];
}

- (NSString *)textForChanceOfPregnancy:(CGFloat)fertileScore dayType:(DayType)type status:(NSInteger)status {
    
    if (status != STATUS_NON_TTC) {
        if (fertileScore - (float)(NSInteger)fertileScore < 0.1) {
            return [NSString stringWithFormat: @"**%.0f%%** chance\n of pregnancy\n ", fertileScore];
        }
        else {
            return [NSString stringWithFormat: @"**%.1f%%** chance\n of pregnancy\n ", fertileScore];
        }
    } else {
        NSString *risk = [NSString stringWithFormat:@"%@", type==kDayFertile? @"high risk": @"risk"];
        if (fertileScore - (float)(NSInteger)fertileScore < 0.1) {
            return [NSString stringWithFormat:@"**%.0f%% %@**\n for pregnancy\n ", fertileScore, risk];
        }
        else {
            return [NSString stringWithFormat:@"**%.1f%% %@**\n for pregnancy\n ", fertileScore, risk];
        }
    }
}


- (NSString *)textForDaysToNextCycle:(NSInteger)days status:(NSInteger)status
{
    if ([User currentUser].isMale || status == STATUS_TREATMENT) {
        return [NSString stringWithFormat:@"Next cycle\n in **%ld** day%s\n ", (long)days, days == 1 ? "" : "s"];
    } else {
        return [NSString stringWithFormat:@"Next period\n in **%ld** day%s\n ", (long)days, days == 1 ? "" : "s"];
    }
}

- (NSString *)textForDaysSinceCurrentCycle:(NSInteger)days status:(NSInteger)status
{
    return [NSString stringWithFormat:@"**%ld** day%s since\nlast period\n ", (long)days, days == 1 ? "" : "s"];
}

- (NSString *)textForTreatmentCycleDay:(NSInteger)days
{
    return [NSString stringWithFormat:@"Treatment cycle\n day **%ld**\n ", (long)days];
}

@end


@implementation CalendarDayInfoSummary
+ (DayInfo *)dayInfoForDate:(NSDate *)date
{
    User *user = [User userOwnsPeriodInfo];
    DayInfo *dayInfo = [DayInfo new];
    dayInfo.date = date;
    dayInfo.user = user;
    return dayInfo;
}
@end
