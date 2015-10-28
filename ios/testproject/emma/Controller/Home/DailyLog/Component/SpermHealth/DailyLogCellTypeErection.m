//
//  DailyLogCellTypeErection.m
//  emma
//
//  Created by ltebean on 15-3-23.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeErection.h"
#import "PillButton.h"
#import "DailyLogConstants.h"

@interface DailyLogCellTypeErection()

@end

@implementation DailyLogCellTypeErection

- (void)awakeFromNib {
    exclusiveButtons = @[button1, button2];
}

- (IBAction)buttonTouched:(id)sender
{
    PillButton *button = (PillButton *)sender;
    [self logButton:BTN_CLK_DAILYLOG_TROUBLE_ERECTION clickType:[self getClickType:button yesBtnTag:DAILY_LOG_VAL_YES] eventData:nil];
    [super buttonTouched:sender];
}

- (void)updateData
{
    [super updateData];
}

@end
