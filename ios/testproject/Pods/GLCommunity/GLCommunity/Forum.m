//
//  Forum.m
//  emma
//
//  Created by Allen Hsu on 11/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>

#import "Forum.h"

#define FORUM_KEY_CATEGORY_ID   @"category_id"
#define FORUM_KEY_TITLE         @"title"
#define FORUM_KEY_CONTENT       @"content"
#define FORUM_KEY_ANONYMOUS     @"anonymous"
#define FORUM_KEY_OPTIONS       @"options"

#define FORUM_KEY_URL_PATH     @"url_path"
#define FORUM_KEY_URL_TITLE     @"url_title"
#define FORUM_KEY_URL_ABSTRACT  @"url_abstract"
#define FORUM_KEY_THUMBNAIL_URL @"thumbnail_url"


#define FORUM_KEY_TOPIC_ID      @"topic_id"
#define FORUM_KEY_REPLY_TO      @"reply_to"
#define FORUM_KEY_REPLY_ID      @"reply_id"
#define FORUM_KEY_FORUM_VERSION @"forum_version"
#define FORUM_KEY_KEYWORD       @"keyword"
#define FORUM_KEY_OFFSET        @"offset"
#define FORUM_KEY_VOTE_INDEX    @"vote_index"
#define FORUM_KEY_LIKED         @"liked"
#define FORUM_KEY_DISLIKED         @"disliked"
#define FORUM_KEY_EMAILS        @"emails"
#define FORUM_KEY_TO_EMAILS     @"to_emails"
#define FORUM_KEY_QUIZ_ID       @"quiz_id"
#define FORUM_KEY_SOURCE_TOKEN  @"source_token"
#define FORUM_KEY_MY_TOKEN      @"my_token"
#define FORUM_KEY_SELECTED_OPTIONS @"selected_options"
#define FORUM_KEY_GENERATION    @"generation"

#define FORUM_KEY_GROUP_ID      @"group_id"
#define FORUM_KEY_WARNING       @"warning"
#define FORUM_KEY_FLAGGED       @"flagged"
#define FORUM_KEY_REASON        @"reason"
#define FORUM_KEY_OFFSET        @"offset"

#define FORUM_KEY_NAME          @"name"
#define FORUM_KEY_DESC          @"desc"
#define FORUM_KEY_INVITEE_ID    @"invitee_id"
#define FORUM_KEY_MESSAGE       @"message"
#define FORUM_KEY_TARGET_UID    @"target_uid"

static NSString * const kForumAPIURLForumInfo       = @"statistics";
static NSString * const kForumAPIURLCreateTopic     = @"create_topic";
static NSString * const kForumAPIURLCreatePoll      = @"create_poll";
static NSString * const kForumAPIURLCreateReply     = @"create_reply";
static NSString * const kForumAPIURLCategory        = @"category";
static NSString * const kForumAPIURLParticipated    = @"participated";
static NSString * const kForumAPIURLBookmarked      = @"bookmarked";
static NSString * const kForumAPIURLCreated         = @"created";
static NSString * const kForumAPIURLReplies         = @"replies_v3";
static NSString * const kForumAPIURLSubReplies      = @"subreplies";
static NSString * const kForumAPIURLCreateBookmark  = @"bookmark";
static NSString * const kForumAPIURLLike            = @"liked";
static NSString * const kForumAPIURLDislike         = @"disliked";
static NSString * const kForumAPIURLSearchTopic     = @"search/topic";
static NSString * const kForumAPIURLSearchReply     = @"search/reply";
static NSString * const kForumAPIURLVotePoll        = @"vote_poll";
static NSString * const kForumAPIURLLikeReply       = @"like_reply";
static NSString * const kForumAPIURLDislikeReply    = @"dislike_reply";
static NSString * const kForumAPIURLLoadGlowUser    = @"load_glow_user";
static NSString * const kForumAPIURLShareTopic      = @"share_by_email";
static NSString * const kForumAPIURLDailyTopic      = @"daily_topic";

static NSString * const kForumAPIURLFlagPost        = @"flag_post";
static NSString * const kForumAPIURLFlagReply       = @"flag_post";
static NSString * const kForumAPIURLRemoveReply     = @"remove_reply";
static NSString * const kForumAPIURLPrerequisite    = @"group/create_prerequisite";
static NSString * const kForumAPIURLGroupsPage      = @"group/group_page";
static NSString * const kForumAPIURLGroupsSubscription      = @"group/subscribed_groups";
static NSString * const kForumAPIURLGroupTopics     = @"group/%llu/topics";

static NSString * const kForumAPIURLFindGroups          = @"group/find_groups";
static NSString * const kForumAPIURLGroupsInCategory    = @"category/%llu/all_groups";
static NSString * const kForumAPIURLCreateTopicInGroup  = @"topic/create";
static NSString * const kForumAPIURLCreatePollInGroup   = @"poll/create";
static NSString * const kForumAPIURLCreatePhotoInGroup  = @"photo/create";
static NSString * const kForumAPIURLCreateURLInGroup  = @"url_topic/create";
static NSString * const kForumAPIURLUpdateTopicInGroup  = @"topic/update";
static NSString * const kForumAPIURLUpdatePollInGroup   = @"poll/update";
static NSString * const kForumAPIURLUpdatePhotoInGroup  = @"photo/update";
static NSString * const kForumAPIURLUpdateURLInGroup  = @"url_topic/update";


static NSString * const kForumAPIURLCreateGroup     = @"group/create";
static NSString * const kForumAPIURLJoinGroup       = @"group/subscribe";
static NSString * const kForumAPIURLLeaveGroup      = @"group/unsubscribe";
static NSString * const kForumAPIURLShareGroup      = @"share_group_by_email";
static NSString * const kForumAPIURLGroupInvite     = @"group/invite";
static NSString * const kForumAPIURLIsUserInGroup   = @"group/is_in_group";

static NSString * const kForumAPIURLHotTopics       = @"hot";
static NSString * const kForumAPIURLNewTopics       = @"new";
static NSString * const kForumAPIURLUserFeeds       = @"user_feeds";
static NSString * const kForumAPIURLUserPopularFeeds       = @"user_popular_feeds";
static NSString * const kForumAPIURLUserPopularTopics   = @"user_popular_topics";

static NSString * const kForumAPIURLReplyForNotification         = @"reply_for_notification";
static NSString * const kForumAPIURLRepliesForArticle   = @"article_replies";
static NSString * const kForumAPIURLWelcomeTopicId      = @"get_welcome_topic_id";
static NSString * const kForumAPIURLGlowAccountId      = @"get_glow_account_id";

static NSString * const kForumAPIURLFollow              = @"social/follow";
static NSString * const kForumAPIURLUnfollow            = @"social/unfollow";
static NSString * const kForumAPIURLFetchFollowers      = @"social/followers";
static NSString * const kForumAPIURLFetchFollowings     = @"social/followings";
static NSString * const kForumAPIURLFetchSocialInfo     = @"social/social_info";
static NSString * const kForumAPIURLFetchProfileData     = @"social/profile_data";
static NSString * const kForumAPIURLFetchProfileDataUserSelf     = @"social/profile_data_user_self";

static NSString * const kForumAPIURLFetchQuiz   = @"quiz/fetch";
static NSString * const kForumAPIURLSubmitQuiz  = @"quiz/submit";

@implementation Forum

#pragma mark - ForumDelegate

