//
//  ReminderHead.m
//  emma
//
//  Created by Eric Xu on 8/13/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ReminderHead.h"

@implementation ReminderHead

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    UIImage *imageWhite = [Utils image:[UIImage imageNamed:@"topnav-close"] withColor:[UIColor whiteColor]];
    [self.closeButton setImage:imageWhite forState:UIControlStateNormal];
    
}

- (IBAction)segChanged:(id)sender {
    [self publish:EVENT_REMINDER_HEADER_SEG_CHANGED];
}

@end
