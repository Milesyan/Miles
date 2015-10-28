//
//  GLQuestionBaseCell.m
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLQuestionBaseCell.h"

@implementation GLQuestionBaseCell

@synthesize leftMargin = _leftMargin;

- (void)awakeFromNib {
    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}


- (void)updateAnwser:(NSString *)value
{
    self.question.answer = value;
    [self.delegate questionCell:self didAnswerQuestion:self.question];
}


- (NSUInteger)leftMargin
{
    if (!_leftMargin) {
        _leftMargin = 16;
    }
    return _leftMargin;
}


- (void)setLeftMargin:(NSUInteger)leftMargin
{
    if (leftMargin == _leftMargin) {
        return;
    }
    
    _leftMargin = leftMargin;
    self.leftMarginConstraint.constant = leftMargin;
    [self setNeedsUpdateConstraints];
}


+ (NSNumber *)heightForQuestion:(GLQuestion *)question
{
    return @(68);
}

+ (NSString *)cellIdentifier
{
    return NSStringFromClass([self class]);
}

- (NSString *)unitName
{
    if (self.question.unitList.count > 0) {
        GLUnit *unit = self.question.unitList[self.question.indexOfSeletedUnit];
        return unit.name;
    } else {
        return nil;
    }
}

- (NSString *)answerTextWithUnit:(NSString *)answer
{
    NSString *unitName = [self unitName];
    return unitName ? [NSString stringWithFormat:@"%@ %@", answer, unitName ?: @""] : answer;
}


- (NSString *)convertAnswer:(NSString *)answer fromUnit:(GLUnit *)fromUnit toUnit:(GLUnit *)destUnit
{
    CGFloat value = [answer floatValue];
    CGFloat finalValue = value / fromUnit.weight * destUnit.weight;
    return [NSString stringWithFormat:@"%.f", finalValue];
}

- (void)publishClickEventWithType:(NSString *)clickType
{
    [self publish:EVENT_GLQUESTION_BUTTON_CLICK data:@{@"key": self.question.key?:@"", @"type": clickType, @"value": self.question.answer?:@""}];
}

@end
