//
//  BooleanPicker.h
//  emma
//
//  Created by Xin Zhao on 13-11-21.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "BasePickerViewController.h"

@class BooleanPicker;

@protocol BooleanPickerDelegate

- (void)booleanPicker:(BooleanPicker *)picker didDismissWith:(BOOL)yesOrNo;

@end

@interface BooleanPicker : BasePickerViewController
@property (nonatomic, weak)id<BooleanPickerDelegate> delegate;
@property (nonatomic, weak)IBOutlet UIPickerView *pickerView;
@property (nonatomic) BOOL yesOrNo;
@property (nonatomic) NSInteger multiPickerIdentifier;

- (id)initWithYesOrNo:(BOOL)yesOrNo config:(NSDictionary *)config;
- (void)present;
- (IBAction)doneClicked:(id)sender;

@end
