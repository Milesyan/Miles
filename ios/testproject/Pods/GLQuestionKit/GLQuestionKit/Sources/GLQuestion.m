//
//  GLQuestion.m
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLQuestion.h"

@implementation GLUnit

+ (GLUnit *)unitWithName:(NSString *)name weight:(CGFloat)weight
{
    return [[GLUnit alloc] initWithName:name weight:weight];
}

- (instancetype)initWithName:(NSString *)name weight:(CGFloat)weight
{
    self = [super init];
    if (self) {
        _name = [name copy];
        _weight = weight;
    }
    return self;
}
@end


@interface GLQuestion()
@property (nonatomic) BOOL originalAnswerInited;
@end

@implementation GLQuestion
- (void)setAnswer:(NSString *)answer
{
    if (!self.originalAnswerInited) {
        _originalAnswer = [answer copy];
    }
    _answer = [answer copy];
    self.originalAnswerInited = YES;
}

- (BOOL)modified
{
    if (!_answer && !_originalAnswer) {
        return NO;
    }
    return ![_answer isEqual:_originalAnswer];
}

- (BOOL)needShowSubquestions
{
    if (self.showSubQuestionsWhenAnswered) {
        return self.answer != nil;
    } else {
        return [self.answer isEqualToString:self.answerToShowSubQuestions];
    }
}

- (void)enumerateSubQuestions:(void(^)(GLQuestion *))block
{
    for (NSArray *section in self.subQuestions) {
        for (GLQuestion *question in section) {
            block(question);
        }
    }
}
@end
