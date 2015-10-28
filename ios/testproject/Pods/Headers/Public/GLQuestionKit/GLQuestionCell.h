//
//  GLQuestionCell.h
//  GLQuestionCell
//
//  Created by ltebean on 15/7/16.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLQuestion.h"

#define GLQuestionCellIdentifier @"GLQuestionCellIdentifier"

@class GLQuestionCell;

@protocol GLQuestionCellDelegate <NSObject>
- (void)questionCell:(GLQuestionCell *)cell didUpdateAnswerToQuestion:(GLQuestion *)question;
@end

@interface GLQuestionCell: UITableViewCell
@property (nonatomic, weak) UITableView *outerTableView;
@property (nonatomic, strong) GLQuestion *question;
@property (nonatomic, weak) id<GLQuestionCellDelegate> delegate;
+ (CGFloat)heightForMainQuestion:(GLQuestion *)question;
@end
