//
//  DailyLogCellTypeMasturbation.m
//  emma
//
//  Created by ltebean on 15-3-23.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeMasturbation.h"
#import "DailyLogConstants.h"
#import "Tooltip.h"

@interface DailyLogCellTypeMasturbation()
@property (weak, nonatomic) IBOutlet PillButton *buttonOnce;
@property (weak, nonatomic) IBOutlet PillButton *buttonTwice;
@property (weak, nonatomic) IBOutlet PillButton *buttonMore;
@property (weak, nonatomic) IBOutlet UILinkLabel *questionLabel;

@end


@implementation DailyLogCellTypeMasturbation

- (void)awakeFromNib
{
    
    self.buttonOnce.tag = MASTURBATE_ONCE;
    self.buttonTwice.tag = MASTURBATE_TWICE;
    self.buttonMore.tag = MASTURBATE_MORE;

    exclusiveButtons = @[button1, button2];
    self.expandedButtons = @[self.buttonOnce, self.buttonTwice, self.buttonMore];
    
    for (PillButton *b in self.expandedButtons) {
        b.titleLabel.font = [Utils boldFont:FONT_SIZE];
    }
    
    self.buttonOnce.aWidth = self.buttonOnce.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
    self.buttonTwice.aWidth = self.buttonTwice.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
    self.buttonMore.aWidth = self.buttonMore.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
    
    self.questionLabel.userInteractionEnabled = YES;
    self.questionLabel.useHyperlinkColor = YES;
    self.questionLabel.useUnderline = YES;
    [self.questionLabel setCallback:^(NSString *str) {
        [Tooltip tip:@"Masturbate"];
    } forKeyword:@"masturbate"];

}

- (IBAction)buttonTouched:(id)sender
{
    PillButton *button = (PillButton *)sender;
    [self logButton:BTN_CLK_DAILYLOG_MASTURBATE clickType:[self getClickType:button yesBtnTag:DAILY_LOG_VAL_YES] eventData:nil];
    [super buttonTouched:sender];
}

- (IBAction)expandedButtonTouched:(id)sender
{
    PillButton *button = (PillButton *)sender;
    NSString * clickType = button.selected? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    [self logButton:BTN_CLK_DAILYLOG_MASTURBATE_TIMES clickType:clickType eventData:@{@"count": @(button.tag)}];
    [super expandedButtonTouched:sender];
}


- (void)updateData
{
    [super updateData];
}

@end
