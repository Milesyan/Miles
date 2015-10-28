//
//  GLQuestion.h
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GLUnit : NSObject
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) CGFloat weight;
+ (GLUnit *)unitWithName:(NSString *)name weight:(CGFloat)weight;
@end



@interface GLQuestion : NSObject
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *answer;
@property (nonatomic, readonly) NSString *originalAnswer;
@property (nonatomic, readonly) BOOL modified;

// subquestions
@property (nonatomic, copy) NSString *answerToShowSubQuestions;
@property (nonatomic) BOOL showSubQuestionsWhenAnswered;
@property (nonatomic, strong) NSArray *subQuestionsSeparatorTitles;
@property (nonatomic, strong) NSArray *subQuestions;
@property (nonatomic, readonly) BOOL needShowSubquestions;

// unit
@property (nonatomic, strong) NSArray *unitList;
@property (nonatomic) NSInteger indexOfSeletedUnit;

// hightlight terms
@property (nonatomic, strong) NSArray *highlightTerms;

// model binding
@property (nonatomic, strong) id model;

// look
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIColor *titleColor;

- (void)enumerateSubQuestions:(void(^)(GLQuestion *))block;

@end
