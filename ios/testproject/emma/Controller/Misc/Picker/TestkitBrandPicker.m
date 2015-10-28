//
//  TestkitBrandPicker.m
//  emma
//
//  Created by Eric Xu on 11/8/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "TestkitBrandPicker.h"
#import <GLFoundation/GLPickerViewController.h>

@interface TestkitBrandPicker ()
@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (nonatomic) NSInteger selectedIndex;
@property (strong, nonatomic) IBOutlet UILabel *label;

- (IBAction)doneButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)startOverButtonPressed:(id)sender;

@end

@implementation TestkitBrandPicker

- (id)init
{
    self = [super initWithNibName:@"TestkitBrandPicker" bundle:nil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    [self.picker reloadAllComponents];
    if (self.selectedIndex >= 0 && self.selectedIndex < [self.brands count]) {
        [self.picker selectRow:self.selectedIndex inComponent:0 animated:NO];
    }
}

- (void)viewDidLayoutSubviews
{
//    self.view.width = SCREEN_WIDTH;
    [super viewDidLayoutSubviews];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)present;
{
    [[GLPickerViewController sharedInstance] presentWithContentController:self];
}

- (void)presentWithBrands:(NSArray *)arr selection:(NSInteger)selectedIndex
{
    GLLog(@"selected: %d", selectedIndex);
    self.brands = arr;
    self.selectedIndex = selectedIndex;
    [self present];
}

#pragma mark - Toolbar buttons
- (IBAction)doneButtonPressed:(id)sender {
    NSInteger idx = [self.picker selectedRowInComponent:0];
    if (self.delegate) {
        [self.delegate testkitBrandPicker:self didDismissWithBrandIndex:idx];
    }
    [[GLPickerViewController sharedInstance] dismiss];
}

- (IBAction)cancelButtonPressed:(id)sender {
    if (self.delegate) {
        [self.delegate testkitBrandPickerDidDismissWithCancelButton:self];
    }
    [[GLPickerViewController sharedInstance] dismiss];
}

- (IBAction)startOverButtonPressed:(id)sender {
    if (self.delegate) {
        [self.delegate testkitBrandPickerDidDismissWithStartOverButton:self];
    }
    [[GLPickerViewController sharedInstance] dismiss];
}

#pragma mark - UIPickerViewDelegate
//- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
//{
//    
//}

//- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
//{
//    
//}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (self.brands && row < [self.brands count])
        return [self.brands objectAtIndex:row];
    else
        return @"";
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (self.brands)
        return [self.brands count];
    else
        return 0;
    
}
@end
