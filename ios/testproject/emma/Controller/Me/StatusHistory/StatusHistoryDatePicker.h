//
//  StatusHistoryDatePicker.h
//  emma
//
//  Created by ltebean on 15/6/22.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "BaseDatePicker.h"

#define TYPE_BEGIN_DATE 0
#define TYPE_END_DATE 1

@interface StatusHistoryDatePicker : BaseDatePicker
@property (nonatomic) NSInteger type;
@property (nonatomic, strong) NSDate *minimumDate;
@property (nonatomic, strong) NSDate *maximumDate;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;

- (instancetype)initWithMinimumDate:(NSDate *)minimumDate maximumDate:(NSDate *)maximumDate;
@end