+ (void)shareTopicWithObject:(id)topicObject {
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(shareTopicWithObject:)]) {
        [f.delegate shareTopicWithObject:topicObject];
    }
}

+ (void)shareGroupWithObject:(id)groupObject {
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(shareGroupWithObject:)]) {
        [f.delegate shareGroupWithObject:groupObject];
    }
}

+ (void)shareQuizResultWithToken:(NSString *)token {
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(shareQuizResultWithToken:)]) {
        [f.delegate shareQuizResultWithToken:token];
    }
}

#pragma mark - ForumNetworkDelegate

+ (NSError *)methodNotImplementedError:(NSDictionary *)info
{
    GLLog(@"Delegate method not implemented: %@", info);
    NSError *error = [NSError errorWithDomain:FORUM_ERROR_DOMAIN code:ForumErrorCodeMethodNotImplemented userInfo:info];
    return error;
}

+ (void)POST:(NSString *)URLString parameters:(NSDictionary *)parameters callback:(ForumAPICallBack)cb {
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(POST:parameters:callback:)]) {
        [f.delegate POST:URLString parameters:parameters callback:cb];
    } else {
        if (cb) {
            cb(nil, [self methodNotImplementedError:@{@"method": NSStringFromSelector(@selector(POST:parameters:callback:))}]);
        }
    }
}

+ (void)POST:(NSString *)URLString parameters:(NSDictionary *)parameters images:(NSDictionary *)images callback:(ForumAPICallBack)cb {
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(POST:parameters:images:callback:)]) {
        [f.delegate POST:URLString parameters:parameters images:images callback:cb];
    } else {
        if (cb) {
            cb(nil, [self methodNotImplementedError:@{@"method": NSStringFromSelector(@selector(POST:parameters:images:callback:))}]);
        }
    }
}

+ (void)GET:(NSString *)URLString parameters:(NSDictionary *)parameters callback:(ForumAPICallBack)cb {
    [self GET:URLString withToken:YES parameters:parameters callback:cb];
}

+ (void)GET:(NSString *)URLString withToken:(BOOL)withToken parameters:(NSDictionary *)parameters callback:(ForumAPICallBack)cb {
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(GET:withToken:parameters:callback:)]) {
        [f.delegate GET:URLString withToken:withToken parameters:parameters callback:cb];
    } else {
        if (cb) {
            cb(nil, [self methodNotImplementedError:@{@"method": NSStringFromSelector(@selector(GET:withToken:parameters:callback:))}]);
        }
    }
}

#pragma mark - APIs

+ (void)createTopicInGroup:(uint64_t)groupId withTitle:(NSString *)title
                   content:(NSString *)content andImages:(NSDictionary *)images
               anonymously:(BOOL)anonymous callback:(ForumAPICallBack)cb
{
    Forum *f = [self sharedInstance];
    [f setCreatedUpdated:YES];
    [f setParticipatedUpdated:YES];
    NSDictionary *params = @{
                             FORUM_KEY_GROUP_ID: @(groupId),
                             FORUM_KEY_TITLE: title ?: @"",
                             FORUM_KEY_CONTENT: content ?: @"",
                             FORUM_KEY_ANONYMOUS: @(anonymous ? 1 : 0),
                             };
    return [self POST:kForumAPIURLCreateTopicInGroup parameters:params images:images callback:cb];
}

+ (void)createPhotoInGroup:(uint64_t)groupId withTitle:(NSString *)title
                    images:(NSDictionary *)images
               anonymously:(BOOL)anonymous warning:(BOOL)warning callback:(ForumAPICallBack)cb
{
    Forum *f = [self sharedInstance];
    [f setCreatedUpdated:YES];
    [f setParticipatedUpdated:YES];
    NSDictionary *params = @{
                             FORUM_KEY_GROUP_ID: @(groupId),
                             FORUM_KEY_TITLE: title ?: @"",
                             FORUM_KEY_ANONYMOUS: @(anonymous ? 1 : 0),
                             FORUM_KEY_WARNING: @(warning ? 1 : 0),
                             };
    return [self POST:kForumAPIURLCreatePhotoInGroup parameters:params images:images callback:cb];
}
+ (void)createURLInGroup:(uint64_t)groupId
               withTitle:(NSString *)title
                     url:(NSString *)url
                urlTitle:(NSString *)urlTitle
             urlAbstract:(NSString *)urlAbstract
               thumbnail:(NSString *)thumb
                callback:(ForumAPICallBack)cb {
    
    Forum *f = [self sharedInstance];
    [f setCreatedUpdated:YES];
    [f setParticipatedUpdated:YES];
    NSDictionary *params = @{
                             FORUM_KEY_GROUP_ID: @(groupId),
                             FORUM_KEY_TITLE: title ?: @"",
                             FORUM_KEY_URL_PATH: url?: @"",
                             FORUM_KEY_URL_ABSTRACT: urlAbstract?: @"",
                             FORUM_KEY_URL_TITLE: urlTitle?:@"",
                             FORUM_KEY_THUMBNAIL_URL: thumb?:@"",
                             };
    return [self POST:kForumAPIURLCreateURLInGroup parameters:params callback:cb];
}

+ (void)createPollInGroup:(uint64_t)groupId withTitle:(NSString *)title
                  options:(NSArray *)options content:(NSString *)content
                andImages:(NSDictionary *)images anonymously:(BOOL)anonymous
                 callback:(ForumAPICallBack)cb
{
    Forum *f = [self sharedInstance];
    [f setCreatedUpdated:YES];
    [f setParticipatedUpdated:YES];
    NSString *optionString = [NSString jsonStringify:options];
    NSDictionary *params = @{
                             FORUM_KEY_GROUP_ID: @(groupId),
                             FORUM_KEY_TITLE: title ?: @"",
                             FORUM_KEY_CONTENT: content ?: @"",
                             FORUM_KEY_OPTIONS: optionString ?: @"",
                             FORUM_KEY_ANONYMOUS: @(anonymous ? 1 : 0),
                             };
    return [self POST:kForumAPIURLCreatePollInGroup parameters:params images:images callback:cb];
}


+ (void)updateTopic:(uint64_t)topicId inGroup:(uint64_t)groupId withTitle:(NSString *)title
            content:(NSString *)content andImages:(NSDictionary *)images
        anonymously:(BOOL)anonymous callback:(ForumAPICallBack)cb {
    Forum *f = [self sharedInstance];
    [f setCreatedUpdated:YES];
    [f setParticipatedUpdated:YES];
    NSMutableDictionary *md = [@{
                                 FORUM_KEY_TOPIC_ID: @(topicId),
                                 FORUM_KEY_ANONYMOUS: @(anonymous ? 1 : 0),
                                 } mutableCopy];
    if (groupId > 0) {
        md[FORUM_KEY_GROUP_ID] = @(groupId);
    }
    if ([NSString isNotEmptyString:title]) {
        md[FORUM_KEY_TITLE] = title;
    }
    if ([NSString isNotEmptyString:content]) {
        md[FORUM_KEY_CONTENT] = content;
    }

    return [self POST:kForumAPIURLUpdateTopicInGroup parameters:md images:images callback:cb];
}

