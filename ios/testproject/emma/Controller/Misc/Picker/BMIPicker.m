//
//  BMIPicker.m
//  emma
//
//  Created by Eric Xu on 12/10/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "BMIPicker.h"
#import <GLFoundation/GLGeneralPicker.h>


@interface BMIPicker() <GLGeneralPickerDataSource, GLGeneralPickerDelegate>
{
    GLGeneralPicker *picker;

    CGFloat weight;
    CGFloat height;
    CGFloat originWeight;
    CGFloat originHeight;
    NSNumberFormatter *numberFormatter;
    
    NSString *cancelButtonSelector;
    NSString *doneButtonSelector;
    
    NSDictionary *BMIUnits;
    
    BMICallback callback;
    Callback cancelCb;
}

@property (nonatomic) NSInteger inputMode;


@end

@implementation BMIPicker


- (BMIPicker *)init {
    self = [super init];
    if (self) {
        [self setup];
    }

    return self;
}

- (void)setup {
    numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.minimumFractionDigits = 1;
    numberFormatter.maximumFractionDigits = 1;
    numberFormatter.roundingMode = NSNumberFormatterRoundHalfUp;
    numberFormatter.locale = [NSLocale currentLocale];

    picker = [GLGeneralPicker picker];
    picker.delegate = self;
    picker.datasource = self;
    picker.showStartOverButton = NO;
    
    BMIUnits = @{@"IN/LB": BMIUnitForInch,
                 @"CM/KG":@"CM/KG"
                 };
}

- (CGFloat)calculateBMI {
    if (height == 0 || weight == 0)
        return 0;
    return [Utils calculateBmiWithHeightInCm:height weightInKg:weight];
}

- (void)presentWithSelectedWeigh:(float)w andHeight:(float)h andDoneCallback:(BMICallback)cb andCancelback:(Callback)ccb {
    
    weight = w;
    height = h;
    callback = cb;
    cancelCb = ccb;

    picker.delegate = self;
    picker.datasource = self;
    [picker present];    
    self.inputMode = INPUT_MODE_HEIGHT;
    
    GLLog(@"IS_INCH: %@", [self isInch]?@"YES":@"NO");
}

- (void)donePressed:(id)sender {
    CGFloat bmi = [self calculateBMI];
    
    NSString *bmiStr ;
    if (bmi == 0) {
        bmiStr = @"Choose";
    } else {
        bmiStr = [numberFormatter stringFromNumber:@(bmi)];
    }

    callback(bmiStr, weight, height);
    [picker dismiss];
}

- (void)cancelPressed:(id)sender {
    if (cancelCb) {
        cancelCb(0, 0);
    }

    [picker dismiss];
}

- (void)switchToHeightPicker:(id)sender {
    self.inputMode = INPUT_MODE_HEIGHT;
}

- (void)switchToWeightPicker:(id)sender {
    self.inputMode = INPUT_MODE_WEIGHT;
}

- (BOOL)isInch {
    NSString *unit = [Utils getDefaultsForKey:kUnitForBMI];
    if (unit) {
        return [unit isEqual:BMIUnitForInch];
    } else
        return YES;
}

- (NSInteger)minHeightCm {
    return (NSInteger)[Utils cmFromInches:(MIN_FEET * 12)];
}

- (NSInteger)maxHeightCm {
    return (NSInteger)[Utils cmFromInches:(MAX_FEET * 12 + 11)];
}

- (NSInteger)minWeightKg {
    return (NSInteger)[Utils kgFromPounds:MIN_POUNDS];
}

- (NSInteger)maxWeightKg {
    return (NSInteger)[Utils kgFromPounds:MAX_POUNDS];
}


