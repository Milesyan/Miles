//
//  GLTextInputQuestionCell.m
//  GLQuestionKit
//
//  Created by ltebean on 15/9/9.
//  Copyright © 2015年 glow. All rights reserved.
//

#import "GLTextInputQuestionCell.h"
#import "GLLinkLabel.h"

@interface GLTextInputQuestionCell()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet GLLinkLabel *questionLabel;
@property (weak, nonatomic) IBOutlet UITextField *inputField;
@end

@implementation GLTextInputQuestionCell
@dynamic question;

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.inputField.delegate = self;
}

- (void)setQuestion:(GLTextInputQuestion *)question
{
    [super setQuestion:question];
    
    self.questionLabel.font = question.titleFont ?: self.questionLabel.font;
    self.questionLabel.textColor = question.titleColor ?: self.questionLabel.textColor;
    self.questionLabel.text = question.title;
    
    [self.questionLabel clearCallbacks];
    for (NSString *term in self.question.highlightTerms) {
        [self.questionLabel setCallback:^(NSString *str) {
            [self publish:EVENT_GLQUESTION_TERM_CLICK data:str];
        } forKeyword:term caseSensitive:NO];
    }
    self.inputField.placeholder = question.placeholderText;
    self.inputField.text = question.answer;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self publish:EVENT_GLQUESTION_BEGIN_EDIT data:self.question];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (![textField.text isEqualToString:@""]) {
        [self updateAnwser:textField.text];
    } else {
        [self updateAnwser:nil];
    }
}

+ (NSNumber *)heightForQuestion:(GLQuestion *)question
{
    return @(60);
}

@end