+ (void)updatePoll:(uint64_t)topicId inGroup:(uint64_t)groupId withTitle:(NSString *)title
           options:(NSArray *)options content:(NSString *)content
         andImages:(NSDictionary *)images anonymously:(BOOL)anonymous
          callback:(ForumAPICallBack)cb {
    Forum *f = [self sharedInstance];
    [f setCreatedUpdated:YES];
    [f setParticipatedUpdated:YES];
    NSMutableDictionary *md = [@{
                                 FORUM_KEY_TOPIC_ID: @(topicId),
                                 FORUM_KEY_ANONYMOUS: @(anonymous ? 1 : 0),
                                 } mutableCopy];
    if (groupId > 0) {
        md[FORUM_KEY_GROUP_ID] = @(groupId);
    }
    if ([NSString isNotEmptyString:title]) {
        md[FORUM_KEY_TITLE] = title;
    }
    if ([NSString isNotEmptyString:content]) {
        md[FORUM_KEY_CONTENT] = content;
    }
    if (options && options.count > 0) {
        NSString *optionString = [NSString jsonStringify:options];
        md[FORUM_KEY_OPTIONS] = optionString ?: @"";
        
    }

    return [self POST:kForumAPIURLUpdatePollInGroup parameters:md images:images callback:cb];
 
}

+ (void)updatePhoto:(uint64_t)topicId inGroup:(uint64_t)groupId withTitle:(NSString *)title
             images:(NSDictionary *)images
        anonymously:(BOOL)anonymous warning:(BOOL)warning callback:(ForumAPICallBack)cb {
    Forum *f = [self sharedInstance];
    [f setCreatedUpdated:YES];
    [f setParticipatedUpdated:YES];
    NSMutableDictionary *md = [@{
                                 FORUM_KEY_TOPIC_ID: @(topicId),
                                 FORUM_KEY_ANONYMOUS: @(anonymous ? 1 : 0),
                                 FORUM_KEY_WARNING: @(warning ? 1 : 0),
                                 } mutableCopy];
    if (groupId > 0) {
        md[FORUM_KEY_GROUP_ID] = @(groupId);
    }
    if ([NSString isNotEmptyString:title]) {
        md[FORUM_KEY_TITLE] = title;
    }

    return [self POST:kForumAPIURLUpdatePhotoInGroup parameters:md images:images callback:cb];
}

+ (void)updateURL:(uint64_t)topicId inGroup:(uint64_t)groupId
        withTitle:(NSString *)title
              url:(NSString *)url
         urlTitle:(NSString *)urlTitle
      urlAbstract:(NSString *)urlAbstract
        thumbnail:(NSString *)thumb
         callback:(ForumAPICallBack)cb {
    Forum *f = [self sharedInstance];
    [f setCreatedUpdated:YES];
    [f setParticipatedUpdated:YES];
    NSMutableDictionary *md = [@{
                                 FORUM_KEY_TOPIC_ID: @(topicId),
                                 } mutableCopy];
    if (groupId > 0) {
        md[FORUM_KEY_GROUP_ID] = @(groupId);
    }
    if ([NSString isNotEmptyString:title]) {
        md[FORUM_KEY_TITLE] = title;
    }
    if ([NSString isNotEmptyString:url]) {
        md[FORUM_KEY_URL_PATH] = url;
    }
    if ([NSString isNotEmptyString:urlAbstract]) {
        md[FORUM_KEY_URL_ABSTRACT] = urlAbstract;
    }
    if ([NSString isNotEmptyString:urlTitle]) {
        md[FORUM_KEY_URL_TITLE] = urlTitle;
    }
    if ([NSString isNotEmptyString:thumb]) {
        md[FORUM_KEY_THUMBNAIL_URL] = thumb;
    }

    return [self POST:kForumAPIURLUpdateURLInGroup parameters:md callback:cb];
 
}


+ (void)createReplyToTopic:(uint64_t)topicId withContent:(NSString *)content andImages:(NSDictionary *)images anonymously:(BOOL)anonymous callback:(ForumAPICallBack)cb
{
    [self createReplyToReply:0 inTopic:topicId withContent:content andImages:images anonymously:anonymous callback:cb];
}

+ (void)createReplyToReply:(uint64_t)replyId inTopic:(uint64_t)topicId withContent:(NSString *)content andImages:(NSDictionary *)images anonymously:(BOOL)anonymous callback:(ForumAPICallBack)cb
{
    Forum *f = [self sharedInstance];
    [f setParticipatedUpdated:YES];
    NSDictionary *params = @{
                             FORUM_KEY_TOPIC_ID: @(topicId),
                             FORUM_KEY_REPLY_TO: @(replyId),
                             FORUM_KEY_CONTENT: content ?: @"",
                             FORUM_KEY_ANONYMOUS: @(anonymous ? 1 : 0),
                             };
    return [self POST:kForumAPIURLCreateReply parameters:params images:images callback:cb];
}

+ (void)fetchTopicsForType:(ForumGroupType)type lastReplyTime:(unsigned int)lastReplyTime callback:(ForumAPICallBack)cb
{
    NSString *URLString = nil;
    switch (type) {
        case ForumGroupParticipated:
            URLString = kForumAPIURLParticipated;
            break;
        case ForumGroupCreated:
            URLString = kForumAPIURLCreated;
            break;
        case ForumGroupBookmarked:
        default:
            URLString = kForumAPIURLBookmarked;
            break;
    }
    if (lastReplyTime > 0) {
        URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", lastReplyTime]];
    }
    return [self GET:URLString parameters:nil callback:cb];
}

+ (void)fetchReplyForNotification:(uint64_t)replyID callback:(ForumAPICallBack)callback
{
    NSString *URLString = kForumAPIURLReplyForNotification;
    URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%llu", replyID]];
    return [self GET:URLString parameters:nil callback:callback];
}

+ (void)fetchRepliesForTopic:(uint64_t)topicId offset:(NSUInteger)offset callback:(ForumAPICallBack)cb
{
    NSString *URLString = kForumAPIURLReplies;
    URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%llu", topicId]];
    if (offset > 0) {
        URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu", offset]];
    }
    return [self GET:URLString parameters:nil callback:cb];
}

+ (void)fetchRepliesForArticle:(uint64_t)articleId lastReplyTime:(unsigned int)lastReplyTime callback:(ForumAPICallBack)cb
{
    NSString *URLString = kForumAPIURLRepliesForArticle;
    URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%llu", articleId]];
    if (lastReplyTime > 0) {
        URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", lastReplyTime]];
    }
    return [self GET:URLString parameters:nil callback:cb];
}

+ (void)fetchRepliesToReply:(uint64_t)replyId lastReplyTime:(unsigned int)lastReplyTime callback:(ForumAPICallBack)cb
{
    NSString *URLString = kForumAPIURLSubReplies;
    URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%llu", replyId]];
    if (lastReplyTime > 0) {
        URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", lastReplyTime]];
    }
    return [self GET:URLString parameters:nil callback:cb];
}

+ (void)markTopic:(uint64_t)topicId bookmarked:(BOOL)bookmarked callback:(ForumAPICallBack)cb
{
    Forum *f = [self sharedInstance];
    [f setBookmarkedUpdated:YES];
    [[Forum sharedInstance] setBookmarkedUpdated:YES];
    NSString *URLString = kForumAPIURLCreateBookmark;
    URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%llu", topicId]];
    URLString = [URLString stringByAppendingPathComponent:bookmarked ? @"1" : @"0"];
    return [self POST:URLString parameters:nil callback:cb];
}

