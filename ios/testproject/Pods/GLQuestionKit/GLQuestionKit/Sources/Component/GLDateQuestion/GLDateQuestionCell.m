//
//  GLDateQuestionCell.m
//  GLQuestionCell
//
//  Created by ltebean on 15/7/19.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLDateQuestionCell.h"
#import <GLFoundation/GLPillButton.h>
#import "GLDatePicker.h"
#import "GLLinkLabel.h"

@interface GLDateQuestionCell()<GLDatePickerDelegate>
@property (weak, nonatomic) IBOutlet GLPillButton *button;
@property (weak, nonatomic) IBOutlet GLLinkLabel *questionLabel;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;


@end

@implementation GLDateQuestionCell
@dynamic question;

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.dateFormatter = [[NSDateFormatter alloc] init];

}

- (void)setQuestion:(GLDateQuestion *)question
{
    [super setQuestion:question];
    
    self.questionLabel.font = question.titleFont ?: self.questionLabel.font;
    self.questionLabel.textColor = question.titleColor ?: self.questionLabel.textColor;
    self.questionLabel.text = question.title;
    self.infoButton.hidden = !question.showInfoButton;
    
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
    
    if (self.question.pickerMode == MODE_DATE) {
        self.dateFormatter.dateFormat = @"YYYY/MM/dd";
    }
    else if (self.question.pickerMode == MODE_DATE_AND_TIME) {
        self.dateFormatter.dateFormat = @"dd HH:mm";
    }
    else if (self.question.pickerMode == MODE_TIME) {
        self.dateFormatter.dateFormat = @"HH:mm";
    }
    if (self.question.answer.length > 0) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[self.question.answer integerValue]];
        [self.button setLabelText:[self.dateFormatter stringFromDate:date] bold:YES];
        [self.button setSelected:YES];
    } else {
        [self.button setLabelText:@"Enter" bold:YES];
        [self.button setSelected:NO];
    }
}

- (IBAction)infoButtonClicked:(id)sender
{
    [self publish:EVENT_GLQUESTION_TERM_CLICK data:self.questionLabel.text];
}

- (IBAction)buttonPressed:(id)sender {
    UIDatePickerMode mode = UIDatePickerModeDate;
    if (self.question.pickerMode == MODE_DATE) {
        mode = UIDatePickerModeDate;
    }
    else if (self.question.pickerMode == MODE_DATE_AND_TIME) {
        mode = UIDatePickerModeDateAndTime;
    }
    else if (self.question.pickerMode == MODE_TIME) {
        mode = UIDatePickerModeTime;
    }
    GLDatePicker *picker = [[GLDatePicker alloc] initWithMinimumDate:nil maximumDate:nil mode:mode title:self.question.pickerTitle];
    picker.delegate = self;
    [picker present];
    if (self.question.answer) {
        picker.datePicker.date = [NSDate dateWithTimeIntervalSince1970:[self.question.answer integerValue]];
    }
    
    [self publish:EVENT_GLQUESTION_BEGIN_EDIT data:self.question];
}


- (void)datePicker:(GLDatePicker *)picker didDismissWithDate:(NSDate *)date
{
    [self updateAnwser:date ? [NSString stringWithFormat:@"%.f", [date timeIntervalSince1970]] : nil];
    [self updateButtonText];
    [self publishClickEventWithType:CLICK_TYPE_INPUT];
}
@end
