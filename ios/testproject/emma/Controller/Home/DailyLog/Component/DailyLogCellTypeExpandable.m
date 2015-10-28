//
//  DailyLogCellTypeExpandable.m
//  emma
//
//  Created by Eric Xu on 2/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeExpandable.h"
#import "PillButton.h"
#import "Logging.h"
#import "UserDailyData.h"

@interface DailyLogCellTypeExpandable() {
}

@end

@implementation DailyLogCellTypeExpandable

- (void)setup {
    [self setClipsToBounds:YES];
    exclusiveButtons = @[button1, button2];
}

- (void)setValue:(NSObject *)value forDate:(NSDate *)date {
    [super setValue:value forDate:date];
    NSInteger val = [(NSNumber *)value integerValue];
    button1.selected = (val >= DAILY_LOG_VAL_YES);
    button2.selected = (val == DAILY_LOG_VAL_NO);
    
    for (PillButton *button in self.expandedButtons) {
        if (self.exclusive) {
            button.selected = (val / button.tag) == 1;
        } else {
            button.selected = (val % (2 * button.tag)) / button.tag == 1;
        }
    }
}

- (IBAction)buttonTouched:(id) sender {
    PillButton *button = (PillButton *)sender;
    if (!button.selected || button.tag == DAILY_LOG_VAL_NO) {
        for (PillButton *b in self.expandedButtons) {
            b.selected = NO;
        }
    }

    if ([self.dataKey isEqualToString:DL_CELL_KEY_MOODS]) {
        [self logButton:BTN_CLK_HOME_EMOTION_CHECK clickType:[self getClickType:button yesBtnTag:DAILY_LOG_VAL_YES] eventData:nil];
    } else if ([self.dataKey isEqualToString:DL_CELL_KEY_PHYSICALDISCOMFORT]) {
        [self logButton:BTN_CLK_HOME_PHYSICAL_DISCOMFORT_CHECK clickType:[self getClickType:button yesBtnTag:DAILY_LOG_VAL_YES] eventData:nil];
    } else if ([self.dataKey isEqualToString:DL_CELL_KEY_PERIOD_FLOW]) {
        [self logButton:BTN_CLK_HOME_PERIOD_FLOW_CHECK clickType:[self getClickType:button yesBtnTag:DAILY_LOG_VAL_YES] eventData:nil];
    }
    [super buttonTouched:sender];
}

- (IBAction)expandedButtonTouched: (id)sender {
    PillButton *button = (PillButton *)sender;
    NSString * clickType = button.selected? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    if ([self.dataKey isEqual:DL_CELL_KEY_PERIOD_FLOW]) {
        [self logButton:BTN_CLK_HOME_PERIOD_FLOW_SLIDE clickType:clickType eventData:@{@"value": @(button.tag)}];
    }

    if(self.exclusive) {
        for (PillButton *b in self.expandedButtons) {
            if (b != button && b.selected) {
                [b toggle:YES];
            }
        }
    }
    [self.delegate findAndResignFirstResponder];
    [self updateData];

}

- (void)updateData {
    NSInteger i = 0;
    for (PillButton *b in exclusiveButtons) {
        i = i + (b.selected? b.tag: 0);
    }
    for (PillButton *b in self.expandedButtons) {
        i = i + (b.selected? b.tag: 0);
    }

    [self.delegate updateDailyData:self.dataKey withValue:@(i)];
}

@end
