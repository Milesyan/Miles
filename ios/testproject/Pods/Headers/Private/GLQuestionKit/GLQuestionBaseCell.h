//
//  GLQuestionBaseCell.h
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLQuestion.h"
#import "GLQuestionEvent.h"
#import <GLFoundation/NSObject+PubSub.h>

@class GLQuestionBaseCell;

@protocol GLQuestionBaseCellDelegate <NSObject>
- (void)questionCell:(GLQuestionBaseCell *)cell didAnswerQuestion:(GLQuestion *)question;
@end


@interface GLQuestionBaseCell : UITableViewCell

@property (nonatomic, strong) GLQuestion *question;
@property (nonatomic, weak) id<GLQuestionBaseCellDelegate> delegate;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *leftMarginConstraint;
@property (nonatomic, assign) NSUInteger leftMargin;

+ (NSNumber *)heightForQuestion:(GLQuestion *)question;
+ (NSString *)cellIdentifier;
- (void)updateAnwser:(NSString *)value;
- (NSString *)unitName;
- (NSString *)answerTextWithUnit:(NSString *)answer;
- (NSString *)convertAnswer:(NSString *)answer fromUnit:(GLUnit *)fromUnit toUnit:(GLUnit *)destUnit;
- (void)publishClickEventWithType:(NSString *)clickType;
@end
