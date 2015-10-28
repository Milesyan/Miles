//
//  DailyArticle.m
//  emma
//
//  Created by ltebean on 15-2-27.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "DailyArticle.h"
#import "User.h"

@implementation DailyArticle
@dynamic topicId;
@dynamic date;
@dynamic title;
@dynamic introduction;
@dynamic thumbnailUrl;
@dynamic articleId;
@dynamic likes;
@dynamic comments;
@dynamic user;

- (NSDictionary *)attrMapper {
    return @{
             @"id"              : @"articleId",
             @"title"           : @"title",
             @"introduction"    : @"introduction",
             @"thumbnail_url"   : @"thumbnailUrl",
             @"date"            : @"date",
             @"topic_id"        : @"topicId",
             @"likes"           : @"likes",
             @"comments"        : @"comments",
             };
}

+ (DailyArticle *)articleAtDate:(NSString *)date forUser:(User *)user
{
    if (!user) {
        return nil;
    }
    return [self fetchObject:@{@"user.id" : user.id, @"date" : date} dataStore:user.dataStore];
}

+ (DailyArticle *)articleByTopicId:(uint64_t)topicId forUser:(User *)user
{
    if (!user) {
        return nil;
    }
    return [self fetchObject:@{@"user.id" : user.id, @"topicId" : @(topicId)} dataStore:user.dataStore];
}

+ (void)updateWithServerData:(NSArray *)serverData onDate:(NSString *)date forUser:(User *)user
{
    // fetch to avoid inserting more than one article a day
    DailyArticle *article = [DailyArticle articleAtDate:date forUser:user];
    if(!article) {
        article = [DailyArticle newInstance:user.dataStore];
        article.user = user;
        article.date = date;
    }
    
    // if no article avalable on that day, set article id = 0
    if (!serverData || serverData.count == 0) {
        article.articleId = 0;
    } else {
        [article updateAttrsFromDictionary:serverData[0]];
    }
    [article save];
}

- (void)updateAttrsFromDictionary:(NSDictionary *)dict
{
    for (NSString *attr in self.attrMapper) {
        NSObject *remoteVal = [dict objectForKey:attr];
        if (remoteVal) {
            NSString *clientAttr = [self.attrMapper valueForKey:attr];
            [self convertAndSetValue:remoteVal forAttr:clientAttr];
        }
    }
}

- (BOOL)hasThumbnail
{
    return self.thumbnailUrl && self.thumbnailUrl.length > 0;
}

@end