+ (void)markTopic:(uint64_t)topicId liked:(BOOL)liked callback:(ForumAPICallBack)cb
{
    NSString *URLString = kForumAPIURLLike;
    URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%llu", topicId]];
    URLString = [URLString stringByAppendingPathComponent:liked ? @"1" : @"0"];
    return [self POST:URLString parameters:nil callback:cb];
}

+ (void)markTopic:(uint64_t)topicId disliked:(BOOL)disliked callback:(ForumAPICallBack)cb
{
    NSString *URLString = kForumAPIURLDislike;
    URLString = [URLString stringByAppendingPathComponent:[NSString stringWithFormat:@"%llu", topicId]];
    URLString = [URLString stringByAppendingPathComponent:disliked ? @"1" : @"0"];
    return [self POST:URLString parameters:nil callback:cb];
}

+ (void)markTopic:(uint64_t)topicId flagged:(BOOL)flagged reason:(NSString *)reason callback:(ForumAPICallBack)cb
{
    NSDictionary *params = @{FORUM_KEY_TOPIC_ID: @(topicId),
                             FORUM_KEY_FLAGGED: @(flagged),
                             FORUM_KEY_REASON: reason};
    return [self POST:kForumAPIURLFlagPost parameters:params callback:cb];
}

+ (void)markReply:(uint64_t)topicId replyId:(uint64_t)replyId liked:(BOOL)liked callback:(ForumAPICallBack)cb {
    NSDictionary *params = @{FORUM_KEY_TOPIC_ID: @(topicId),
                             FORUM_KEY_REPLY_ID: @(replyId),
                             FORUM_KEY_LIKED: @(liked ? 1 : 0)};
    return [self POST:kForumAPIURLLikeReply parameters:params callback:cb];
}

+ (void)markReply:(uint64_t)topicId replyId:(uint64_t)replyId disliked:(BOOL)disliked callback:(ForumAPICallBack)cb {
    NSDictionary *params = @{FORUM_KEY_TOPIC_ID: @(topicId),
                             FORUM_KEY_REPLY_ID: @(replyId),
                             FORUM_KEY_DISLIKED: @(disliked ? 1 : 0)};
    return [self POST:kForumAPIURLDislikeReply parameters:params callback:cb];
}

+ (void)markReply:(uint64_t)topicId replyId:(uint64_t)replyId flagged:(BOOL)flagged reason:(NSString *)reason callback:(ForumAPICallBack)cb
{
    NSDictionary *params = @{FORUM_KEY_TOPIC_ID: @(topicId),
                             FORUM_KEY_REPLY_ID: @(replyId),
                             FORUM_KEY_FLAGGED: @(flagged),
                             FORUM_KEY_REASON: reason};
    return [self POST:kForumAPIURLFlagReply parameters:params callback:cb];
}

+ (void)searchTopicWithKeyword:(NSString *)keyword offset:(NSUInteger)offset callback:(ForumAPICallBack)cb
{
    NSDictionary *params = @{FORUM_KEY_KEYWORD: (keyword ?: @""), FORUM_KEY_OFFSET: @(offset)};
    return [self GET:kForumAPIURLSearchTopic parameters:params callback:cb];
}

+ (void)searchReplyWithKeyword:(NSString *)keyword offset:(NSUInteger)offset callback:(ForumAPICallBack)cb
{
    NSDictionary *params = @{FORUM_KEY_KEYWORD: (keyword ?: @""), FORUM_KEY_OFFSET: @(offset)};
    return [self GET:kForumAPIURLSearchReply parameters:params callback:cb];
}

+ (void)votePoll:(uint64_t)topicId atOption:(int)optionIndex callback:(ForumAPICallBack)cb {
    Forum *f = [self sharedInstance];
    [f setParticipatedUpdated:YES];
    NSDictionary *params = @{FORUM_KEY_TOPIC_ID: @(topicId),
                             FORUM_KEY_VOTE_INDEX: @(optionIndex)};
    return [self POST:kForumAPIURLVotePoll parameters:params callback:cb];
}

+ (void)fetchDailyTopic:(uint64_t)topicId callback:(ForumAPICallBack)cb {
    NSDictionary *params = @{FORUM_KEY_TOPIC_ID: @(topicId)};
    return [self POST:kForumAPIURLDailyTopic parameters:params callback:cb];
}

+ (void)removeReply:(uint64_t)replyId callback:(ForumAPICallBack)cb {
    NSDictionary *params = @{FORUM_KEY_REPLY_ID: @(replyId)};
    return [self POST:kForumAPIURLRemoveReply parameters:params callback:cb];
}

+ (void)fetchQuizWithTopicId:(uint64_t)topicId quizId:(int)quizId sourceToken:(NSString *)sourceToken myToken:(NSString *)myToken callback:(ForumAPICallBack)cb;
{
    NSDictionary *params = @{
        FORUM_KEY_TOPIC_ID: @(topicId),
        FORUM_KEY_QUIZ_ID: @(quizId),
        FORUM_KEY_SOURCE_TOKEN: sourceToken ?: @"",
        FORUM_KEY_MY_TOKEN: myToken ?: @"",
    };
    return [self GET:kForumAPIURLFetchQuiz withToken:NO parameters:params callback:cb];
}

+ (void)submitQuizWithQuizId:(int)quizId sourceToken:(NSString *)sourceToken selectedOptions:(NSDictionary *)selectedOptions generation:(int)generation callback:(ForumAPICallBack)cb
{
    NSDictionary *params = @{
        FORUM_KEY_QUIZ_ID: @(quizId),
        FORUM_KEY_SOURCE_TOKEN: sourceToken ?: @"",
        FORUM_KEY_SELECTED_OPTIONS: selectedOptions ?: @{},
        FORUM_KEY_GENERATION: @(generation),
    };
    return [self POST:kForumAPIURLSubmitQuiz parameters:params callback:cb];
}

#pragma mark - SharedInsatnce

+ (Forum *)sharedInstance
{
    static Forum *sForum = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sForum = [[Forum alloc] init];
    });
    [sForum setup];
    return sForum;
}

+ (UIStoryboard *)storyboard
{
    return [UIStoryboard storyboardWithName:@"Community" bundle:nil];
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)setup
{
    if (!self.subscribedGroupIds) {
        _subscribedGroupIds = [NSMutableSet set];
    }
    if (!self.cidToCategories) {
        _cidToCategories = [@{} mutableCopy];
    }
    
}

- (void)dealloc
{
    [self unsubscribeAll];
}

- (void)onLogout
{
    _categories = nil;
    _subscribedGroups = nil;
    _recommendedGroups = nil;
    _subscribedGroupIds = nil;
    _cidToCategories = nil;
}

- (NSArray *)subscribedGroups {
    return _subscribedGroups;
}

- (NSArray *)recommendedGroups {
    return _recommendedGroups;
}

+ (NSArray *)flagReasonsIsTopic:(BOOL)isTopic
{
    if (isTopic) {
        return @[@"Wrong group", @"Rude", @"Obscene", @"Spam", @"Solicitation", @"Other"];
    } else {
        return @[@"Rude", @"Obscene", @"Spam", @"Solicitation", @"Other"];
    }
}

- (NSArray *)categories
{
    if (!_categories) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = [paths firstObject];
        NSString *filePath = [cachesDirectory stringByAppendingPathComponent:@"forum_categories.json"];
        BOOL cacheExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        if (cacheExists) {
            NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
            [self parseCategoriesJSONData:jsonData];
        }
        if (0 == _categories.count) {
            if (cacheExists) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
            }
            filePath = [[NSBundle mainBundle] pathForResource:@"forum_categories" ofType:@"json"];
            NSData *jsonData = [NSData dataWithContentsOfFile:filePath];
            [self parseCategoriesJSONData:jsonData];
        }
    }
    return _categories;
}

