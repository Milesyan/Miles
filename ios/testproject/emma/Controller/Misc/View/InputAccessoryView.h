//
//  InputAccessoryView.h
//  emma
//
//  Created by Peng Gu on 10/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InputAccessoryView : UIView
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *segButtonItem;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segControl;


- (IBAction)doneButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)startOverButtonPressed:(id)sender;

@end
