//
//  ForumReply.h
//  emma
//
//  Created by Allen Hsu on 11/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ForumUser.h"
#import "ForumTopic.h"

typedef NS_OPTIONS(NSUInteger, ForumReplyFlag) {
    ForumReplyFlagAnonymous     = 1 <<  0,
    ForumReplyFlagAdminHide     = 1 <<  9,
    ForumReplyFlagAdminUnhide   = 1 <<  10,
};

@interface ForumReply : NSObject

@property (strong, nonatomic) ForumUser *author;
@property (strong, nonatomic) ForumTopic *topic;

@property (assign, nonatomic) uint64_t identifier;
@property (assign, nonatomic) uint64_t topicId;
@property (assign, nonatomic) uint64_t userId;
@property (assign, nonatomic) uint64_t replyTo;

@property (assign, nonatomic) unsigned int countReplies;
@property (assign, nonatomic) unsigned int countLikes;
@property (assign, nonatomic) unsigned int countDislikes;
@property (assign, nonatomic) unsigned int timeCreated;
@property (assign, nonatomic) unsigned int timeModified;
@property (assign, nonatomic) unsigned int timeRemoved;
@property (assign, nonatomic) unsigned int flags;

@property (assign, nonatomic) BOOL containsImage;
@property (assign, nonatomic) BOOL liked;
@property (assign, nonatomic) BOOL disliked;
@property (assign, nonatomic) BOOL lowRating;
@property (assign, nonatomic) BOOL didUnlockLowRatingContent;
@property (assign, nonatomic) BOOL shouldHideLowRatingContent;

@property (strong, nonatomic) NSString *content;
@property (strong, nonatomic) NSString *htmlWithTermLinks;
@property (strong, nonatomic) NSArray *replies;
@property (strong, nonatomic) NSArray *images;

- (id)initWithDictionary:(NSDictionary *)dict;
- (BOOL)isAnonymous;

@end
