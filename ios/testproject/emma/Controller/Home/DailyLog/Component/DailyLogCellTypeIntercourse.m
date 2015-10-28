//
//  DailyLogCellTypeIntercourse.m
//  emma
//
//  Created by Ryan Ye on 4/7/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogConstants.h"
#import "DailyLogCellTypeIntercourse.h"
#import "PillButton.h"
#import "logging.h"
#import "Tooltip.h"
#import "User.h"

@interface DailyLogCellTypeIntercourse() {
    IBOutlet PillButton *button3;
    IBOutlet PillButton *button4;
    
    IBOutlet PillButton *buttonOnBottom;
    IBOutlet PillButton *buttonBentOver;
    IBOutlet PillButton *buttonOnTop;
    IBOutlet PillButton *buttonOther;
    
    IBOutlet UIView *orgasmContainer;
    IBOutlet UIView *birthControlContainer;
    
    IBOutletCollection(PillButton) NSArray * threeButtonsInLine;
    IBOutletCollection(PillButton) NSArray * twoButtonsInLine;
    
    __weak IBOutlet UIImageView *hiddenIndicatorImageView;
    __weak IBOutlet UILinkLabel *birthControlUsedLinkLabel;
    IBOutletCollection(PillButton) NSArray *birthControlButtons;
//    UILabel *extraLabel;
//    UIView *extraButtonsContainer;
    NSArray *allButtons;
}

- (IBAction)extraExclusiveButtonTouched: (id)sender;
- (IBAction)birthControlButtonTouched:(id)sender;
@end

@implementation DailyLogCellTypeIntercourse

- (void)awakeFromNib {
    // set tags
    button3.tag = INTERCOURSE_ORGASM_YES;
    button4.tag = INTERCOURSE_ORGASM_NO;
    buttonOnBottom.tag  = INTERCOURSE_POSITION_ONBOTTOM;
    buttonBentOver.tag  = INTERCOURSE_POSITION_INFRONT;
    buttonOnTop.tag     = INTERCOURSE_POSITION_ONTOP;
    buttonOther.tag     = INTERCOURSE_POSITION_OTHER;
    
    allButtons = @[button1, button2, button3, button4, buttonBentOver, buttonOnBottom, buttonOnTop,  buttonOther];
    allButtons = [allButtons arrayByAddingObjectsFromArray:birthControlButtons];
    exclusiveButtons = @[button1, button2];
    self.expandedButtons = @[buttonOnBottom, buttonBentOver, buttonOnTop, buttonOther];
    self.extraExclusiveButtons = @[button3, button4];
    
    for (PillButton *b in self.expandedButtons) {
        b.titleLabel.font = [Utils boldFont:FONT_SIZE];
    }    
    for (PillButton *b in birthControlButtons) {
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
    if ([self needShowHiddenIndicator]) {
        hiddenIndicatorImageView.hidden = NO;
    } else {
        hiddenIndicatorImageView.hidden = YES;
    }
}

- (BOOL)needShowHiddenIndicator
{
    if ([User currentUser].partner) {
        return YES;
    } else {
        return NO;
    }
}

- (void)setup {
    
    [super setup];
}

- (void)setPurposeTTC:(BOOL)purposeTTC {
    _purposeTTC = purposeTTC;
    orgasmContainer.hidden = !purposeTTC;
    birthControlContainer.hidden = purposeTTC;
    
    if ([self needShowHiddenIndicator]) {
        hiddenIndicatorImageView.hidden = orgasmContainer.hidden;
    }
}

- (void)setValue:(NSObject *)value forDate:(NSDate *)date {
    [super setValue:value forDate:date]; 
    int val = [(NSNumber *)value intValue];
    button3.selected = (val % 0x100) / LOG_VAL_INTERCOURSE_ORGASM_CHECK == 1;
    button4.selected = (val % 0x100) / LOG_VAL_INTERCOURSE_ORGASM_CROSS == 1;
    
    for (PillButton *b in allButtons) {
        b.selected = (val % (b.tag * 2))/ b.tag == 1;
    }
    
    if (DETECT_TIPS) {
        birthControlUsedLinkLabel.userInteractionEnabled = YES;
        birthControlUsedLinkLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        [Tooltip setCallbackForAllKeywordOnLabel:birthControlUsedLinkLabel
            caseSensitive:NO];
    }
}

- (IBAction)expandedButtonTouched: (id)sender
{
    PillButton *button = (PillButton *)sender;
    NSString * clickType = button.selected? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    [self logButton:BTN_CLK_HOME_SEX_POSITION clickType:clickType eventData:@{@"position": @(button.tag)}];
    [super expandedButtonTouched:sender];
}

- (IBAction)extraExclusiveButtonTouched: (id)sender {
    PillButton *button = (PillButton *)sender;
    [self logButton:BTN_CLK_HOME_SEX_ORGASM clickType:[self getClickType:button yesBtnTag:16] eventData:nil];
    
    for (PillButton *b in self.extraExclusiveButtons) {
        if (b != button && b.selected) {
            [b toggle:YES];
        }
    }
    
    [self.delegate findAndResignFirstResponder];
    [self updateData];
    
}

- (IBAction)birthControlButtonTouched:(id)sender {
    PillButton *button = (PillButton *)sender;
    [self logButton:BTN_CLK_HOME_SEX_BIRTH_CONTROL clickType:[self getClickType:button yesBtnTag:16] eventData:nil];

    for (PillButton *b in birthControlButtons) {
        if (b != button && b.selected) {
            [b toggle:YES];
        }
    }

    [self.delegate findAndResignFirstResponder];
    [self updateData];

}

- (IBAction)buttonTouched:(id) sender {
    PillButton *button = (PillButton *)sender;
    [self logButton:BTN_CLK_HOME_SEXUAL_CHECK clickType:[self getClickType:button yesBtnTag:DAILY_LOG_VAL_YES] eventData:nil];

    button3.selected = NO;
    button4.selected = NO;
    
    for (PillButton *b in birthControlButtons) {
        b.selected = NO;
    }

    [super buttonTouched:sender];
}

- (void)updateData {
    NSInteger i = 0;
    for (PillButton *b in allButtons) {
        i = i + (b.selected? b.tag: 0);
    }
    [self.delegate updateDailyData:self.dataKey withValue:@(i)];
}

@end