- (ForumCategory *)successStoriesCategory
{
    for (ForumCategory *category in self.categories) {
        if (category.identifier == FORUM_CATEGORY_ID_SUCCESS_STORIES) {
            return category;
        }
    }
    // The worst thing happend, there's no success stories category in cache, create a dummy one
    ForumCategory *category = [[ForumCategory alloc] init];
    category.identifier = FORUM_CATEGORY_ID_SUCCESS_STORIES;
    return category;
}

- (void)parseCategoriesJSONData:(NSData *)jsonData
{
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:NULL];
    [self parseCategoriesJSONDictionary:dict];
}

- (void)parseCategoriesJSONDictionary:(NSDictionary *)dict
{
    NSArray *dataArray = [dict objectForKey:@"categories"];
    NSNumber *versionNumber = [dict objectForKey:@"version"];
    if ([dataArray isKindOfClass:[NSArray class]]) {
        NSMutableArray *tmpCategories = [NSMutableArray arrayWithCapacity:dataArray.count];
        for (NSDictionary *dict in dataArray) {
            ForumCategory *category = [[ForumCategory alloc] initWithDictionary:dict];
            [tmpCategories addObject:category];
        }
        _categories = tmpCategories;
        if ([versionNumber isKindOfClass:[NSNumber class]]) {
            _version = [versionNumber floatValue];
        }
        [self addPseudoCategories];
    }
}

- (void)addPseudoCategories
{
    ForumCategory *category = [ForumCategory bookmarkCategory];
    if ([_categories indexOfObject:category] == NSNotFound) {
        [_categories addObject:category];
    }
}

- (BOOL)saveCategoriesCache:(NSDictionary *)dict
{
    [self parseCategoriesJSONDictionary:dict];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths firstObject];
    NSString *filePath = [cachesDirectory stringByAppendingPathComponent:@"forum_categories.json"];
    return [jsonData writeToFile:filePath atomically:YES];
}

# pragma mark - Groups
+ (BOOL)isSubscribedGroup:(ForumGroup *)group
{
    return [[self sharedInstance].subscribedGroupIds containsObject:@(group.identifier)];
}

+ (BOOL)isSubscribedGroupId:(uint64_t)groupId
{
    return [[self sharedInstance].subscribedGroupIds containsObject:@(groupId)];
}

+ (void)unsubscribeGroup:(uint64_t)groupId
{
    Forum *forum = [Forum sharedInstance];
    forum.subscribedGroups = [[forum.subscribedGroups
                               filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:
                                                            @"(identifier != %llu)", groupId]] mutableCopy];
    [forum.subscribedGroupIds removeAllObjects];
    for (ForumGroup *group in [Forum sharedInstance].subscribedGroups) {
        [forum.subscribedGroupIds addObject:@(group.identifier)];
    }
}

+ (ForumCategory *)categoryFromGroup:(ForumGroup *)group
{
    if (group.isBookmark) {
        return [ForumCategory bookmarkCategory];
    }
    ForumCategory *result = [Forum sharedInstance].cidToCategories[@(group.categoryId)];
    
    return result ? result : [ForumCategory defaultCategory];
}

