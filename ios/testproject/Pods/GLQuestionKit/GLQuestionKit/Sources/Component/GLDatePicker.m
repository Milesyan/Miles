//
//  GLDatePicker.m
//  GLQuestionCell
//
//  Created by ltebean on 15/7/19.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLDatePicker.h"
#import <GLFoundation/GLPickerViewController.h>

@interface GLDatePicker ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@end

@implementation GLDatePicker

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.minimumDate) {
        self.datePicker.minimumDate = self.minimumDate;
    }
    if (self.maximumDate) {
        self.datePicker.maximumDate = self.maximumDate;
    }
    self.datePicker.datePickerMode = self.mode;
    self.titleLabel.text = self.pickerTitle;
}

- (instancetype)initWithMinimumDate:(NSDate *)minimumDate maximumDate:(NSDate *)maximumDate
                               mode:(UIDatePickerMode)mode title:(NSString *)title
{
    self = [super init];
    if (self) {
        self.minimumDate = minimumDate;
        self.maximumDate = maximumDate;
        self.mode = mode;
        self.pickerTitle = title;
    }
    return self;
}

- (void)present {
    if (self.view) {
        [[GLPickerViewController sharedInstance] presentWithContentController:self];
    }
}

- (void)setDate:(NSDate *)date {
    self.datePicker.date = date;
}


- (IBAction)cancelButtonPressed:(id)sender {
    [[GLPickerViewController sharedInstance] dismiss];
    [self.delegate datePicker:self didDismissWithDate:nil];
}


- (IBAction)doneButtonPressed:(id)sender {
    [[GLPickerViewController sharedInstance] dismiss];
    [self.delegate datePicker:self didDismissWithDate:self.datePicker.date];
}



@end
