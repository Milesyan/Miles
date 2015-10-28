//
//  WatchDataController.m
//  emma
//
//  Created by Peng Gu on 5/9/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "WatchDataController.h"
#import "User.h"
#import "PeriodInfo.h"
#import "User+CycleData.h"
#import <GLFoundation/GLNameFormatter.h>
#import <GLPeriodEditor/GLCycleData.h>
#import <GLPeriodEditor/GLDateUtils.h>
#import "MMWormhole.h"
#import "UserMedicalLog.h"
#import "HealthProfileData.h"
#import "CalendarDayInfoSummary.h"
#import "StatusHistory.h"
#import "UserStatusDataManager.h"
#import "Period.h"

typedef NS_ENUM(NSInteger, DateTypeForTreatment) {
    dateTreatmentNone           = 0,
    dateTreatmentCountdown      = 1,
    dateTreatmentStartdate      = 2,
    dateAfterStartBeforeEnd     = 3,
    dateTreatmentLikeTTC        = 4
};

#define kPinkColorHex 0xF1679B
#define kPurpleColorHex 0x5a62d2
#define kGreenColorHex 0x73bd37
#define kRedColorHex 0xFA1816

@interface WatchDataController ()

@property (nonatomic, strong) MMWormhole *wormhole;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSMutableArray *cycleDataList;
@property (nonatomic) BOOL isPeriodEditorOpen;

@end


@implementation WatchDataController

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static WatchDataController *dc = nil;
    dispatch_once(&onceToken, ^{
        dc = [[WatchDataController alloc] init];
    });
    return dc;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString* appGroups = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"AppGroups"];
        _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:appGroups
                                                         optionalDirectory:kWormholeDirectory];
        
        _user = [User userOwnsPeriodInfo];
        
        [self subscribe:EVENT_USER_LOGGED_IN selector:@selector(userLoggedIn)];
        [self subscribe:EVENT_USER_LOGGED_OUT selector:@selector(userLoggedOut)];
        
        @weakify(self)
        [self subscribe:EVENT_DID_ENTER_PERIOD_EDITOR handler:^(Event *event) {
            @strongify(self)
            self.isPeriodEditorOpen = YES;
            [self passWatchData];
        }];
        [self subscribe:EVENT_DID_LEAVE_PERIOD_EDITOR handler:^(Event *event) {
            @strongify(self)
            self.isPeriodEditorOpen = NO;
            [self passWatchData];
        }];
        [self subscribe:EVENT_USER_STATUS_HISTORY_CHANGED handler:^(Event *event) {
            @strongify(self)
            [self passWatchData];
        }];
    }
    return self;
}

- (void)reloadCycleData
{
    BOOL showFeritileWindow = self.user.shouldHaveFertileScore;
    
    self.cycleDataList = [NSMutableArray array];
    NSInteger futureCycleCount = 0;
    for (NSDictionary *p in self.user.prediction) {
        NSDate *pb = [Utils dateWithDateLabel:[p objectForKey:@"pb"]];
        NSDate *pe = [Utils dateWithDateLabel:[p objectForKey:@"pe"]];
        NSDate *fb = [Utils dateWithDateLabel:[p objectForKey:@"fb"]];
        NSDate *fe = [Utils dateWithDateLabel:[p objectForKey:@"fe"]];
        GLCycleData *cycleData = [GLCycleData dataWithPeriodBeginDate:pb periodEndDate:pe];
        Period *period = [Period periodWithBeginDate:[p objectForKey:@"pb"] endDate:[p objectForKey:@"pe"] forUser:self.user];
        cycleData.model = [period createPushRequest];
        
        if (showFeritileWindow && fb && fe) {
            cycleData.fertileWindowBeginDate = fb;
            cycleData.fertileWindowEndDate = fe;
        }
        
        if (p[@"solid"]) {
            cycleData.isPrediction = NO;
        } else {
            cycleData.isPrediction = YES;
        }
        
        [self.cycleDataList addObject:cycleData];
        if (cycleData.isFuture) {
            futureCycleCount ++;
        }
        if (futureCycleCount >= 2) {
            break;
        }
    }
}