+ (void)fetchPrerequisiteForCreatingGroupCallback:(ForumAPICallBack)cb
{
    @weakify(self)
    return [self GET:kForumAPIURLPrerequisite parameters:nil callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}

+ (void)fetchGroupsPageCallback:(ForumAPICallBack)cb {
    Forum *f = [self sharedInstance];
    if (f.fetchGroupsPageLocked) {
        return;
    }
    f.fetchGroupsPageLocked = YES;
    @weakify(self)
    return [self GET:kForumAPIURLGroupsPage parameters:nil callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        f.fetchGroupsPageLocked = NO;
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}
+ (void)fetchGroupsSubscribedByUser:(uint64_t)userId callback:(ForumAPICallBack)cb {
    @weakify(self)
    return [self GET:kForumAPIURLGroupsSubscription parameters:@{@"target_user_id": @(userId)} callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}

+ (void)fetchTopicsInGroup:(uint64_t)groupId withOffset:(int)offset
                    orType:(ForumGroupType)type withLastReply:(unsigned int)lastReply
                  callback:(ForumAPICallBack)cb;
{
    if (ForumGroupNormal != type) {
        [self fetchTopicsForType:type lastReplyTime:lastReply callback:cb];
        return;
    }
    
    NSString *url = [NSString stringWithFormat:kForumAPIURLGroupTopics, groupId];
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    @weakify(self)
    return [self GET:url parameters:nil callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}

+ (void)fetchFindGroupsPageCallback:(ForumAPICallBack)cb;
{
    @weakify(self)
    return [self GET:kForumAPIURLFindGroups parameters:nil callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}

+ (void)fetchGroupsInCategory:(uint64_t)categoryId offset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = [NSString stringWithFormat:kForumAPIURLGroupsInCategory, categoryId];
    NSDictionary *params = @{FORUM_KEY_OFFSET: @(offset)};
    @weakify(self)
    return [self GET:url parameters:params callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}

+ (void)createGroupWithName:(NSString *)name categoryId:(uint16_t)categoryId
                       desc:(NSString *)desc photo:(UIImage *)photo callback:(ForumAPICallBack)cb
{
    NSDictionary *params = @{FORUM_KEY_NAME: name,
                             FORUM_KEY_CATEGORY_ID: @(categoryId),
                             FORUM_KEY_DESC: desc};
    @weakify(self)
    return [self POST:kForumAPIURLCreateGroup parameters:params images:photo ? @{@"image": photo} : @{} callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}

+ (void)joinGroup:(uint64_t)groupId callback:(ForumAPICallBack)cb
{
    NSDictionary *params = @{FORUM_KEY_GROUP_ID: @(groupId)};
    @weakify(self)
    return [self POST:kForumAPIURLJoinGroup parameters:params callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}

+ (void)leaveGroup:(uint64_t)groupId callback:(ForumAPICallBack)cb
{
    NSDictionary *params = @{FORUM_KEY_GROUP_ID: @(groupId)};
    @weakify(self)
    return [self POST:kForumAPIURLLeaveGroup parameters:params callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}

+ (void)_processGroupCallback:(ForumAPICallBack)cb withResult:(NSDictionary *)result error:(NSError *)error
{
    [self _checkGroupPageInResult:result];
    if (cb) {
        cb(result, error);
    }
}

+ (void)_checkGroupPageInResult:(NSDictionary *)result
{
    if ([result isKindOfClass:[NSDictionary class]] && result[@"_group_page"]) {
        [self _updateLocalGroupsFromServerData:result[@"_group_page"]];
    }
}

+ (void)_updateLocalGroupsFromServerData:(NSDictionary *)groups
{
    Forum *forum = [Forum sharedInstance];
    NSMutableArray *subGroups = [NSMutableArray array];
    NSMutableArray *recGroups = [NSMutableArray array];
    NSArray *array = groups[@"subscribed"];
    if ([array isKindOfClass:[NSArray class]]) {
        for (NSDictionary *dict in array) {
            ForumGroup *group = [[ForumGroup alloc] initWithDictionary:dict];
            if (group) {
                [subGroups addObject:group];
            }
        }
    }
    forum.subscribedGroups = [NSArray arrayWithArray:subGroups];
    array = groups[@"recommended"];
    if ([array isKindOfClass:[NSArray class]]) {
        for (NSDictionary *dict in array) {
            ForumGroup *group = [[ForumGroup alloc] initWithDictionary:dict];
            if (group) {
                [recGroups addObject:group];
            }
        }
    }
    forum.recommendedGroups = [NSArray arrayWithArray:recGroups];
    [forum.subscribedGroupIds removeAllObjects];
    for (ForumGroup *group in forum.subscribedGroups) {
        [forum.subscribedGroupIds addObject:@(group.identifier)];
    }
    [forum.cidToCategories removeAllObjects];
    for (NSDictionary *category in groups[@"categories"]) {
        forum.cidToCategories[category[@"id"]] =
        [[ForumCategory alloc] initWithDictionary:category];
    }
    forum.groupPageDataUpdated = YES;
    [forum publish:EVENT_FORUM_GROUP_SUBSCRIPTION_UPDATED];
}

+ (void)inviteUser:(uint64_t)uid toGroup:(uint64_t)groupId message:(NSString *)message
{
    NSDictionary *params = @{FORUM_KEY_GROUP_ID: @(groupId),
                             FORUM_KEY_INVITEE_ID: @(uid),
                             FORUM_KEY_MESSAGE: message};
    return [self POST:kForumAPIURLGroupInvite parameters:params callback:nil];
}

+ (void)isUser:(uint64_t)uid alreadyInGroup:(uint64_t)groupId callback:(ForumAPICallBack)cb
{
    NSDictionary *params = @{FORUM_KEY_GROUP_ID: @(groupId),
                             FORUM_KEY_INVITEE_ID: @(uid)};
    return [self GET:kForumAPIURLIsUserInGroup parameters:params callback:cb];
}

+ (NSString *)_groupOrderKeyForCurrentUser
{
    return catstr(DEFAULTS_GROUP_ORDER_PRE, [NSString stringWithFormat:@"%llu", [[self currentForumUser] identifier]], nil);
}

+ (void)saveOrderWith:(NSArray *)subscribed
{
    NSMutableArray *orderedId = [@[] mutableCopy];
    for (ForumGroup *group in subscribed) {
        [orderedId addObject:@(group.identifier)];
    }
    NSString *defaultsKey = [self _groupOrderKeyForCurrentUser];
    [GLUtils setDefaultsForKey:defaultsKey withValue:orderedId];
    [[Forum sharedInstance] publish:EVENT_FORUM_GROUP_LOCAL_SUBSCRIPTION_UPDATED];
}

+ (NSArray *)reorderGroups:(NSArray *)unorderedGroups
{
    NSString *defaultsKey = [self _groupOrderKeyForCurrentUser];
    NSArray *orderedId = (NSArray*)[GLUtils getDefaultsForKey:defaultsKey];
    if (!orderedId) {
        return unorderedGroups;
    }

    NSMutableArray *reordered = [@[] mutableCopy];
    NSMutableArray *mutableUnordered = [unorderedGroups mutableCopy];
    for (NSNumber *oid in orderedId) {
        NSPredicate *predicator = [NSPredicate predicateWithFormat:
            @"identifier == %@", oid];
        NSArray *existing = [unorderedGroups filteredArrayUsingPredicate:
            predicator];
        if (existing.count > 0) {
            [reordered addObject:existing[0]];
            [mutableUnordered removeObject:existing[0]];
        }
    }
    for (ForumGroup *group in mutableUnordered) {
        [reordered addObject:group];
    }
    return [NSArray arrayWithArray:reordered];
}

+ (void)fetchHotTopicsOffset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = kForumAPIURLHotTopics;
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    @weakify(self)
    return [self GET:url parameters:nil callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}

+ (void)fetchNewTopicsOffset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = kForumAPIURLNewTopics;
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    @weakify(self)
    return [self GET:url parameters:nil callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self _processGroupCallback:cb withResult:result error:error];
    }];
}

+ (void)fetchWelcomeTopicIdWithCallback:(ForumAPICallBack)cb
{
    return [self GET:kForumAPIURLWelcomeTopicId parameters:nil callback:cb];
}

+ (void)fetchFeedsForUser:(uint64_t)target_uid offset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = kForumAPIURLUserFeeds;
    if (offset > 0) {
        url = [kForumAPIURLUserFeeds stringByAppendingFormat:@"/%u", offset];
    }
    
    NSDictionary *params = @{FORUM_KEY_TARGET_UID: @(target_uid)};
    return [self GET:url parameters:params callback:cb];
}

+ (void)fetchPopularFeedsForUser:(uint64_t)target_uid offset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = kForumAPIURLUserPopularFeeds;
    if (offset > 0) {
        url = [kForumAPIURLUserPopularFeeds stringByAppendingFormat:@"/%u", offset];
    }
    
    NSDictionary *params = @{FORUM_KEY_TARGET_UID: @(target_uid)};
    return [self GET:url parameters:params callback:cb];
}

+ (void)fetchPopularTopicsForUser:(uint64_t)target_uid offset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = kForumAPIURLUserPopularTopics;
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    
    NSDictionary *params = @{FORUM_KEY_TARGET_UID: @(target_uid)};
    return [self GET:url parameters:params callback:cb];
}

+ (void)followUser:(uint64_t)target_uid callback:(ForumAPICallBack)cb
{
    NSString *url = kForumAPIURLFollow;
    NSDictionary *parameters = @{FORUM_KEY_TARGET_UID: @(target_uid)};
    [self POST:url parameters:parameters callback:cb];
}


+ (void)unfollowUser:(uint64_t)target_uid callback:(ForumAPICallBack)cb
{
    NSString *url = kForumAPIURLUnfollow;
    NSDictionary *parameters = @{FORUM_KEY_TARGET_UID: @(target_uid)};
    [self POST:url parameters:parameters callback:cb];
}


+ (void)fetchFollowersForUser:(uint64_t)target_uid withOffset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = kForumAPIURLFetchFollowers;
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    
    NSDictionary *params = @{FORUM_KEY_TARGET_UID: @(target_uid)};
    [self GET:url parameters:params callback:cb];
}


+ (void)fetchFollowingsForUser:(uint64_t)target_uid withOffset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = kForumAPIURLFetchFollowings;
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    
    NSDictionary *params = @{FORUM_KEY_TARGET_UID: @(target_uid)};
    [self GET:url parameters:params callback:cb];
}


+ (void)fetchSocialInfoForUser:(uint64_t)target_uid callback:(ForumAPICallBack)cb
{
    NSString *url = kForumAPIURLFetchSocialInfo;
    NSDictionary *params = @{FORUM_KEY_TARGET_UID: @(target_uid)};
    [self GET:url parameters:params callback:cb];
}


+ (void)fetchProfileDataForUser:(uint64_t)target_uid callback:(ForumAPICallBack)cb
{
    if (target_uid == [Forum currentForumUser].identifier) {
        NSString *url = kForumAPIURLFetchProfileDataUserSelf;
        [self GET:url parameters:@{} callback:cb];
    }
    else {
        NSString *url = kForumAPIURLFetchProfileData;
        NSDictionary *params = @{FORUM_KEY_TARGET_UID: @(target_uid)};
        [self GET:url parameters:params callback:cb];
    }
}


