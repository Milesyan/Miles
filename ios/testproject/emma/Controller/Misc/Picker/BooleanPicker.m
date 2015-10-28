//
//  BooleanPicker.m
//  emma
//
//  Created by Xin Zhao on 13-11-21.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "BooleanPicker.h"
#import <GLFoundation/GLPickerViewController.h>

@interface BooleanPicker () <UIPickerViewDelegate>{
    NSArray *options;
}
@end

@implementation BooleanPicker

#pragma mark - init and setup
- (id)initWithYesOrNo:(BOOL)yesOrNo config:(NSDictionary *)config {
    self = [super initWithNibName:@"BooleanPicker" bundle:nil];
    if (self) {
        self.pickerView.delegate = self;
        self.yesOrNo = yesOrNo;
        options = config[@"options"];
    }
    return self;
}

#pragma mark - delegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 2;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 300;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 37)];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.font = [Utils boldFont:24];
    label.text = options[row];
    return label;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    [self.pickerView selectRow:self.yesOrNo? 0 : 1 inComponent:0 animated:NO];
}

- (void)present {
    [[GLPickerViewController sharedInstance] presentWithContentController:self];
}

- (IBAction)doneClicked:(id)sender {
    [[GLPickerViewController sharedInstance] dismiss];
    self.yesOrNo = [self.pickerView selectedRowInComponent:0] == 0 ? YES : NO;
    [self.delegate booleanPicker:self didDismissWith:self.yesOrNo];
}

@end