- (void)setInputMode:(NSInteger)val {
    _inputMode = val;
    [picker reload];
    if (val == INPUT_MODE_HEIGHT) {
        [picker updateTitle:@"Enter your height"];
        if (height == 0) {
//            [picker setCancelButtonTitle:@"Cancel"];
            [picker setShowStartOverButton:NO];
            [picker setDoneButtonTitle:@"Next"];

            cancelButtonSelector = @"cancelPressed:";
            doneButtonSelector = @"switchToWeightPicker:";
        } else {
            [picker setShowStartOverButton:YES];
            [picker setStartOverButtonTitle:@"Weight"];
            [picker setDoneButtonTitle:@"Done"];

            cancelButtonSelector = @"switchToWeightPicker:";
            doneButtonSelector = @"donePressed:";
        }
        height = (height > 0) ? height : DEFAULT_HEIGHT;
        if ([self isInch]) {
            NSInteger feet = [Utils inchesFromCm:height] / 12;
            NSInteger inches = [Utils inchesFromCm:height] % 12;
            [picker selectRow:(feet - MIN_FEET) inComponent:0];
            [picker selectRow:inches inComponent:1];
        } else {
            [picker selectRow:(height - [self minHeightCm]) inComponent:0];
        }
    } else if (val == INPUT_MODE_WEIGHT) {
        [CrashReport leaveBreadcrumb:@"enter BMI - weight"];
        [picker updateTitle:@"Enter your weight"];
        [picker setStartOverButtonTitle:@"Height"];
        [picker setDoneButtonTitle:@"Done"];
        cancelButtonSelector = @"switchToHeightPicker:";
        doneButtonSelector = @"donePressed:";

        weight = (weight > 0) ? weight : DEFAULT_WEIGHT;
        if ([self isInch]) {
            [picker selectRow:([Utils poundsFromKg:weight] - MIN_POUNDS) inComponent:0];
        } else {
            NSInteger kg = (NSInteger)weight;
            NSInteger mkg = (NSInteger)(weight * 10 - kg * 10);
            [picker selectRow:(kg - [self minWeightKg]) inComponent:0];
            [picker selectRow:mkg inComponent:1];
        }
    }
}

#pragma mark - GeneralPickerDelegate and Datasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if (self.inputMode == INPUT_MODE_HEIGHT) {
        return ([self isInch]) ? 2 : 1;
    } else {
        return ([self isInch]) ? 1 : 3;
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (self.inputMode == INPUT_MODE_HEIGHT) {
        if ([self isInch]) {
            if (component == 0) {
                // number of feet
                return MAX_FEET - MIN_FEET + 1;
            } else {
                // number of inches
                return 12;
            }
        } else {
            return [self maxHeightCm] - [self minHeightCm] + 1;
        }
    } else {
        if ([self isInch]) {
            return MAX_POUNDS - MIN_POUNDS + 1;
        } else {
            if (component == 0) {
                // number of KG
                return [self maxWeightKg] - [self minWeightKg] + 1;
            } else if(component == 1){
                // number of .1 KG
                return 10;
            } else {
                return 1;
            }
        }
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (self.inputMode == INPUT_MODE_HEIGHT) {
        if ([self isInch]) {
            if (component == 0)
                return [NSString stringWithFormat:@"%ld ft", MIN_FEET + row];
            else
                return [NSString stringWithFormat:@"%ld in", (long)row];
        } else {
            return [NSString stringWithFormat:@"%ld cm", [self minHeightCm] + row];
        }
    } else {
        if ([self isInch]) {
            return [NSString stringWithFormat:@"%ld lbs", MIN_POUNDS + row];
        } else {
            if (component == 0)
                return [NSString stringWithFormat:@"%ld", [self minWeightKg] + row];
            else if (component == 1)
                return [NSString stringWithFormat:@"%@%ld", numberFormatter.decimalSeparator, (long)row];
            else return @"kg";
        }
    }
    return @"";
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if ([self isInch]) {
        if (self.inputMode == INPUT_MODE_HEIGHT) {
            return 80;
        } else
            return 180;
    } else {
        if (self.inputMode == INPUT_MODE_HEIGHT) {
            return 120;
        } else {
            return component == 1? 30 : 50;
//            return 30;
        }
    }

    return [UIScreen mainScreen].bounds.size.width;
}

- (void)pickerView:(UIPickerView *)aPickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (self.inputMode == INPUT_MODE_HEIGHT) {
        if ([self isInch]) {
            NSInteger feet = MIN_FEET + [picker selectedRowInComponent:0];
            NSInteger inches = [picker selectedRowInComponent:1];
            height = [Utils cmFromInches:(feet * 12 + inches)];
        } else {
            NSInteger cms = [self minHeightCm] + [picker selectedRowInComponent:0];
            height = cms;
        }
    } else {
        if ([self isInch]) {
            NSInteger lbs = MIN_POUNDS + [picker selectedRowInComponent:0];
            weight = [Utils kgFromPounds:lbs];
        } else {
            NSInteger kgs = [self minWeightKg] + [picker selectedRowInComponent:0];
            NSInteger mkgs = [picker selectedRowInComponent:1];
            weight = kgs + mkgs * 1.0 / 10.0;
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)doneButtonPressed {
    if (![Utils isEmptyString:doneButtonSelector]) {
        [self performSelector:NSSelectorFromString(doneButtonSelector) withObject:nil];
    }
}

- (void)cancelButtonPressed {
    if (![Utils isEmptyString:cancelButtonSelector]) {
        [self performSelector:NSSelectorFromString(cancelButtonSelector) withObject:nil];
    }

}
#pragma clang diagnostic pop

@end
