//
//  InputAccessoryView.h
//  emma
//
//  Created by Peng Gu on 10/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define EVENT_KBINPUT_DONE @"eventKBInputDone"
#define EVENT_KBINPUT_CANCEL @"eventKBInputCancel"
#define EVENT_KBINPUT_STARTOVER @"eventKBInputStartOver"
#define EVENT_KEYBOARD_DISMISSED @"KeyboardDismissed"
#define EVENT_KBINPUT_UNIT_SWITCH @"eventKBUnitSwitch"

@interface GLQuestionInputAccessoryView : UIView
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *segButtonItem;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segControl;


- (IBAction)doneButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)startOverButtonPressed:(id)sender;

@end