- (void)userLoggedIn
{
    self.user = [User userOwnsPeriodInfo];
    [self passWatchData];
}


- (void)userLoggedOut
{
    self.user = nil;
    [self passWatchData];
}


- (void)handleWatchRequest:(NSDictionary *)request withReply:(void (^)(NSDictionary *))reply
{
    if (!self.user) {
        [self passWatchData];
        return;
    }
    
    RequestType requestType = [request[kRequestType] integerValue];
    
    NSDictionary *loggingData = @{
        @(RequestTypeLogTodayPage): PAGE_IMP_WATCH_APP_TODAY,
        @(RequestTypeLogPredictionPage): PAGE_IMP_WATCH_APP_PREDICTION,
        @(RequestTypeLogGlancePage): PAGE_IMP_WATCH_APP_GLANCE,
        @(RequestTypeLogNotificationPage): PAGE_IMP_WATCH_APP_NOTIFICATION
    };
    NSString *loggingEvent = [loggingData objectForKey:@(requestType)];
    if (loggingEvent) {
        [Logging log:loggingEvent];
        return;
    }
    
    if (requestType == RequestTypeRefreshWatchData) {
        NSLog(@"Passing data to watch app.");
        NSDictionary *watchData = [self passWatchData];
        reply(watchData);
        [Logging log:BTN_CLK_WATCH_APP_REFRESH];
        return;
    }
    
    NSDate *today = [GLDateUtils cutDate:[NSDate date]];
    
    if (requestType == RequestTypePeriodIsLate) {
        NSLog(@"Period is late.");
        GLCycleData *data = [self availableCycleDataForShortcutButton];
        NSInteger length = data.periodLength;
        NSDate *begin = [GLDateUtils dateByAddingDays:2 toDate:today];
        NSDate *end = [GLDateUtils dateByAddingDays:length-1 toDate:begin];
        [self updateCycleData:data withPeriodBeginDate:begin periodEndDate:end];
        [Logging log:BTN_CLK_WATCH_APP_PERIOD_IS_LATE];
    }
    else if (requestType == RequestTypePeriodStartedToday) {
        NSLog(@"Period started today.");
        GLCycleData *data = [self availableCycleDataForShortcutButton];
        NSInteger length = data.periodLength;
        NSDate *begin = today;
        NSDate *end = [GLDateUtils dateByAddingDays:length-1 toDate:begin];
        [self updateCycleData:data withPeriodBeginDate:begin periodEndDate:end];
        [Logging log:BTN_CLK_WATCH_APP_PERIOD_STARTED_TODAY];
    }
    
    NSDictionary *watchData = [self passWatchData];
    reply(watchData);
}


- (NSDictionary *)passWatchData
{
    [self reloadCycleData];
    NSDictionary *message = [self makeWatchData];
    [self.wormhole passMessageObject:message identifier:kWormholeWatchData];
    return message;
}


- (NSDictionary *)makeWatchData
{
    if (!self.user) {
        return @{kNoUserAvailable: @(YES)};
    }
    
    NSDictionary *message = @{
                              kTodayData: [self getTodayData],
                              kPredictionData: [self getNextThreeDaysPredictions],
                              kGlanceData: [self getGlanceData],
                              kNoUserAvailable: @(NO),
                              };
    return message;
}
                               

#pragma mark - next three days prediction
- (NSArray *)getNextThreeDaysPredictions
{
    NSMutableArray *predictions = [NSMutableArray array];
    
    NSDate *today = [GLDateUtils cutDate:[NSDate date]];
    for (NSInteger i=1; i<=3; i++) {
        NSDate *date = [today dateByAddingTimeInterval:3600*24*i];
        [predictions addObject:[self getPredictionForDate:date]];
    }
    
    return predictions;
}


