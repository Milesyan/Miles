//
//  ForumQuizResultViewController.h
//  GLCommunity
//
//  Created by Allen Hsu on 8/14/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumQuiz.h"
#import "ForumUser.h"
#import "ForumQuizViewController.h"

@interface ForumQuizResultViewController : UIViewController

@property (weak, nonatomic) ForumQuizViewController *quizViewController;

- (void)refillData;

@end
