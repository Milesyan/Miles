//
//  Forum.h
//  emma
//
//  Created by Allen Hsu on 11/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ForumCategory.h"
#import "ForumTopic.h"
#import "ForumUser.h"
#import "ForumGroup.h"
#import "ForumReply.h"
#import "ForumEvents.h"
#import "ForumLoggingData.h"

#define FORUM_MIN_TITLE_LENGTH      5
#define FORUM_MAX_TITLE_LENGTH      255
#define FORUM_MIN_CONTENT_LENGTH    5
#define FORUM_MAX_CONTENT_LENGTH    10000
#define FORUM_MIN_REPLY_LENGTH      5
#define FORUM_MAX_REPLY_LENGTH      2000
#define FORUM_POLL_OPTION_MAX_LENGTH  25
#define FORUM_RULES_TOPIC_ID        149741

#define FORUM_CATEGORY_ID_SUCCESS_STORIES   3
#define FORUM_CATEGORY_ID_TODO_TOPIC    8
#define FORUM_CATEGORY_ID_ARTICLE       9
#define FORUM_CATEGORY_ID_KL_TODO_TOPIC 10
#define FORUM_SYSTEM_CATEGORIES         @[@(8), @(9), @(10)]

#define kDidClickCheckoutCommunity      @"kDidClickCheckoutCommunity"
#define kDidClickGroupsButton           @"kDidClickGroupsButton"
#define kDidClickNewSectionInCommunity  @"kDidClickNewSectionInCommunity"

#define RC_SUCCESS 0

#define FORUM_SCHEME_TOOLTIP        @"tooltip"
#define FORUM_ERROR_DOMAIN          @"FORUM_ERROR_DOMAIN"

#define DEFAULTS_GROUP_ORDER_PRE    @"defaults_group_order_"
#define DEFAULTS_HIDE_TOPIC_PRE     @"defaults_hide_topic"
#define DEFAULTS_HIDE_REPLY_PRE     @"defaults_hide_reply"
#define DEFAULTS_NEEDS_SHOW_MY_GROUPS_POPUP     @"defaults_needs_show_my_groups_popup"
#define DEFAULTS_SELECTED_AGE_RANGES            @"defaults_selected_age_ranges"

#define IOS_TOPIC_VIEW_FROM_BOOKMARK        @"ios topic view from bookmark"
#define IOS_TOPIC_VIEW_FROM_FORUM           @"ios topic view from forum"
#define IOS_TOPIC_VIEW_FROM_HOME            @"ios topic view from home"
#define IOS_TOPIC_VIEW_FROM_SEARCH_TOPIC    @"ios topic view from search topic"
#define IOS_TOPIC_VIEW_FROM_SEARCH_REPLY    @"ios topic view from search reply"
#define IOS_TOPIC_VIEW_FROM_WELCOME         @"ios topic view from welcome"
#define IOS_TOPIC_VIEW_FROM_COMMUNITY_RULES @"ios topic view from community rules"
#define IOS_TOPIC_VIEW_FROM_CREATE_TOPIC    @"ios topic view from create topic"
#define IOS_TOPIC_VIEW_FROM_PROFILE @"ios topic view from profile"
#define IOS_TOPIC_VIEW_FROM_NOTIFICATION @"ios topic view from notification"

#define COMPOSE_BUTTON_TOPIC    @"compose button topic"
#define COMPOSE_BUTTON_POLL     @"compose button poll"
#define COMPOSE_BUTTON_PHOTO    @"compose button photo"
#define COMPOSE_BUTTON_URL      @"compose button url"
#define COMPOSE_BUTTON_MORE     @"compose button more"

#define FALLBACK_READABILITY_URL @"https://readability.com/api/content/v1/parser"
#define FALLBACK_READABILITY_TOKEN @"b2153944ad94f9e2e5eccbeaad25f67a3e41d8cb"


#define FORUM_COLOR_LIGHT_GRAY UIColorFromRGB(0xf1f2f4)


