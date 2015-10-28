//
//  UserDailyPoll.h
//  emma
//
//  Created by Jirong Wang on 5/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ForumTopic.h"

// get and save in UserDefault, not in server
@interface UserDailyPoll : NSObject

+ (UserDailyPoll *)sharedInstance;
- (ForumTopic *)getTopicByDateStr:(NSString *)dateStr;
- (NSNumber *)getTopicIdByDateStr:(NSString *)dateStr;
- (ForumTopic *)getTopicById:(uint64_t)topicId;
- (void)loadTopicByDate:(NSDate *)date;

@end
