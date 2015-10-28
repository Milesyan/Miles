//
//  DailyLogCellTypePeriodFlow.m
//  emma
//
//  Created by Eric Xu on 12/11/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogConstants.h"
#import "DailyLogCellTypePeriodFlow.h"
#import "PillButton.h"
#import "Logging.h"


@interface DailyLogCellTypePeriodFlow() {
    IBOutlet PillButton *spottingButton;
    IBOutlet PillButton *lowButton;
    IBOutlet PillButton *mediumButton;
    IBOutlet PillButton *heavyButton;

    IBOutlet UILinkLabel *how;
}
@property (nonatomic) BOOL changedButtons;

@end

@implementation DailyLogCellTypePeriodFlow

- (void)awakeFromNib {
    self.exclusive = YES;
    self.expandedButtons = @[spottingButton, lowButton, mediumButton, heavyButton];
    [self setup];
    self.changedButtons = NO;
}

- (void)setInPeriod:(BOOL)inPeriod {
    _inPeriod = inPeriod;
    if (inPeriod) {
        [self.label setText:@"Record your menstrual flow?"];
        spottingButton.hidden = NO;
        [lowButton setLabelText:@"Light" bold:YES];
        [mediumButton setLabelText:@"Medium" bold:YES];
        [heavyButton setLabelText:@"Heavy" bold:YES];
        [how setText:@"PERIOD FLOW"];
        
        // 4 buttons in line
        if (!self.changedButtons) {
            spottingButton.aWidth = spottingButton.aWidth + WIDTH_DIFF_WITH_4_BUTTON;
            lowButton.aWidth = lowButton.aWidth + WIDTH_DIFF_WITH_4_BUTTON;
            mediumButton.aWidth = mediumButton.aWidth + WIDTH_DIFF_WITH_4_BUTTON;
            heavyButton.aWidth = heavyButton.aWidth + WIDTH_DIFF_WITH_4_BUTTON;
        }
    }
    else {
        [self.label setText:@"Any spotting?"];
        spottingButton.hidden = YES;
        [lowButton setLabelText:@"Light" bold:YES];
        [mediumButton setLabelText:@"Medium" bold:YES];
        [heavyButton setLabelText:@"Heavy" bold:YES];
        [how setText:@"HOW MUCH"];
        
        // 3 buttons in line
        if (!self.changedButtons) {
            spottingButton.aWidth = 0;
            lowButton.aLeft = 5.0f;
            lowButton.aWidth = lowButton.aWidth + WIDTH_DIFF_WITH_3_BUTTON + 24;
            mediumButton.aWidth = mediumButton.aWidth + WIDTH_DIFF_WITH_3_BUTTON + 24;
            heavyButton.aWidth = heavyButton.aWidth + WIDTH_DIFF_WITH_3_BUTTON + 24;
        }
    }
    self.changedButtons = YES;
}

- (void)setValue:(NSObject*)value forDate:(NSDate *)date {
    int val = [(NSNumber *)value intValue];
    // Translate old slider value (2-100)
    if (val > DAILY_LOG_VAL_YES) {
        val -= DAILY_LOG_VAL_YES;
        if (!self.inPeriod) {
            if (val <= 33) {
                val = PERIOD_FLOW_LOW;
            } else if (val <= 66) {
                val = PERIOD_FLOW_MEDIUM;
            } else {
                val = PERIOD_FLOW_HEAVY;
            }
        }
        else {
            if (val <= 10) {
                val = PERIOD_FLOW_SPOTTING;
            } else if (val <= 33) {
                val = PERIOD_FLOW_LOW;
            } else if (val <= 66) {
                val = PERIOD_FLOW_MEDIUM;
            } else {
                val = PERIOD_FLOW_HEAVY;
            }
        }
        val += SPOTTING_YES;
    }
    GLLog(@"Period flow set value: %d", val);
    [super setValue:@(val) forDate:date];
}
@end
