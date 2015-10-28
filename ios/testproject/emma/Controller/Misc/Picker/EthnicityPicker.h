//
//  InsurancePicker.h
//  emma
//
//  Created by Peng Gu on 2/16/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "BasePickerViewController.h"

typedef void (^DismissAction)(NSInteger row, NSInteger comp);

@interface EthnicityPicker : BasePickerViewController

- (void)presentWithOptions:(NSArray *)options
               selectedRow:(NSInteger)selectedRow
                doneAction:(DismissAction)doneAction
              cancelAction:(DismissAction)cancelAction;

@end
