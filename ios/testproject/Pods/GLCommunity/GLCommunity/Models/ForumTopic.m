//
//  ForumTopic.m
//  emma
//
//  Created by Allen Hsu on 11/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/NSDictionary+Accessors.h>
#import <GLFoundation/NSString+Utils.h>
#import "ForumTopic.h"
#import "Forum.h"

@interface ForumTopic ()

@end

@implementation ForumTopic

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            _identifier = [dict unsignedLongLongForKey:@"id"];
            _categoryId = [dict unsignedIntForKey:@"category_id"];
            _groupId = [dict unsignedLongLongForKey:@"group_id"];
            _userId = [dict unsignedLongLongForKey:@"user_id"];
            _replyUserId = [dict unsignedLongLongForKey:@"reply_user_id"];
            _countReplies = [dict unsignedIntForKey:@"count_replies"];
            _countSubReplies = [dict unsignedIntForKey:@"count_subreplies"];
            _countLikes = [dict unsignedIntForKey:@"count_likes"];
            _countDislikes = [dict unsignedIntForKey:@"count_dislikes"];
            _lastReplyTime = [dict unsignedIntForKey:@"last_reply_time"];
            _timeCreated = [dict unsignedIntForKey:@"time_created"];
            _timeModified = [dict unsignedIntForKey:@"time_modified"];
            _timeRemoved = [dict unsignedIntForKey:@"time_removed"];
            _bookmarked = [dict boolForKey:@"bookmarked"];
            _liked = [dict boolForKey:@"liked"];
            _disliked = [dict boolForKey:@"disliked"];
            _lowRating = [dict boolForKey:@"low_rating"];
            _flags = [dict unsignedIntForKey:@"flags"];
            _title = [dict stringForKey:@"title"];
            _content = [dict stringForKey:@"content"];
            _desc = [[dict stringForKey:@"desc"] trim];
            _author = [[ForumUser alloc] initWithDictionary:[dict dictionaryForKey:@"author"]];
            _replier = [[ForumUser alloc] initWithDictionary:[dict dictionaryForKey:@"replier"]];
            _views = [dict unsignedLongLongForKey:@"views"];
            _image = [dict stringForKey:@"image"];
            _thumbnail = [dict stringForKey:@"thumbnail"];
            
            _urlTitle = [dict stringForKey:@"url_title"];
            _urlAbstract = [dict stringForKey:@"url_abstract"];
            _urlPath = [dict stringForKey:@"url_path"];
            
            NSArray *options = [dict objectForKey:@"options"];
            if ([options isKindOfClass:[NSArray class]]) {
                NSDictionary * optionInfo =@{@"topic_id": @(_identifier),
                                             @"voted": [dict objectForKey:@"voted"],
                                             @"vote_index": [dict objectForKey:@"vote_index"]};
                _pollOptions = [ForumPollOptions createPollBy:options withInfo:optionInfo];
            } else {
                _pollOptions = [ForumPollOptions createEmptyPoll];
            }
            [self checkHtml];
        }
    }
    return self;
}

- (void)checkHtml
{
    _desc = [_desc stringByReplacingOccurrencesOfString:@"(:?<(?:div|p)[^>]*>)+" withString:@"\n" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _desc.length)];
    _desc = [_desc stringByReplacingOccurrencesOfString:@"<br[^>]*>" withString:@"\n" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _desc.length)];
    _desc = [_desc stringByReplacingOccurrencesOfString:@"</?[a-z][^>]*>" withString:@"" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _desc.length)];
    _desc = [_desc stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    _desc = [_desc stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    _desc = [_desc stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
    _desc = [_desc stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    _desc = [_desc stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    _desc = [_desc stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    _desc = [_desc stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    _desc = [_desc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isAnonymous
{
    return (self.flags & ForumTopicFlagAnonymous) ? YES : NO;
}

- (BOOL)isPinned
{
    return (self.flags & ForumTopicFlagAnnouncement) ? YES : NO;
}

- (BOOL)isPoll {
    return (self.flags & ForumTopicFlagPoll) ? YES : NO;
}

- (BOOL)isPhotoTopic {
    return (self.flags & ForumTopicFlagPhoto) ? YES : NO;
}
- (BOOL)isURLTopic {
    return (self.flags & ForumTopicFlagURL) ? YES : NO;
}
- (BOOL)isSystemTopic {
    return (self.flags & ForumTopicFlagSystem) ? YES : NO;
}

- (BOOL)hasImproperContent {
    return (self.flags & ForumTopicFlagWarning) ? YES : NO;
}

- (BOOL)isNoComment {
    return (self.flags & ForumTopicFlagNoComment) ? YES : NO;
}

- (BOOL)isQuiz {
    return (self.flags & ForumTopicFlagQuiz) ? YES : NO;
}

- (BOOL)hasDesc {
    return self.desc.length > 0;
}

- (BOOL)isHidden
{
    BOOL hidden = [Forum isTopicHidden:self.identifier];
    if (hidden) {
        return YES;
    }
    else if (self.author) {
        return [self.author shouldHideTopic];
    }
    else {
        return NO;
    }
}

- (BOOL)shouldHideLowRatingContent
{
    return self.lowRating && !self.didUnlockLowRatingContent;
}


- (NSString *)debugDescription
{
    NSDictionary *dict = @{
                           @"identifier": @(self.identifier),
                           @"categoryId": @(self.categoryId),
                           @"groupId": @(self.groupId),
                           @"userId": @(self.userId),
                           @"replyUserId": @(self.replyUserId),
                           @"countReplies": @(self.countReplies),
                           @"countSubReplies": @(self.countSubReplies),
                           @"countLikes": @(self.countLikes),
                           @"countDislikes": @(self.countDislikes),
                           @"lastReplyTime": @(self.lastReplyTime),
                           @"flags": @(self.flags),
                           @"title": self.title,
                           @"content": self.content,
                           @"desc": self.desc,
                           @"author": self.author,
                           @"replier": self.replier,
                           @"bookmarked": @(self.bookmarked),
                           @"liked": @(self.liked),
                           @"disliked": @(self.disliked),
                           @"lowRating": @(self.lowRating),
                           @"pollOptions": self.pollOptions,
                           @"image": self.image,
                           @"thumbnail": self.thumbnail,
                           @"views": @(self.views),
                           @"isWelcomeTopic": @(self.isWelcomeTopic),
                           @"articleID": @(self.articleID),
                           @"isAnonymous": @([self isAnonymous]),
                           @"isPinned": @([self isPinned]),
                           @"isPoll": @([self isPoll]),
                           @"isPhotoTopic": @([self isPhotoTopic]),
                           @"isSystemTopic": @([self isSystemTopic]),
                           @"isHidden": @([self isHidden]),
                           };
    
    return [NSString stringWithFormat:@"%@", dict];
}



@end



