//
//  treatmentStartPicker.m
//  emma
//
//  Created by Jirong Wang on 10/31/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "TreatmentStartPicker.h"

@interface TreatmentStartPicker ()

@end

@implementation TreatmentStartPicker

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    int pastTime = 60 * 24 * 60 * 60; // 60 days
    int futureTime = 90 * 24 * 60 * 60; // 90 days
    
    self.datePicker.minimumDate = self.minimumDate ?: [NSDate dateWithTimeIntervalSinceNow:0-pastTime];
    self.datePicker.maximumDate = self.maximumDate ?: [NSDate dateWithTimeIntervalSinceNow:futureTime];
    
    if (self.type == TYPE_START_DATE) {
        self.titleLabel.text = @"Treatment start date";
    }
    else if (self.type == TYPE_END_DATE) {
        self.titleLabel.text = @"Treatment end date";
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
