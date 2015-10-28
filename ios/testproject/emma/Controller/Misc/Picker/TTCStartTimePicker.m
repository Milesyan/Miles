//
//  TTCLengthPicker.m
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "TTCStartTimePicker.h"
#import <GLFoundation/GLPickerViewController.h>

@interface TTCStartTimePicker () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic) BOOL hasChoose;
@property (nonatomic) int choosePosition;

@end

@implementation TTCStartTimePicker

- (id)initWithLength:(NSString *)length {
    self = [super initWithNibName:@"TTCStartTimePicker" bundle:nil];
    if (self) {
        self.length = length;
        self.hasChoose = NO;
        self.choosePosition = 0;
    }
    return self;
}

- (id)initWithChoose:(int)position length:(NSString *)length {
    self = [super initWithNibName:@"TTCStartTimePicker" bundle:nil];
    if (self) {
        self.length = length;
        self.hasChoose = YES;
        self.choosePosition = position;
    }
    return self;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    // only add choose at "number", not at week/month/year
    if (self.hasChoose) {
        // 0...25, plus "Choose"
        return component == 0 ? (25 + 1) : 3;
    } else {
        return component == 0 ? 1300 : 3;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return component == 0 ? 100 : 115;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor clearColor];
    label.font = [Utils boldFont:24];
    if (component == 0) {
        label.frame = CGRectMake(0, 0, 100, 37);
        label.textAlignment = NSTextAlignmentRight;
        if (self.hasChoose) {
            if (row == self.choosePosition) {
                label.text = @"(Choose)";
            } else {
                if (row < self.choosePosition) {
                    label.text = [NSString stringWithFormat:@"%ld", row];
                } else {
                    label.text = [NSString stringWithFormat:@"%ld", row - 1];
                }
            }
        } else {
            label.text = [NSString stringWithFormat:@"%ld", row % 13];
        }
    } else {
        label.text = [@[@"weeks", @"months", @"years"] objectAtIndex:row];
        label.frame = CGRectMake(20, 0, 95, 37);
        label.textAlignment = NSTextAlignmentLeft;
    }
    return label;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (!self.length) {
        if (self.hasChoose) {
            [self.pickerView selectRow:self.choosePosition inComponent:0 animated:NO];
        } else {
            [self.pickerView selectRow:6 inComponent:0 animated:NO];
        }
        [self.pickerView selectRow:1 inComponent:1 animated:NO];
    } else {
        NSArray *rows = [self.length componentsSeparatedByString:@" "];
        NSDictionary *unitDict = DURATION_UNITS;
        int leftSelected = [rows[0] integerValue];
        if (self.hasChoose) {
            if (leftSelected < self.choosePosition) {
                [self.pickerView selectRow:leftSelected inComponent:0 animated:NO];
            } else {
                [self.pickerView selectRow:(leftSelected + 1) inComponent:0 animated:NO];
            }
        } else {
            // we have circles, so plus 650
            [self.pickerView selectRow:[rows[0] integerValue] + 650 inComponent:0 animated:NO];
        }
        [self.pickerView selectRow:[unitDict[rows[1]] integerValue] inComponent:1 animated:NO];
    }
}

- (void)present {
    [[GLPickerViewController sharedInstance] presentWithContentController:self];
}

- (IBAction)doneClicked:(id)sender {
    [[GLPickerViewController sharedInstance] dismiss];
    int leftSelected = [self.pickerView selectedRowInComponent:0];
    int num = 0;
    if (self.hasChoose) {
        if (leftSelected == self.choosePosition) {
            [self.delegate TTCStartTimePicker:self didDismissWithLength:@""];
            return;
        } else {
            if (leftSelected < self.choosePosition) {
                num = leftSelected;
            } else {
                num = leftSelected - 1;
            }
        }
    } else {
        num = leftSelected % 25;
    }
    NSInteger unit = [self.pickerView selectedRowInComponent:1];
    NSString *strUnit = @[@"week", @"month", @"year"][unit];
    self.length = [NSString stringWithFormat:@"%d %@%@", num, strUnit, num != 1? @"s": @""];
    [self.delegate TTCStartTimePicker:self didDismissWithLength:self.length];
}

@end
