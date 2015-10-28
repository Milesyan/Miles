//
//  DailyLogCellTypeBMI.m
//  emma
//
//  Created by Ryan Ye on 7/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeBMI.h"
#import "User.h"
#import "PillButton.h"
#import <GLFoundation/GLPickerViewController.h>
#import "Logging.h"
#import "DailyLogConstants.h"
#import "UILinkLabel.h"
#import "Tooltip.h"
#import "WeightPicker.h"

#define INCH_TO_CM 2.54
#define KG_TO_POUNDS 2.2

#define INPUT_MODE_HEIGHT 1
#define INPUT_MODE_WEIGHT 2
#define INPUT_MODE_WEIGHT_WITH_BACK 3

#define MIN_FEET 4
#define MAX_FEET 8
#define MIN_POUNDS 50
#define MAX_POUNDS 500

#define DEFAULT_HEIGHT 170
#define DEFAULT_WEIGHT 68

@interface DailyLogCellTypeBMI() <UIActionSheetDelegate> {
    IBOutlet PillButton *BMIButton;
    IBOutlet UILabel *BMILabel;
    IBOutlet PillButton *BMIUnitButton;
    IBOutlet UILabel *sourceLabel;

    UILabel *weightUnitLabel;
    User *user;
    CGFloat weight;
    CGFloat height;
    CGFloat originWeight;
    CGFloat originHeight;
    NSNumberFormatter *numberFormatter;
    WeightPicker *picker;
}
@property (nonatomic)int inputMode;
@property (nonatomic, strong) NSDictionary *BMIUnits;

@end

@implementation DailyLogCellTypeBMI

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    user = [User currentUser]; 
    height = user.settings.height;
    
    picker = [[WeightPicker alloc] init];
    picker.showStartOverButton = YES;
    
    // key = action sheet text, value = panel text
    self.BMIUnits = @{
        @"LB": BMIUnitForLB,
        @"KG": @"KG"
        };

    numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.minimumFractionDigits = 1;
    numberFormatter.maximumFractionDigits = 1;
    numberFormatter.roundingMode = NSNumberFormatterRoundHalfUp;
    numberFormatter.locale = [NSLocale currentLocale];
}

- (void)setValue:(NSObject*)value forDate:(NSDate *)date {
    weight = [(NSNumber *)value floatValue];

    NSString *unit = [Utils getDefaultsForKey:kUnitForWeight];
    if (unit) {
        [BMIUnitButton setLabelText:unit bold:YES];
    } else {
        [BMIUnitButton setLabelText:BMIUnitForLB bold:YES];
        [Utils setDefaultsForKey:kUnitForWeight withValue:BMIUnitForLB];
    }
    [self updateBMI];
    sourceLabel.hidden = ([self.delegate fromMfpFlag] & FROM_MFP_FLAT_WEIGHT) ? NO : YES;
}

- (void)updateBMI {
    float showWeight = weight;
    if (weight == 0) {
        showWeight = [self previousWeight];

    }
    if (!showWeight) {
        [BMIButton setLabelText:@"Choose" bold:YES];
    } else {
        NSString *unit = [Utils getDefaultsForKey:kUnitForWeight];
        if ([unit isEqualToString:BMIUnitForLB]) {
            //lb
            CGFloat lb = [Utils poundsFromKg:showWeight];
            [BMIButton setLabelText:[NSString stringWithFormat:@"%.1f lbs", lb] bold:YES];
        } else {
            [BMIButton setLabelText:[NSString stringWithFormat:@"%.1f kg", showWeight] bold:YES];
        }
    }
    BMIButton.selected = (weight > 0);
}

- (CGFloat)previousWeight {
    return [[Utils getDefaultsForKey:DEFAULTS_PREVIOUS_WEIGHT] floatValue];
}

- (void)setPreviousWeight:(CGFloat)val {
    [Utils setDefaultsForKey:DEFAULTS_PREVIOUS_WEIGHT withValue:@(val)];
}

- (IBAction)buttonTouched:(id)sender {
    BMIButton.selected = (weight > 0);
    originWeight = weight;
    
    [self openPicker];

    [self logButton:BTN_CLK_HOME_WEIGHT clickType:CLICK_TYPE_NONE eventData:nil];
}


- (void)openPicker
{
    [picker presentWithWeightInKG:(BMIButton.selected? weight: self.previousWeight) andCallback:^(float w) {
        self.previousWeight = w;
        weight = w;
        [self.delegate updateDailyData:self.dataKey withValue:@(weight)];
        [self updateBMI];
    } andStartoverCallback:^(float h) {
        weight = 0;
        [self.delegate updateDailyData:self.dataKey withValue:@(DAILY_LOG_VAL_NONE)];
        [self updateBMI];
    }];
}

- (void)enterEditingVisibility:(BOOL)visible height:(CGFloat)cellHeight {
    [super enterEditingVisibility:visible height:cellHeight];
    [BMIButton setAlpha:0];
}

- (void)exitEditing {
    [super exitEditing];
    [BMIButton setAlpha:1];
}
@end
