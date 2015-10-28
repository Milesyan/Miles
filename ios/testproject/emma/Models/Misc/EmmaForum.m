//
//  EmmaForum.m
//  emma
//
//  Created by Allen Hsu on 9/11/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "EmmaForum.h"
#import "User.h"
#import "Tooltip.h"
#import "UserDailyPoll.h"
#import "Network.h"
#import "ShareController.h"
#import <GLFoundation/GLUtils.h>
#import <GLCommunity/ForumGroup.h>
#import "DailyArticle.h"
#import "SyncableAttribute.h"
#import "DailyTodo.h"

@implementation EmmaForum


#pragma mark - network delegate
- (void)GET:(NSString *)URLString parameters:(NSDictionary *)parameters callback:(ForumAPICallBack)cb
{
    [self GET:URLString withToken:YES parameters:parameters callback:cb];
}


- (void)GET:(NSString *)URLString withToken:(BOOL)withToken parameters:(NSDictionary *)parameters callback:(ForumAPICallBack)cb
{
    URLString = [@"forum/" stringByAppendingString:URLString];
    
    if (!parameters) {
        parameters = @{};
    }
    
    NSMutableDictionary *queryDictionary = [parameters mutableCopy];
    if (withToken) {
        queryDictionary[@"ut"] = [User currentUser].encryptedToken;
    }
    
    URLString = [Utils apiUrl:URLString query:queryDictionary];
    [[Network sharedNetwork] get:URLString completionHandler:cb];
}


- (void)POST:(NSString *)URLString parameters:(NSDictionary *)parameters callback:(ForumAPICallBack)cb
{
    URLString = [@"forum/" stringByAppendingString:URLString];
    User *user = [User currentUser];
    NSDictionary *request = [user postRequest:parameters];
    [[Network sharedNetwork] post:URLString data:request requireLogin:YES completionHandler:cb];
}


- (void)POST:(NSString *)URLString parameters:(NSDictionary *)parameters images:(NSDictionary *)images callback:(ForumAPICallBack)cb
{
    URLString = [@"forum/" stringByAppendingString:URLString];
    User *user = [User currentUser];
    NSDictionary *request = [user postRequest:parameters];
    [[Network sharedNetwork] post:URLString data:request requireLogin:YES images:images completionHandler:cb];
}


#pragma mark - misc delegates

- (ForumUser *)currentForumUser
{
    static ForumUser *sCurrentUser = nil;
    User *user = [User currentUser];
    if (!sCurrentUser || sCurrentUser.identifier != [user.id unsignedLongLongValue]) {
        sCurrentUser = [[ForumUser alloc] init];
        sCurrentUser.identifier = [user.id unsignedLongLongValue];
        sCurrentUser.type = ForumUserTypeNormal;
        sCurrentUser.firstName = user.firstName;
        sCurrentUser.lastName = user.lastName;
        sCurrentUser.profileImage = user.profileImageUrl;
        sCurrentUser.backgroundImage = user.settings.backgroundImageUrl;
        sCurrentUser.bio = user.settings.bio;
        sCurrentUser.location = user.settings.location;
        sCurrentUser.gender = user.gender;
        sCurrentUser.hidePosts = user.settings.hidePosts;
    }
    
    if ([sCurrentUser needFetchSocialInfo]) {
        [sCurrentUser fetchSocialInfoWithCompletion:nil];
    }
    
    if (!sCurrentUser.location && user.currentLocationCity) {
        sCurrentUser.location = user.currentLocationCity;
    }
    sCurrentUser.cachedProfileImage = user.profileImage;
    sCurrentUser.cachedBackgroundImage = user.settings.backgroundImage;
    return sCurrentUser;
}

- (void)log:(NSString *)eventName
{
    [Logging log:eventName];
}

- (void)log:(NSString *)eventName eventData:(NSDictionary *)eventData
{
    [Logging log:eventName eventData:eventData];
}

- (NSString *)replaceTermLinksInHtml:(NSString *)html caseSensitive:(BOOL)caseSensitive
{
    // Do nothing in Demo
    if (!html || ![html isKindOfClass:[NSString class]]) {
        return nil;
    }
    return [Tooltip replaceTermLinksInHtml:html caseSensitive:caseSensitive];
}

