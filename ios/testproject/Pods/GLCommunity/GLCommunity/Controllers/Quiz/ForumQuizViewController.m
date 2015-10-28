//
//  QuizMainViewController.m
//  GLCommunity
//
//  Created by Allen Hsu on 8/10/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <GLFoundation/NSDictionary+Accessors.h>
#import <GLFoundation/GLTheme.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import "Forum.h"
#import "ForumQuizViewController.h"
#import "ForumQuizResultViewController.h"
#import "ForumQuizMainViewController.h"
#import "ForumQuiz.h"

@interface ForumQuizViewController ()

@property (strong, nonatomic) ForumQuizResultViewController *resultViewController;
@property (strong, nonatomic) ForumQuizMainViewController *mainViewController;
@property (weak, nonatomic) IBOutlet UIView *resultContainer;
@property (weak, nonatomic) IBOutlet UIView *quizContainer;
@property (weak, nonatomic) IBOutlet UIView *loadingOverlay;

@end

@implementation ForumQuizViewController

+ (ForumQuizViewController *)viewController {
    return [[UIStoryboard storyboardWithName:@"ForumQuiz" bundle:nil] instantiateViewControllerWithIdentifier:@"quiz"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self fetchQuiz];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchQuiz {
    [Forum fetchQuizWithTopicId:self.topicId quizId:self.quizId sourceToken:self.sourceAnswerToken myToken:self.myAnswerToken callback:^(NSDictionary *result, NSError *error) {
        NSLog(@"Quiz result: %@", result);
        ForumQuiz *quiz = nil;
        ForumUser *sourceUser = nil;
        ForumQuizAnswer *sourceAnswer = nil;
        ForumQuizResult *sourceResult = nil;
        ForumQuizAnswer *myAnswer = nil;
        ForumQuizResult *myResult = nil;
        if (result && !error) {
            NSDictionary *quizDict = [result dictionaryForKey:@"quiz"];
            NSDictionary *answerDict = [result dictionaryForKey:@"source_answer"];
            NSDictionary *resultDict = [result dictionaryForKey:@"source_result"];
            NSDictionary *userDict = [result dictionaryForKey:@"source_user"];
            NSDictionary *myAnswerDict = [result dictionaryForKey:@"my_answer"];
            NSDictionary *myResultDict = [result dictionaryForKey:@"my_result"];
            if (quizDict) {
                quiz = [[ForumQuiz alloc] initWithDictionary:quizDict];
            }
            if (answerDict) {
                sourceAnswer = [[ForumQuizAnswer alloc] initWithDictionary:answerDict];
            }
            if (userDict) {
                sourceUser = [[ForumUser alloc] initWithDictionary:userDict];
            }
            if (resultDict) {
                sourceResult = [[ForumQuizResult alloc] initWithDictionary:resultDict];
            }
            if (myAnswerDict) {
                myAnswer = [[ForumQuizAnswer alloc] initWithDictionary:myAnswerDict];
            }
            if (myResultDict) {
                myResult = [[ForumQuizResult alloc] initWithDictionary:myResultDict];
            }
        }
        self.quiz = quiz;
        self.quizId = quiz.identifier;
        self.sourceAnswer = sourceAnswer;
        self.sourceResult = sourceResult;
        self.sourceUser = sourceUser;
        self.myAnswer = myAnswer;
        self.myResult = myResult;
        [self refillData];
        if (!self.sourceResult) {
            self.resultContainer.hidden = YES;
        }
        if (self.myResult) {
            [self.mainViewController showResultWithAnimation:NO];
        }
        if (!self.quiz) {
            [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Failed to get the quiz", nil) dismissAfter:3.0 styleName:GLStatusBarStyleError];
            [self dismissSelf];
        } else {
            [Forum log:PAGE_IMP_FORUM_QUIZ eventData:@{
                @"quiz_id": @(self.quiz.identifier),
                @"topic_id": @(self.topicId),
                @"source_token": self.sourceAnswerToken ?: @"",
                @"generation": @(self.gen),
                @"my_token": self.myAnswerToken ?: @"",
            }];
            [UIView animateWithDuration:0.25 animations:^{
                self.loadingOverlay.alpha = 0.0;
            }];
        }
    }];
}

- (void)refillData {
    [self.resultViewController refillData];
    [self.mainViewController refillData];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"result"]) {
        self.resultViewController = segue.destinationViewController;
        self.resultViewController.quizViewController = self;
    } else if ([segue.identifier isEqualToString:@"questions"]) {
        self.mainViewController = segue.destinationViewController;
        self.mainViewController.quizViewController = self;
        self.mainViewController.topicId = self.topicId;
    }
}

- (IBAction)close:(id)sender {
    [self dismissSelf];
    [Forum log:BTN_CLK_FORUM_QUIZ_LOADING_CLOSE eventData:@{
        @"quiz_id": @(self.quizId),
        @"generation": @(self.gen),
        @"source_token": self.sourceAnswerToken ?: @"",
    }];
}

- (void)dismissSelf {
    [self dismissSelfCompletion:nil];
}

- (void)dismissSelfCompletion:(void (^)(void))completion {
    UIViewController *presentingViewController = self.presentingViewController ?: self;
    [presentingViewController dismissViewControllerAnimated:YES completion:completion];
}

- (void)takeQuiz {
    [UIView animateWithDuration:0.25 animations:^{
        self.resultContainer.alpha = 0.0;
    }];
}

@end