- (NSDictionary *)getPredictionForDate:(NSDate *)date
{
    GLCycleData *currentCycle = self.user.currentCycle;
    if (!currentCycle) {
        return @{kPredictionText: @"No period data",
                 kPredictionColor: @(kPurpleColorHex)};
    }
    DayInfo *dayInfo = [CalendarDayInfoSummary dayInfoForDate:date];
    
    // treatment cycle day
    if (dayInfo.treatmentCycleDay > 0) {
        return @{kPredictionText: [NSString stringWithFormat:@"treatment cycle day %ld", (long)dayInfo.treatmentCycleDay],
                 kPredictionColor: @(dayInfo.backgroundColorHexValue)};

    }
    
    // period
    if (dayInfo.dayType  == kDayPeriod) {
        return @{kPredictionText: [self tipTextForPeriodDay:date withPeriodDayTitle:YES],
                 kPredictionColor: @(dayInfo.backgroundColorHexValue)};
    }
    
    // fertile score
    NSString *text;
    if ([self.user shouldHaveFertileScore]) {
        text = [NSString stringWithFormat:@"%.1f%% ", dayInfo.fertileScore];
        BOOL isTTC = (dayInfo.userStatus.status != STATUS_NON_TTC);
        text = [text stringByAppendingString:isTTC ? @"chance of pregnancy" : @"risk for pregnancy"];
    } else {
        NSInteger days = dayInfo.daysToNextCycle;
        text = [NSString stringWithFormat:@"%ld %@ until next cycle", (long)days, days == 1 ? @"day" : @"days"];

    }
    return @{kPredictionText: text,
             kPredictionColor: @(dayInfo.backgroundColorHexValue)};
}


#pragma mark - today

- (NSInteger)leastTimeSinceLastSync
{
    return 60 * 60 * 24;
}

- (NSDictionary *)getTodayData
{
    GLCycleData *currentCycle = self.user.currentCycle;
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    NSDate *today = [GLDateUtils cutDate:[NSDate date]];
    
    if (!currentCycle) {
        data[kButtonType] = @(ButtonTypeNone);
        NSDictionary *circle = @{kCircleTitle: @"No\nperiod data",
                                 kCircleBackgroundColor: @(kPurpleColorHex)};
        data[kCirclesData] = @[circle];
        return data;
    }
    
    DayInfo *dayInfo = [CalendarDayInfoSummary dayInfoForDate:[NSDate date]];
    NSInteger color = dayInfo.backgroundColorHexValue;
    
    // treatment cycle day
    if (dayInfo.treatmentCycleDay > 0) {
        NSString *title = [NSString stringWithFormat:@"%ld %@", dayInfo.treatmentCycleDay,dayInfo.treatmentCycleDay == 1 ? @"day" : @"days"];
        NSDictionary *circle = @{kCircleTitle: title,
                                 kCircleText: @"since treatment\ncycle started",
                                 kCircleBackgroundColor: @(color)};
        data[kCirclesData] = @[circle];
        data[kButtonType] = @(ButtonTypeNone);
        return data;
    }
    
    
    GLCycleData *cycleData = [self availableCycleDataForShortcutButton];
    
    
    // Button type
    NSInteger time = [[NSDate date] timeIntervalSinceDate:self.user.lastSyncTime];
    if (time > self.leastTimeSinceLastSync) {
        data[kButtonType] = @(ButtonTypeNone);
    }
    else if (cycleData && [cycleData periodContainsDate:[NSDate date]]) {
        data[kButtonType] = @(ButtonTypeMyPeriodIsLate);
    }
    else if (cycleData) {
        data[kButtonType] = @(ButtonTypeMyPeriodStartedToday);
    }
    else {
        data[kButtonType] = @(ButtonTypeNone);
    }
    
    if (self.isPeriodEditorOpen || !self.user.isPrimary) {
        data[kButtonType] = @(ButtonTypeNone);
    }
    

    if (dayInfo.dayType == kDayPeriod) {
        NSDictionary *circle = @{kCircleTitle: @"Period Day",
                                 kCircleText: [self tipTextForPeriodDay:today withPeriodDayTitle:NO],
                                 kCircleBackgroundColor: @(color)};
        data[kCirclesData] = @[circle];
        return data;
    }
    
   
    NSString *title = [NSString stringWithFormat:@"%ld %@", dayInfo.daysToNextCycle, dayInfo.daysToNextCycle == 1 ? @"day" : @"days"];
    
    NSDictionary *circleOne = @{kCircleTitle: title,
                                kCircleText: @"until next\ncycle",
                                kCircleBackgroundColor: @(color)};
    
    title = [NSString stringWithFormat:@"%.1f%%", dayInfo.fertileScore];
    
    NSString *text = (dayInfo.userStatus.status != STATUS_NON_TTC) ? @"chance of\npregnancy" : @"risk for\npregnancy";
    
    NSDictionary *circleTwo = @{kCircleTitle: title,
                                kCircleText: text,
                                kCircleBackgroundColor: @(color)
                                };
    if ([self.user shouldHaveFertileScore]) {
        data[kCirclesData] = @[circleOne, circleTwo];
    } else {
        data[kCirclesData] = @[circleOne];
    }
    
    return data;
}


