//
//  GLYesOrNoQuestionCell.m
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLYesOrNoQuestionCell.h"
#import <GLFoundation/GLPillButton.h>
#import "GLLinkLabel.h"

@interface GLYesOrNoQuestionCell()
@property (weak, nonatomic) IBOutlet GLLinkLabel *questionLabel;
@property (weak, nonatomic) IBOutlet GLPillButton *buttonYes;
@property (weak, nonatomic) IBOutlet GLPillButton *buttonNo;
@end

@implementation GLYesOrNoQuestionCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setQuestion:(GLQuestion *)question
{
    [super setQuestion:question];
    
    self.questionLabel.font = question.titleFont ?: self.questionLabel.font;
    self.questionLabel.textColor = question.titleColor ?: self.questionLabel.textColor;
    self.questionLabel.text = question.title;
    
    if ([self.question.answer isEqualToString:ANSWER_YES]) {
        [self.buttonYes setSelected:YES animated:NO];
        [self.buttonNo setSelected:NO animated:NO];
    } else if ([self.question.answer isEqualToString:ANSWER_NO]) {
        [self.buttonYes setSelected:NO animated:NO];
        [self.buttonNo setSelected:YES animated:NO];
    } else {
        [self.buttonYes setSelected:NO animated:NO];
        [self.buttonNo setSelected:NO animated:NO];
    }
    
    [self.questionLabel clearCallbacks];
    for (NSString *term in self.question.highlightTerms) {
        [self.questionLabel setCallback:^(NSString *str) {
            [self publish:EVENT_GLQUESTION_TERM_CLICK data:str];
        } forKeyword:term caseSensitive:NO];
    }
    
}

- (IBAction)buttonYesPressed:(id)sender {
    [self.buttonNo setSelected:NO animated:NO];
    [self update];
    [self publishClickEventWithType:self.buttonYes.selected ? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT];
}

- (IBAction)buttonNoPressed:(id)sender {
    [self.buttonYes setSelected:NO animated:NO];
    [self update];
    [self publishClickEventWithType:self.buttonNo.selected ? CLICK_TYPE_NO_SELECT : CLICK_TYPE_NO_UNSELECT];
}

- (void)update
{
    if (self.buttonYes.selected) {
        [self updateAnwser:ANSWER_YES];
    } else if (self.buttonNo.selected) {
        [self updateAnwser:ANSWER_NO];
    } else {
        [self updateAnwser:nil];
    }
}

@end
