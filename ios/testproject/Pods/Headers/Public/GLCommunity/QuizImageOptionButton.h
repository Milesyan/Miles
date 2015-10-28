//
//  QuizImageOptionButton.h
//  GLCommunity
//
//  Created by Allen Hsu on 8/17/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumQuiz.h"

@interface QuizImageOptionButton : UIControl

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) ForumQuizOption *option;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

+ (QuizImageOptionButton *)button;

@end
