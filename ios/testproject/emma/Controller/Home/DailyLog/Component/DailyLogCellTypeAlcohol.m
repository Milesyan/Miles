//
//  DailyLogCellTypeAlcohol.m
//  emma
//
//  Created by Eric Xu on 10/12/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//
#import "DailyLogConstants.h"
#import "DailyLogCellTypeAlcohol.h"
#import "PillButton.h"
#import "Logging.h"
#import "Tooltip.h"
#import "User.h"

@interface DailyLogCellTypeAlcohol()  {
    IBOutlet UISlider *slider;
    IBOutlet PillButton *yesBtn;
    IBOutlet PillButton *noBtn;
    __weak IBOutlet UILinkLabel *questionLabel;
    
}

- (IBAction)alcoholValueChanged:(id)sender;
- (void)updateDataValueFromSlider;
- (IBAction)dragStopped:(id)sender;
@end

@implementation DailyLogCellTypeAlcohol

- (void)awakeFromNib {
    exclusiveButtons = @[yesBtn, noBtn];
    
    if (![User currentUser].isFemale) {
        questionLabel.userInteractionEnabled = YES;
        questionLabel.useHyperlinkColor = YES;
        questionLabel.useUnderline = YES;
        [questionLabel setCallback:^(NSString *str) {
            [Tooltip tip:@"Alcohol"];
        } forKeyword:@"alcohol"];
    }
}

- (void)setup {
    
}

- (void)setValue:(NSObject *)value forDate:(NSDate *)date {
    [super setValue:value forDate:date];
    int val = [(NSNumber *)value intValue];
    yesBtn.selected = val >= ALCOHOL_YES;
    noBtn.selected = (val == ALCOHOL_NO);
    if (val >= ALCOHOL_YES) {
        [slider setValue:(val - ALCOHOL_YES) animated:NO];
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
    [self logButton:BTN_CLK_HOME_ALCOHOL_CHECK clickType:clickType eventData:nil];
    
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
        [self.delegate updateDailyData:self.dataKey withValue:@(ALCOHOL_NO)];
    } else {
        [self.delegate updateDailyData:self.dataKey withValue:@(DAILY_LOG_VAL_NONE)];
    }
}

- (void)updateDataValueFromSlider {
    self.dataValue = (int)slider.value + ALCOHOL_YES;
}

- (void)alcoholValueChanged:(id)sender {
    float newStep = roundf((slider.value) / 1);
    slider.value = newStep;
    [self updateDataValueFromSlider];
}

- (IBAction)dragStopped:(id)sender {
    [self logButton:BTN_CLK_HOME_ALCOHOL_AMOUNT clickType:CLICK_TYPE_NONE eventData:@{@"value": @((int)slider.value)}];
    [self updateData];
}


@end
