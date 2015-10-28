//
//  WaistPicker.m
//  emma
//
//  Created by Peng Gu on 3/26/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "WaistPicker.h"
#import <GLFoundation/GLGeneralPicker.h>


#define MIN_WAIST 20
#define MIN_WAIST_CM 50

#define MAX_WAIST 50
#define MAX_WAIST_CM 127

@interface WaistPicker () <GLGeneralPickerDataSource, GLGeneralPickerDelegate>

@property (nonatomic, copy) WaistCallback doneCallback;
@property (nonatomic, copy) WaistCallback cancelCallback;
@property (nonatomic, strong) GLGeneralPicker *picker;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, assign, readonly) BOOL isInchUnit;

@property (nonatomic, assign) NSUInteger selectedWaistInCM;
@property (nonatomic, assign) NSUInteger maxWaist;
@property (nonatomic, assign) NSUInteger minWaist;

@end


@implementation WaistPicker


- (instancetype)init
{
    self = [super init];
    if (self) {
        _picker = [GLGeneralPicker picker];
        _picker.delegate = self;
        _picker.datasource = self;
        _picker.showStartOverButton = YES;
    }
    
    return self;
}


- (NSString *)unit
{
    NSString *unit = [Utils getDefaultsForKey:kUnitForHeight];
    if (!unit) {
        unit = UNIT_INCH;
    }
    return unit;
}


- (BOOL)isInchUnit
{
    return [self.unit isEqual:UNIT_INCH];
}


- (void)unitChanged:(UISegmentedControl *)segment
{
    NSString *unit = @[UNIT_CM, UNIT_INCH][segment.selectedSegmentIndex];
    [Utils setDefaultsForKey:kUnitForHeight withValue:unit];
    [self.picker reload];
    [self selectWaist];
}


- (NSUInteger)maxWaist
{
    return self.isInchUnit ? MAX_WAIST : MAX_WAIST_CM;
}


- (NSUInteger)minWaist
{
    return self.isInchUnit ? MIN_WAIST : MIN_WAIST_CM;
}


- (void)selectWaist
{
    NSUInteger waist = self.selectedWaistInCM;
    if (self.isInchUnit) {
        waist = [Utils inchesFromCm:waist];
    }
    
    NSInteger row = waist - self.minWaist;
    [self.picker selectRow:row inComponent:0];
}


- (void)presentWithWaistInCM:(float)waist
            withDoneCallback:(WaistCallback)doneCallback
              cancelCallback:(WaistCallback)cancelCallback
{
    self.doneCallback = doneCallback;
    self.cancelCallback = cancelCallback;
    
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[UNIT_CM, UNIT_INCH]];
    segment.selectedSegmentIndex = [@[UNIT_CM, UNIT_INCH] indexOfObject:self.unit];
    [segment addTarget:self
                action:@selector(unitChanged:)
      forControlEvents:UIControlEventValueChanged];
    self.picker.customButtons = @[segment];
    
    [self.picker present];
    [self.picker setStartOverButtonTitle:@"Cancel"];
    
    self.selectedWaistInCM = waist;
    if (self.isInchUnit) {
        waist = [Utils inchesFromCm:waist];
    }
    [self.picker selectRow:waist-self.minWaist inComponent:0];
}


#pragma mark - GeneralPickerDelegate and Datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.maxWaist - self.minWaist + 1;
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSUInteger waist = self.minWaist + row;
    return [NSString stringWithFormat:@"%ld %@", waist, [self.unit lowercaseString]];
}


- (void)startOverPressed
{
    if (self.cancelCallback) {
        self.cancelCallback(0);
    }
    [self.picker dismiss];
}


- (void)doneButtonPressed
{
    if (self.doneCallback) {
        NSUInteger waist = [self.picker selectedRowInComponent:0] + self.minWaist;
        if (self.isInchUnit) {
            waist = [Utils cmFromInches:waist];
        }
        self.doneCallback(waist);
    }
    
    [self.picker dismiss];
}

@end






