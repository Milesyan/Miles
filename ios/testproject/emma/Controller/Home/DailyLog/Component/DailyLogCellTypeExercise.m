//
//  DailyLogCellTypeActivityLevel.m
//  emma
//
//  Created by Eric Xu on 12/2/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//
#import "DailyLogConstants.h"
#import "DailyLogCellTypeExercise.h"
#import <GLFoundation/GLPickerViewController.h>
#import "PillButton.h"

@interface DailyLogCellTypeExercise() {
    IBOutlet PillButton *lightlyActiveButton;
    IBOutlet PillButton *activeButton;
    IBOutlet PillButton *veryActiveButton;
}

@end

@implementation DailyLogCellTypeExercise

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // set tags
    lightlyActiveButton.tag = EXERCISE_LIGHTLY;
    activeButton.tag        = EXERCISE_ACTIVE;
    veryActiveButton.tag    = EXERCISE_VERY_ACTIVE;
    
    exclusiveButtons = @[button1, button2];
    self.expandedButtons = @[lightlyActiveButton, activeButton, veryActiveButton];
    
    for (PillButton *b in self.expandedButtons) {
        b.titleLabel.font = [Utils boldFont:FONT_SIZE];
    }
    
    lightlyActiveButton.aWidth = lightlyActiveButton.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
    activeButton.aWidth = activeButton.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
    veryActiveButton.aWidth = veryActiveButton.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
}

- (void)setValue:(NSObject *)value forDate:(NSDate *)date {
    [super setValue:value forDate:date];
    NSInteger val = [(NSNumber *)value integerValue];
    button1.selected = (val >= DAILY_LOG_VAL_YES);
    button2.selected = (val == DAILY_LOG_VAL_NO);
    
    for (PillButton *button in self.expandedButtons) {
        // ignore the right 2 bits
        button.selected = (val >> 2 << 2) == button.tag ;
    }
}

- (IBAction)buttonTouched:(id)sender
{
    PillButton *button = (PillButton *)sender;
    [self logButton:BTN_CLK_HOME_EXERCISE clickType:[self getClickType:button yesBtnTag:DAILY_LOG_VAL_YES] eventData:nil];
    [super buttonTouched:sender];
}

- (IBAction)expandedButtonTouched:(id)sender
{
    PillButton *button = (PillButton *)sender;
    NSString * clickType = button.selected? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    [self logButton:BTN_CLK_HOME_EXERCISE_TYPE clickType:clickType eventData:@{@"active": @(button.tag)}];
    [super expandedButtonTouched:sender];
}

- (void)updateData
{
    [super updateData];
}



@end