typedef NS_ENUM(NSUInteger, ForumErrorCode) {
    ForumErrorCodeMethodNotImplemented = 1001,
};

typedef void(^ForumEmailContactCallback)(NSArray *emails);
typedef void(^ForumAPICallBack)(NSDictionary *result, NSError *error);


@class ForumPromotionFeed;

@protocol ForumDelegate <NSObject>

#pragma mark - Misc delegate methods
@required
- (ForumUser *)currentForumUser;
- (void)log:(NSString *)eventName eventData:(NSDictionary *)eventData;
- (void)log:(NSString *)eventName;
- (NSString *)replaceTermLinksInHtml:(NSString *)html caseSensitive:(BOOL)caseSensitive;
- (UIViewController *)emailContactViewControllerWithBackTitle:(NSString *)backTitle callback:(ForumEmailContactCallback)cb;
- (void)updateUserProfile:(ForumUser *)newUser;
- (void)updateProfileImage:(UIImage *)profileImage;
- (void)updateBackgroundImage:(UIImage *)backgroundImage;
- (void)restoreBackgroundImage;
- (UIImage *)defaultBackgroundImage;
- (void)toggleLikedTopic:(ForumTopic *)topic liked:(BOOL)liked;
- (void)tip:(NSString *)tip;

- (void)shareTopicWithObject:(id)topicObject;
- (void)shareGroupWithObject:(id)groupObject;
- (void)shareQuizResultWithToken:(NSString *)token;

- (void)fetchURLContent:(NSString *)url callback:(ForumAPICallBack)cb;

@optional
- (NSArray *)composeButtonsOrder;
- (void)actionRequiresLogin;
- (UIImage *)bannerImageForWelcomeDialog;
- (NSString *)textForWelcomeDialog;
- (NSString *)text1ForWelcomeDialog;
- (NSString *)text2ForWelcomeDialog;

- (NSDate *)appInstallDate;

- (ForumPromotionFeed *)promotionFeed;
- (CGFloat)heightForPromotionFeed:(ForumPromotionFeed *)feed withInWidth:(CGFloat)maxWidth;
- (void)userDidmissedPromotionFeed:(ForumPromotionFeed *)feed;
- (void)userClickedPromotionFeed:(ForumPromotionFeed *)feed fromViewController: (UIViewController *)vc;
- (void)userDidFinishQuiz:(int)quizId withResultId:(int)resultId answerToken:(NSString *)answerToken;


#pragma mark - network delegate

@required
- (void)POST:(NSString *)URLString parameters:(NSDictionary *)parameters callback:(ForumAPICallBack)cb;
- (void)POST:(NSString *)URLString parameters:(NSDictionary *)parameters images:(NSDictionary *)images callback:(ForumAPICallBack)cb;
- (void)GET:(NSString *)URLString withToken:(BOOL)withToken parameters:(NSDictionary *)parameters callback:(ForumAPICallBack)cb;

@end

@interface Forum : NSObject

// Retain delegate here to keep it live
@property (strong, nonatomic) id <ForumDelegate> delegate;
@property (strong, nonatomic) NSString *baseURL;
@property (strong, nonatomic) NSMutableArray *categories;
@property (strong, nonatomic) NSMutableDictionary *cidToCategories;
@property (strong, nonatomic) NSArray *subscribedGroups;
@property (strong, nonatomic) NSArray *recommendedGroups;
@property (strong, nonatomic) NSMutableSet *subscribedGroupIds;
@property (assign, nonatomic) float version;
@property (assign, nonatomic) BOOL bookmarkedUpdated;
@property (assign, nonatomic) BOOL createdUpdated;
@property (assign, nonatomic) BOOL participatedUpdated;

@property (assign, nonatomic) BOOL fetchGroupsPageLocked;
@property (assign, nonatomic) BOOL groupPageDataUpdated;

+ (Forum *)sharedInstance;
+ (UIStoryboard *)storyboard;

