//
//  PeriodEditorViewController.m
//  emma
//
//  Created by ltebean on 15-4-28.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "PeriodEditorViewController.h"
#import "User.h"
#import "GLCycleData.h"
#import "StatusBarOverlay.h"
#import "UserDailyData.h"
#import "DropdownMessageController.h"
#import <GLPeriodEditor/GLPeriodEditorHeader.h>
#import "Tooltip.h"
#import "HealthProfileData.h"
#import <GLPeriodEditor/GLPeriodEditorTipsPopup.h>
#import <GLPeriodEditor/GLDateUtils.h>
#import "Period.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "NetworkLoadingView.h"

@interface PeriodEditorViewController ()
@property (nonatomic) BOOL pulled;
@end

@implementation PeriodEditorViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSDate *today = [NSDate date];
        self.firstDate = [Utils dateByAddingYears:-3 toDate:today];
        self.lastDate = [Utils dateByAddingDays:30 toDate:today];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    self.pulled = NO;
    [super viewWillAppear:animated];
    [Logging log:PAGE_IMP_PERIOD];
    [self subscribe:EVENT_PREDICTION_UPDATE selector:@selector(predictionUpdated:)];
    [self subscribe:EVENT_USER_SYNC_COMPLETED selector:@selector(syncCompleted)];
    [self subscribe:EVENT_USER_SYNC_FAILED selector:@selector(syncFailed)];
    
    NSDate *now = [NSDate date];
    NSInteger time = [now timeIntervalSinceDate:self.user.lastSyncTime];
    if (time > self.leastTimeSinceLastSync && !self.pulled) {
        [NetworkLoadingView showWithoutAutoClose];
        [self.user syncWithServer];
    }
}

- (void)syncCompleted
{
    [NetworkLoadingView hide];
    self.pulled = YES;
}

- (void)syncFailed
{
    [NetworkLoadingView hide];
    [UIAlertView bk_showAlertViewWithTitle:@"Sorry, we're unable to fetch your period data due to a poor connection." message:nil cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            
        }];
    }];
}

- (NSInteger)leastTimeSinceLastSync
{
    return 60 * 60 * 24;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self publish:EVENT_DID_ENTER_PERIOD_EDITOR];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unsubscribeAll];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self scrollToPage:0 animated:NO];
    [self publish:EVENT_DID_LEAVE_PERIOD_EDITOR];
}

- (NSMutableArray *)initialData
{
    BOOL showFeritileWindow = self.user.shouldHaveFertileScore;
    
    NSMutableArray *data = [NSMutableArray array];
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
        
        [data addObject:cycleData];
        if (cycleData.isFuture) {
            futureCycleCount ++;
        }
        if (futureCycleCount >= 2) {
            break;
        }
    }
    return data;
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


- (void)didAddCycleData:(GLCycleData *)cycleData
{
    [super didAddCycleData:cycleData];
    [self clearFutureCyclesAfterCycle:cycleData];
    cycleData.model = [@{
        @"pb": [cycleData.periodBeginDate toDateLabel],
        @"pe": [cycleData.periodEndDate toDateLabel],
        @"flag": @(1 << FLAG_ADDED_BIT | FLAG_SOURCE_USER_INPUT)
    } mutableCopy];
    [self saveCyclesWithCompensatedCycle:nil];
}


- (void)didUpdateCycleData:(GLCycleData *)cycleData withPeriodBeginDate:(NSDate *)periodBeginDate periodEndDate:(NSDate *)periodEndDate
{
    [super didUpdateCycleData:cycleData withPeriodBeginDate:periodBeginDate periodEndDate:periodEndDate];
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

- (void)didRemoveCycleData:(GLCycleData *)cycleData
{
    [super didRemoveCycleData:cycleData];
    GLCycleData *compensatedCycle = [self compensatedCycleAfterDelete:cycleData];
    if (compensatedCycle) {
        [self clearFutureCyclesAfterCycle:cycleData];
    }
    [self saveCyclesWithCompensatedCycle:compensatedCycle];
}


- (GLCycleData *)compensatedCycleAfterDelete:(GLCycleData *)deletedCycle
{
    for (GLCycleData *cycleData in self.cycleDataList) {
        if ([cycleData.periodBeginDate timeIntervalSinceDate:deletedCycle.periodEndDate] > 0 && !cycleData.isPrediction) {
            return nil;
        }
    }
    NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    NSInteger pbIndex = [Utils dateToIntFrom20130101:deletedCycle.periodBeginDate];
    NSInteger peIndex = [Utils dateToIntFrom20130101:deletedCycle.periodEndDate];
    NSInteger newPbIndex = MIN(pbIndex + 7, todayIndex + 15);
    NSDate *begin = [Utils dateIndexToDate:newPbIndex];
    NSDate *end = [Utils dateByAddingDays:(peIndex - pbIndex) toDate:begin];
    
    return [GLCycleData dataWithPeriodBeginDate:begin periodEndDate:end];
}


- (void)dataUpdated
{
    [self saveExpandPeriodCalendar];

    if (!self.user.predictionMigrated0) {
        [self.user update:@"predictionMigrated0" value:@YES];
    }
    [self.user save];
    
    // if user is in IUI or IVF
    if ([self.user isIUIOrIVF]) {
        [self.user syncWithServer];
    } else {
        [self.user pushToServer];
    }

    [self.user publish:EVENT_MULTI_DAILY_DATA_UPDATE data:DEFAULT_PB];

    [[StatusBarOverlay sharedInstance] postMessage:@"Magic and science at work..."
                                           options:StatusBarShowSpinner | StatusBarShowProgressBar
                                          duration:3.0];
    [[StatusBarOverlay sharedInstance] setProgress:0.0 animated:NO];
    [[StatusBarOverlay sharedInstance] setProgress:0.7 animated:YES duration:0.5];
    [Utils performInMainQueueAfter:0.5 callback:^{
        [[StatusBarOverlay sharedInstance] setProgress:0.8 animated:YES duration:1.25];
    }];
    [Utils performInMainQueueAfter:2.0 callback:^{
        [[StatusBarOverlay sharedInstance] postMessage:@"Prediction updated!"
                                               options:StatusBarShowProgressBar
                                              duration:1.5];
        [[StatusBarOverlay sharedInstance] setProgress:1.0 animated:YES duration:0.25];
    }];
}


- (void)didClickInfoIcon
{
    [GLPeriodEditorTipsPopup presentWithURL:[NSString stringWithFormat:@"%@/%@", EMMA_BASE_URL, @"term/period_editor_tips"]];
}


- (void)predictionUpdated:(Event *)event
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
    });
}


