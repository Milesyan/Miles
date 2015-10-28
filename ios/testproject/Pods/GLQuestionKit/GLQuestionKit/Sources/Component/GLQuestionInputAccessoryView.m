//
//  InputAccessoryView.m
//  emma
//
//  Created by Peng Gu on 10/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "GLQuestionInputAccessoryView.h"
#import <GLFoundation/NSObject+PubSub.h>

@implementation GLQuestionInputAccessoryView

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (IBAction)doneButtonPressed:(id)sender {
    [self publish:EVENT_KBINPUT_DONE];
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self publish:EVENT_KBINPUT_CANCEL];
}
- (IBAction)unitSegChanged:(id)sender {
    UISegmentedControl *ctrl = (UISegmentedControl *)sender;
    [self publish:EVENT_KBINPUT_UNIT_SWITCH data:@([ctrl selectedSegmentIndex])];
}

- (IBAction)startOverButtonPressed:(id)sender {
    [self publish:EVENT_KBINPUT_STARTOVER];
}


@end
