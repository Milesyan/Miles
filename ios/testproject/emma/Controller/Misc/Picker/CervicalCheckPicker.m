//
//  CervicalCheckPicker.m
//  emma
//
//  Created by Eric Xu on 12/17/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "CervicalCheckPicker.h"
#import "UserDailyData+CervicalPosition.h"


@interface CervicalCheckPicker()<GLGeneralPickerDataSource, GLGeneralPickerDelegate>
{
    GLGeneralPicker *picker;
    CervicalDoneCallback doneCb;
    Callback startoverCb;
}

@end


@implementation CervicalCheckPicker

- (void)prepareData
{
    picker = [GLGeneralPicker picker];
    picker.delegate = self;
    picker.datasource = self;
    picker.showStartOverButton = YES;
}


- (void)presentWithCervicalPosition:(NSDictionary *)cervical
                       doneCallback:(CervicalDoneCallback)doneCallback
                  startoverCallback:(Callback)startoverCallback
{
    doneCb = doneCallback;
    startoverCb = startoverCallback;
    
    [self prepareData];
    
    NSNumber *height = [cervical objectForKey:@(CervicalPositionHeight)];
    NSNumber *openness = [cervical objectForKey:@(CervicalPositionOpenness)];
    NSNumber *firmness = [cervical objectForKey:@(CervicalPositionFirmness)];
    
    if (cervical) {
        
        [picker selectRow:height.intValue-1 inComponent:0];
        [picker selectRow:openness.intValue-1 inComponent:1];
        [picker selectRow:firmness.intValue-1 inComponent:2];
    }
    
    picker.delegate = self;
    picker.datasource = self;
    [picker present];
    [picker reload];
}


#pragma mark - GeneralPickerDelegate and Datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 3;
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    uint64_t cervical = CervicalPositionHeight;
    if (component == 1) {
        cervical = CervicalPositionOpenness;
    }
    else if (component == 2) {
        cervical = CervicalPositionFirmness;
    }
    
    return [UserDailyData statusTitleForCervicalPosition:cervical statusValue:row+1];
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return 106;
}


- (void)doneButtonPressed
{
    [picker dismiss];
    
    if (doneCb) {
        NSNumber *height = @([picker selectedRowInComponent:0]+1);
        NSNumber *openness = @([picker selectedRowInComponent:1]+1);
        NSNumber *firmness = @([picker selectedRowInComponent:2]+1);
        
        NSDictionary *cervical = @{@(CervicalPositionHeight): height,
                                   @(CervicalPositionOpenness): openness,
                                   @(CervicalPositionFirmness): firmness};
        doneCb(cervical);
    }
}

- (void)startOverPressed {
    if (startoverCb) {
        startoverCb(0, 0);
    }
    
    [picker selectRow:0 inComponent:0];
    [picker selectRow:0 inComponent:1];
    [picker selectRow:0 inComponent:2];
    
    [picker dismiss];
}
@end
