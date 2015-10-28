//
//  StatusHistoryDatePicker.m
//  emma
//
//  Created by ltebean on 15/6/22.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "StatusHistoryDatePicker.h"
#import "GLPickerViewController.h"
@interface StatusHistoryDatePicker()

@end

@implementation StatusHistoryDatePicker
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.minimumDate) {
        self.datePicker.minimumDate = self.minimumDate;
    }
    if (self.maximumDate) {
        self.datePicker.maximumDate = self.maximumDate;
    }
}

- (instancetype)initWithMinimumDate:(NSDate *)minimumDate maximumDate:(NSDate *)maximumDate
{
    self = [super init];
    if (self) {
        self.minimumDate = minimumDate;
        self.maximumDate = maximumDate;
    }
    return self;
}


- (IBAction)cancelButtonPressed:(id)sender {
    [[GLPickerViewController sharedInstance] dismiss];
}
@end
