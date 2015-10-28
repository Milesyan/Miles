//
//  UserDailyPoll.m
//  emma
//
//  Created by Jirong Wang on 5/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UserDailyPoll.h"
#import "User.h"
#import "ForumTopic.h"
#import "Forum.h"
#import "NSDictionary+Accessors.h"


@interface UserDailyPoll()

@property (nonatomic) NSNumber * savedUserId;
// a dictionary with key = date, value = forum topic, load from server
@property (nonatomic) NSMutableDictionary * polls;
// a dictionary with key = date, value = forum topic id, save to UserDefault
@property (nonatomic) NSMutableDictionary * pollIds;
@property (nonatomic) NSDate * latestTodayLoadTime;

@end

@implementation UserDailyPoll

static UserDailyPoll * _instance;
+ (UserDailyPoll *)sharedInstance {
    if (!_instance) {
        _instance = [[UserDailyPoll alloc] init];
        _instance.polls = [[NSMutableDictionary alloc] init];
        _instance.pollIds = [[NSMutableDictionary alloc] init];
        _instance.latestTodayLoadTime = nil;
        [_instance checkIfNeedReset];
        [_instance subscribeOnce:EVENT_USER_LOGGED_OUT selector:@selector(clearAll)];
    }
    return _instance;
}

- (BOOL)isCurrentUser {
    if (!self.savedUserId) return NO;
    User * u;
    @try {
        u = [User currentUser];
    }
    @catch (NSException *exception) {
        // in the case that we are not in main thread and user is logout
        return NO;
    }
    return ((!self.savedUserId) || [u.id isEqualToNumber:self.savedUserId]);
}

- (void)clearAll {
    [self.polls removeAllObjects];
    [self.pollIds removeAllObjects];
    self.latestTodayLoadTime = nil;
    self.savedUserId = @0;
    [Utils setDefaultsForKey:USERDEFAULTS_USER_DAILY_POLL_IDS withValue:@{}];
}

- (void)checkIfNeedReset {
    User * u;
    @try {
        u = [User currentUser];
    }
    @catch (NSException *exception) {
        // in the case that we are not in main thread and user is logout
        [self.polls removeAllObjects];
        [self.pollIds removeAllObjects];
        self.savedUserId = @0;
        return;
    }
    if ((!self.savedUserId) || (![u.id isEqualToNumber:self.savedUserId])) {
        [self.polls removeAllObjects];
        [self.pollIds removeAllObjects];
        self.savedUserId = u.id.copy;
        self.latestTodayLoadTime = nil;
        NSDictionary * dict = [Utils getDefaultsForKey:USERDEFAULTS_USER_DAILY_POLL_IDS];
        //GLLog(@"EEEEEE jr debug, %@", dict);
        if (dict) {
            [self.pollIds addEntriesFromDictionary:dict];
        }
    }
}

- (void)addPoll:(ForumTopic *)topic ByDateStr:(NSString *)dateStr {
    [self checkIfNeedReset];
    // find if the topic is already in the list
    // remove the duplicated in the array
    NSMutableArray * duplicated = [[NSMutableArray alloc] init];
    for (NSString * str in [self.pollIds allKeys]) {
        uint64_t topicId = [[self.pollIds objectForKey:str] longLongValue];
        if (topicId == topic.identifier) {
            [duplicated addObject:str.copy];
        }
    }
    for (NSString * str in duplicated) {
        [self.polls removeObjectForKey:str];
        [self.pollIds removeObjectForKey:str];
    }
    [self.polls setObject:topic forKey:dateStr];
    [self.pollIds setObject:@(topic.identifier) forKey:dateStr];
    [Utils setSyncableDefautsForKey:USERDEFAULTS_USER_DAILY_POLL_IDS
        withValue:self.pollIds];
}

- (NSNumber *)getTopicIdByDateStr:(NSString *)dateStr {
    return [self.pollIds objectForKey:dateStr];
}

- (ForumTopic *)getTopicByDateStr:(NSString *)dateStr {
    return [self.polls objectForKey:dateStr];
}

- (ForumTopic *)getTopicById:(uint64_t)topicId {
    for (NSString * str in [self.pollIds allKeys]) {
        uint64_t tid = [[self.pollIds objectForKey:str] longLongValue];
        if (topicId == tid) {
            return [self.polls objectForKey:str];
        }
    }
    return nil;
}

- (void)loadTopicByDate:(NSDate *)date {
    NSString * dateStr = [Utils dailyDataDateLabel:date];
    NSNumber * topicId = [self getTopicIdByDateStr:dateStr];
    BOOL isToday = [Utils date:date isSameDayAsDate:[NSDate date]];

    if ((!topicId) || ([topicId longLongValue] == 0)) {
        if (!isToday) return;
        if (self.latestTodayLoadTime) {
            if (![Utils date:self.latestTodayLoadTime isSameDayAsDate:[NSDate date]]) {
                // latest load time not today
                self.latestTodayLoadTime = nil;
            } else if ([[NSDate date] timeIntervalSinceDate:self.latestTodayLoadTime] <= 3600) {
                // latest load time in 1 hour
                return;
            }
        }
    }
    //GLLog(@"CCCCCCCC jr debug, in UserDailyPoll, %@", topicId);
    [Forum fetchDailyTopic:[topicId longLongValue] callback:^(NSDictionary *result, NSError *error) {
        if (!error) {
            NSInteger rc = [result integerForKey:@"rc"];
            if (rc == RC_SUCCESS) {
                NSDictionary * dict = [result objectForKey:@"topic"];
                ForumTopic * topic = [[ForumTopic alloc] initWithDictionary:dict];
                [self addPoll:topic ByDateStr:dateStr];
                [self publish:EVENT_DAILY_POLL_LOADED data:dateStr];
            }
            // no matter if we successfully loaded today's topic, we should set the time
            // to avoid loading today's topic too much times (if response is none topic)
            if (isToday) {
                self.latestTodayLoadTime = [NSDate date];
            }
        }
    }];
}

@end
