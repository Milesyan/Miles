//
//  WeightPicker.m
//  emma
//
//  Created by Eric Xu on 12/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "HeightPicker.h"
#define DEFAULT_HEIGHT 170

#define MIN_FEET 4
#define MAX_FEET 8

@interface HeightPicker()<GLGeneralPickerDataSource, GLGeneralPickerDelegate>
{
    GLGeneralPicker *picker;
    UISegmentedControl *unitControl;
    HeightCallback doneCb;

    NSDictionary *units;
    NSString *unit;
    float height;
}

@property (nonatomic) BOOL hasChoose;
@property (nonatomic) int cmPosition;
@property (nonatomic) int feetPosition;
@property (nonatomic) int inchPosition;

@end

@implementation HeightPicker

- (HeightPicker *)init {
    self = [super init];
    if (self) {
        self.hasChoose = NO;
        self.cmPosition = 0;
        self.feetPosition = 0;
        self.inchPosition = 0;
        [self prepareData];
    }
    return self;
}

- (HeightPicker *)initWithChoose:(int)cmPosition feetPosition:(int)feetPosition inchPosition:(int)inchPosition {
    self = [super init];
    if (self) {
        self.hasChoose = YES;
        self.cmPosition = cmPosition;
        self.feetPosition = feetPosition;
        self.inchPosition = inchPosition;
        [self prepareData];
    }
    return self;
}

- (void)prepareData{
    picker = [GLGeneralPicker picker];
    picker.delegate = self;
    picker.datasource = self;

    units = @{
              UNIT_INCH: @"IN",
              UNIT_CM: @"CM"
              };

    unitControl = [[UISegmentedControl alloc] initWithItems:[units allValues]];
    [unitControl addTarget:self
                    action:@selector(unitChanged:)
          forControlEvents:UIControlEventValueChanged];
    
    [picker setCustomButtons:@[unitControl]];
    unit = [Utils getDefaultsForKey:kUnitForHeight];
    if (![[units allKeys] containsObject:unit]) {
        unit = UNIT_INCH;
    }
}

- (void)presentWithHeightInCM:(float)h andCallback:(HeightCallback)doneCallback
{
    doneCb = doneCallback;
    picker.delegate = self;
    picker.datasource = self;
    [picker present];

    [unitControl setSelectedSegmentIndex:[[units allValues] indexOfObject:unit]];

    height = h;
    if ((!self.hasChoose) && (height <= 0)) {
        height = DEFAULT_HEIGHT;
    }
    [self selectHeight];
}

- (void)unitChanged:(id)x {
    UISegmentedControl *sc = (UISegmentedControl *)x;
    unit = [units allValues][sc.selectedSegmentIndex];
    [Utils setDefaultsForKey:kUnitForHeight withValue:unit];
    [picker reload];
    [self selectHeight];
}

- (void)selectHeight {
    if (height > 0) {
        if ([self isInch]) {
            NSInteger feet = [Utils inchesFromCm:height] / 12;
            NSInteger inches = [Utils inchesFromCm:height] % 12;
            int feetSelected = (feet - MIN_FEET);
            int inchSelected = inches;
            if (self.hasChoose) {
                if (feetSelected < self.feetPosition) {
                    [picker selectRow:feetSelected inComponent:0];
                } else {
                    [picker selectRow:(feetSelected + 1) inComponent:0];
                }
                if (inchSelected < self.inchPosition) {
                    [picker selectRow:inchSelected inComponent:1];
                } else {
                    [picker selectRow:(inchSelected + 1) inComponent:1];
                }
            } else {
                [picker selectRow:(feet - MIN_FEET) inComponent:0];
                [picker selectRow:inches inComponent:1];
            }
        } else {
            // only one picker
            int selected = (height - [self minHeightCm]);
            if (self.hasChoose) {
                if (selected < self.cmPosition) {
                    [picker selectRow:selected inComponent:0];
                } else {
                    [picker selectRow:(selected + 1) inComponent:0];
                }
            } else {
                [picker selectRow:selected inComponent:0];
            }
        }
    } else {
        // I don't know why but if height is zero, and not hasChoose, we dont set picker
        if ([self isInch]) {
            if (self.hasChoose) {
                [picker selectRow:self.feetPosition inComponent:0];
                [picker selectRow:self.inchPosition inComponent:1];
            }
        } else {
            if (self.hasChoose) {
                [picker selectRow:self.cmPosition inComponent:0];
            }
        }
    }
}

