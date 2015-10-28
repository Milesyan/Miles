//
//  GLOptionsQuestionCell.m
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLNumberQuestionCell.h"
#import <GLFoundation/GLPillButton.h>
#import "GLQuestionInputAccessoryView.h"
#import <libextobjc/EXTScope.h>
#import <GLFoundation/NSObject+PubSub.h>
#import "GLLinkLabel.h"

@interface GLNumberQuestionCell()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet GLPillButton *button;
@property (weak, nonatomic) IBOutlet GLLinkLabel *questionLabel;
@property (weak, nonatomic) IBOutlet UITextField *hiddenInputField;
@property (weak, nonatomic) GLQuestionInputAccessoryView *inputAccessoryView;
@end

@implementation GLNumberQuestionCell
@dynamic question;

- (void)awakeFromNib
{
    [super awakeFromNib];
    GLQuestionInputAccessoryView *view = (GLQuestionInputAccessoryView *)[[[NSBundle mainBundle] loadNibNamed:@"GLQuestionInputAccessoryView" owner:self options:nil] objectAtIndex:0];
    self.inputAccessoryView = view;
    self.hiddenInputField.inputAccessoryView = view;
    self.hiddenInputField.hidden = YES;
    self.hiddenInputField.delegate = self;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(textChanged:)
     name:UITextFieldTextDidChangeNotification
     object:self.hiddenInputField];

    
    @weakify(self)
    [self subscribe:EVENT_KEYBOARD_DISMISSED handler:^(Event *event) {
        @strongify(self)
        id firstResponder = [event data];
        if (firstResponder && firstResponder == self.hiddenInputField) {
            [self.hiddenInputField resignFirstResponder];
        }
    }];
    
    [self subscribe:EVENT_KBINPUT_DONE handler:^(Event *event) {
        @strongify(self)
        if (self && self.hiddenInputField.isFirstResponder) {
            [self.hiddenInputField resignFirstResponder];
            [self updateButtonTextWithAnswer:self.hiddenInputField.text];
            [self publishClickEventWithType:CLICK_TYPE_INPUT];
        }
    }];

    
    [self subscribe:EVENT_KBINPUT_UNIT_SWITCH handler:^(Event *event) {
        @strongify(self)
        if (self && self.hiddenInputField.isFirstResponder) {
            NSInteger index = [(NSNumber *)event.data integerValue];
            GLUnit *originalUnit = self.question.unitList[self.question.indexOfSeletedUnit];
            GLUnit *destinationUnit = self.question.unitList[index];
            self.question.indexOfSeletedUnit = index;
            NSString *answer = self.hiddenInputField.text.length > 0 ? self.hiddenInputField.text : self.question.answer;
            if (!answer) {
                return;
            }
            NSString *convertedAnswer = [self convertAnswer:answer fromUnit:originalUnit toUnit:destinationUnit];
            [self updateButtonTextWithAnswer:convertedAnswer];
            self.hiddenInputField.text = convertedAnswer;
        }
    }];

    
    [self subscribe:EVENT_KBINPUT_STARTOVER handler:^(Event *event) {
        @strongify(self)
        if (self && self.hiddenInputField.isFirstResponder) {
            [self.hiddenInputField resignFirstResponder];
            [self updateButtonTextWithAnswer:nil];
            [self publishClickEventWithType:CLICK_TYPE_INPUT];
        }
    }];
    
    
    [self subscribe:EVENT_GLQUESTION_BEGIN_EDIT handler:^(Event *event) {
        @strongify(self)
        GLQuestion *question = (GLQuestion *)event.data;
        if (question != self.question) {
            [self.hiddenInputField resignFirstResponder];
            if (self.question.answer.length > 0) {
                [self.button setLabelText:[self answerTextWithUnit:self.question.answer] bold:YES];
                [self.button setSelected:YES];
            } else {
                [self.button setLabelText:@"Enter" bold:YES];
                [self.button setSelected:NO];
            }
        }
    }];
}



- (void)setQuestion:(GLNumberQuestion *)question
{
    [super setQuestion:question];

    self.questionLabel.font = question.titleFont ?: self.questionLabel.font;
    self.questionLabel.textColor = question.titleColor ?: self.questionLabel.textColor;
    self.questionLabel.text = question.title;
    
    if (question.answer.length > 0) {
        [self.button setLabelText:[self answerTextWithUnit:question.answer] bold:YES];
        [self.button setSelected:YES];
    } else {
        [self.button setLabelText:@"Enter" bold:YES];
        [self.button setSelected:NO];
    }
        
    if (question.padType == NUMBER_PAD) {
        self.hiddenInputField.keyboardType = UIKeyboardTypeNumberPad;
    } else {
        self.hiddenInputField.keyboardType = UIKeyboardTypeDecimalPad;
    }
    
    if (question.unitList.count > 1) {
        self.inputAccessoryView.segControl.hidden = NO;
        for (NSInteger i = 0; i < question.unitList.count; i ++) {
            GLUnit *unit = question.unitList[i];
            [self.inputAccessoryView.segControl setTitle:unit.name forSegmentAtIndex:i];
        }
    } else {
        self.inputAccessoryView.segControl.hidden = YES;
    }
    
    [self.questionLabel clearCallbacks];
    for (NSString *term in question.highlightTerms) {
        [self.questionLabel setCallback:^(NSString *str) {
            [self publish:EVENT_GLQUESTION_TERM_CLICK data:str];
        } forKeyword:term caseSensitive:NO];
    }
}


- (void)textChanged:(NSNotification *)notif {
    NSString *text = self.hiddenInputField.text;
    [self updateButtonTextWithAnswer:text];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    NSString *chars = @"0123456789.";
    NSCharacterSet *characterSet = [[NSCharacterSet characterSetWithCharactersInString:chars] invertedSet];
    if ([newString rangeOfCharacterFromSet:characterSet].location != NSNotFound) {
        return NO;
    }
    if ([textField.text rangeOfString:@"."].location != NSNotFound && [string isEqualToString:@"."]) {
        return NO;
    }
    if (newString.length == 1 && newString.integerValue == 0) {
        return NO;
    }
    if (!self.question.maximumValue || self.question.maximumValue == 0) {
        return YES;
    }
    return newString.doubleValue <= self.question.maximumValue;
}

- (void)updateButtonTextWithAnswer:(NSString *)value
{
    if (value.length > 0) {
        [self.button setLabelText:[self answerTextWithUnit:value] bold:YES];
        [self.button setSelected:YES];
        [self updateAnwser:value];
    } else {
        [self.button setLabelText:@"Enter" bold:YES];
        [self.button setSelected:NO];
        [self updateAnwser:nil];
    }
}

- (IBAction)buttonPressed:(id)sender {
    self.hiddenInputField.text = @"";
    [self.button setSelected:YES];
    [self.hiddenInputField becomeFirstResponder];
}

- (NSString *)answerTextWithUnit:(NSString *)answer
{
    return [NSString stringWithFormat:@"  %@  ", [super answerTextWithUnit:answer]];
}

- (void)dealloc
{
    [self unsubscribeAll];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
