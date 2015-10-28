//
//  ReminderHead.h
//  emma
//
//  Created by Eric Xu on 8/13/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define EVENT_REMINDER_HEADER_SEG_CHANGED @"event_reminder_header_seg_changed"

@interface ReminderHead : UIView
@property (strong, nonatomic) IBOutlet UILabel *headerText;
@property (strong, nonatomic) IBOutlet UIView *breakLine;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UISegmentedControl *headerSegment;

@end
