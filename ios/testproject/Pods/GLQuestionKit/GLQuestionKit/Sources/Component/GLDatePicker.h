//
//  GLDatePicker.h
//  GLQuestionCell
//
//  Created by ltebean on 15/7/19.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GLDatePicker;

@protocol GLDatePickerDelegate
- (void)datePicker:(GLDatePicker *)picker didDismissWithDate:(NSDate *)date;
@end

@interface GLDatePicker : UIViewController
@property (nonatomic) NSInteger type;
@property (nonatomic, copy) NSString *pickerTitle;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic) UIDatePickerMode mode;
@property (nonatomic, copy) NSDate *minimumDate;
@property (nonatomic, copy) NSDate *maximumDate;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, weak) id<GLDatePickerDelegate> delegate;
- (instancetype)initWithMinimumDate:(NSDate *)minimumDate maximumDate:(NSDate *)maximumDate
                               mode:(UIDatePickerMode)mode title:(NSString *)title;
- (void)present;


@end
