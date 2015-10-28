//
//  ForumPollOptions.h
//  emma
//
//  Created by Jirong Wang on 5/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

// ForumPollOptions will be used for show a created poll (voted/unvoted)
@interface ForumPollOptions : NSObject

@property (nonatomic) uint64_t topicId;
@property (nonatomic) int totalVotes;
// arrary for ForumPollOptionData
@property (nonatomic) NSArray * options;
@property (nonatomic) BOOL isVoted;
@property (nonatomic) int votedIndex;  // useless

+ (ForumPollOptions *)createPollBy:(NSArray *)options withInfo:(NSDictionary *)info;
+ (ForumPollOptions *)createEmptyPoll;

@end

// ForumPollOptionData will be used for
// 1 - create a poll
// 2 - show a poll
// So, we should not put topic Id in this class
@interface ForumPollOptionData : NSObject

@property (nonatomic) NSString *option;
// In most cases, displayOptionIndex = realOptionIndex
// But, if an option is deleted after the poll posted, they are diff
// e.g.  realOptionIndex  = [0, 1, 3]
//     displayOptionIndex = [0, 1, 2]
@property (nonatomic) int displayOptionIndex;  // for UI order
@property (nonatomic) int realOptionIndex;     // backend order
@property (nonatomic) int votes;
@property (nonatomic) int totalVotes;
@property (nonatomic) BOOL isVoted;
// @property (nonatomic) ForumPollOptions * parent;

@end