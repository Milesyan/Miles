//
//  ChildrenNumberPicker.h
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasePickerViewController.h"

@class ChildrenNumberPicker;

@protocol ChildrenNumberPickerDelegate
- (void)childrenNumberPicker:(ChildrenNumberPicker *)picker didDismissWithNumber:(NSInteger)num;
@end

@interface ChildrenNumberPicker : BasePickerViewController
@property (nonatomic, weak)id<ChildrenNumberPickerDelegate> delegate;
@property (nonatomic, weak)IBOutlet UIPickerView *pickerView;
@property (nonatomic, assign) NSInteger number;

- (id)initWithChoose:(int)position number:(NSInteger)number;
- (id)initWithNumber:(NSInteger)num;
- (void)present;
- (IBAction)doneClicked:(id)sender;
@end