#pragma mark - glance
- (NSDictionary *)getGlanceData
{
    GLCycleData *currentCycle = self.user.currentCycle;
    
    if (!currentCycle) {
        return @{kGlanceTitle: @"No period data",
                 kGlanceCircleColor: @(kPurpleColorHex)};
    }
    
    NSDate *today = [GLDateUtils cutDate:[NSDate date]];
    DayInfo *dayInfo = [CalendarDayInfoSummary dayInfoForDate:[NSDate date]];
    NSInteger color = dayInfo.backgroundColorHexValue;
    
    if (dayInfo.treatmentCycleDay > 0) {
        return @{kGlanceTitle: [NSString stringWithFormat:@"%ld %@", dayInfo.treatmentCycleDay,dayInfo.treatmentCycleDay == 1 ? @"day" : @"days"],
                 kGlanceSubtitle: @"since treatment cycle started",
                 kGlanceCircleColor: @(color)};
    }
    
    
    DayType dayType = [self.user predictionForDate:today];

    if (dayType == kDayPeriod) {
        return @{kGlanceTitle: @"Period Day",
                 kGlanceSubtitle: [self tipTextForPeriodDay:today withPeriodDayTitle:NO],
                 kGlanceCircleColor: @(color)};
    }
        
    NSString *title = [NSString stringWithFormat:@"%ld days", dayInfo.daysToNextCycle];
    NSString *subTitle = @"until next cycle";
    
    NSString *text;
    if ([self.user shouldHaveFertileScore]) {
        CGFloat score = [self.user fertileScoreOfDate:today];
        text = [NSString stringWithFormat:@"%.1f%% ", score];
        BOOL isTTC = dayInfo.userStatus.status != STATUS_NON_TTC;
        text = [text stringByAppendingString:isTTC ? @"chance of pregnancy" : @"risk for pregnancy"];
    } else {
        text = @"";
    }
    return @{kGlanceTitle: title,
             kGlanceSubtitle: subTitle,
             kGlanceText: text,
             kGlanceCircleColor: @(color)};
}




- (NSString *)tipTextForPeriodDay:(NSDate *)date withPeriodDayTitle:(BOOL)withPeriodDayTitle
{
    NSInteger idx = [date timeIntervalSince1970] / 86400;
    NSArray *textList;
    if (self.user.isSecondary) {
        textList = @[@"Hold her",
                     @"Compliment her",
                     @"Comfort her",
                     @"Talk to her",
                     @"Make her smile"];
    }
    else {
        textList = @[@"Indulge yourself",
                     @"Pamper yourself",
                     @"Snuggle away",
                     @"Eat well",
                     @"Stay hydrated"];
    }
    
    NSString *text = [textList objectAtIndex:idx % 5];
    
    if (!withPeriodDayTitle) {
        return text;
    }
        
    return [@"Period Day\n" stringByAppendingString:text];
}