#pragma mark - helper
- (NSInteger)minHeightCm {
    return (NSInteger)[Utils cmFromInches:(MIN_FEET * 12)];
}

- (NSInteger)maxHeightCm {
    return (NSInteger)[Utils cmFromInches:(MAX_FEET * 12 + 11)];
}

- (BOOL)isInch {
    return [unit isEqual:UNIT_INCH];
}

#pragma mark - GeneralPickerDelegate and Datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if (![self isInch]) {
        return 1;
    } else{
        return 2;
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (![self isInch]) {
        if (self.hasChoose) {
            return [self maxHeightCm] - [self minHeightCm] + 2;
        } else {
            return [self maxHeightCm] - [self minHeightCm] + 1;
        }
    } else {
        if (component == 0) {
            // number of feet
            return self.hasChoose ? (MAX_FEET - MIN_FEET + 2) : (MAX_FEET - MIN_FEET + 1);
        } else {
            // number of inches
            return self.hasChoose ? 13 : 12;
        }
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (![self isInch]) {
        if (self.hasChoose) {
            if (row == self.cmPosition) {
                return @"(Choose)";
            } else if (row < self.cmPosition) {
                return [NSString stringWithFormat:@"%ld cm", [self minHeightCm] + row];
            } else {
                return [NSString stringWithFormat:@"%ld cm", [self minHeightCm] + row - 1];
            }
        } else {
            return [NSString stringWithFormat:@"%ld cm", [self minHeightCm] + row];
        }
    } else {
        if (self.hasChoose) {
            if (component == 0) {
                if (row == self.feetPosition) {
                    return @"(Choose)";
                } else if (row < self.feetPosition) {
                    return [NSString stringWithFormat:@"%ld ft", MIN_FEET + row];
                } else {
                    return [NSString stringWithFormat:@"%ld ft", MIN_FEET + row - 1];
                }
            } else {
                if (row == self.inchPosition) {
                    return @"(Choose)";
                } else if (row < self.inchPosition) {
                    return [NSString stringWithFormat:@"%ld in", row];
                } else {
                    return [NSString stringWithFormat:@"%ld in", row - 1];
                }
            }
        } else {
            if (component == 0) {
                return [NSString stringWithFormat:@"%ld ft", MIN_FEET + row];
            } else if (component == 1) {
                return [NSString stringWithFormat:@"%ld in", row];
            }
        }
    }
    return @"";
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if ([self isInch]) {
        if (component == 0) {
            return 120;
        } else if(component == 1) {
            return 120;
        }
    } else
        return 120;

    return SCREEN_WIDTH;
}

- (void)doneButtonPressed {
    if ([self isInch]) {
        int feetSelected = [picker selectedRowInComponent:0];
        int inchSelected = [picker selectedRowInComponent:1];
        if (self.hasChoose) {
            if (feetSelected == self.feetPosition || inchSelected == self.inchPosition) {
                height = 0;
            } else {
                NSInteger feet;
                NSInteger inches;
                if (feetSelected < self.feetPosition) {
                    feet = MIN_FEET + feetSelected;
                } else {
                    feet = MIN_FEET + feetSelected - 1;
                }
                if (inchSelected < self.inchPosition) {
                    inches = inchSelected;
                } else {
                    inches = inchSelected - 1;
                }
                height = [Utils cmFromInches:(feet * 12 + inches)];
            }
        } else {
            NSInteger feet = MIN_FEET + feetSelected;
            NSInteger inches = inchSelected;
            height = [Utils cmFromInches:(feet * 12 + inches)];
        }
    } else {
        int selected = [picker selectedRowInComponent:0];
        if (self.hasChoose) {
            if (selected == self.cmPosition) {
                height = 0;
            } else if (selected < self.cmPosition) {
                height = [self minHeightCm] + selected;
            } else {
                height = [self minHeightCm] + selected - 1;
            }
        } else {
            height = [self minHeightCm] + selected;
        }
    }

    if (doneCb) {
        doneCb(height);
    }

    [picker dismiss];
}

@end
