//
//  MyCyclesDetailView.m
//  emma
//
//  Created by Xin Zhao on 5/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "MyCyclesDetailView.h"

@implementation MyCyclesDetailView

- (id)initWithFrame:(CGRect)frame
{
    //self = [super initWithFrame:frame];
    
    self = [[[NSBundle mainBundle] loadNibNamed:@"MyCyclesDetailView" owner:nil options:nil] lastObject];
    if (self) {
        // Initialization code
        self.frame = frame;
    }
    return self;
}

- (void)setDates:(NSString *)datesStr duration:(int)duration
    cycleLength:(int)cl {
    self.periodDatesLabel.text = datesStr;
    self.durationLabel.text = [NSString stringWithFormat:@"%d", duration];
    self.cycleLengthLabel.text = [NSString stringWithFormat:@"%d", cl];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
