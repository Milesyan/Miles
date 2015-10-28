//
//  EmmaDatePicker.h
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BaseDatePicker;

@protocol DatePickerDelegate
- (void)datePicker:(BaseDatePicker *)datePicker didDismissWithDate:(NSDate *)date;
@end

@interface BaseDatePicker : UIViewController
@property (nonatomic, strong)IBOutlet UIDatePicker *datePicker;
@property (nonatomic, strong)IBOutlet UILabel *titleLabel;
@property (nonatomic, weak)id<DatePickerDelegate> delegate;
@property (nonatomic, strong)NSDate *date;

- (void)present;
- (IBAction)doneClicked:(id)sender;
@end
