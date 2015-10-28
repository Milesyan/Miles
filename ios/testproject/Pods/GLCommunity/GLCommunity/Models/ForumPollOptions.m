//
//  ForumPollOptions.m
//  emma
//
//  Created by Jirong Wang on 5/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ForumPollOptions.h"
#import "NSDictionary+Accessors.h"

@implementation ForumPollOptionData

@end


@implementation ForumPollOptions

+ (ForumPollOptions *)createPollBy:(NSArray *)options withInfo:(NSDictionary *)info {
    ForumPollOptions * poll = [[ForumPollOptions alloc] init];
    poll.topicId = [info unsignedLongLongForKey:@"topic_id"];
    poll.isVoted = [info boolForKey:@"voted"];
    poll.votedIndex = (poll.isVoted) ? [info intForKey:@"vote_index"] : -1;
    
    NSMutableArray * pollOptions = [[NSMutableArray alloc] init];
    int i = 0;
    int totalVotes = 0;
    for (NSDictionary * dict in options) {
        ForumPollOptionData * data = [[ForumPollOptionData alloc] init];
        data.option = [dict stringForKey:@"option_text"];
        data.votes  = [dict intForKey:@"votes"];
        data.realOptionIndex = [dict intForKey:@"option_index"];
        data.displayOptionIndex = i;
        data.isVoted = (poll.isVoted && poll.votedIndex == data.realOptionIndex);
        i++;
        totalVotes += data.votes;
        [pollOptions addObject:data];
        // data.parent = poll;
    }
    for (ForumPollOptionData * data in pollOptions) {
        data.totalVotes = totalVotes;
    }
    poll.totalVotes = totalVotes;
    poll.options = (NSArray *)pollOptions;
    return poll;
}

+ (ForumPollOptions *)createEmptyPoll {
    ForumPollOptions * poll = [[ForumPollOptions alloc] init];
    poll.topicId = 0;
    poll.totalVotes = 0;
    poll.options = @[];
    poll.isVoted = NO;
    poll.votedIndex = -1;
    return poll;
}

@end
