//
//  GLSliderQuestionCell.m
//  GLQuestionKit
//
//  Created by ltebean on 15/7/21.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLSliderQuestionCell.h"
@interface GLSliderQuestionCell()
@property (weak, nonatomic) IBOutlet UILabel *leftTipLabel;
@property (weak, nonatomic) IBOutlet UILabel *middleTipLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightTipLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@end

@implementation GLSliderQuestionCell
@dynamic question;

- (void)setQuestion:(GLSliderQuestion *)question
{
    [super setQuestion:question];
    self.slider.minimumValue = question.minimumValue;
    self.slider.maximumValue = question.maximumValue;
    self.slider.value = [question.answer floatValue];
    
    self.leftTipLabel.text = question.leftTip ?: @"";
    [self.leftTipLabel sizeToFit];
    
    self.middleTipLabel.text = question.middleTip ?: @"";
    [self.middleTipLabel sizeToFit];
    
    self.rightTipLabel.text = question.rightTip ?: @"";
    [self.rightTipLabel sizeToFit];
}

- (IBAction)sliderValueChanged:(id)sender {
    [self updateAnwser:[NSString stringWithFormat:@"%f", self.slider.value]];
}

@end
