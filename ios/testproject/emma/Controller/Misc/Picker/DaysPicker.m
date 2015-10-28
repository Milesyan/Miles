//
//  DaysPicker.m
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DaysPicker.h"
#import <GLFoundation/GLPickerViewController.h>

#define REPEAT_COUNT 100

@interface DaysPicker () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong)NSString *title;
@property (nonatomic) NSInteger value;
@property (nonatomic) NSInteger min;
@property (nonatomic) NSInteger max;
@property (nonatomic) BOOL hasChoose;
@property (nonatomic) int choosePosition;
@end

@implementation DaysPicker

- (id)initWithTitle:(NSString *)title default:(NSInteger)value min:(NSInteger)minDays max:(NSInteger)maxDays {
    self = [super initWithNibName:@"DaysPicker" bundle:nil];
    if (self) {
        self.min = minDays;
        self.max = maxDays;
        self.value = value;
        self.title = title;
        self.hasChoose = NO;
        self.choosePosition = 0;
    }
    return self;
}

- (id)initWithChoose:(int)position title:(NSString *)title default:(NSInteger)value min:(NSInteger)minDays max:(NSInteger)maxDays {
    // for pickers with Choose, we don't have any cycle
    // and we have a hack here is "value" will never be 0.
    // 0 means "Choose"
    self = [super initWithNibName:@"DaysPicker" bundle:nil];
    if (self) {
        self.min = minDays;
        self.max = maxDays;
        self.value = value;
        self.title = title;
        self.hasChoose = YES;
        self.choosePosition = position;
    }
    return self;
}

- (NSInteger)rangeCount {
    return self.max - self.min + 1;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (self.hasChoose) {
        // for "Choose"
        return self.rangeCount + 1;
    } else {
        return self.rangeCount * REPEAT_COUNT;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 100;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 37)];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.font = [Utils boldFont:24];
    if (self.hasChoose) {
        if (row == self.choosePosition) {
            label.text = @"(Choose)";
        } else {
            if (row < self.choosePosition) {
                label.text = [NSString stringWithFormat:@"%ld", row + self.min];
            } else {
                label.text = [NSString stringWithFormat:@"%ld", row + self.min - 1];
            }
        }
    } else {
        label.text = [NSString stringWithFormat:@"%ld", row % self.rangeCount + self.min ];
    }
    return label;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if (self.hasChoose) {
        if (self.value <= 0) {
            // "Choose"
            [self.pickerView selectRow:self.choosePosition inComponent:0 animated:NO];
        } else {
            int position = (self.value - self.min);
            if (position < self.choosePosition) {
                [self.pickerView selectRow:position inComponent:0 animated:NO];
            } else {
                [self.pickerView selectRow:(1+position) inComponent:0 animated:NO];
            }
        }
    } else {
        [self.pickerView selectRow:self.value - self.min + self.rangeCount * REPEAT_COUNT / 2 inComponent:0 animated:NO];
    }
    self.titleLabel.text = self.title;
    self.titleLabel.preferredMaxLayoutWidth = self.titleLabel.width;
    [self.titleLabel sizeToFit];
}

- (void)present {
    [[GLPickerViewController sharedInstance] presentWithContentController:self];
}

- (IBAction)doneClicked:(id)sender {
    [[GLPickerViewController sharedInstance] dismiss];
    NSInteger row = [self.pickerView selectedRowInComponent:0];
    if (self.hasChoose) {
        if (row == self.choosePosition) {
            self.value = 0;
        } else {
            if (row < self.choosePosition) {
                self.value = row + self.min;
            } else {
                self.value = row + self.min - 1;
            }
        }
    } else {
        self.value = row % self.rangeCount + self.min;
    }
    [self.delegate daysPicker:self didDismissWithDays:self.value];
}

@end