- (UIViewController *)emailContactViewControllerWithBackTitle:(NSString *)backTitle callback:(ForumEmailContactCallback)cb
{
    // You'd better provide a sharing page
    return nil;
}

- (void)updateUserProfile:(ForumUser *)newUser
{
    // Update user's profile (check changes by yourself)
    User *currentUser = [User currentUser];
    BOOL modified = NO;
    if (newUser.firstName && ![currentUser.firstName isEqualToString:newUser.firstName]) {
        [currentUser update:@"firstName" value:newUser.firstName];
        modified = YES;
    }
    if (newUser.lastName && ![currentUser.lastName isEqualToString:newUser.lastName]) {
        [currentUser update:@"lastName" value:newUser.lastName];
        modified = YES;
    }
    if (newUser.bio && ![currentUser.settings.bio isEqualToString:newUser.bio]) {
        [currentUser.settings update:SETTINGS_KEY_BIO value:newUser.bio];
        modified = YES;
    }
    if (newUser.location && ![currentUser.settings.location isEqualToString:newUser.location]) {
        [currentUser.settings update:SETTINGS_KEY_LOCATION value:newUser.location];
        modified = YES;
    }
    if (currentUser.settings.hidePosts != newUser.hidePosts) {
        [currentUser.settings update:SETTINGS_KEY_HIDE_POSTS value:@(newUser.hidePosts)];
        modified = YES;
    }
    if (modified) {
        [currentUser save];
        [currentUser pushToServer];
        [self publish:EVENT_PROFILE_MODIFIED];
    }
}

- (void)updateProfileImage:(UIImage *)profileImage
{
    // Update profile image
    [[User currentUser] updateProfileImage:profileImage];
}

- (void)updateBackgroundImage:(UIImage *)backgroundImage
{
    // Update background image
    [[[User currentUser] settings] updateBackgroundImage:backgroundImage];
}

- (void)restoreBackgroundImage
{
    // Restore background image
    [[[User currentUser] settings] restoreBackgroundImage];
}

- (UIImage *)defaultBackgroundImage
{
    return [[[User currentUser] settings] defaultBackgroundImage];
}

- (void)toggleLikedTopic:(ForumTopic *)topic liked:(BOOL)liked
{
    // Do something for your homepage daily poll and todo section
    int diff = topic.liked ? 1 : -1;

    NSArray *todos = [DailyTodo todosByTopicId:topic.identifier forUser:[User currentUser]];
    if (todos && todos.count > 0) {
        for (DailyTodo *todo in todos) {
            todo.likes += diff;
        }
        return;
    }
    
    // see if it is a daily poll
    ForumTopic * pollTopic = [[UserDailyPoll sharedInstance] getTopicById:topic.identifier];
    if (pollTopic) {
        pollTopic.liked = topic.liked;
        pollTopic.countLikes = topic.countLikes;
        return;
    }
    
    // see if it is a daily article
    DailyArticle *article = [DailyArticle articleByTopicId:topic.identifier forUser:[User currentUser]];
    if (article) {
        article.likes += diff;
        [article save];
    }
}

- (void)tip:(NSString *)tip
{
    // Pop a view controller for tip from terms link
    [Tooltip tip:tip];
}

- (void)createReplyToReply:(uint64_t)replyId inTopic:(uint64_t)topicId withContent:(NSString *)content andImages:(NSDictionary *)images anonymously:(BOOL)anonymous callback:(ForumAPICallBack)cb
{
    User *user = [User currentUser];
    NSString *url = @"forum/create_reply";
    NSDictionary *request = [user postRequest:@{@"topic_id": @(topicId),
                                                @"content": content,
                                                @"anonymous": @(anonymous ? 1:0),
                                                @"reply_to": @(replyId)
                                                }];
    [[Network sharedNetwork] post:url data:request requireLogin:YES images:images completionHandler:cb];
}

