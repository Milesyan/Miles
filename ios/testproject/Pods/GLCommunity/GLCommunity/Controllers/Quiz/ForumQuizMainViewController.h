//
//  ForumQuizMainViewController.h
//  GLCommunity
//
//  Created by Allen Hsu on 8/17/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumQuiz.h"
#import "ForumUser.h"
#import "ForumQuizViewController.h"

@interface ForumQuizMainViewController : UIViewController

@property (weak, nonatomic) ForumQuizViewController *quizViewController;
@property (assign, nonatomic) uint64_t topicId;

- (void)refillData;
- (void)nextQuestion;
- (void)prevQuestion;
- (void)showResultWithAnimation:(BOOL)animation;

@end
