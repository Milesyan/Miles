//
//  Share.m
//  emma
//
//  Created by Peng Gu on 8/18/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "Share.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "Network.h"
#import "Insight.h"
#import "Contact.h"
#import "User.h"
#import "SendFBRequest.h"
#import <Social/Social.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <GLCommunity/ForumGroup.h>


@implementation Share
 

+ (NSString *)descriptionForShareType:(ShareType)shareType
{
    NSDictionary *mapping =  @{@(ShareTypeNone)                   : SHARE_TYPE_NONE,
                               @(ShareTypeAppReferral)            : SHARE_TYPE_APP_REFERRAL,
                               @(ShareTypeAppShareMe)             : SHARE_TYPE_APP_SHARE_ME,
                               @(ShareTypeAppShareDailyTodo)      : SHARE_TYPE_APP_SHARE_DAILY_TODO,
                               @(ShareTypeAppShareSyncComplete)   : SHARE_TYPE_APP_SHARE_SYNC_COMPLETE,
                               @(ShareTypeInsightShare)           : SHARE_TYPE_INSIGHT_SHARE,
                               @(ShareTypeInsightShareThreeLikes) : SHARE_TYPE_INSIGHT_SHARE_THREE_LIKES,
                               @(ShareTypeGroupShare)             : SHARE_TYPE_GROUP_SHARE,
                               @(ShareTypeTopicShare)             : SHARE_TYPE_TOPIC_SHARE,
                               @(ShareTypeTopicShareAddingNew)    : SHARE_TYPE_TOPIC_SHARE_ADDING_NEW,
                               @(ShareTypePollShare)              : SHARE_TYPE_POLL_SHARE,
                               @(ShareTypePollShareAddingNew)     : SHARE_TYPE_POLL_SHARE_ADDING_NEW,
                               @(ShareTypePhotoShare)             : SHARE_TYPE_PHOTO_SHARE,
                               @(ShareTypePhotoShareAddingNew)    : SHARE_TYPE_PHOTO_SHARE_ADDING_NEW,
                               @(ShareTypeQuizResult)             : SHARE_TYPE_QUIZ_RESULT,
                               };
    
    NSString *desc = mapping[@(shareType)];
    return desc ? desc : SHARE_TYPE_NONE;
}

+ (void)postData:(NSDictionary *)data toURL:(NSString *)url requireLogin:(BOOL)login completion:(shareCallback)completion
{
    [[Network sharedNetwork] post:url
                             data:data
                     requireLogin:login
                completionHandler:^(NSDictionary *response, NSError *err) {
                    if (!completion) {
                        return;
                    }
                    
                    if (!err && [[response objectForKey:@"rc"] intValue] == RC_SUCCESS) {
                        completion(YES, [response objectForKey:@"data"], nil);
                    }
                    else {
                        completion(NO, nil, err);
                    }
                }];
}


+ (NSDictionary *)makePostDataForItem:(id)item shareType:(ShareType)shareType
{
    User *user = [User currentUser];
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:[user postRequest:@{}]];
    data[@"share_type"] = [Share descriptionForShareType:shareType];
    NSMutableDictionary *item_to_share = [NSMutableDictionary dictionary];
    NSString *title = [self titleForItem:item];
    NSString *content = [self contentForItem:item];;
    item_to_share[@"id"] = [self itemIDForItem:item shareType:shareType];
    item_to_share[@"title"] = title ? title : @"";
    item_to_share[@"content"] = content ? content : @"";
    data[@"item_to_share"] = item_to_share;
    return data;
}


+ (NSNumber *)itemIDForItem:(id)item shareType:(ShareType)shareType
{
    if (!item) {
        return [NSNumber numberWithInteger:-1];
    }
    
    if (shareType == ShareTypeInsightShare || shareType == ShareTypeInsightShareThreeLikes) {
        return [NSNumber numberWithUnsignedLongLong:[(Insight *)item type]];
    }
    else if (shareType == ShareTypeGroupShare) {
        return @([(ForumGroup *)item identifier]);
    }
    else if (shareType == ShareTypeTopicShare || shareType == ShareTypeTopicShareAddingNew ||
             shareType == ShareTypePollShare  || shareType == ShareTypePollShareAddingNew) {
        return [NSNumber numberWithUnsignedLongLong:[(ForumTopic *)item identifier]];
    }
    else {
        return [NSNumber numberWithInteger:0];
    }
}

+ (NSString *)titleForItem:(id)item
{
    if (!item) {
        return @"";
    }
    if ([item isKindOfClass:[Insight class]]) {
        return [(Insight *)item title];
    }
    if ([item isKindOfClass:[ForumTopic class]]) {
        return [(ForumTopic *)item title];
    }
    return @"";
}

+ (UIImage *)imageForItem:(id)item shareType:(ShareType)shareType
{
    if ([item isKindOfClass:[ForumTopic class]]) {
        ForumTopic *topic = (ForumTopic *)item;
        if (topic.image && ![topic.image isEqualToString:@""]) {
            NSURLResponse *response;
            NSError *error;
            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:topic.image] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if (data && !error) {
                return [UIImage imageWithData:data];
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    }
    return nil;
}


+ (NSString *)contentForItem:(id)item
{
    if (!item) {
        return @"";
    }
    if ([item isKindOfClass:[Insight class]]) {
        return [(Insight *)item body];
    }
    if ([item isKindOfClass:[ForumTopic class]]) {
        return [(ForumTopic *)item content];
    }
    return @"";
}


+ (void)shareItem:(id)item shareType:(ShareType)shareType completion:(shareCallback)completion
{
    NSDictionary *data = [self makePostDataForItem:item shareType:shareType];
    NSString *url = @"users/share/content_for_system_share_sheet";
    [self postData:data toURL:url requireLogin:YES completion:completion];
    
}


@end





