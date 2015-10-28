//
//  ChildrenNumberPicker.m
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ChildrenNumberPicker.h"
#import <GLFoundation/GLPickerViewController.h>

@interface ChildrenNumberPicker () {
    NSArray *options;
}

@property (nonatomic) BOOL hasChoose;
@property (nonatomic) int choosePosition;

@end

@implementation ChildrenNumberPicker

- (id)initWithChoose:(int)position number:(NSInteger)number {
    self = [super initWithNibName:@"ChildrenNumberPicker" bundle:nil];
    if (self) {
        self.number = number < 0 ? -1 : number;
        self.hasChoose = YES;
        self.choosePosition = position;
    }
    return self;
}

- (id)initWithNumber:(NSInteger)number {
    self = [super initWithNibName:@"ChildrenNumberPicker" bundle:nil];
    if (self) {
        self.number = number < 0 ? 0 : number;
        self.hasChoose = NO;
        self.choosePosition = 0;
    }
    return self;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (self.hasChoose) {
        // +1 for choose
        return options.count + 1;
    } else {
        return [options count] * 100;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 300;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 37)];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.font = [Utils boldFont:24];
    if (self.hasChoose) {
        if (row == self.choosePosition) {
            label.text = @"(Choose)";
        } else {
            if (row < self.choosePosition) {
                label.text = [options objectAtIndex:row];
            } else {
                label.text = [options objectAtIndex:(row - 1)];
            }
        }
    } else {
        label.text = [options objectAtIndex:row % [options count]];
    }
    return label;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    options = @[
        @"0",
        @"1",
        @"2",
        @"3",
        @"4",
        @"5",
        @"6",
        @"7",
        @"8",
        @"9"
    ];
    if (self.hasChoose) {
        if (self.number < 0) {
            [self.pickerView selectRow:self.choosePosition inComponent:0 animated:NO];
        } else {
            if (self.number < self.choosePosition) {
                [self.pickerView selectRow:self.number inComponent:0 animated:NO];
            } else {
                [self.pickerView selectRow:self.number + 1 inComponent:0 animated:NO];
            }
        }
    } else {
        [self.pickerView selectRow:self.number + [options count] * 50 inComponent:0 animated:NO];
    }
}

- (void)present {
    [[GLPickerViewController sharedInstance] presentWithContentController:self];
}

- (IBAction)doneClicked:(id)sender {
    [[GLPickerViewController sharedInstance] dismiss];
    NSInteger num = 0;
    NSInteger selected = [self.pickerView selectedRowInComponent:0];
    if (self.hasChoose) {
        if (selected == self.choosePosition) {
            num = -1;
        } else {
            if (selected < self.choosePosition) {
                num = selected;
            } else {
                num = selected - 1;
            }
        }
    } else {
        num = selected % [options count];
    }
    [self.delegate childrenNumberPicker:self didDismissWithNumber:num];
}
@end
