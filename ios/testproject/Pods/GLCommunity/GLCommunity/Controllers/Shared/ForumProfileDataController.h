//
//  ForumProfileDataController.h
//  Pods
//
//  Created by Peng Gu on 4/21/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ForumUserActivityType) {
    ForumUserActivityTypeFeed,
    ForumUserActivityTypePopularFeed,
    ForumUserActivityTypeCreated,
    ForumUserActivityTypeBookmarked,
    ForumUserActivityTypeParticipated,
};

typedef NS_ENUM(NSUInteger, ForumFeedType) {
    ForumFeedTypeTopic = 1,
    ForumFeedTypeComment = 2,
    ForumFeedTypeReply = 3
};

typedef void(^ForumUserActivityDataReloadCallback)(BOOL success, NSError *error);


@class ForumUser;
@class ForumTopic;


@interface ForumProfileDataController : NSObject

@property (nonatomic, strong) ForumUser *user;

@property (nonatomic, assign) ForumUserActivityType activityType;
@property (nonatomic, copy) NSString *activityTypeDescription;
@property (nonatomic, assign) NSArray *activeItems; // returns items based on the current data type
@property (nonatomic, assign) BOOL hasLoadedItems;
@property (nonatomic, assign) BOOL hasNoMoreItems;

@property (nonatomic, strong) NSArray *feeds;
@property (nonatomic, strong) NSArray *popularFeeds;
@property (nonatomic, strong) NSArray *createdTopics;
@property (nonatomic, strong) NSArray *bookmarkedTopics;
@property (nonatomic, strong) NSArray *participatedTopics;

- (instancetype)initWithUserID:(uint64_t)userid;

- (void)fetchInitialDataWithCompletion:(ForumUserActivityDataReloadCallback)completion;

- (void)fetchData:(ForumUserActivityType)dataType
        completion:(ForumUserActivityDataReloadCallback)completion;

- (void)fetchMoreDataWithCompletion:(ForumUserActivityDataReloadCallback)completion;

- (void)addTopicToBookmarkedTopics:(ForumTopic *)topic;
- (void)removeTopicFromBookmarkedTopics:(ForumTopic *)topic;

@end
