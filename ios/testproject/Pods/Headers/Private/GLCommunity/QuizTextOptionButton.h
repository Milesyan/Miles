//
//  QuizTextOptionButton.h
//  GLCommunity
//
//  Created by Allen Hsu on 8/17/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumQuiz.h"

@interface QuizTextOptionButton : UIControl

@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) ForumQuizOption *option;

+ (QuizTextOptionButton *)button;

@end
