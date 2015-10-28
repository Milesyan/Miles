//
//  ForumQuizResultViewController.m
//  GLCommunity
//
//  Created by Allen Hsu on 8/14/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <GLFoundation/NSString+Markdown.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <GLFoundation/UIColor+Utils.h>
#import "ForumQuizResultViewController.h"
#import "Forum.h"

@interface ForumQuizResultViewController ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UILabel *correctLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *takeQuizButton;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation ForumQuizResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage *bgImage = [UIImage imageNamed:@"gl-community-geometry-bg"];
    self.backgroundView.backgroundColor = [UIColor colorWithPatternImage:bgImage];
    self.imageView.layer.cornerRadius = self.imageView.frame.size.width / 2.0;
    self.takeQuizButton.layer.cornerRadius = self.takeQuizButton.frame.size.height / 2.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refillData {
    ForumQuizAnswer *answer = self.quizViewController.sourceAnswer;
    ForumQuizResult *result = self.quizViewController.sourceResult;
    int guess = self.quizViewController.guess;
    NSString *name = self.quizViewController.sourceUser.firstName;
    if (name.length == 0 || [[name lowercaseString] isEqualToString:@"guest"]) {
        name = NSLocalizedString(@"your friend", nil);
    }
    NSString *content = result.content;
    if (guess == answer.resultId) {
        // Correct guess
        self.correctLabel.text = NSLocalizedString(@"You guessed it right!", nil);
        self.correctLabel.textColor = UIColorFromRGB(0x6BB945);
        NSString *nameString = [NSString stringWithFormat:NSLocalizedString(@"%@ can't keep any secrets from you, can she?! :) **%@** did get:", nil), name, [name capitalizedString]];
        self.nameLabel.attributedText = [NSString markdownToAttributedText:nameString fontSize:16.0 lineHeight:16.0 color:UIColorFromRGB(0x676767) boldColor:[UIColor blackColor] alignment:NSTextAlignmentCenter];
    } else {
        // Wrong guess
        self.correctLabel.text = NSLocalizedString(@"Nice try...", nil);
        self.correctLabel.textColor = UIColorFromRGB(0xFE4444);
        NSString *nameString = [NSString stringWithFormat:NSLocalizedString(@"But you clearly do not know %@ very well. **%@** actually got:", nil), name, [name capitalizedString]];
        self.nameLabel.attributedText = [NSString markdownToAttributedText:nameString fontSize:16.0 lineHeight:16.0 color:UIColorFromRGB(0x676767) boldColor:[UIColor blackColor] alignment:NSTextAlignmentCenter];
    }
    
    self.titleLabel.text = result.title;
    self.contentLabel.attributedText = [NSString markdownToAttributedText:content fontSize:16.0 lineHeight:20.0 color:UIColorFromRGB(0x676767) boldColor:[UIColor blackColor] alignment:NSTextAlignmentLeft];
    
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:result.image]];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)skip:(id)sender {
    [self.quizViewController dismissSelf];
    [Forum log:BTN_CLK_FORUM_QUIZ_GUESS_DISMISS eventData:@{
        @"quiz_id": @(self.quizViewController.quizId),
        @"generation": @(self.quizViewController.gen),
        @"source_token": self.quizViewController.sourceAnswerToken ?: @"",
    }];
}

- (IBAction)takeQuiz:(id)sender {
    if (self.quizViewController) {
        [self.quizViewController takeQuiz];
        [Forum log:BTN_CLK_FORUM_QUIZ_GUESS_TAKE_QUIZ eventData:@{
            @"quiz_id": @(self.quizViewController.quizId),
            @"generation": @(self.quizViewController.gen),
            @"source_token": self.quizViewController.sourceAnswerToken ?: @"",
        }];
    } else {
        [self skip:sender];
    }
}

@end
