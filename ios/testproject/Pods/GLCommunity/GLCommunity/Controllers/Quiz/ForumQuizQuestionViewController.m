//
//  ForumQuizQuestionViewController.m
//  GLCommunity
//
//  Created by Allen Hsu on 8/14/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "ForumQuizQuestionViewController.h"
#import "QuizTextOptionButton.h"
#import "QuizImageOptionButton.h"

@interface ForumQuizQuestionViewController ()

@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) NSArray *optionViews;
@property (weak, nonatomic) IBOutlet UIView *leftSample;
@property (weak, nonatomic) IBOutlet UIView *rightSample;
@property (weak, nonatomic) IBOutlet UIImageView *bannerImage;

@end

@implementation ForumQuizQuestionViewController

+ (ForumQuizQuestionViewController *)viewController {
    return [[UIStoryboard storyboardWithName:@"ForumQuiz" bundle:nil] instantiateViewControllerWithIdentifier:@"question"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bannerImage.layer.cornerRadius = 5.0;
    [self refillData];
}

- (void)refillData {
    self.questionLabel.text = self.question.title;
    if (self.question.image.length == 0) {
        self.questionLabel.hidden = NO;
        self.bannerImage.hidden = YES;
    } else {
        self.bannerImage.hidden = NO;
        self.questionLabel.hidden = YES;
        [self.bannerImage sd_setImageWithURL:[NSURL URLWithString:self.question.image] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (error || !image) {
                self.questionLabel.hidden = NO;
                self.bannerImage.hidden = YES;
            }
        }];
    }
    NSArray *options = self.question.options;
    NSMutableArray *views = [NSMutableArray arrayWithCapacity:options.count];
    for (UIView *view in self.optionViews) {
        [view removeFromSuperview];
    }
    if ([self.question isImageOption]) {
        UIView *lastLeftView = nil;
        for (int i = 0; i < options.count; ++i) {
            ForumQuizOption *o = options[i];
            QuizImageOptionButton *bt = [QuizImageOptionButton button];
            [bt addTarget:self action:@selector(tapOnOption:) forControlEvents:UIControlEventTouchUpInside];
            bt.option = o;
            bt.tag = o.identifier;
            if (self.selectedOptionId && [self.selectedOptionId intValue] == o.identifier) {
                bt.selected = YES;
            } else {
                bt.selected = NO;
            }
            bt.imageView.alpha = 1.0;
            [self.contentView addSubview:bt];
            if (i % 2 == 0) {
                // Left
                [bt autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:15.0];
                [bt autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.leftSample];
                if (!lastLeftView) {
                    [bt autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.bannerImage withOffset:10.0];
                } else {
                    [bt autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:lastLeftView withOffset:10.0];
                }
                lastLeftView = bt;
            } else {
                // Right
                [bt autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:15.0];
                [bt autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.leftSample];
                [bt autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:lastLeftView];
                if (!lastLeftView) {
                    [bt autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.bannerImage withOffset:10.0];
                } else {
                    [bt autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:lastLeftView];
                }
            }
            [views addObject:bt];
        }
        if (lastLeftView) {
            [lastLeftView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0];
        }
    } else {
        UIView *lastView = nil;
        for (ForumQuizOption *o in options) {
            QuizTextOptionButton *bt = [QuizTextOptionButton button];
            [bt addTarget:self action:@selector(tapOnOption:) forControlEvents:UIControlEventTouchUpInside];
            bt.option = o;
            bt.tag = o.identifier;
            if (self.selectedOptionId && [self.selectedOptionId intValue] == o.identifier) {
                bt.selected = YES;
            } else {
                bt.selected = NO;
            }
            [self.contentView addSubview:bt];
            [bt autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:15.0];
            [bt autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:15.0];
            if (!lastView) {
                [bt autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.bannerImage withOffset:10.0];
            } else {
                [bt autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:lastView withOffset:10.0];
            }
            [views addObject:bt];
            lastView = bt;
        }
        if (lastView) {
            [lastView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:15.0];
        }
    }
    self.optionViews = views;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)tapOnOption:(id)sender {
    UIView *bt = sender;
    self.selectedOptionId = @(bt.tag);
    for (UIControl *view in self.optionViews) {
        if (view.tag == bt.tag) {
            view.selected = YES;
        } else {
            view.selected = NO;
        }
    }
    if (self.selectedOptionId) {
        [self.mainViewController nextQuestion];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (int)pointsForSelectedOption {
    if (!self.selectedOptionId) {
        return 0;
    } else {
        int optionId = [self.selectedOptionId intValue];
        for (ForumQuizOption *op in self.question.options) {
            if (op.identifier == optionId) {
                return op.points;
            }
        }
    }
    return 0;
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
