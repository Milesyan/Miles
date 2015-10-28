//
//  BirthdayPicker.m
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "BirthdayPicker.h"

@interface BirthdayPicker ()
@end

@implementation BirthdayPicker

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:- MAX_AGE];
    self.datePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:- MIN_AGE];
    self.datePicker.date = [NSDate dateWithTimeIntervalSinceNow:- DEFAULT_AGE];
}

@end