+ (NSArray *)flagReasonsIsTopic:(BOOL)isTopic;
- (ForumCategory *)successStoriesCategory;
- (BOOL)saveCategoriesCache:(NSDictionary *)dict;

+ (void)createReplyToTopic:(uint64_t)topicId withContent:(NSString *)content andImages:(NSDictionary *)images anonymously:(BOOL)anonymous callback:(ForumAPICallBack)cb;
+ (void)createReplyToReply:(uint64_t)replyId inTopic:(uint64_t)topicId withContent:(NSString *)content andImages:(NSDictionary *)images anonymously:(BOOL)anonymous callback:(ForumAPICallBack)cb;
+ (void)fetchTopicsForType:(ForumGroupType)type lastReplyTime:(unsigned int)lastReplyTime callback:(ForumAPICallBack)cb;
+ (void)fetchRepliesForTopic:(uint64_t)topicId offset:(NSUInteger)offset callback:(ForumAPICallBack)cb;
+ (void)fetchRepliesForArticle:(uint64_t)articleId lastReplyTime:(unsigned int)lastReplyTime callback:(ForumAPICallBack)cb;
+ (void)fetchReplyForNotification:(uint64_t)replyID callback:(ForumAPICallBack)callback;
+ (void)fetchRepliesToReply:(uint64_t)replyId lastReplyTime:(unsigned int)lastReplyTime callback:(ForumAPICallBack)cb;
+ (void)markTopic:(uint64_t)topicId bookmarked:(BOOL)bookmarked callback:(ForumAPICallBack)cb;
+ (void)markTopic:(uint64_t)topicId liked:(BOOL)liked callback:(ForumAPICallBack)cb;
+ (void)markTopic:(uint64_t)topicId disliked:(BOOL)disliked callback:(ForumAPICallBack)cb;
+ (void)markTopic:(uint64_t)topicId flagged:(BOOL)flagged reason:(NSString *)reason callback:(ForumAPICallBack)cb;
+ (void)markReply:(uint64_t)topicId replyId:(uint64_t)replyId liked:(BOOL)liked callback:(ForumAPICallBack)cb;
+ (void)markReply:(uint64_t)topicId replyId:(uint64_t)replyId disliked:(BOOL)disliked callback:(ForumAPICallBack)cb;
+ (void)markReply:(uint64_t)topicId replyId:(uint64_t)replyId flagged:(BOOL)flagged reason:(NSString *)reason callback:(ForumAPICallBack)cb;
+ (void)searchTopicWithKeyword:(NSString *)keyword offset:(NSUInteger)offset callback:(ForumAPICallBack)cb;
+ (void)searchReplyWithKeyword:(NSString *)keyword offset:(NSUInteger)offset callback:(ForumAPICallBack)cb;
+ (void)votePoll:(uint64_t)topicId atOption:(int)optionIndex callback:(ForumAPICallBack)cb;
+ (void)shareTopicWithObject:(id)topicObject;
+ (void)shareQuizResultWithToken:(NSString *)token;
+ (void)removeReply:(uint64_t)replyId callback:(ForumAPICallBack)cb;

+ (void)fetchDailyTopic:(uint64_t)topicId callback:(ForumAPICallBack)cb;

+ (BOOL)isSubscribedGroupId:(uint64_t)groupId;
+ (BOOL)isSubscribedGroup:(ForumGroup *)group;
+ (void)unsubscribeGroup:(uint64_t)groupId;
+ (ForumCategory *)categoryFromGroup:(ForumGroup *)group;

+ (void)fetchPrerequisiteForCreatingGroupCallback:(ForumAPICallBack)cb;
+ (void)fetchGroupsPageCallback:(ForumAPICallBack)cb;
+ (void)fetchGroupsSubscribedByUser:(uint64_t)userId callback:(ForumAPICallBack)cb;
+ (void)fetchTopicsInGroup:(uint64_t)groupId withOffset:(int)offset
                    orType:(ForumGroupType)type withLastReply:(unsigned int)lastReply
                  callback:(ForumAPICallBack)cb;
