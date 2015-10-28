//
//  DailyLogCellTypeFever.m
//  emma
//
//  Created by ltebean on 15-3-23.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeFever.h"
#import "DailyLogConstants.h"
#import "Tooltip.h"

@interface DailyLogCellTypeFever() 
@property (weak, nonatomic) IBOutlet PillButton *buttonOneDay;
@property (weak, nonatomic) IBOutlet PillButton *buttonTwoDays;
@property (weak, nonatomic) IBOutlet PillButton *buttonMoreDays;
@property (weak, nonatomic) IBOutlet UILinkLabel *questionLabel;

@end


@implementation DailyLogCellTypeFever

- (void)awakeFromNib
{
    // set tags
    self.buttonOneDay.tag = FEVER_ONE_DAY;
    self.buttonTwoDays.tag = FEVER_TWO_DAYS;
    self.buttonMoreDays.tag = FEVER_THREE_PLUS_DAYS;
    
    exclusiveButtons = @[button1, button2];
    self.expandedButtons = @[self.buttonOneDay, self.buttonTwoDays, self.buttonMoreDays];
    
    for (PillButton *b in self.expandedButtons) {
        b.titleLabel.font = [Utils boldFont:FONT_SIZE];
    }
    
    self.buttonOneDay.aWidth = self.buttonOneDay.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
    self.buttonTwoDays.aWidth = self.buttonTwoDays.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
    self.buttonMoreDays.aWidth = self.buttonMoreDays.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
    
    self.questionLabel.userInteractionEnabled = YES;
    self.questionLabel.useHyperlinkColor = YES;
    self.questionLabel.useUnderline = YES;
    [self.questionLabel setCallback:^(NSString *str) {
        [Tooltip tip:@"Fever"];
    } forKeyword:@"fever"];
    
}

- (IBAction)buttonTouched:(id)sender
{
    PillButton *button = (PillButton *)sender;
    [self logButton:BTN_CLK_DAILYLOG_FEVER clickType:[self getClickType:button yesBtnTag:DAILY_LOG_VAL_YES] eventData:nil];
    [super buttonTouched:sender];
}

- (IBAction)expandedButtonTouched: (id)sender
{
    PillButton *button = (PillButton *)sender;
    NSString * clickType = button.selected? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    [self logButton:BTN_CLK_DAILYLOG_FEVER_TYPE clickType:clickType eventData:@{@"fever_days": @(button.tag)}];
    [super expandedButtonTouched:sender];
}

- (void)updateData
{
    [super updateData];
}
@end
