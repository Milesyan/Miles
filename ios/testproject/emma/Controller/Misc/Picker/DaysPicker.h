//
//  DaysPicker.h
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasePickerViewController.h"

@class DaysPicker;

@protocol DaysPickerDelegate
- (void)daysPicker:(DaysPicker *)daysPicker didDismissWithDays:(NSInteger)days;
@end

@interface DaysPicker : BasePickerViewController

@property (nonatomic, weak)id<DaysPickerDelegate> delegate;
@property (nonatomic, weak)IBOutlet UIPickerView *pickerView;
@property (nonatomic) NSInteger identifier;

- (id)initWithTitle:(NSString *)title default:(NSInteger)value min:(NSInteger)minDays max:(NSInteger)maxDays;
- (id)initWithChoose:(int)position title:(NSString *)title default:(NSInteger)value min:(NSInteger)minDays max:(NSInteger)maxDays;
- (void)present;
- (IBAction)doneClicked:(id)sender;
@end
