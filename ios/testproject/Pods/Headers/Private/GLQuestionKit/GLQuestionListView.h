//
//  GLQuestionListView.h
//  GLQuestionKit
//
//  Created by ltebean on 15/7/21.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLQuestion.h"

@class GLQuestionListView;
@protocol GLQuestionListViewDelegate <NSObject>
- (void)questionListView:(GLQuestionListView *)questionListView didUpdateAnswerToQuestion:(GLQuestion *)question;
@end

@interface GLQuestionListView : UIView
@property (nonatomic, strong) NSArray *questions;
@property (nonatomic, weak) id<GLQuestionListViewDelegate> delegate;
- (void)reloadData;
@end
