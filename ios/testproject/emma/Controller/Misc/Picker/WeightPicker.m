//
//  WeightPicker.m
//  emma
//
//  Created by Eric Xu on 12/12/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "WeightPicker.h"
#define DEFAULT_WEIGHT 68
#define MIN_POUNDS 50
#define MAX_POUNDS 500



@interface WeightPicker() <GLGeneralPickerDataSource, GLGeneralPickerDelegate>
{
    GLGeneralPicker *picker;
    UISegmentedControl *unitControl;
    WeightCallback doneCb;
    WeightCallback startoverCb;
    
    NSDictionary *units;
    NSString *unit;
    float weight;
    
    NSNumberFormatter *numberFormatter;
}

@property (nonatomic) BOOL hasChoose;
@property (nonatomic) int kgPosition;
@property (nonatomic) int lbPosition;

@end

@implementation WeightPicker


- (WeightPicker *)init {
    self = [super init];
    if (self) {
        self.hasChoose = NO;
        self.kgPosition = 0;
        self.lbPosition = 0;
        [self prepareData];
    }
    return self;
}

- (WeightPicker *)initWithChoose:(int)kgPosition and:(int)lbPosition {
    self = [super init];
    if (self) {
        self.hasChoose = YES;
        self.kgPosition = kgPosition;
        self.lbPosition = lbPosition;
        [self prepareData];
    }
    return self;
}

- (void)prepareData{
    picker = [GLGeneralPicker picker];
    picker.delegate = self;
    picker.datasource = self;
    picker.showStartOverButton = NO;
    
    units = @{
              UNIT_LB: @"LB",
              UNIT_KG: @"KG"
              };

    unitControl = [[UISegmentedControl alloc] initWithItems:[units allValues]];
    [unitControl addTarget:self
                    action:@selector(unitChanged:)
          forControlEvents:UIControlEventValueChanged];

    [picker setCustomButtons:@[unitControl]];

    unit = [Utils getDefaultsForKey:kUnitForWeight];
    if (![[units allKeys] containsObject:unit]) {
        unit = UNIT_LB;
    }
    
    numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.minimumFractionDigits = 1;
    numberFormatter.maximumFractionDigits = 1;
    numberFormatter.roundingMode = NSNumberFormatterRoundHalfUp;
    numberFormatter.locale = [NSLocale currentLocale];
}

- (void)presentWithWeightInKG:(float)w andCallback:(WeightCallback)doneCallback
{
    [self presentWithWeightInKG:w andCallback:doneCallback andStartoverCallback:nil];
}

- (void)presentWithWeightInKG:(float)w andCallback:(WeightCallback)doneCallback andStartoverCallback:(WeightCallback)startoverCallback
{
    doneCb = doneCallback;
    startoverCb = startoverCallback;
    
    unit = [Utils getDefaultsForKey:kUnitForWeight];
    if (![[units allKeys] containsObject:unit]) {
        unit = UNIT_LB;
    }
    
    picker.delegate = self;
    picker.datasource = self;
    [picker reload];
    [picker present];
    
    [unitControl setSelectedSegmentIndex:[[units allValues] indexOfObject:unit]];
    
    weight = w;
    if ((!self.hasChoose) && (weight <= 0)){
        weight = DEFAULT_WEIGHT;
    }
    [self selectWeight];
}

- (void)unitChanged:(id)x {
    UISegmentedControl *sc = (UISegmentedControl *)x;
    unit = [units allValues][sc.selectedSegmentIndex];
    [Utils setDefaultsForKey:kUnitForWeight withValue:unit];
    [picker reload];
    [self selectWeight];
}

- (void)selectWeight {
    if (weight > 0) {
        if ([self isLb]) {
            CGFloat pounds = [Utils poundsFromKg:weight];
            NSInteger lbs = (NSInteger)pounds;
            NSInteger mlbs = roundf((pounds - lbs) * 10);
            int selected = (lbs - MIN_POUNDS);
            if (self.hasChoose) {
                if (selected < self.lbPosition) {
                    [picker selectRow:selected inComponent:0];
                } else {
                    [picker selectRow:(selected + 1) inComponent:0];
                }
            } else {
                [picker selectRow:selected inComponent:0];
            }
            [picker selectRow:mlbs inComponent:1];
        } else {
            NSInteger kg = (NSInteger)weight;
            NSInteger mkg = (NSInteger)(weight * 10 - kg * 10);
            int selected = (kg - [self minWeightKg]);
            if (self.hasChoose) {
                if (selected < self.kgPosition) {
                    [picker selectRow:selected inComponent:0];
                } else {
                    [picker selectRow:(selected + 1) inComponent:0];
                }
            } else {
                [picker selectRow:selected inComponent:0];
            }
            [picker selectRow:mkg inComponent:1];
        }
    } else {
        // I don't know why but if weight is zero, and not hasChoose, we dont set picker
        if ([self isLb]) {
            if (self.hasChoose) {
                [picker selectRow:self.lbPosition inComponent:0];
                [picker selectRow:0 inComponent:1];
            }
        } else {
            if (self.hasChoose) {
                [picker selectRow:self.kgPosition inComponent:0];
                [picker selectRow:0 inComponent:1];
            }
        }
    }
}

