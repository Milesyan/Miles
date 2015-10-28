//
//  HeightPicker.m
//  emma
//
//  Created by Eric Xu on 12/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ExercisePicker.h"
#import <GLFoundation/GLGeneralPicker.h>
#import "DailyLogConstants.h"

@interface ExercisePicker() <GLGeneralPickerDelegate, GLGeneralPickerDataSource>
{
    GLGeneralPicker *picker;
    Callback doneCb;
    Callback cancelCb;
    BOOL initializeData;
}


@end


static NSArray *settingDatasource;
static NSArray *settingValues;
static NSArray *logDatasource;
static NSArray *logValues;

@implementation ExercisePicker


- (ExercisePicker *)init {
    self = [super init];
    if (self) {
        [self prepareData];
    }
    return self;
}

- (void)prepareData{
    picker = [GLGeneralPicker picker];
    picker.delegate = self;
    picker.datasource = self;
    picker.showStartOverButton = NO;
//    picker.showCancelButton = NO;
    [picker updateTitle:@"Daily average"];
    
    [ExercisePicker prepareConents];

    initializeData = YES;
}

+ (void)prepareConents {
    settingDatasource = @[@"Sedentary", @"Lightly active", @"Active", @"Very active"];
    settingValues = @[@(EXERCISE_SEDENTARY), @(EXERCISE_LIGHTLY), @(EXERCISE_ACTIVE), @(EXERCISE_VERY_ACTIVE)];
    logDatasource = @[@"Lightly active (15-30 mins)", @"Active (30-60 mins)", @"Very active (60+ mins)"];
    logValues = @[@(EXERCISE_LIGHTLY), @(EXERCISE_ACTIVE), @(EXERCISE_VERY_ACTIVE)];
}

+ (NSString *)titleForFullListIndex:(NSInteger)idx {
    if (!settingDatasource || [settingDatasource count] == 0) {
        [ExercisePicker prepareConents];
    }

    if (idx >= 0 && idx < [settingDatasource count]) {
        return settingDatasource[idx];
    } else
        return @"";
}

+ (NSInteger)valueForFullListIndex:(NSInteger)idx {
    if (!settingDatasource || [settingDatasource count] == 0) {
        [ExercisePicker prepareConents];
    }

    if (idx >= 0 && idx < [settingValues count]) {
        return [settingValues[idx] integerValue];
    } else
        return 0;
}

+ (NSInteger)indexOfValue:(NSInteger)val {
    if (!settingDatasource || [settingDatasource count] == 0) {
        [ExercisePicker prepareConents];
    }

    return [settingValues indexOfObject:@(val)];
}

- (void)presentWithSelectedRow:(NSInteger)row inComponents:(NSInteger)component withDoneCallback:(Callback)doneCallback andCancelCallback:(Callback)cancelCallback;
{
    if (!initializeData) {
        [self prepareData];
    }

    doneCb = doneCallback;
    cancelCb = cancelCallback;
    
    picker.delegate = self;
    picker.datasource = self;
    [picker present];
    [picker selectRow:row inComponent:component];
}

#pragma mark - GeneralPickerDelegate and Datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (self.target == TARGET_DAILY_LOG) {
        return 3;
    } else if (self.target == TARGET_SETTING) {
        return 5;
    }
    
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {

//    return @"aaa";
    if (!settingDatasource || [settingDatasource count] == 0) {
        [ExercisePicker prepareConents];
    }

    switch (self.target) {
        case TARGET_SETTING:
        {
            if (row >= 0 && row < [settingDatasource count]) {
                return settingDatasource[row];
            }
        }
            break;
        case TARGET_DAILY_LOG:
        {
            if (row >= 0 && row < [logDatasource count]) {
                return logDatasource[row];
            }
        }
            break;
        default:
            break;
    }
    return @"";

}

- (void)doneButtonPressed {
    if (doneCb) {
        doneCb([picker selectedRowInComponent:0], 0);
    }
    
    [picker dismiss];
}

- (void)cancelButtonPressed {
    if (cancelCb) {
        cancelCb(0, 0);
    }

    [picker dismiss];
}



@end
