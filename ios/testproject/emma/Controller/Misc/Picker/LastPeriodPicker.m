//
//  LastPeriodPickerViewController.m
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "LastPeriodPicker.h"

@interface LastPeriodPicker ()

@end

@implementation LastPeriodPicker
- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:- 60 * 60 * 24 * (CYCLE_LENGTH_MAX+1)];
    self.datePicker.maximumDate = [NSDate date];
}

@end
