//
//  treatmentStartPicker.h
//  emma
//
//  Created by Jirong Wang on 10/31/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "BaseDatePicker.h"

#define TYPE_START_DATE 0
#define TYPE_END_DATE 1

@interface TreatmentStartPicker : BaseDatePicker
@property (nonatomic) NSInteger type;
@property (nonatomic, strong) NSDate *minimumDate;
@property (nonatomic, strong) NSDate *maximumDate;
- (instancetype)initWithMinimumDate:(NSDate *)minimumDate maximumDate:(NSDate *)maximumDate;
@end