+ (void)fetchGlowAccountID:(ForumAPICallBack)cb
{
    return [self GET:kForumAPIURLGlowAccountId parameters:@{} callback:cb];
}


#pragma mark - Misc delegate methods

+ (ForumUser *)currentForumUser
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(currentForumUser)]) {
        return [f.delegate currentForumUser];
    }
    return nil;
}

+ (BOOL)isLoggedIn {
    ForumUser *u = [Forum currentForumUser];
    return (u != nil && !u.isGuest);
}

+ (void)actionRequiresLogin {
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(actionRequiresLogin)]) {
        [f.delegate actionRequiresLogin];
    }
}

+ (void)log:(NSString *)eventName eventData:(NSDictionary *)eventData
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(log:eventData:)]) {
        [f.delegate log:eventName eventData:eventData];
    }
}

+ (void)log:(NSString *)eventName
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(log:)]) {
        [f.delegate log:eventName];
    }
}

+ (NSString *)replaceTermLinksInHtml:(NSString *)html caseSensitive:(BOOL)caseSensitive
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(replaceTermLinksInHtml:caseSensitive:)]) {
        return [f.delegate replaceTermLinksInHtml:html caseSensitive:caseSensitive];
    }
    return html;
}

+ (UIViewController *)emailContactViewControllerWithCallback:(ForumEmailContactCallback)cb
{
    return [self emailContactViewControllerWithBackTitle:nil callback:cb];
}

+ (UIViewController *)emailContactViewControllerWithBackTitle:(NSString *)backTitle callback:(ForumEmailContactCallback)cb
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(emailContactViewControllerWithBackTitle:callback:)]) {
        return [f.delegate emailContactViewControllerWithBackTitle:backTitle callback:cb];
    }
    return nil;
}

+ (void)updateUserProfile:(ForumUser *)newUser
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(updateUserProfile:)]) {
        [f.delegate updateUserProfile:newUser];
    }
}

+ (void)updateProfileImage:(UIImage *)profileImage
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(updateProfileImage:)]) {
        [f.delegate updateProfileImage:profileImage];
    }
}

+ (void)updateBackgroundImage:(UIImage *)backgroundImage
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(updateBackgroundImage:)]) {
        [f.delegate updateBackgroundImage:backgroundImage];
    }
}

+ (void)restoreBackgroundImage
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(restoreBackgroundImage)]) {
        [f.delegate restoreBackgroundImage];
    }
}

+ (UIImage *)defaultBackgroundImage
{
    Forum *f = [self sharedInstance];
    UIImage *defaultBackgroundImage = nil;
    if ([f.delegate respondsToSelector:@selector(defaultBackgroundImage)]) {
        defaultBackgroundImage = [f.delegate defaultBackgroundImage];
    }
    return defaultBackgroundImage;
}

+ (void)toggleLikedTopic:(ForumTopic *)topic liked:(BOOL)liked
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(toggleLikedTopic:liked:)]) {
        [f.delegate toggleLikedTopic:topic liked:liked];
    }
}

+ (void)tip:(NSString *)tip
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(tip:)]) {
        [f.delegate tip:tip];
    }
}

+ (UIImage *)bannerImageForWelcomeDialog {
    Forum *f = [self sharedInstance];
    UIImage *banner = nil;
    if ([f.delegate respondsToSelector:@selector(bannerImageForWelcomeDialog)]) {
        banner = [f.delegate bannerImageForWelcomeDialog];
    }
    if (!banner) {
        ForumUser *user = [Forum currentForumUser];
        if ([user isMale]) {
            banner = [UIImage imageNamed:@"gl-community-welcome-male.jpg"];
        } else {
            banner = [UIImage imageNamed:@"gl-community-welcome"];
        }
    }
    return banner;
}

+ (NSString *)textForWelcomeDialog {
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(textForWelcomeDialog)]) {
        return [f.delegate textForWelcomeDialog];
    }
    return [NSString stringWithFormat:@"%@\n\n%@", [self text1ForWelcomeDialog], [self text2ForWelcomeDialog]];
}

+ (NSString *)text1ForWelcomeDialog
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(text1ForWelcomeDialog)]) {
        return [f.delegate text1ForWelcomeDialog];
    }
    return @"**Glow Community** is the most supportive place for topics such as health, lifestyle, sex, relationships, TTC, parenting, and more!";
}

+ (NSString *)text2ForWelcomeDialog
{
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(text2ForWelcomeDialog)]) {
        return [f.delegate text2ForWelcomeDialog];
    }
    return @"To help you get started, we automatically enrolled you into these groups: **General Health, General Sex & Relationships, Birth Control, Glow Support**, etc";
}

+ (NSString *)keyForHideTopic:(uint64_t)topicId
{
    ForumUser *user = [Forum currentForumUser];
    return [NSString stringWithFormat:@"%@_%llu_%llu", DEFAULTS_HIDE_TOPIC_PRE, user.identifier, topicId];
}

+ (BOOL)isTopicHidden:(uint64_t)topicId
{
    NSString *key = [self keyForHideTopic:topicId];
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

+ (void)hideTopic:(uint64_t)topicId
{
    [self setTopic:topicId hidden:YES];
}

+ (void)flagTopic:(uint64_t)topicId withReason:(NSString *)reason
{
    [self markTopic:topicId flagged:YES reason:reason callback:^(NSDictionary *result, NSError *error) {
        [JDStatusBarNotification showWithStatus:@"Reported!" dismissAfter:2.0 styleName:GLStatusBarStyleSuccess];
    }];
}

+ (void)reportTopic:(uint64_t)topicId
{
    UIActionSheet *as = [UIActionSheet bk_actionSheetWithTitle:@"Please select the reason why you are flagging this topic"];
    for (NSString *title in [Forum flagReasonsIsTopic:YES]) {
        [as bk_addButtonWithTitle:title handler:^{
            if ([title isEqualToString:@"Other"]) {
                UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:nil message:@"Please tell us why you are flagging this topic"];
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                @weakify(alert)
                [alert bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
                [alert bk_addButtonWithTitle:@"Flag" handler:^{
                    @strongify(alert)
                    NSString *reason = [[alert textFieldAtIndex:0] text];
                    [self flagTopic:topicId withReason:reason];
                }];
                [alert show];
            } else {
                [self flagTopic:topicId withReason:title];
            }
        }];
    }
    [as bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
    [as showInView:[[UIApplication sharedApplication] keyWindow]];
}

+ (void)flagReply:(uint64_t)replyId ofTopic:(uint64_t)topicId withReason:(NSString *)reason
{
    [self markReply:topicId replyId:replyId flagged:YES reason:reason callback:^(NSDictionary *result, NSError *error) {
        [JDStatusBarNotification showWithStatus:@"Reported!" dismissAfter:2.0 styleName:GLStatusBarStyleSuccess];
    }];
}

+ (void)reportReply:(uint64_t)replyId ofTopic:(uint64_t)topicId
{
    UIActionSheet *as = [UIActionSheet bk_actionSheetWithTitle:@"Please select the reason why you are flagging this reply"];
    for (NSString *title in [Forum flagReasonsIsTopic:NO]) {
        [as bk_addButtonWithTitle:title handler:^{
            if ([title isEqualToString:@"Other"]) {
                UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:nil message:@"Please tell us why you are flagging this reply"];
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                @weakify(alert)
                [alert bk_addButtonWithTitle:@"Flag" handler:^{
                    @strongify(alert)
                    NSString *reason = [[alert textFieldAtIndex:0] text];
                    [self flagReply:replyId ofTopic:topicId withReason:reason];
                }];
                [alert bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
                [alert show];
            } else {
                [self flagReply:replyId ofTopic:topicId withReason:title];
            }
        }];
    }
    [as bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
    [as showInView:[[UIApplication sharedApplication] keyWindow]];
}

+ (void)setTopic:(uint64_t)topicId hidden:(BOOL)hidden
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *key = [self keyForHideTopic:topicId];
    [ud setBool:hidden forKey:key];
    [ud synchronize];
}

+ (NSString *)keyForHideReply:(uint64_t)replyId
{
    ForumUser *user = [Forum currentForumUser];
    return [NSString stringWithFormat:@"%@_%llu_%llu", DEFAULTS_HIDE_REPLY_PRE, user.identifier, replyId];
}

+ (BOOL)isReplyHidden:(uint64_t)replyId
{
    NSString *key = [self keyForHideReply:replyId];
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

+ (void)hideReply:(uint64_t)replyId
{
    [self setReply:replyId hidden:YES];
}

+ (void)setReply:(uint64_t)replyId hidden:(BOOL)hidden
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *key = [self keyForHideReply:replyId];
    [ud setBool:hidden forKey:key];
    [ud synchronize];
}

+ (BOOL)needsShowMyGruopsPopup
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_NEEDS_SHOW_MY_GROUPS_POPUP] && [Forum isLoggedIn];
}

