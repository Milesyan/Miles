//
//  ForumProfileDataController.m
//  Pods
//
//  Created by Peng Gu on 4/21/15.
//
//

#import <GLFoundation/GLFoundation.h>
#import <BlocksKit/NSArray+BlocksKit.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "ForumProfileDataController.h"
#import "Forum.h"


@interface ForumProfileDataController ()

@property (nonatomic, assign) uint64_t userid;

@property (nonatomic, assign) BOOL hasLoadedFeeds;
@property (nonatomic, assign) BOOL hasLoadedPopularFeeds;
@property (nonatomic, assign) BOOL hasLoadedCreatedTopics;
@property (nonatomic, assign) BOOL hasLoadedBookmarkedTopics;
@property (nonatomic, assign) BOOL hasLoadedParticipatedTopics;

@property (nonatomic, assign) BOOL noMoreFeeds;
@property (nonatomic, assign) BOOL noMorePopularFeeds;
@property (nonatomic, assign) BOOL noMoreCreatedTopics;
@property (nonatomic, assign) BOOL noMoreBookmarkedTopics;
@property (nonatomic, assign) BOOL noMoreParticipatedTopics;

@end

@implementation ForumProfileDataController


- (instancetype)initWithUserID:(uint64_t)userid
{
    self = [super init];
    if (self) {
        BOOL isUserSelf = [Forum currentForumUser].identifier == userid;
        _userid = userid;
        _activityType = isUserSelf ? ForumUserActivityTypeParticipated : ForumUserActivityTypePopularFeed;
        _feeds = [NSArray array];
        _popularFeeds = [NSArray array];
        _createdTopics = [NSArray array];
        _bookmarkedTopics = [NSArray array];
        _participatedTopics = [NSArray array];
    }
    return self;
}


- (NSString *)activityTypeDescription
{
    if (self.activityType == ForumUserActivityTypeFeed) {
        return @"All";
    }
    else if (self.activityType == ForumUserActivityTypePopularFeed) {
        return @"Popular";
    }
    else if (self.activityType == ForumUserActivityTypeCreated) {
        return @"Created";
    }
    else if (self.activityType == ForumUserActivityTypeBookmarked) {
        return @"Bookmarked";
    }
    else if (self.activityType == ForumUserActivityTypeParticipated) {
        return @"Participated";
    }
    return @"All";
}


- (NSArray *)activeItems
{
    if (self.activityType == ForumUserActivityTypeFeed) {
        return self.feeds;
    }
    else if (self.activityType == ForumUserActivityTypePopularFeed) {
        return self.popularFeeds;
    }
    else if (self.activityType == ForumUserActivityTypeCreated) {
        return self.createdTopics;
    }
    else if (self.activityType == ForumUserActivityTypeBookmarked) {
        return self.bookmarkedTopics;
    }
    else if (self.activityType == ForumUserActivityTypeParticipated) {
        return self.participatedTopics;
    }
    return nil;
}


- (BOOL)hasLoadedItems
{
    if (self.activityType == ForumUserActivityTypeFeed) {
        return self.hasLoadedFeeds;
    }
    else if (self.activityType == ForumUserActivityTypePopularFeed) {
        return self.hasLoadedPopularFeeds;
    }
    else if (self.activityType == ForumUserActivityTypeCreated) {
        return self.hasLoadedCreatedTopics;
    }
    else if (self.activityType == ForumUserActivityTypeBookmarked) {
        return self.hasLoadedBookmarkedTopics;
    }
    else if (self.activityType == ForumUserActivityTypeParticipated) {
        return self.hasLoadedParticipatedTopics;
    }
    return NO;
}


- (BOOL)hasNoMoreItems
{
    if (self.activityType == ForumUserActivityTypeFeed) {
        return self.noMoreFeeds;
    }
    else if (self.activityType == ForumUserActivityTypePopularFeed) {
        return self.noMorePopularFeeds;
    }
    else if (self.activityType == ForumUserActivityTypeCreated) {
        return self.noMoreCreatedTopics;
    }
    else if (self.activityType == ForumUserActivityTypeBookmarked) {
        return self.noMoreBookmarkedTopics;
    }
    else if (self.activityType == ForumUserActivityTypeParticipated) {
        return self.noMoreParticipatedTopics;
    }
    return YES;
}


#pragma mark - update data
- (void)addTopicToBookmarkedTopics:(ForumTopic *)topic
{
    self.bookmarkedTopics = [@[topic] arrayByAddingObjectsFromArray:self.bookmarkedTopics];
}


- (void)removeTopicFromBookmarkedTopics:(ForumTopic *)topic
{
    self.bookmarkedTopics = [self.bookmarkedTopics bk_select:^BOOL(id obj) {
        return topic.identifier != [(ForumTopic *)obj identifier];
    }];
}


#pragma mark - fetching data APIs

- (void)fetchInitialDataWithCompletion:(ForumUserActivityDataReloadCallback)completion
{
    if ([self.user isMyself]) {
        self.hasLoadedParticipatedTopics = YES;
        self.participatedTopics = [NSArray array];
    }
    else {
        self.hasLoadedPopularFeeds = YES;
        self.popularFeeds = [NSArray array];
    }
    
    @weakify(self)
    [Forum fetchProfileDataForUser:self.userid callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        
        if (error && completion) {
            completion(NO, error);
            return;
        }

        NSDictionary *userDict = result[@"user"];
        
        if (self.userid == [Forum currentForumUser].identifier) {
            [[Forum currentForumUser] updateWithDict:userDict];
            self.user = [Forum currentForumUser];
        }
        else {
            self.user = [[ForumUser alloc] initWithDictionary:userDict];
        }
        
        [self _handleFetchingResult:result error:error type:self.activityType completion:completion];
    }];
}


