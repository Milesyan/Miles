//
//  QuizMainViewController.h
//  GLCommunity
//
//  Created by Allen Hsu on 8/10/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumQuiz.h"
#import "ForumUser.h"

@interface ForumQuizViewController : UIViewController

@property (strong, nonatomic) NSString *sourceAnswerToken;
@property (strong, nonatomic) NSString *myAnswerToken;
@property (assign, nonatomic) uint64_t topicId;
@property (assign, nonatomic) int quizId;
@property (assign, nonatomic) int guess;
@property (assign, nonatomic) int gen;
@property (assign, nonatomic) BOOL shouldShowTopic;

@property (strong, nonatomic) ForumQuiz *quiz;
@property (strong, nonatomic) ForumQuizAnswer *sourceAnswer;
@property (strong, nonatomic) ForumQuizResult *sourceResult;
@property (strong, nonatomic) ForumQuizAnswer *myAnswer;
@property (strong, nonatomic) ForumQuizResult *myResult;
@property (strong, nonatomic) ForumUser *sourceUser;

+ (ForumQuizViewController *)viewController;

- (void)dismissSelf;
- (void)dismissSelfCompletion:(void (^)(void))completion;
- (void)takeQuiz;

@end
