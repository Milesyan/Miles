//
//  DailyLogCellTypeHeatSource.m
//  emma
//
//  Created by ltebean on 15-3-23.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeHeatSource.h"
#import "DailyLogConstants.h"
#import "Tooltip.h"

@interface DailyLogCellTypeHeatSource() {
    IBOutlet UIView *birthControlContainer;
    
    IBOutletCollection(PillButton) NSArray * threeButtonsInLine;
    IBOutletCollection(PillButton) NSArray * twoButtonsInLine;
    
    __weak IBOutlet UILinkLabel *questionLabel;
    IBOutletCollection(PillButton) NSArray *answerButtons;

    __weak IBOutlet PillButton *buttonHotBaths;
    __weak IBOutlet PillButton *buttonSaunas;
    __weak IBOutlet PillButton *buttonElectricBlankets;
    __weak IBOutlet PillButton *buttonOther;
}
@end


@implementation DailyLogCellTypeHeatSource
- (void)awakeFromNib {
    // set tags
    buttonHotBaths.tag = EXPOSE_TO_HEAT_HOT_BATH;
    buttonSaunas.tag = EXPOSE_TO_HEAT_SAUNAS;
    buttonElectricBlankets.tag = EXPOSE_TO_HEAT_ELECTRIC_BLANKET;
    buttonOther.tag = EXPOSE_TO_HEAT_OTHER;
    
    exclusiveButtons = @[button1, button2];
    
    self.expandedButtons = answerButtons;

    for (PillButton *b in self.expandedButtons) {
        b.titleLabel.font = [Utils boldFont:FONT_SIZE];
    }
    for (PillButton *b in answerButtons) {
        b.titleLabel.font = [Utils boldFont:FONT_SIZE];
    }
    
    if (WIDTH_DIFF_WITH_2_BUTTON > 0) {
        // two buttons in line
        for (UIView * v in twoButtonsInLine) {
            v.aWidth = v.aWidth + WIDTH_DIFF_WITH_2_BUTTON;
        }
        for (UIView * v in threeButtonsInLine) {
            v.aWidth = v.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
        }
    }
    questionLabel.userInteractionEnabled = YES;
    questionLabel.useHyperlinkColor = YES;
    questionLabel.useUnderline = YES;
    [questionLabel setCallback:^(NSString *str) {
        [Tooltip tip:@"Direct heat sources"];
    } forKeyword:@"direct heat sources"];
}

- (IBAction)buttonTouched:(id)sender
{
    PillButton *button = (PillButton *)sender;
    [self logButton:BTN_CLK_DAILYLOG_EXPOSED_TO_HEAT clickType:[self getClickType:button yesBtnTag:DAILY_LOG_VAL_YES] eventData:nil];
    [super buttonTouched:sender];
}

- (IBAction)expandedButtonTouched: (id)sender
{
    PillButton *button = (PillButton *)sender;
    NSString * clickType = button.selected? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    [self logButton:BTN_CLK_DAILYLOG_EXPOSED_TO_HEAT_TYPE clickType:clickType eventData:@{@"heat_type": @(button.tag)}];
    [super expandedButtonTouched:sender];
}

- (void)updateData
{
    [super updateData];
}

@end