- (void)fetchTopicsForType:(ForumGroupType)type lastReplyTime:(unsigned int)lastReplyTime callback:(ForumAPICallBack)cb
{
    NSString *url = nil;
    switch (type) {
        case ForumGroupParticipated:
            url = @"forum/participated";
            break;
        case ForumGroupBookmarked:
            url = @"forum/bookmarked";
            break;
        case ForumGroupCreated:
            url = @"forum/created";
            break;
        default:
            break;
    }
    if (lastReplyTime > 0) {
        url = [url stringByAppendingFormat:@"/%u", lastReplyTime];
    }
    if (url) {
        NSDictionary *queryDictionary = @{@"ut": [User currentUser].encryptedToken};
        url = [Utils apiUrl:url query:queryDictionary];
        [[Network sharedNetwork] get:url completionHandler:cb];
    }
}

- (void)fetchRepliesForTopic:(uint64_t)topicId lastReplyTime:(unsigned int)lastReplyTime callback:(ForumAPICallBack)cb
{
    NSString *url = nil;
    if (lastReplyTime > 0) {
        url = [NSString stringWithFormat:@"forum/replies_new/%llu/%u", topicId, lastReplyTime];
    } else {
        url = [NSString stringWithFormat:@"forum/replies_new/%llu", topicId];
    }
    NSDictionary *queryDictionary = @{@"ut": [User currentUser].encryptedToken};
    url = [Utils apiUrl:url query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)fetchRepliesForArticle:(uint64_t)articleId lastReplyTime:(unsigned int)lastReplyTime callback:(ForumAPICallBack)cb
{
    // Not supported
}

- (void)fetchRepliesToReply:(uint64_t)replyId lastReplyTime:(unsigned int)lastReplyTime callback:(ForumAPICallBack)cb
{
    NSString *url = nil;
    if (lastReplyTime > 0) {
        url = [NSString stringWithFormat:@"forum/subreplies/%llu/%u", replyId, lastReplyTime];
    } else {
        url = [NSString stringWithFormat:@"forum/subreplies/%llu", replyId];
    }
    NSDictionary *queryDictionary = @{@"ut": [User currentUser].encryptedToken};
    url = [Utils apiUrl:url query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)markTopic:(uint64_t)topicId bookmarked:(BOOL)bookmarked callback:(ForumAPICallBack)cb
{
    User *user = [User currentUser];
    NSString *url = [NSString stringWithFormat:@"forum/bookmark/%llu/%d", topicId, bookmarked ? 1 : 0];
    NSDictionary *request = [user postRequest:nil];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)markTopic:(uint64_t)topicId liked:(BOOL)liked callback:(ForumAPICallBack)cb
{
    User *user = [User currentUser];
    NSString *url = [NSString stringWithFormat:@"forum/liked/%llu/%d", topicId, liked ? 1 : 0];
    NSDictionary *request = [user postRequest:nil];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)markTopic:(uint64_t)topicId flagged:(BOOL)flagged reason:(NSString *)reason callback:(ForumAPICallBack)cb
{
    User *user = [User currentUser];
    NSString *url = @"forum/flag_post";
    NSDictionary *request = [user postRequest:@{@"topic_id": @(topicId), @"flagged":@(flagged), @"reason": reason}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)markReply:(uint64_t)topicId replyId:(uint64_t)replyId liked:(BOOL)liked callback:(ForumAPICallBack)cb
{
    User *user = [User currentUser];
    NSString *url = @"forum/like_reply";
    NSDictionary *request = [user postRequest:@{@"topic_id": @(topicId), @"reply_id": @(replyId), @"liked":@(liked)}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)markReply:(uint64_t)topicId replyId:(uint64_t)replyId flagged:(BOOL)flagged reason:(NSString *)reason callback:(ForumAPICallBack)cb
{
    User *user = [User currentUser];
    NSString *url = @"forum/flag_post";
    NSDictionary *request = [user postRequest:@{@"topic_id": @(topicId), @"reply_id": @(replyId), @"flagged":@(flagged), @"reason":reason}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)searchTopicWithKeyword:(NSString *)keyword offset:(unsigned int)offset callback:(ForumAPICallBack)cb
{
    NSDictionary *queryDictionary = @{@"ut": [User currentUser].encryptedToken, @"keyword": keyword, @"offset": @(offset)};
    NSString *url = [Utils apiUrl:@"forum/search/topic" query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)searchReplyWithKeyword:(NSString *)keyword offset:(unsigned int)offset callback:(ForumAPICallBack)cb
{
    NSDictionary *queryDictionary = @{@"ut": [User currentUser].encryptedToken, @"keyword": keyword, @"offset": @(offset)};
    NSString *url = [Utils apiUrl:@"forum/search/reply" query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)votePoll:(uint64_t)topicId atOption:(int)optionIndex callback:(ForumAPICallBack)cb
{
    [[Forum sharedInstance] setParticipatedUpdated:YES];
    User *user = [User currentUser];
    NSString *url = @"forum/vote_poll";
    NSDictionary *request = [user postRequest:@{@"topic_id": @(topicId),
                                                @"vote_index": @(optionIndex)
                                                }];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)removeReply:(uint64_t)replyId callback:(ForumAPICallBack)cb
{
    User *user = [User currentUser];
    NSString *url = @"forum/remove_reply";
    NSDictionary *request = [user postRequest:@{@"reply_id": @(replyId)}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)fetchDailyTopic:(uint64_t)topicId callback:(ForumAPICallBack)cb
{
    User *user = [User currentUser];
    NSString *url = @"forum/daily_topic";
    NSDictionary *request = [user postRequest:@{@"topic_id": @(topicId)}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)fetchPrerequisiteForCreatingGroupCallback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/group/create_prerequisite";
    NSDictionary *queryDictionary = @{@"ut": [User currentUser].encryptedToken};
    url = [Utils apiUrl:url query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)fetchGroupsPageCallback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/group/group_page";
    NSDictionary *queryDictionary = @{@"ut": [User currentUser].encryptedToken};
    url = [Utils apiUrl:url query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)fetchTopicsInGroup:(uint64_t)groupId withOffset:(int)offset
                orCategory:(uint64_t)categoryId
                  callback:(ForumAPICallBack)cb
{
    NSString *url = [NSString stringWithFormat:@"forum/group/%llu/topics",
        groupId];
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    NSDictionary *queryDictionary = @{
        @"ut": [User currentUser].encryptedToken,
        @"old_category_id": @(categoryId)};
    url = [Utils apiUrl:url query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)fetchFindGroupsPageCallback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/group/find_groups";
    NSDictionary *queryDictionary = @{@"ut": [User currentUser].encryptedToken};
    url = [Utils apiUrl:url query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)fetchGroupsInCategory:(uint64_t)categoryId offset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = [NSString stringWithFormat:
        @"forum/category/%llu/all_groups", categoryId];
    NSDictionary *queryDictionary = @{
        @"ut": [User currentUser].encryptedToken,
        @"offset": @(offset)};
    url = [Utils apiUrl:url query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)createGroupWithName:(NSString *)name categoryId:(uint16_t)categoryId
                       desc:(NSString *)desc photo:(UIImage *)photo callback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/group/create";
    User *user = [User currentUser];
    NSDictionary *request = [user postRequest:@{@"name": name, @"category_id":
        @(categoryId), @"desc": desc}];
    if (photo) {
        [[Network sharedNetwork] post:url data:request requireLogin:YES image:photo completionHandler:cb];
    } else {
        [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
    }
}

- (void)createTopicInGroup:(uint64_t)groupId withTitle:(NSString *)title
                   content:(NSString *)content andImages:(NSDictionary *)images
               anonymously:(BOOL)anonymous callback:(ForumAPICallBack)cb
{
    [[Forum sharedInstance] setCreatedUpdated:YES];
    [[Forum sharedInstance] setParticipatedUpdated:YES];
    User *user = [User currentUser];
    NSString *url = @"forum/topic/create";
    NSDictionary *request = [user postRequest:@{@"group_id": @(groupId),
                                                @"title": title,
                                                @"content": content,
                                                @"anonymous": @(anonymous ? 1:0)
                                                }];
    [[Network sharedNetwork] post:url data:request requireLogin:YES images:images completionHandler:cb];
}

- (void)createPollInGroup:(uint64_t)groupId withTitle:(NSString *)title
                  options:(NSArray *)options content:(NSString *)content
                andImages:(NSDictionary *)images anonymously:(BOOL)anonymous
                 callback:(ForumAPICallBack)cb
{
    [[Forum sharedInstance] setCreatedUpdated:YES];
    [[Forum sharedInstance] setParticipatedUpdated:YES];
    User *user = [User currentUser];
    NSString *url = @"forum/poll/create";
    NSString * optionString = [Utils jsonStringify:options];
    NSDictionary *request = [user postRequest:@{@"group_id": @(groupId),
        @"title": title, @"options": optionString, @"content": content,
        @"anonymous": @(anonymous ? 1:0)}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES images:images
        completionHandler:cb];
}

- (void)createPhotoInGroup:(uint64_t)groupId withTitle:(NSString *)title
                    images:(NSDictionary *)images
               anonymously:(BOOL)anonymous warning:(BOOL)warning callback:(ForumAPICallBack)cb
{
    [[Forum sharedInstance] setCreatedUpdated:YES];
    [[Forum sharedInstance] setParticipatedUpdated:YES];
    User *user = [User currentUser];
    NSString *url = @"forum/photo/create";
    NSDictionary *request = [user postRequest:@{@"group_id": @(groupId),
                                                @"title": title,
                                                @"anonymous": @(anonymous ? 1:0),
                                                @"warning": @(warning? 1:0),
                                                }];
    [[Network sharedNetwork] post:url data:request requireLogin:YES images:images completionHandler:cb];
}

- (void)createURLInGroup:(uint64_t)groupId withTitle:(NSString *)title
                     url:(NSString *)url urlTitle:(NSString *)urlTitle
             urlAbstract:(NSString *)urlAbstract thumbnail:(NSString *)thumb callback:(ForumAPICallBack)cb
{
    [[Forum sharedInstance] setCreatedUpdated:YES];
    [[Forum sharedInstance] setParticipatedUpdated:YES];
    User *user = [User currentUser];
    NSString *postEndpoint = @"forum/url_topic/create";
    NSDictionary *request = [user postRequest:@{@"group_id": @(groupId),
                                                @"title": title,
                                                @"content": url,
                                                @"url_title": urlTitle,
                                                @"url_abstract": urlAbstract,
                                                @"thumbnail_url": thumb,
                                                }];
    [[Network sharedNetwork] post:postEndpoint data:request requireLogin:YES completionHandler:cb];
}

- (void)joinGroup:(uint64_t)groupId callback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/group/subscribe";
    User *user = [User currentUser];
    NSDictionary *request = [user postRequest:@{@"group_id": @(groupId)}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)leaveGroup:(uint64_t)groupId callback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/group/unsubscribe";
    User *user = [User currentUser];
    NSDictionary *request = [user postRequest:@{@"group_id": @(groupId)}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)shareQuizResultWithToken:(NSString *)token
{
    // TODO
}

- (void)shareTopicWithObject:(id)topicObject
{
    GLLog(@"%@",topicObject);
    if ([topicObject isKindOfClass:[ForumTopic class]])
    {
        UIViewController *presentingViewController;
        {
            UIViewController *topController = [GLUtils keyWindow].rootViewController;
            
            while (topController.presentedViewController) {
                //make sure it can be presented by this controller
                topController = topController.presentedViewController;
            }
            presentingViewController = topController;
        }
        if (presentingViewController) {
            ForumTopic *topic = topicObject;
            ShareType shareType = topic.isPoll ? ShareTypePollShare : ShareTypeTopicShare;
            [ShareController presentWithShareType:shareType shareItem:topic fromViewController:presentingViewController];
        }
    }
}

- (void)shareGroupWithObject:(id)groupObject
{
    GLLog(@"%@",groupObject);
    if ([groupObject isKindOfClass:[ForumGroup class]])
    {
        UIViewController *presentingViewController;
        {
            UIViewController *topController = [GLUtils keyWindow].rootViewController;
            
            while (topController.presentedViewController) {
                //make sure it can be presented by this controller
                topController = topController.presentedViewController;
            }
            presentingViewController = topController;
        }
        if (presentingViewController) {
            ForumGroup *group = groupObject;
            [ShareController presentWithShareType:ShareTypeGroupShare shareItem:group fromViewController:presentingViewController];
        }
    }
}


- (void)inviteUser:(uint64_t)uid toGroup:(uint64_t)groupId message:(NSString *)message callback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/group/invite";
    User *user = [User currentUser];
    NSDictionary *request = [user postRequest:
        @{@"group_id": @(groupId), @"invitee_id":@(uid),
        @"message":message}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:
        ^(NSDictionary *response, NSError *err) {}];
}

- (void)isUser:(uint64_t)uid alreadyInGroup:(uint64_t)groupId callback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/group/is_in_group";
    NSDictionary *queryDictionary = @{
        @"ut": [User currentUser].encryptedToken,
        @"group_id": @(groupId),
        @"invitee_id": @(uid)};
    url = [Utils apiUrl:url query:queryDictionary];
    
    [[Network sharedNetwork] get:url completionHandler:
        ^(NSDictionary *response, NSError *err) {
        if (cb) {
            cb(response, err);
        }
    }];
}

- (void)fetchHotTopicsOffset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/hot";
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    NSDictionary *queryDictionary = @{
                                      @"ut": [User currentUser].encryptedToken,
                                      };
    url = [Utils apiUrl:url query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)fetchNewTopicsOffset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/new";
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    NSDictionary *queryDictionary = @{
                                      @"ut": [User currentUser].encryptedToken,
                                      };
    url = [Utils apiUrl:url query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)fetchWelcomeTopicIdWithCallback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/get_welcome_topic_id";
    NSDictionary *request = [[User currentUser] postRequest:@{}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:cb];
}

- (void)fetchFeedsForUser:(uint64_t)target_uid offset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/user_feeds";
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    NSDictionary *queryDictionary = @{
                                      @"ut": [User currentUser].encryptedToken,
                                      @"target_uid": @(target_uid),
                                      };
    url = [Utils apiUrl:url query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:cb];

}

- (void)fetchPopularTopicsForUser:(uint64_t)target_uid offset:(int)offset callback:(ForumAPICallBack)cb
{
    NSString *url = @"forum/user_popular_topics";
    if (offset > 0) {
        url = [url stringByAppendingFormat:@"/%u", offset];
    }
    NSDictionary *query = @{
                            @"ut": [User currentUser].encryptedToken,
                            @"target_uid": @(target_uid)};
    url = [Utils apiUrl:url query:query];
    [[Network sharedNetwork] get:url completionHandler:cb];
}

- (void)fetchURLContent:(NSString *)url callback:(ForumAPICallBack)cb
{
    SyncableAttribute *syncAttr = [SyncableAttribute tsetWithName:ATTRIBUTE_READABILITY];
    NSString *endPoint = FALLBACK_READABILITY_URL;
    NSString *token = FALLBACK_READABILITY_TOKEN;
    
    @try {
        NSDictionary *data = [Utils jsonParse:syncAttr.stringifiedAttribute];
        endPoint = data[@"url"]?: endPoint;
        token = data[@"token"]?: token;
    }
    @catch (NSException *exception) {
    }
    @finally {
    }
    
    NSDictionary *query = @{@"url": url?:@"", @"token": token};
    [[Network sharedNetwork] getNonGlowURL:endPoint
                                     query:query
                         completionHandler:cb];
}

- (NSString *)text1ForWelcomeDialog
{
    if ([[User currentUser] isMale]) {
        return @"**Glow Community** is the most supportive place for topics such as health, sex, relationships and more!";
    } else {
        return @"**Glow Community** is the most supportive place for topics such as health, lifestyle, sex, relationships, TTC, parenting, and more!";
    }
}

- (NSString *)text2ForWelcomeDialog
{
    if ([[User currentUser] isMale]) {
        return @"To help you get started, we automatically enrolled you into these groups: **Men's Health, Fitness & Exercise, Sports & Entertainment**, etc";
    } else {
        return @"To help you get started, we automatically enrolled you into these groups: **General Health, General Sex & Relationships, Birth Control, Glow Support**, etc";
    }
}


- (NSDate *)appInstallDate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"firstLaunch"];
}




@end