- (void)setShowStartOverButton:(BOOL)showStartOverButton {
    _showStartOverButton = showStartOverButton;
    [picker setShowStartOverButton:showStartOverButton];
}

#pragma mark - helper
- (NSInteger)minWeightKg {
    return (NSInteger)[Utils kgFromPounds:MIN_POUNDS];
}

- (NSInteger)maxWeightKg {
    return (NSInteger)[Utils kgFromPounds:MAX_POUNDS];
}

- (BOOL)isLb {
    return [unit isEqual:UNIT_LB];
}

#pragma mark - GeneralPickerDelegate and Datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        NSInteger number = [self isLb] ? MAX_POUNDS - MIN_POUNDS : [self maxWeightKg] - [self minWeightKg];
        return self.hasChoose ? number + 2 : number + 1;
    }
    else if (component == 1) {
        return 10;
    }
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    if ([self isLb]) {
        if (component == 0) {
            if (self.hasChoose) {
                if (row == self.lbPosition) {
                    return @"(Choose)";
                } else if (row < self.lbPosition) {
                    return [NSString stringWithFormat:@"%ld", MIN_POUNDS + row];
                } else {
                    return [NSString stringWithFormat:@"%ld", MIN_POUNDS + row - 1];
                }
            } else {
                return [NSString stringWithFormat:@"%ld", MIN_POUNDS + row];
            }
        }
        else if (component == 1) {
            return [NSString stringWithFormat:@"%@%ld", numberFormatter.decimalSeparator, row];
        }
        else {
            return @"lbs";
        }
        
    } else {
        if (component == 0)
            if (self.hasChoose) {
                if (row == self.kgPosition) {
                    return @"(Choose)";
                } else if (row < self.kgPosition) {
                    return [NSString stringWithFormat:@"%ld", [self minWeightKg] + row];
                } else {
                    return [NSString stringWithFormat:@"%ld", [self minWeightKg] + row - 1];
                }
            } else {
                return [NSString stringWithFormat:@"%ld", [self minWeightKg] + row];
            }
        else if (component == 1)
            return [NSString stringWithFormat:@"%@%ld", numberFormatter.decimalSeparator, row];
        else return @"kg";
    }
    return @"";
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return component == 0 ? 120 : 50;
}

- (void)doneButtonPressed {
    if ([self isLb]) {
        int selected = [picker selectedRowInComponent:0];
        NSInteger mlbs = [picker selectedRowInComponent:1];
        if (self.hasChoose) {
            if (selected == self.lbPosition) {
                weight = 0;
            } else if (selected < self.lbPosition) {
                NSInteger lbs = MIN_POUNDS + selected;
                weight = lbs + mlbs / 10;
                weight = [Utils kgFromPounds:weight];
            } else {
                NSInteger lbs = MIN_POUNDS + selected - 1;
                weight = lbs + (CGFloat)mlbs / 10;
                weight = [Utils kgFromPounds:weight];
            }
        } else {
            NSInteger lbs = MIN_POUNDS + selected;
            CGFloat pounds = lbs + (CGFloat)mlbs / 10;
            weight = [Utils kgFromPounds:pounds];
        }
    } else {
        int selected = [picker selectedRowInComponent:0];
        NSInteger mkgs = [picker selectedRowInComponent:1];
        if (self.hasChoose) {
            if (selected == self.kgPosition) {
                weight = 0;
            } else if (selected < self.kgPosition) {
                NSInteger kgs = [self minWeightKg] + selected;
                weight = kgs + mkgs * 1.0 / 10.0;
            } else {
                NSInteger kgs = [self minWeightKg] + selected - 1;
                weight = kgs + mkgs * 1.0 / 10.0;
            }
        } else {
            NSInteger kgs = [self minWeightKg] + selected;
            weight = kgs + mkgs * 1.0 / 10.0;
        }
    }
    if (doneCb) {
        doneCb(weight);
    }
    
    [picker dismiss];
}

- (void)startOverPressed {
    if (startoverCb) {
        startoverCb(0);
    }
    
    [picker dismiss];
}
@end