+ (void)fetchFindGroupsPageCallback:(ForumAPICallBack)cb;
+ (void)fetchGroupsInCategory:(uint64_t)categoryId offset:(int)offset callback:
(ForumAPICallBack)cb;

+ (void)createGroupWithName:(NSString *)name categoryId:(uint16_t)categoryId
                       desc:(NSString *)desc photo:(UIImage *)photo callback:(ForumAPICallBack)cb;
+ (void)createTopicInGroup:(uint64_t)groupId withTitle:(NSString *)title
                   content:(NSString *)content andImages:(NSDictionary *)images
               anonymously:(BOOL)anonymous callback:(ForumAPICallBack)cb;
+ (void)createPollInGroup:(uint64_t)groupId withTitle:(NSString *)title
                  options:(NSArray *)options content:(NSString *)content
                andImages:(NSDictionary *)images anonymously:(BOOL)anonymous
                 callback:(ForumAPICallBack)cb;
+ (void)createPhotoInGroup:(uint64_t)groupId withTitle:(NSString *)title
                    images:(NSDictionary *)images
               anonymously:(BOOL)anonymous warning:(BOOL)warning callback:(ForumAPICallBack)cb;
+ (void)createURLInGroup:(uint64_t)groupId
               withTitle:(NSString *)title
                     url:(NSString *)url
                urlTitle:(NSString *)urlTitle
             urlAbstract:(NSString *)urlAbstract
               thumbnail:(NSString *)thumb
                callback:(ForumAPICallBack)cb;
+ (void)updateTopic:(uint64_t)topicId inGroup:(uint64_t)groupId withTitle:(NSString *)title
                   content:(NSString *)content andImages:(NSDictionary *)images
               anonymously:(BOOL)anonymous callback:(ForumAPICallBack)cb;
+ (void)updatePoll:(uint64_t)topicId inGroup:(uint64_t)groupId withTitle:(NSString *)title
                  options:(NSArray *)options content:(NSString *)content
                andImages:(NSDictionary *)images anonymously:(BOOL)anonymous
                 callback:(ForumAPICallBack)cb;
+ (void)updatePhoto:(uint64_t)topicId inGroup:(uint64_t)groupId withTitle:(NSString *)title
                    images:(NSDictionary *)images
               anonymously:(BOOL)anonymous warning:(BOOL)warning callback:(ForumAPICallBack)cb;
+ (void)updateURL:(uint64_t)topicId inGroup:(uint64_t)groupId
               withTitle:(NSString *)title
                     url:(NSString *)url
                urlTitle:(NSString *)urlTitle
             urlAbstract:(NSString *)urlAbstract
               thumbnail:(NSString *)thumb
                callback:(ForumAPICallBack)cb;

+ (void)joinGroup:(uint64_t)groupId callback:(ForumAPICallBack)cb;
+ (void)leaveGroup:(uint64_t)groupId callback:(ForumAPICallBack)cb;

+ (void)shareGroupWithObject:(id)groupObject;
+ (void)inviteUser:(uint64_t)uid toGroup:(uint64_t)groupId message:
(NSString *)message;
+ (void)isUser:(uint64_t)uid alreadyInGroup:(uint64_t)groupId callback:
(ForumAPICallBack)cb;

+ (void)saveOrderWith:(NSArray *)subscribed;
+ (NSArray *)reorderGroups:(NSArray *)unorderedGroups;

+ (void)fetchHotTopicsOffset:(int)offset callback:(ForumAPICallBack)cb;
+ (void)fetchNewTopicsOffset:(int)offset callback:(ForumAPICallBack)cb;
+ (void)fetchWelcomeTopicIdWithCallback:(ForumAPICallBack)cb;

+ (void)fetchFeedsForUser:(uint64_t)target_uid offset:(int)offset callback:(ForumAPICallBack)cb;
+ (void)fetchPopularFeedsForUser:(uint64_t)target_uid offset:(int)offset callback:(ForumAPICallBack)cb;
+ (void)fetchPopularTopicsForUser:(uint64_t)target_uid offset:(int)offset callback:(ForumAPICallBack)cb;

