//
//  DailyLogCellTypeMaleIntercourse.m
//  emma
//
//  Created by ltebean on 15-3-23.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeMaleIntercourse.h"
#import "DailyLogConstants.h"
#import "Tooltip.h"

@interface DailyLogCellTypeMaleIntercourse() {
    IBOutlet UIView *birthControlContainer;
    
    __weak IBOutlet UILinkLabel *questionLabel;
    IBOutletCollection(PillButton) NSArray * threeButtonsInLine;
    IBOutletCollection(PillButton) NSArray * twoButtonsInLine;
    
    IBOutletCollection(PillButton) NSArray *answerButtons;

    __weak IBOutlet PillButton *buttonNone;
    __weak IBOutlet PillButton *buttonSiliconBased;
    __weak IBOutlet PillButton *buttonWaterBased;
    __weak IBOutlet PillButton *buttonOilBased;
    __weak IBOutlet PillButton *buttonOther;
}
- (IBAction)answerButtonTouched:(id)sender;

@end


@implementation DailyLogCellTypeMaleIntercourse
- (void)awakeFromNib {
    // set tags

    buttonNone.tag = INTERCOURSE_LUBRICANT_NONE;
    buttonSiliconBased.tag = INTERCOURSE_LUBRICANT_SILICON;
    buttonWaterBased.tag = INTERCOURSE_LUBRICANT_WATER;
    buttonOilBased.tag = INTERCOURSE_LUBRICANT_OIL;
    buttonOther.tag = INTERCOURSE_LUBRICANT_OTHER;
    
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
        [Tooltip tip:@"Sex"];
    } forKeyword:@"sex"];
}

- (IBAction)buttonTouched:(id)sender
{
    PillButton *button = (PillButton *)sender;
    [self logButton:BTN_CLK_HOME_SEXUAL_CHECK clickType:[self getClickType:button yesBtnTag:DAILY_LOG_VAL_YES] eventData:nil];
    [super buttonTouched:sender];
}

- (IBAction)expandedButtonTouched:(id)sender
{
    PillButton *button = (PillButton *)sender;
    NSString * clickType = button.selected? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    [self logButton:BTN_CLK_DAILYLOG_SEX_LUBRICANT clickType:clickType eventData:@{@"lubricant": @(button.tag)}];
    [super expandedButtonTouched:sender];
}


- (void)updateData
{
    [super updateData];
}

@end
