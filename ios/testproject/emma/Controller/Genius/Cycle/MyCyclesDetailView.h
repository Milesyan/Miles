//
//  MyCyclesDetailView.h
//  emma
//
//  Created by Xin Zhao on 5/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyCyclesDetailView : UIView

@property (weak, nonatomic) IBOutlet UILabel *periodDatesLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *cycleLengthLabel;


- (void)setDates:(NSString *)datesStr duration:(int)duration cycleLength:(int)cl;

@end
