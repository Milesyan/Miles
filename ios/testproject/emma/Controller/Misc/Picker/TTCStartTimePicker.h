//
//  TTCLengthPicker.h
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasePickerViewController.h"

@class TTCStartTimePicker;

@protocol TTCStartTimerPickerDelegate
- (void)TTCStartTimePicker:(TTCStartTimePicker *)picker didDismissWithLength:(NSString *)length;
@end

@interface TTCStartTimePicker : BasePickerViewController
@property (nonatomic, weak)id<TTCStartTimerPickerDelegate> delegate;
@property (nonatomic, weak)IBOutlet UIPickerView *pickerView;
@property (nonatomic)NSString *length;

- (id)initWithChoose:(int)position length:(NSString *)length;
- (id)initWithLength:(NSString *)length;
- (void)present;
@end