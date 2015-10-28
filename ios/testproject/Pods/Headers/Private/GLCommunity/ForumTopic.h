//
//  ForumTopic.h
//  emma
//
//  Created by Allen Hsu on 11/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ForumUser.h"
#import "ForumPollOptions.h"

typedef NS_OPTIONS(NSUInteger, ForumTopicFlag) {
    ForumTopicFlagAnonymous     = 1 <<  0,
    ForumTopicFlagAnnouncement  = 1 <<  1,
    ForumTopicFlagPoll          = 1 <<  2,
    ForumTopicFlagPhoto         = 1 <<  3,
    ForumTopicFlagWarning       = 1 <<  4,
    ForumTopicFlagSystem        = 1 <<  5,
    ForumTopicFlagURL           = 1 <<  6,
    ForumTopicFlagNoComment     = 1 <<  7,
    ForumTopicFlagQuiz          = 1 <<  8,
    ForumTopicFlagAdminHide     = 1 <<  9,
    ForumTopicFlagAdminUnhide   = 1 << 10,
};

@interface ForumTopic : NSObject

@property (assign, nonatomic) uint64_t identifier;
@property (assign, nonatomic) unsigned int categoryId;
@property (assign, nonatomic) uint64_t groupId;
@property (assign, nonatomic) uint64_t userId;
@property (assign, nonatomic) uint64_t replyUserId;
@property (assign, nonatomic) unsigned int countReplies;
@property (assign, nonatomic) unsigned int countSubReplies;
@property (assign, nonatomic) unsigned int countLikes;
@property (assign, nonatomic) unsigned int countDislikes;
@property (assign, nonatomic) unsigned int lastReplyTime;
@property (assign, nonatomic) unsigned int timeCreated;
@property (assign, nonatomic) unsigned int timeModified;
@property (assign, nonatomic) unsigned int timeRemoved;
@property (assign, nonatomic) unsigned int flags;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *content;
@property (strong, nonatomic) NSString *desc;
@property (strong, nonatomic) NSString *urlTitle;
@property (strong, nonatomic) NSString *urlAbstract;
@property (strong, nonatomic) NSString *urlPath;

@property (strong, nonatomic) ForumUser *author;
@property (strong, nonatomic) ForumUser *replier;
@property (assign, nonatomic) BOOL bookmarked;
@property (assign, nonatomic) BOOL liked;
@property (assign, nonatomic) BOOL disliked;
@property (assign, nonatomic) BOOL lowRating;
@property (assign, nonatomic) BOOL didUnlockLowRatingContent;
@property (assign, nonatomic) BOOL shouldHideLowRatingContent;

@property (strong, nonatomic) ForumPollOptions * pollOptions;
@property (strong, nonatomic) NSString *image;
@property (strong, nonatomic) NSString *thumbnail;

@property (assign, nonatomic) uint64_t views;
@property (nonatomic, assign) BOOL isWelcomeTopic;
@property (assign, nonatomic) uint64_t articleID;

- (id)initWithDictionary:(NSDictionary *)dict;
- (BOOL)isAnonymous;
- (BOOL)isPinned;
- (BOOL)isPoll;
- (BOOL)isPhotoTopic;
- (BOOL)isURLTopic;
- (BOOL)isSystemTopic;
- (BOOL)isHidden;
- (BOOL)isNoComment;
- (BOOL)isQuiz;
- (BOOL)hasImproperContent;
- (BOOL)hasDesc;

@end
