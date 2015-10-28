//
//  EmmaDatePicker.m
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "BaseDatePicker.h"
#import <GLFoundation/GLPickerViewController.h>

@interface BaseDatePicker ()
@end

@implementation BaseDatePicker
- (NSDate *)date {
    return self.datePicker.date;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}
- (void)setDate:(NSDate *)date {
    if (date)
        self.datePicker.date = date;
}

- (void)present {
    if (self.view) {
        [[GLPickerViewController sharedInstance] presentWithContentController:self];
    }
}

- (IBAction)doneClicked:(id)sender {
    [[GLPickerViewController sharedInstance] dismiss];
    [self.delegate datePicker:self didDismissWithDate:self.datePicker.date];
}
@end