- (void)saveExpandPeriodCalendar
{
    NSDate *today = [[NSDate date] truncatedSelf];
    NSString *todayLabel = [Utils dailyDataDateLabel:today];
    UserDailyData *dailyData = [UserDailyData getUserDailyData:todayLabel forUser:self.user];
    if (!dailyData) {
        dailyData = [UserDailyData tset:todayLabel forUser:self.user];
    }
    if (!dailyData.expandPeriodCalendar) {
        [dailyData update:@"expandPeriodCalendar" value:@YES];
    }
}

- (void)didReceiveLoggingEvent:(LOGGING_EVENT)event data:(id)data
{
    if (event == BTN_CLK_TIPS) {
        NSLog(@"click tips");
        [Logging log:BTN_CLK_PERIOD_INFO_ICON];
    }
    else if (event == BTN_CLK_BACK) {
        NSLog(@"click back");
        [Logging log:BTN_CLK_PERIOD_BACK];
    }
    else if (event == BTN_CLK_VIEW_CAL_VIEW) {
        NSLog(@"click view cal view");
        [Logging log:BTN_CLK_PERIOD_VIEW_CAL_VIEW];
    }
    else if (event == BTN_CLK_VIEW_LIST_VIEW) {
        NSLog(@"click view list view");
        [Logging log:BTN_CLK_PERIOD_VIEW_LIST_VIEW];
    }
    else if (event == BTN_CLK_LIST_VIEW_PERIOD_DEL) {
        NSLog(@"click list delete");
        GLCycleData *cycleData = (GLCycleData *)data;
        NSString *begin = [cycleData.periodBeginDate toDateLabel];
        if (begin) {
            [Logging log:BTN_CLK_PERIOD_LIST_VIEW_DEL eventData:@{@"begin": begin}];
        } else {
            [Logging log:BTN_CLK_PERIOD_LIST_VIEW_DEL];
        }
    }
    else if (event == BTN_CLK_CAL_VIEW_PERIOD_SAVE) {
        NSLog(@"click cal save");
        if (data) {
            GLCycleData *cycleData = (GLCycleData *)data;
            NSDictionary *eventData = @{@"begin":[cycleData.periodBeginDate toDateLabel], @"end":[cycleData.periodEndDate toDateLabel]};
            [Logging log:BTN_CLK_PERIOD_SAVE eventData:eventData];
        } else {
            [Logging log:BTN_CLK_PERIOD_SAVE];
        }
    }
    else if (event == BTN_CLK_CAL_VIEW_PERIOD_DEL) {
        NSLog(@"click cal delete");
        [Logging log:BTN_CLK_PERIOD_DEL];
    }
    else if (event == BTN_CLK_CAL_VIEW_PERIOD_DEL_CONFIRM) {
        NSLog(@"click cal delete confirm");
        GLCycleData *cycleData = (GLCycleData *)data;
        NSString *begin = [cycleData.periodBeginDate toDateLabel];
        if (begin) {
            [Logging log:BTN_CLK_PERIOD_DEL_CONFIRM eventData:@{@"begin": begin}];
        } else {
            [Logging log:BTN_CLK_PERIOD_DEL_CONFIRM];
        }
    }
    else if (event == BTN_CLK_CAL_VIEW_PERIOD_ADD_CONFIRM) {
        NSLog(@"click cal add confirm");
        GLCycleData *cycleData = (GLCycleData *)data;
        NSString *begin = [cycleData.periodBeginDate toDateLabel];
        if (begin) {
            [Logging log:BTN_CLK_PERIOD_ADD_CONFIRM eventData:@{@"begin": begin}];
        } else {
            [Logging log:BTN_CLK_PERIOD_ADD_CONFIRM];
        }
    }
    else if (event == BTN_CLK_CAL_VIEW_PERIOD_IS_LATE) {
        NSLog(@"click cal is late");
        [Logging log:BTN_CLK_PERIOD_IS_LATE];
    }
    else if (event == BTN_CLK_CAL_VIEW_PERIOD_STARTED_TODAY) {
        NSLog(@"click cal start today");
        [Logging log:BTN_CLK_PERIOD_STARTED_TODAY];
    }
}

- (BOOL)isFuture:(NSDate *)date {
    return [date compare:[GLDateUtils cutDate:[NSDate date]]] == NSOrderedDescending;
}

- (User *)user
{
    return [User userOwnsPeriodInfo];
}
@end
