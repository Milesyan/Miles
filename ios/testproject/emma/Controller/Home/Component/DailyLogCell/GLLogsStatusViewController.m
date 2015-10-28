//
//  GLLogsStatusViewController.m
//  kaylee
//
//  Created by Eric Xu on 11/17/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLLogsStatusViewController.h"
#import "User.h"
#import "PillButton.h"
#import <GLFoundation/GLDialogViewController.h>
#import <DACircularProgress/DACircularProgressView.h>
#import "UserDailyData.h"
#import "Tooltip.h"

@interface GLLogsStatusViewController ()
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) GLDialogViewController *dialog;

@property (nonatomic, strong) IBOutlet UILabel *dayLabel;
@property (nonatomic, strong) IBOutlet UILabel *weekLabel;
@property (nonatomic, strong) IBOutlet UILabel *otherLabel;
@property (nonatomic, strong) IBOutlet DACircularProgressView *weeklyProgressView;
@property (nonatomic, strong) IBOutlet UILabel *weeklyProgressLabel;

@property (nonatomic, strong) IBOutletCollection(PillButton) NSArray *weeklyButtons;
@property (nonatomic, strong) IBOutletCollection(PillButton) NSArray *weeklyLabelButtons;
@property (nonatomic, strong) IBOutletCollection(UILabel) NSArray *todayLabels;
@end

@implementation GLLogsStatusViewController

static GLLogsStatusViewController *inst;
+ (instancetype)viewController
{
    if (!inst) {
        inst = [[GLLogsStatusViewController alloc] initWithNibName:@"GLLogsStatusViewController" bundle:nil];
    }
    return inst;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.weeklyProgressView setRoundedCorners:YES];
    [self.weeklyProgressView setClockwiseProgress:YES];
    [self.weeklyProgressView setTintColor:GLOW_COLOR_PURPLE];
    [self.weeklyProgressView setProgressTintColor:GLOW_COLOR_PURPLE];
    [self.weeklyProgressView setTrackTintColor:UIColorFromRGBA(0x5B65CE50)];
    [self.weeklyProgressView setThicknessRatio:.2];

    for (PillButton *button in self.weeklyButtons) {
        button.hidden = YES;// (button.tag % 3 != 0);
    }
    
    for (UILabel *today in self.todayLabels) {
        today.hidden = YES;
    }

    for (PillButton *button in self.weeklyLabelButtons) {
        [button setLabelText:@[@"", @"S", @"M", @"T", @"W", @"T", @"F", @"S"][button.tag] bold:YES];
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.date) {
        [self.weeklyProgressView setProgress:0 animated:NO];
        [self.weeklyProgressLabel setText:@"0%"];
        return;
    }
    
    [self.dayLabel setText:[self.date toReadableDate]];
    
    // reset
    for (PillButton *button in self.weeklyButtons) {
        button.hidden = YES;
    }
    for (UILabel *l in self.todayLabels) {
        l.hidden = YES;
    }
    // #DBDCEF, the color if not logged
    for (PillButton *p in self.weeklyLabelButtons) {
        [p setButtonColor:UIColorFromRGB(0xDBDCEF)];
    }
    
    NSArray *result = [UserDailyData userDailyDataInWeek:self.date forUser:[User currentUser]];
    int count = 0;
    for (int i=0; i<7; i++) {
        BOOL hasDailyData = [result[i] isKindOfClass:[NSNull class]] ? NO : YES;
        if (hasDailyData) {
            count ++;
            for (PillButton *button in self.weeklyButtons) {
                if (button.tag == i+1) {
                    button.hidden = NO;
                }
            }
        }
    }
    
    // get progress
    float pp = count / 7.0;
    
    [self.weeklyProgressView setProgress:pp animated:YES];
    [self.weeklyProgressLabel setText:[NSString stringWithFormat:@"%d / 7", count]];

    // get the latest date
    NSInteger dateIndex = [self.date getWeekDay];
    NSString * dateLabel = [self.date toDateLabel];
    NSString * saturday =  [Utils dateLabelAfterDateLabel:dateLabel withDays:(7 - dateIndex)];
    if ([Utils dateLabel:saturday minus: [[NSDate date] toDateLabel]] >= 0) {
        NSInteger todayIndex = [[NSDate date] getWeekDay];
        for (UILabel *l in self.todayLabels) {
            if (l.tag == todayIndex) {
                l.hidden = NO;
            }
        }
        for (PillButton *p in self.weeklyLabelButtons) {
            if (p.tag > todayIndex) {
                [p setButtonColor:UIColorFromRGB(0xD1D1D1)];
            }
        }
    }    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    NSDictionary *logResult = [GLHealthScoreManager logsOfWeek:self.date];
//
//    [self.weeklyProgressView setProgress:[logResult[LOG_RESULT_KEY_FLT] floatValue] animated:YES];
//    [self.weeklyProgressLabel setText:logResult[LOG_RESULT_KEY_STR]];
}



- (void)presentForDate:(NSDate *)date
{
    self.date = date;
    
    self.dialog = [GLDialogViewController sharedInstance];
    [self.dialog presentWithContentController:self];
}


- (IBAction)infoButtonClicked:(id)sender
{
    [self subscribeOnce:EVENT_DIALOG_DISMISSED obj:self.dialog handler:^(Event *evt){
        [Tooltip tip:@"Logs this week"];
    }];
    [self.dialog close];
}


@end
