//
//  GLPickerOptionsQuestionCell.m
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLPickerQuestionCell.h"
#import <GLFoundation/GLPillButton.h>
#import <GLFoundation/GLGeneralPicker.h>
#import "GLLinkLabel.h"

@interface GLPickerQuestionCell()
@property (weak, nonatomic) IBOutlet GLPillButton *button;
@property (weak, nonatomic) IBOutlet GLLinkLabel *questionLabel;
@end

@implementation GLPickerQuestionCell
@dynamic question;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setQuestion:(GLPickerQuestion *)question
{
    [super setQuestion:question];
    
    self.questionLabel.font = question.titleFont ?: self.questionLabel.font;
    self.questionLabel.textColor = question.titleColor ?: self.questionLabel.textColor;
    self.questionLabel.text = question.title;

    [self updateButtonText];
    
    [self.questionLabel clearCallbacks];
    for (NSString *term in question.highlightTerms) {
        [self.questionLabel setCallback:^(NSString *str) {
            [self publish:EVENT_GLQUESTION_TERM_CLICK data:str];
        } forKeyword:term caseSensitive:NO];
    }
}

- (void)updateButtonText
{
    if (self.question.answer) {
        NSString *text = self.question.optionTitles[[self.question.optionValues indexOfObject:self.question.answer]];
        [self.button setLabelText:[NSString stringWithFormat:@"  %@  ", text] bold:YES];
        [self.button setSelected:YES];
    } else {
        [self.button setLabelText:@"Choose" bold:YES];
        [self.button setSelected:NO];
    }
}


- (IBAction)buttonPressed:(id)sender
{
    int selectedRow = (int)[self.question.optionValues indexOfObject:self.question.answer];
    
    [GLGeneralPicker presentStartoverSimplePickerWithTitle:self.question.pickerTitle rows:self.question.optionTitles selectedRow:selectedRow doneCompletion:^(NSInteger row, NSInteger comp) {
        NSString *value = self.question.optionValues[row];
        [self updateAnwser:value];
        [self updateButtonText];
        [self publishClickEventWithType:CLICK_TYPE_INPUT];

    } startoverCompletion:^(NSInteger row, NSInteger comp) {
        [self updateAnwser:nil];
        [self updateButtonText];
        [self publishClickEventWithType:CLICK_TYPE_INPUT];

    }];
}

@end
