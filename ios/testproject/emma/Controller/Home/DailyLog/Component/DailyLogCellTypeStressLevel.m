//
//  DailyLogCellTypeStressLevel.m
//  emma
//
//  Created by Xin Zhao on 5/18/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "DailyLogConstants.h"
#import "DailyLogCellTypeStressLevel.h"
#import "PillButton.h"
#import "Logging.h"


@interface DailyLogCellTypeStressLevel()  {
    IBOutlet UISlider *slider;
    IBOutlet PillButton *yesBtn;
    IBOutlet PillButton *noBtn;
}

- (IBAction)smokeValueChanged:(id)sender;
- (void)updateDataValueFromSlider;
- (IBAction)dragStopped:(id)sender;
@end

@implementation DailyLogCellTypeStressLevel

- (void)awakeFromNib {
    exclusiveButtons = @[yesBtn, noBtn];
}

- (void)setup {
    
}

- (void)setValue:(NSObject *)value forDate:(NSDate *)date {
    [super setValue:value forDate:date];
    int val = [(NSNumber *)value intValue];
    yesBtn.selected = val >= STRESS_LEVEL_YES;
    noBtn.selected = (val == STRESS_LEVEL_NO);
    if (val >= STRESS_LEVEL_YES) {
        [slider setValue:(val - STRESS_LEVEL_YES) animated:NO];
    }
    self.dataValue = value;
}

- (IBAction)buttonTouched: (id)sender {
    PillButton *button = (PillButton *)sender;
    // logging first
    NSString * clickType;
    if (button == yesBtn) {
        clickType = button.selected ? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    } else {
        clickType = button.selected ? CLICK_TYPE_NO_SELECT : CLICK_TYPE_NO_UNSELECT;
    }
    [self logButton:BTN_CLK_HOME_SMOKE_CHECK clickType:clickType eventData:nil];
    
    for (PillButton *b in exclusiveButtons) {
        if (b != button && b.selected) {
            [b toggle:YES];
        }
    }
    [self.delegate findAndResignFirstResponder];
    if (yesBtn.selected) {
        [slider setValue:1 animated:NO];
        [self updateDataValueFromSlider];
    }
    if (button.inAnimation) {
        [self subscribeOnce:EVENT_PILLBUTTON_ANIMATION_END obj:button selector:@selector(updateData)];
    } else {
        [self updateData];
    }
}

- (void)updateData {
    if (yesBtn.selected) {
        [self.delegate updateDailyData:self.dataKey withValue:@(self.dataValue)];
    } else if (noBtn.selected) {
        [self.delegate updateDailyData:self.dataKey withValue:@(STRESS_LEVEL_NO)];
    } else {
        [self.delegate updateDailyData:self.dataKey withValue:@(DAILY_LOG_VAL_NONE)];
    }
}

- (void)updateDataValueFromSlider {
    self.dataValue = (int)slider.value + STRESS_LEVEL_YES;
}

- (void)smokeValueChanged:(id)sender {
    [self updateDataValueFromSlider];
}

- (IBAction)dragStopped:(id)sender {
    [self logButton:BTN_CLK_HOME_SMOKE_AMOUNT clickType:CLICK_TYPE_NONE eventData:@{@"value": @((int)slider.value)}];
    [self updateData];
}
@end

