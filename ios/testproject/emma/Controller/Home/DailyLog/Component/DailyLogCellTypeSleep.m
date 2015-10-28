//
//  DailyLogCellTypeSleep.m
//  emma
//
//  Created by Peng Gu on 8/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeSleep.h"
#import "PillButton.h"
#import "Logging.h"
#import <GLFoundation/GLGeneralPicker.h>
#import "BaseDatePicker.h"

@interface DailyLogCellTypeSleep () <GLGeneralPickerDataSource, GLGeneralPickerDelegate>

@property (nonatomic, weak) IBOutlet PillButton *button;
@property (nonatomic, strong) GLGeneralPicker *timePicker;

@property (nonatomic, strong) NSArray *hours;
@property (nonatomic, strong) NSArray *mins;

@property (nonatomic, strong) NSNumber *sleepDuration;

- (IBAction)buttonClicked:(id)sender;

@end


@implementation DailyLogCellTypeSleep


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.hours = @[@(1), @(2), @(3), @(4), @(5), @(6), @(7), @(8), @(9), @(10), @(11), @(12), @(13), @(14), @(15), @(16)];
    self.mins = @[@(0), @(10), @(20), @(30), @(40), @(50)];
}


- (GLGeneralPicker *)timePicker
{
    if (!_timePicker) {
        _timePicker = [GLGeneralPicker picker];
        _timePicker.datasource = self;
        _timePicker.delegate = self;
        _timePicker.showStartOverButton = YES;
//        _timePicker.title = @"Duration";
        [_timePicker updateTitle:@"Duration"];
    }
    return _timePicker;
}


- (void)setValue:(NSObject *)value forDate:(NSDate *)date
{
    [super setValue:value forDate:date];
    
    if (value) {
        self.sleepDuration = (NSNumber *)value;
    }
    [self updateButton];
}


- (void)updateButton
{
    if (!self.sleepDuration || self.sleepDuration.integerValue <= 0) {
        [self.button setLabelText:@"Choose" bold:YES];
        self.button.selected = NO;
    }
    else {
        [self getHoursAndMins:^(NSUInteger hours, NSUInteger mins) {
            NSString *title = [NSString stringWithFormat:@"%luh %lum", (unsigned long)hours, (unsigned long)mins];
            if (mins == 0) {
                title = [NSString stringWithFormat:@"%luh", (unsigned long)hours];
            }
            [self.button setLabelText:title bold:YES];
            self.button.selected = YES;
        }];
    }
}


- (void)getHoursAndMins:(void (^)(NSUInteger hours, NSUInteger mins))callbackBlock
{
    NSUInteger totalSeconds = [self.sleepDuration unsignedLongLongValue];
    NSUInteger hours = (int)(totalSeconds / 3600);
    NSUInteger mins = (int)((totalSeconds % 3600) / 60);
    callbackBlock(hours, mins);
}


- (void)buttonClicked:(id)sender
{
    self.timePicker.delegate = self;
    self.timePicker.datasource = self;
    [self.timePicker present];
    if (self.sleepDuration && self.sleepDuration.integerValue > 0) {
        [self getHoursAndMins:^(NSUInteger hours, NSUInteger mins) {
            [self.timePicker selectRow:[self.hours indexOfObject:@(hours)] inComponent:0];
            [self.timePicker selectRow:[self.mins indexOfObject:@(mins)] inComponent:1];
        }];
    }
    else {
        [self.timePicker selectRow:7 inComponent:0];
        [self.timePicker selectRow:0 inComponent:1];
    }
    
    [self.timePicker setStartOverButtonTitle:@"Clear"];
}


- (void)enterEditingVisibility:(BOOL)visible height:(CGFloat)cellHeight
{
    [super enterEditingVisibility:visible height:cellHeight];
    self.button.alpha = 0;
}


- (void)exitEditing
{
    [super exitEditing];
    self.button.alpha = 1;
}


#pragma mark - picker 
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return component == 0 ? self.hours.count : self.mins.count;
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        return [NSString stringWithFormat:@"%@ hours", self.hours[row]];
    }
    return [NSString stringWithFormat:@"%@ mins", self.mins[row]];
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return 120;
}


- (void)doneButtonPressed
{
    NSUInteger hours = [self.hours[[self.timePicker selectedRowInComponent:0]] unsignedIntegerValue];
    NSUInteger mins = [self.mins[[self.timePicker selectedRowInComponent:1]] unsignedIntegerValue];
    
    if (self.sleepDuration.unsignedIntegerValue != hours * 3600 + mins * 60) {
        self.sleepDuration = [NSNumber numberWithUnsignedInteger:hours * 3600 + mins * 60];
        [self updateButton];
        [self.delegate updateDailyData:self.dataKey withValue:self.sleepDuration];
        [self.timePicker dismiss];
    }
    else {
        self.button.selected = !self.button.selected;
        [self.timePicker dismiss];
    }
    
    [self logButton:BTN_CLK_HOME_SLEEP clickType:CLICK_TYPE_NONE eventData:@{@"duration": self.sleepDuration}];
}


- (void)startOverPressed
{
    self.sleepDuration = [NSNumber numberWithInt:0];
    [self updateButton];
    [self.delegate updateDailyData:self.dataKey withValue:self.sleepDuration];
    
    self.button.selected = NO;
    [self.timePicker dismiss];
}



@end