+ (void)setNeedsShowMyGroupsPopup:(BOOL)needs
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:needs forKey:DEFAULTS_NEEDS_SHOW_MY_GROUPS_POPUP];
    [ud synchronize];
}

+ (NSString *)keyForSelectedAgeRanges
{
    ForumUser *user = [Forum currentForumUser];
    return [NSString stringWithFormat:@"%@_%llu", DEFAULTS_SELECTED_AGE_RANGES, user.identifier];
}

static NSArray *_selectedAgeRangeIndexes = nil;

+ (NSArray *)selectedAgeRangeIndexes
{
    if (!_selectedAgeRangeIndexes) {
        NSString *key = [self keyForSelectedAgeRanges];
        NSArray *indexes = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        NSMutableArray *tmp = [NSMutableArray array];
        for (NSNumber *n in indexes) {
            if ([n intValue] < [[self availableAgeRanges] count]) {
                [tmp addObject:n];
            }
        }
        if (tmp.count == 0) {
            for (int i = 0; i < [[self availableAgeRanges] count]; i++) {
                [tmp addObject:@(i)];
            }
        }
        if (indexes.count != tmp.count) {
            [self setSelectedAgeRangeIndexes:[tmp copy]];
        }
        _selectedAgeRangeIndexes = [tmp sortedArrayUsingSelector:@selector(compare:)];
    }
    return _selectedAgeRangeIndexes;
}

+ (NSArray *)availableAgeRanges
{
    return @[[NSValue valueWithRange:NSMakeRange(13, 6)],
             [NSValue valueWithRange:NSMakeRange(19, 7)],
             [NSValue valueWithRange:NSMakeRange(26, 0)]];
}

+ (void)setSelectedAgeRangeIndexes:(NSArray *)selectedAgeRangeIndexes
{
    if (![_selectedAgeRangeIndexes isEqualToArray:selectedAgeRangeIndexes]) {
        selectedAgeRangeIndexes = [selectedAgeRangeIndexes sortedArrayUsingSelector:@selector(compare:)];
        _selectedAgeRangeIndexes = selectedAgeRangeIndexes;
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *key = [self keyForSelectedAgeRanges];
        [ud setObject:selectedAgeRangeIndexes forKey:key];
        [ud synchronize];
        [self publish:EVENT_FORUM_AGE_FILTER_UPDATED];
    }
}

+ (BOOL)isBirthdayFiltered:(int64_t)birthdayTimestamp
{
    if (birthdayTimestamp == 0) {
        return NO;
    }
    NSArray *indexes = [self selectedAgeRangeIndexes];
    if (indexes.count > 0) {
        NSArray *options = [self availableAgeRanges];
        if (indexes.count == options.count) {
            return NO;
        }
        int age = (int)(([[NSDate date] timeIntervalSince1970] - birthdayTimestamp) / (365.2425 * 86400));
        for (NSNumber *idx in indexes) {
            int i = [idx intValue];
            if (i < options.count) {
                NSValue *v = options[i];
                NSRange r = [v rangeValue];
                if (age >= r.location && (r.length == 0 || age < r.location + r.length)) {
                    return NO;
                }
            }
        }
        return YES;
    }
    return NO;
}

+ (NSString *)descriptionOfAgeRangeIndexes:(NSArray *)indexes
{
    NSArray *options = [self availableAgeRanges];
    if (indexes.count == 0 || indexes.count == options.count) {
        return @"All";
    } else {
        indexes = [indexes sortedArrayUsingSelector:@selector(compare:)];
        NSMutableArray *descs = [NSMutableArray array];
        NSRange lastR = NSMakeRange(0, 0);
        for (NSNumber *idx in indexes) {
            int i = [idx intValue];
            if (i < options.count) {
                NSValue *v = options[i];
                NSRange r = [v rangeValue];
                if (r.location == lastR.location + lastR.length) {
                    if (r.length == 0) {
                        lastR.length = 0;
                    } else {
                        lastR.length += r.length;
                    }
                } else {
                    if (lastR.location > 0) {
                        NSString *range = [self descriptionOfAgeRange:lastR];
                        if (range.length > 0) {
                            [descs addObject:range];
                        }
                    }
                    lastR = r;
                }
            }
        }
        NSString *range = [self descriptionOfAgeRange:lastR];
        if (range.length > 0) {
            [descs addObject:range];
        }
        if (descs.count > 0) {
            return [descs componentsJoinedByString:@", "];
        }
    }
    return @"";
}

+ (NSString *)selectedAgeRangeDescription
{
    NSArray *indexes = [self selectedAgeRangeIndexes];
    return [self descriptionOfAgeRangeIndexes:indexes];
}

+ (NSString *)descriptionOfAgeRange:(NSRange)range
{
    NSString *text = @"";
    if (range.location == 0 && range.length > 0) {
        text = [NSString stringWithFormat:@"%lu-", (unsigned long)range.length];
    } else if (range.length == 0) {
        text = [NSString stringWithFormat:@"%lu+", (unsigned long)range.location];
    } else if (range.length == 1) {
        text = [NSString stringWithFormat:@"%lu", (unsigned long)range.location];
    } else {
        text = [NSString stringWithFormat:@"%lu - %lu", (unsigned long)range.location, range.location + range.length - 1];
    }
    return text;
}

+ (NSDate *)appInstallDate {
    NSDate *firstLaunch = nil;
    Forum *f = [self sharedInstance];
    if ([f.delegate respondsToSelector:@selector(appInstallDate)]) {
        firstLaunch = [f.delegate appInstallDate];
    }
    if (!firstLaunch) {
        // back support emma
        firstLaunch = [GLUtils getDefaultsForKey:@"firstLaunch"];
    }
    if (!firstLaunch) {
        // back support kaylee
        firstLaunch = [GLUtils getDefaultsForKey:@"app_install_date"];
    }
    if (!firstLaunch) {
        // back support ruby
        firstLaunch = [GLUtils getDefaultsForKey:@"install_date"];
    }
    return firstLaunch;
}

@end