#pragma mark - period update logic
- (void)updateCycleData:(GLCycleData *)cycleData withPeriodBeginDate:(NSDate *)periodBeginDate periodEndDate:(NSDate *)periodEndDate
{
    [self clearFutureCyclesAfterCycle:cycleData];
    cycleData.isPrediction = NO;
    NSMutableDictionary *period = cycleData.model;
    if (period) {
        period[@"pb"] = [periodBeginDate toDateLabel];
        period[@"pe"] = [periodEndDate toDateLabel];
        period[@"flag"] = @([period[@"flag"] integerValue] | 1 << FLAG_MODIFIED_BIT);
    } else {
        cycleData.model = [@{
                             @"pb": [periodBeginDate toDateLabel],
                             @"pe": [periodEndDate toDateLabel],
                             @"flag": @(1 << FLAG_MODIFIED_BIT | FLAG_SOURCE_USER_INPUT)
                             } mutableCopy];
    }

    [self saveCyclesWithCompensatedCycle:nil];
}

- (void)clearFutureCyclesAfterCycle:(GLCycleData *)cycleData
{
    if ([GLDateUtils daysBetween:cycleData.periodEndDate and:[NSDate date]] > 15) {
        return;
    }
    for (GLCycleData *data in self.cycleDataList) {
        if (data.isFuture && data != cycleData) {
            data.isPrediction = YES;
        }
    }
}


- (void)saveCyclesWithCompensatedCycle:(GLCycleData *)compensatedCycle
{
    NSDate *today = [NSDate date];
    NSMutableArray *periods = [NSMutableArray array];
    for (GLCycleData *data in self.cycleDataList) {
        if (!data.isPrediction || [data.periodBeginDate compare:today] <= NSOrderedSame) {
            NSDictionary *period = data.model;
            if (period) {
                [periods addObject:period];
            } else {
                [periods addObject:[@{
                                      @"pb": [data.periodBeginDate toDateLabel],
                                      @"pe": [data.periodEndDate toDateLabel],
                                      @"flag": @(FLAG_SOURCE_PREDICTION)
                                      } mutableCopy]];
            }
            
        }
        
    }
    if (compensatedCycle) {
        [periods addObject:[@{
                              @"pb": [compensatedCycle.periodBeginDate toDateLabel],
                              @"pe": [compensatedCycle.periodEndDate toDateLabel],
                              @"flag": @(1 << FLAG_ADDED_BY_DELETION_BIT)
                              } mutableCopy]];
    }
    // set pe one day later
    for (NSMutableDictionary *period in periods) {
        period[@"pe"] = [Utils dateLabelAfterDateLabel:period[@"pe"] withDays:1];
    }
    User *user = [User userOwnsPeriodInfo];
    [Period resetWithAlive:periods archived:nil forUser:user];
    user.periodDirty = YES;
    user.dirty = YES;
    [self dataUpdated];
}



- (void)dataUpdated
{
    if (!self.user.predictionMigrated0) {
        [self.user update:@"predictionMigrated0" value:@YES];
    }
    [self.user save];
    [self.user pushToServer];
    [self.user publish:EVENT_MULTI_DAILY_DATA_UPDATE data:DEFAULT_PB];
}


- (GLCycleData *)availableCycleDataForShortcutButton
{
    NSDate *today = [NSDate date];
    
    GLCycleData *cycleDataContainsToday;
    GLCycleData *cycleDataInNearFuture;
    
    for (GLCycleData *cycleData in self.cycleDataList) {
        if ([cycleData periodContainsDate:today]) {
            cycleDataContainsToday = cycleData;
            break;
        }
        NSInteger dayDiffs = [GLDateUtils daysBetween:today and:cycleData.periodBeginDate];
        if (dayDiffs > 0 && dayDiffs < 10) {
            cycleDataInNearFuture = cycleData;
        }
    }
    if (cycleDataContainsToday) {
        return cycleDataContainsToday;
    }
    if (cycleDataInNearFuture) {
        return cycleDataInNearFuture;
    }
    return nil;
}

- (BOOL)isFuture:(NSDate *)date {
    return [date compare:[GLDateUtils cutDate:[NSDate date]]] == NSOrderedDescending;
}

@end
