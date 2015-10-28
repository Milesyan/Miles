//
//  FertilityTestInputCell.m
//  emma
//
//  Created by Peng Gu on 7/13/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "FertilityTestInputCell.h"
#import "FertilityTestItem.h"

@interface FertilityTestInputCell () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UILabel *inputTitleLabel;
@property (nonatomic, weak) IBOutlet UITextField *inputField;
@property (nonatomic, strong) FertilityTestItem *item;

@end


@implementation FertilityTestInputCell


- (void)configureWithItem:(FertilityTestItem *)item answer:(NSString *)answer
{
    self.item = item;
    self.inputTitleLabel.text = item.question;
    self.inputField.delegate = self;
    
    if ([Utils isEmptyString:answer]) {
        self.inputField.text = @"";
        self.inputField.placeholder = item.placeholderAnswerText;
    }
    else {
        self.inputField.text = answer;
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (![textField.text isEqualToString:self.item.answer]) {
        if ([self.delegate respondsToSelector:@selector(fertilityTestInputCell:didInputValue:forItem:)]) {
            [self.delegate fertilityTestInputCell:self didInputValue:textField.text forItem:self.item];
        }
    }
}


@end
