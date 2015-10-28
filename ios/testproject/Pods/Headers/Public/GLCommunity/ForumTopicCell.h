//
//  ForumTopicCell.h
//  emma
//
//  Created by Allen Hsu on 11/22/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumTopic.h"
#import "ForumGroupButton.h"
#import "ForumGroup.h"

#define TOPIC_CELL_IDENTIFIER           @"ForumTopicCell"

#define TOPIC_CELL_HEIGHT_FULL      115
#define PHOTO_TOPIC_CELL_HEIGHT     126
#define TOPIC_CELL_HEIGHT_ONE_LINE  20
#define TOPIC_CELL_HEIGHT_RESPONSE  25

@class ForumTopicCell;

@protocol ForumTopicCellDelegate <NSObject>

@optional
- (void)cell:(ForumTopicCell *)cell showProfileForUser:(ForumUser *)user;
- (void)cell:(ForumTopicCell *)cell gotoGroup:(ForumGroup *)group;
- (void)cell:(ForumTopicCell *)cell hideTopic:(ForumTopic *)topic;
- (void)cell:(ForumTopicCell *)cell reportTopic:(ForumTopic *)topic;
- (void)cell:(ForumTopicCell *)cell editTopic:(ForumTopic *)topic;
- (void)cell:(ForumTopicCell *)cell presentUrlPage:(NSString *)url;
- (void)cell:(ForumTopicCell *)cell didClickQuizButtonOfTopic:(ForumTopic *)topic;

- (void)cell:(ForumTopicCell *)cell showLowRatingContent:(ForumTopic *)topic;
- (void)cell:(ForumTopicCell *)cell showRules:(ForumTopic *)topic;

@end

@interface ForumTopicCell : UITableViewCell

@property (weak, nonatomic) id <ForumTopicCellDelegate> delegate;

@property (strong, nonatomic) ForumGroup *group;
@property (assign, nonatomic) BOOL isParticipatedTopic;

@property (assign, nonatomic, readonly) BOOL showResponse;

+ (CGFloat)cellHeightForTopic:(ForumTopic *)topic;
+ (CGFloat)cellHeightForTopic:(ForumTopic *)topic showsGroup:(BOOL)showsGroup showsPinned:(BOOL)showsPinned;

- (void)configureWithTopic:(ForumTopic *)topic
                 isProfile:(BOOL)isProfile
                 showGroup:(BOOL)showGroup
                showPinned:(BOOL)showPinned;

@end
