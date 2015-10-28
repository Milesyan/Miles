//
//  InsurancePicker.m
//  emma
//
//  Created by Peng Gu on 2/16/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "EthnicityPicker.h"
#import <GLFoundation/GLPickerViewController.h>

@interface EthnicityPicker () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, strong) NSArray *options;
@property (nonatomic, assign) NSInteger selectedRow;

@property (nonatomic, strong) DismissAction doneAction;
@property (nonatomic, strong) DismissAction cancelAction;

@end

@implementation EthnicityPicker

- (id)init
{
    return [super initWithNibName:@"EthnicityPicker" bundle:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.pickerView reloadAllComponents];
    if (self.selectedRow >= 0 && self.selectedRow < self.options.count) {
        [self.pickerView selectRow:self.selectedRow inComponent:0 animated:NO];
    }
}


#pragma mark - actions
- (IBAction)cancelButtonPressed:(id)sender
{
    if (self.cancelAction) {
        self.cancelAction(self.selectedRow, NO);
    }
    [[GLPickerViewController sharedInstance] dismiss];
}


- (IBAction)doneButtonPressed:(id)sender
{
    if (self.doneAction) {
        self.doneAction(self.selectedRow, YES);
    }
    [[GLPickerViewController sharedInstance] dismiss];
}


- (void)presentWithOptions:(NSArray *)options
               selectedRow:(NSInteger)selectedRow
                doneAction:(DismissAction)doneAction
              cancelAction:(DismissAction)cancelAction
{
    self.options = options;
    self.selectedRow = selectedRow;
    self.doneAction = doneAction;
    self.cancelAction = cancelAction;
    
    [[GLPickerViewController sharedInstance] presentWithContentController:self];
}


#pragma mark - picker delegates
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return SCREEN_WIDTH;
}


- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel* label = (UILabel*)view;
    if (!label)
    {
        label = [[UILabel alloc] init];
        label.font = [Utils semiBoldFont:18];
        label.textAlignment = NSTextAlignmentCenter;
    }
    
    label.text = [self.options objectAtIndex:row];
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.selectedRow = row;
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.options.count;
}

@end
