//
//  ForumReply.m
//  emma
//
//  Created by Allen Hsu on 11/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ForumReply.h"
#import "Forum.h"

@implementation ForumReply

@synthesize content = _content;

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            id obj;
            obj = [dict objectForKey:@"id"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _identifier = [obj unsignedLongLongValue];
            }
            obj = [dict objectForKey:@"topic_id"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _topicId = [obj unsignedLongLongValue];
            }
            obj = [dict objectForKey:@"reply_to"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _replyTo = [obj unsignedLongLongValue];
            }
            obj = [dict objectForKey:@"count_replies"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _countReplies = [obj unsignedIntValue];
            }
            obj = [dict objectForKey:@"count_likes"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _countLikes = [obj unsignedIntValue];
            }
            obj = [dict objectForKey:@"count_dislikes"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _countDislikes = [obj unsignedIntValue];
            }
            obj = [dict objectForKey:@"user_id"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _userId = [obj unsignedLongLongValue];
            }
            obj = [dict objectForKey:@"content"];
            if ([obj isKindOfClass:[NSString class]]) {
                self.content = obj;
            }
            obj = [dict objectForKey:@"desc"];
            if ([obj isKindOfClass:[NSString class]] && !self.content) {
                self.content = obj;
            }

            obj = [dict objectForKey:@"time_created"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _timeCreated = [obj unsignedIntValue];
            }
            obj = [dict objectForKey:@"time_modified"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _timeModified = [obj unsignedIntValue];
            }
            obj = [dict objectForKey:@"time_removed"];
            if ([obj isKindOfClass:[NSString class]]) {
                _timeRemoved = [obj unsignedIntValue];
            }
            obj = [dict objectForKey:@"author"];
            if ([obj isKindOfClass:[NSDictionary class]]) {
                _author = [[ForumUser alloc] initWithDictionary:obj];
            }
            obj = [dict objectForKey:@"liked"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _liked = [obj boolValue];
            }
            obj = [dict objectForKey:@"disliked"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _disliked = [obj boolValue];
            }
            obj = [dict objectForKey:@"low_rating"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _lowRating = [obj boolValue];
            }
            obj = [dict objectForKey:@"replies"];
            if ([obj isKindOfClass:[NSArray class]]) {
                NSArray *array = (NSArray *)obj;
                NSMutableArray *subReplies = [NSMutableArray arrayWithCapacity:array.count];
                for (NSDictionary *subdict in array) {
                    ForumReply *reply = [[ForumReply alloc] initWithDictionary:subdict];
                    if (reply) {
                        [subReplies addObject:reply];
                    }
                }
                _replies = [NSArray arrayWithArray:subReplies];
            }
            obj = [dict objectForKey:@"topic"];
            if ([obj isKindOfClass:[NSDictionary class]]) {
                _topic = [[ForumTopic alloc] initWithDictionary:obj];
            }
            
            obj = [dict objectForKey:@"images"];
            if ([obj isKindOfClass:[NSArray class]]) {
                _images = obj;
            }
        }
    }
    return self;
}

- (void)checkContent
{
    self.containsImage = [self.content rangeOfString:@"<img"].location != NSNotFound;
    if (!self.containsImage) {
        _content = [_content stringByReplacingOccurrencesOfString:@"(:?<(?:div|p)[^>]*>)+" withString:@"\n" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _content.length)];
        _content = [_content stringByReplacingOccurrencesOfString:@"<br[^>]*>" withString:@"\n" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _content.length)];
        _content = [_content stringByReplacingOccurrencesOfString:@"</?[a-z][^>]*>" withString:@"" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _content.length)];
        _content = [_content stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
        _content = [_content stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
        _content = [_content stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
        _content = [_content stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        _content = [_content stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        _content = [_content stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        _content = [_content stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
        _content = [_content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else {
        _content = [_content stringByReplacingOccurrencesOfString:@"^(?:<(?:div|p)[^>]*><\\/(?:div|p)>)+" withString:@"" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _content.length)];
        _content = [_content stringByReplacingOccurrencesOfString:@"(?:<(?:div|p)[^>]+><\\/(?:div|p)>)+$" withString:@"" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _content.length)];
        _content = [_content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

- (void)setContent:(NSString *)content
{
    if (_content != content) {
        _content = content;
        _htmlWithTermLinks = nil;
        [self checkContent];
    }
}


- (NSString *)content
{
    if (self.shouldHideLowRatingContent) {
        return @"Content hidden due to low rating.";
    }
    return _content;
}

- (BOOL)shouldHideLowRatingContent
{
    return self.lowRating && !self.didUnlockLowRatingContent;
}

- (BOOL)isAnonymous
{
    return (self.flags & ForumReplyFlagAnonymous) ? YES : NO;
}

- (NSString *)htmlWithTermLinks
{
    if (!_htmlWithTermLinks) {
        _htmlWithTermLinks =  [Forum replaceTermLinksInHtml:self.content caseSensitive:YES];
    }
    return _htmlWithTermLinks;
}

@end