- (void)fetchData:(ForumUserActivityType)activityType
       completion:(ForumUserActivityDataReloadCallback)completion
{
    [self _fetchDataWithType:activityType offset:0 completion:completion];
}


- (void)fetchMoreDataWithCompletion:(ForumUserActivityDataReloadCallback)completion
{
    [self _fetchDataWithType:self.activityType offset:self.activeItems.count completion:completion];
}


#pragma mark - private fetching methods
- (void)_fetchDataWithType:(ForumUserActivityType)activityType
                    offset:(NSUInteger)offset
                completion:(ForumUserActivityDataReloadCallback)completion
{
    if (activityType == ForumUserActivityTypeFeed) {
        self.hasLoadedFeeds = YES;
        [Forum fetchFeedsForUser:self.user.identifier
                          offset:(int)offset
                        callback:^(NSDictionary *result, NSError *error)
         {
             [self _handleFetchingResult:result error:error type:activityType completion:completion];
         }];
    }
    else if (activityType == ForumUserActivityTypePopularFeed) {
        self.hasLoadedPopularFeeds = YES;
        [Forum fetchPopularFeedsForUser:self.user.identifier
                                 offset:(int)offset
                               callback:^(NSDictionary *result, NSError *error)
        {
            [self _handleFetchingResult:result error:error type:activityType completion:completion];
        }];
    }
    else if (activityType == ForumUserActivityTypeCreated) {
        self.hasLoadedCreatedTopics = YES;
        [Forum fetchTopicsForType:ForumGroupCreated
                    lastReplyTime:0
                         callback:^(NSDictionary *result, NSError *error) {
            [self _handleFetchingResult:result error:error type:activityType completion:completion];
        }];
    }
    else if (activityType == ForumUserActivityTypeBookmarked) {
        self.hasLoadedBookmarkedTopics = YES;
        [Forum fetchTopicsForType:ForumGroupBookmarked
                    lastReplyTime:0
                         callback:^(NSDictionary *result, NSError *error)
        {
            [self _handleFetchingResult:result error:error type:activityType completion:completion];
        }];
    }
    else if (activityType == ForumUserActivityTypeParticipated) {
        self.hasLoadedParticipatedTopics = YES;
        [Forum fetchTopicsForType:ForumGroupParticipated
                    lastReplyTime:0
                         callback:^(NSDictionary *result, NSError *error)
        {
            [self _handleFetchingResult:result error:error type:activityType completion:completion];
        }];
    }
}


- (void)_handleFetchingResult:(NSDictionary *)result
                        error:(NSError *)error
                         type:(ForumUserActivityType)type
                   completion:(ForumUserActivityDataReloadCallback)completion
{
    if (error && completion) {
        completion(NO, error);
        return;
    }
    
    NSArray *items = [self _getDataFromFetchingResult:result forType:type];
    
    NSInteger pageSize = [result[@"page_size"] integerValue];
    BOOL noMoreData = pageSize > items.count;
    
    if (type == ForumUserActivityTypeFeed) {
        self.feeds = [self.feeds arrayByAddingObjectsFromArray:items];
        self.noMoreFeeds = noMoreData;
    }
    else if (type == ForumUserActivityTypePopularFeed) {
        self.popularFeeds = [self.popularFeeds arrayByAddingObjectsFromArray:items];
        self.noMorePopularFeeds = noMoreData;
    }
    else if (type == ForumUserActivityTypeCreated) {
        self.createdTopics = [self.createdTopics arrayByAddingObjectsFromArray:items];
        self.noMoreCreatedTopics = noMoreData;
    }
    else if (type == ForumUserActivityTypeBookmarked) {
        self.bookmarkedTopics = [self.bookmarkedTopics arrayByAddingObjectsFromArray:items];
        self.noMoreBookmarkedTopics = noMoreData;
    }
    else if (type == ForumUserActivityTypeParticipated) {
        self.participatedTopics = [self.participatedTopics arrayByAddingObjectsFromArray:items];
        self.noMoreParticipatedTopics = noMoreData;
    }
    
    if (completion) {
        completion(YES, nil);
    }
}


- (NSArray *)_getDataFromFetchingResult:(NSDictionary *)result forType:(ForumUserActivityType)type
{
    NSArray *items;
    
    if (type == ForumUserActivityTypeFeed || type == ForumUserActivityTypePopularFeed) {
        items = [result[@"feeds"] bk_map:^id(id obj) {
            NSNumber *type = [obj objectForKey:@"post_type"];
            if (type.integerValue == ForumFeedTypeTopic) {
                return [[ForumTopic alloc] initWithDictionary:obj];
            }
            else if (type.integerValue == ForumFeedTypeComment) {
                return [[ForumReply alloc] initWithDictionary:obj];
            }
            return [[ForumTopic alloc] initWithDictionary:obj];
        }];
    }
    else {
        items = [result[@"topics"] bk_map:^id(id obj) {
            return [[ForumTopic alloc] initWithDictionary:obj];
        }];
    }
    
    return items;
}


@end




