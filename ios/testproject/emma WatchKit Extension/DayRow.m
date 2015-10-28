//
//  DayRow.m
//  watch
//
//  Created by ltebean on 15/5/9.
//  Copyright (c) 2015年 ltebean. All rights reserved.
//

#import "DayRow.h"
#import "DataController.h"

@interface DayRow()
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *circle;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *textLabel;
@end

@implementation DayRow
- (void)setData:(NSDictionary *)data
{
    _data = data;
    [self updateUI];
}


- (void)updateUI
{
    UIColor *color = UIColorFromRGB([self.data[kPredictionColor] integerValue]);
    
    [self.circle setBackgroundColor:color];
    [self.textLabel setText:self.data[kPredictionText]];
}
@end
