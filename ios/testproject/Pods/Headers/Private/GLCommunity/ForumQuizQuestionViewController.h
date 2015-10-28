//
//  ForumQuizQuestionViewController.h
//  GLCommunity
//
//  Created by Allen Hsu on 8/14/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumQuiz.h"
#import "ForumUser.h"
#import "ForumQuizMainViewController.h"

@interface ForumQuizQuestionViewController : UIViewController

@property (strong, nonatomic) NSNumber *selectedOptionId;
@property (strong, nonatomic) ForumQuizQuestion *question;
@property (weak, nonatomic) ForumQuizMainViewController *mainViewController;

+ (ForumQuizQuestionViewController *)viewController;
- (int)pointsForSelectedOption;

@end
