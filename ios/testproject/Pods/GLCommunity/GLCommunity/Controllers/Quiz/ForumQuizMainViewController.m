//
//  ForumQuizMainViewController.m
//  GLCommunity
//
//  Created by Allen Hsu on 8/17/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <GLFoundation/NSDictionary+Accessors.h>
#import <GLFoundation/GLNavigationController.h>
#import <GLFoundation/GLUtils.h>
#import <GLFoundation/NSString+Markdown.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "Forum.h"
#import "ForumQuizMainViewController.h"
#import "ForumQuizQuestionViewController.h"
#import "ForumTopicDetailViewController.h"

@interface ForumQuizMainViewController ()

@property (copy, nonatomic) NSArray *questionControllers;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentWidth;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *resultView;
@property (weak, nonatomic) IBOutlet UIImageView *resultImageView;
@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (assign, nonatomic) BOOL hasClickedShareButton;

@end

@implementation ForumQuizMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImage *bgImage = [UIImage imageNamed:@"gl-community-geometry-bg"];
    self.resultView.backgroundColor = [UIColor colorWithPatternImage:bgImage];
    self.resultView.hidden = YES;
    self.resultImageView.layer.cornerRadius = self.resultImageView.frame.size.width / 2.0;
    self.shareButton.layer.cornerRadius = self.shareButton.frame.size.height / 2.0;
    self.bottomView.alpha = 0.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refillData {
    for (ForumQuizQuestionViewController *vc in self.questionControllers) {
        [vc willMoveToParentViewController:nil];
        [vc.view removeFromSuperview];
        [vc removeFromParentViewController];
    }
    NSArray *questions = self.quizViewController.quiz.questions;
    NSMutableArray *vcs = [NSMutableArray arrayWithCapacity:questions.count];
    UIView *lastView = nil;
    for (ForumQuizQuestion *q in questions) {
        ForumQuizQuestionViewController *qvc = [ForumQuizQuestionViewController viewController];
        qvc.mainViewController = self;
        qvc.question = q;
        [self addChildViewController:qvc];
        [self.contentView addSubview:qvc.view];
        [qvc didMoveToParentViewController:self];
        [vcs addObject:qvc];
        [qvc.view autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.scrollView];
        [qvc.view autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.scrollView];
        if (!lastView) {
            [qvc.view autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        } else {
            [qvc.view autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:lastView];
        }
        [qvc.view autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [qvc.view autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        lastView = qvc.view;
    }
    if (lastView) {
        [lastView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    }
    self.questionControllers = vcs;
    [self.contentWidth autoRemove];
    self.contentWidth = [self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.scrollView withMultiplier:questions.count];
    self.pageControl.numberOfPages = vcs.count;
    [self gotoPage:0];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (IBAction)didClickBack:(id)sender {
    [self prevQuestion];
}

- (IBAction)didClickClose:(id)sender {
    BOOL shouldShowTopic = self.quizViewController.shouldShowTopic;
    NSString *token = self.quizViewController.myAnswerToken;
    if (!self.hasClickedShareButton && token.length > 0) {
        [UIAlertView bk_showAlertViewWithTitle:NSLocalizedString(@"Do you want to share this quiz with your friends?", nil) message:nil cancelButtonTitle:@"No, thanks" otherButtonTitles:@[@"Yes!"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1 && token.length > 0) {
                [Forum log:BTN_CLK_FORUM_QUIZ_SHARE_POPUP_YES eventData:@{
                    @"quiz_id": @(self.quizViewController.quizId),
                    @"my_token": self.quizViewController.myAnswerToken ?: @"",
                }];
                [Forum shareQuizResultWithToken:token];
            } else {
                [Forum log:BTN_CLK_FORUM_QUIZ_SHARE_POPUP_NO eventData:@{
                    @"quiz_id": @(self.quizViewController.quizId),
                    @"my_token": self.quizViewController.myAnswerToken ?: @"",
                }];
            }
        }];
    }
    [self.quizViewController dismissSelfCompletion:^{
        if (shouldShowTopic && self.quizViewController && [Forum isLoggedIn] && self.topicId > 0 && self.quizViewController.myAnswerToken.length > 0) {
            ForumTopic *topic = [[ForumTopic alloc] init];
            topic.identifier = self.topicId;
            ForumTopicDetailViewController *vc = [ForumTopicDetailViewController viewController];
            vc.topic = topic;
            GLNavigationController *nav = [[GLNavigationController alloc] initWithRootViewController:vc];
            [[[GLUtils keyWindow] rootViewController] presentViewController:nav animated:YES completion:nil];
        }
    }];
    [Forum log:BTN_CLK_FORUM_QUIZ_RESULT_CLOSE eventData:@{
        @"quiz_id": @(self.quizViewController.quizId),
        @"result_id": @(self.quizViewController.myResult.identifier),
        @"generation": @(self.quizViewController.gen),
        @"source_token": self.quizViewController.sourceAnswerToken ?: @"",
        @"my_token": self.quizViewController.myAnswerToken ?: @"",
    }];
}

- (IBAction)didClickShare:(id)sender {
    if (self.quizViewController.myAnswerToken.length > 0) {
        self.hasClickedShareButton = YES;
        [Forum shareQuizResultWithToken:self.quizViewController.myAnswerToken];
    }
    [Forum log:BTN_CLK_FORUM_QUIZ_SHARE eventData:@{
        @"quiz_id": @(self.quizViewController.quizId),
        @"result_id": @(self.quizViewController.myResult.identifier),
        @"generation": @(self.quizViewController.gen),
        @"source_token": self.quizViewController.sourceAnswerToken ?: @"",
        @"my_token": self.quizViewController.myAnswerToken ?: @"",
    }];
}

- (void)gotoPage:(int)page {
    self.pageControl.currentPage = page;
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * page, 0.0) animated:YES];
    if (page == 0) {
        self.backButton.hidden = YES;
    } else {
        self.backButton.hidden = NO;
    }
}

- (void)nextQuestion {
    int nextPage = self.pageControl.currentPage + 1;
    int currentQuestionId = self.pageControl.currentPage + 1;
    if (nextPage >= self.pageControl.numberOfPages) {
        [self submit];
    } else {
        [self gotoPage:nextPage];
    }
    [Forum log:BTN_CLK_FORUM_QUIZ_NEXT_STEP eventData:@{
        @"quiz_id": @(self.quizViewController.quizId),
        @"question_id": @(currentQuestionId),
        @"generation": @(self.quizViewController.gen),
        @"source_token": self.quizViewController.sourceAnswerToken ?: @"",
    }];
}

- (void)prevQuestion {
    if (self.pageControl.currentPage > 0) {
        int nextPage = self.pageControl.currentPage - 1;
        [self gotoPage:nextPage];
    }
}

- (void)submit {
    int points = 0;
    ForumQuiz *quiz = self.quizViewController.quiz;
    NSMutableDictionary *selectedOptions = [NSMutableDictionary dictionary];
    for (ForumQuizQuestionViewController *qvc in self.questionControllers) {
        if (qvc.selectedOptionId) {
            points += [qvc pointsForSelectedOption];
            NSString *key = [NSString stringWithFormat:@"%d", qvc.question.identifier];
            selectedOptions[key] = qvc.selectedOptionId;
        }
    }
    ForumQuizResult *myResult = nil;
    for (ForumQuizResult *res in quiz.results) {
        if (points >= res.minPoints && points <= res.maxPoints) {
            myResult = res;
        }
    }
    self.quizViewController.myResult = myResult;
    [self showResultWithAnimation:YES];
    [Forum submitQuizWithQuizId:quiz.identifier sourceToken:self.quizViewController.sourceAnswerToken selectedOptions:selectedOptions generation:self.quizViewController.gen callback:^(NSDictionary *result, NSError *error) {
        NSLog(@"Quiz result: %@", result);
        NSString *answerToken = [result stringForKey:@"answer_token"];
        if (answerToken.length > 0) {
            self.quizViewController.myAnswerToken = answerToken;
            id<ForumDelegate> fd = [[Forum sharedInstance] delegate];
            if ([fd respondsToSelector:@selector(userDidFinishQuiz:withResultId:answerToken:)]) {
                [fd userDidFinishQuiz:quiz.identifier withResultId:myResult.identifier answerToken:answerToken];
            }
            [UIView animateWithDuration:0.25 animations:^{
                self.bottomView.alpha = 1.0;
            }];
        }
        self.topicId = [result unsignedLongLongForKey:@"topic_id"];
    }];
    [Forum log:BTN_CLK_FORUM_QUIZ_SUBMIT eventData:@{
        @"quiz_id": @(self.quizViewController.quizId),
        @"result_id": @(myResult.identifier),
        @"generation": @(self.quizViewController.gen),
        @"source_token": self.quizViewController.sourceAnswerToken ?: @"",
    }];
}

- (void)showResultWithAnimation:(BOOL)animation {
    ForumQuiz *quiz = self.quizViewController.quiz;
    ForumQuizResult *myResult = self.quizViewController.myResult;
    self.questionLabel.text = quiz.title;
    self.titleLabel.text = myResult.title;
    NSString *content = myResult.content;
    self.contentLabel.attributedText = [NSString markdownToAttributedText:content fontSize:16.0 lineHeight:20.0 color:UIColorFromRGB(0x676767)];
    [self.resultImageView sd_setImageWithURL:[NSURL URLWithString:myResult.image]];
    if (!animation) {
        if (self.quizViewController.myAnswerToken) {
            self.bottomView.hidden = NO;
            self.bottomView.alpha = 1.0;
        } else {
            self.bottomView.alpha = 0.0;
        }
        self.resultView.hidden = NO;
        self.resultView.alpha = 1.0;
        self.backButton.alpha = 0.0;
    } else {
        self.resultView.hidden = NO;
        self.resultView.alpha = 0.0;
        if (self.quizViewController.myAnswerToken) {
            self.bottomView.hidden = NO;
            self.bottomView.alpha = 1.0;
        }
        [UIView animateWithDuration:0.25 animations:^{
            self.backButton.alpha = 0.0;
            self.resultView.alpha = 1.0;
        }];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