+ (void)followUser:(uint64_t)target_uid callback:(ForumAPICallBack)cb;
+ (void)unfollowUser:(uint64_t)target_uid callback:(ForumAPICallBack)cb;

+ (void)fetchFollowersForUser:(uint64_t)target_uid withOffset:(int)offset callback:(ForumAPICallBack)cb;
+ (void)fetchFollowingsForUser:(uint64_t)target_uid withOffset:(int)offset callback:(ForumAPICallBack)cb;

+ (void)fetchSocialInfoForUser:(uint64_t)target_uid callback:(ForumAPICallBack)cb;
+ (void)fetchProfileDataForUser:(uint64_t)target_uid callback:(ForumAPICallBack)cb;

+ (void)fetchGlowAccountID:(ForumAPICallBack)cb;
+ (void)fetchQuizWithTopicId:(uint64_t)topicId quizId:(int)quizId sourceToken:(NSString *)sourceToken myToken:(NSString *)myToken callback:(ForumAPICallBack)cb;
+ (void)submitQuizWithQuizId:(int)quizId sourceToken:(NSString *)sourceToken selectedOptions:(NSDictionary *)selectedOptions generation:(int)generation callback:(ForumAPICallBack)cb;

#pragma mark - Delegate Proxy

+ (ForumUser *)currentForumUser;
+ (BOOL)isLoggedIn;
+ (void)actionRequiresLogin;

+ (void)log:(NSString *)eventName eventData:(NSDictionary *)eventData;
+ (void)log:(NSString *)eventName;
+ (NSString *)replaceTermLinksInHtml:(NSString *)html caseSensitive:(BOOL)caseSensitive;
+ (UIViewController *)emailContactViewControllerWithCallback:(ForumEmailContactCallback)cb;
+ (UIViewController *)emailContactViewControllerWithBackTitle:(NSString *)backTitle callback:(ForumEmailContactCallback)cb;
+ (void)updateUserProfile:(ForumUser *)newUser;
+ (void)updateProfileImage:(UIImage *)profileImage;
+ (void)updateBackgroundImage:(UIImage *)backgroundImage;
+ (void)restoreBackgroundImage;
+ (UIImage *)defaultBackgroundImage;
+ (void)toggleLikedTopic:(ForumTopic *)topic liked:(BOOL)liked;
+ (void)tip:(NSString *)tip;
+ (NSDate *)appInstallDate;

+ (UIImage *)bannerImageForWelcomeDialog;
+ (NSString *)textForWelcomeDialog;

+ (BOOL)isTopicHidden:(uint64_t)topicId;
+ (void)hideTopic:(uint64_t)topicId;
+ (void)setTopic:(uint64_t)topicId hidden:(BOOL)hidden;
+ (void)reportTopic:(uint64_t)topicId;
+ (void)reportReply:(uint64_t)replyId ofTopic:(uint64_t)topicId;

+ (BOOL)isReplyHidden:(uint64_t)replyId;
+ (void)hideReply:(uint64_t)replyId;
+ (void)setReply:(uint64_t)replyId hidden:(BOOL)hidden;

- (void)onLogout;

#pragma mark - user defaults

+ (BOOL)needsShowMyGruopsPopup;
+ (void)setNeedsShowMyGroupsPopup:(BOOL)needs;
+ (NSArray *)selectedAgeRangeIndexes;
+ (void)setSelectedAgeRangeIndexes:(NSArray *)selectedAgeRangeIndexes;
+ (NSArray *)availableAgeRanges;
+ (BOOL)isBirthdayFiltered:(int64_t)birthdayTimestamp;
+ (NSString *)selectedAgeRangeDescription;
+ (NSString *)descriptionOfAgeRangeIndexes:(NSArray *)indexes;
+ (NSString *)descriptionOfAgeRange:(NSRange)range;

@end
