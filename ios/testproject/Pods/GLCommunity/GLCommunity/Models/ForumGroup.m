//
//  ForumGroup.m
//  GLCommunity
//
//  Created by Allen Hsu on 11/4/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/NSDictionary+Accessors.h>
#import <GLFoundation/UIColor+Utils.h>
#import "ForumGroup.h"

@implementation ForumGroup

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            _identifier = [dict unsignedLongLongForKey:@"id"];
            _categoryId = [dict unsignedIntForKey:@"category_id"];
            _creatorId = [dict unsignedLongLongForKey:@"creator_id"];
            _type = [dict unsignedIntegerForKey:@"type"];
//            _categoryType = [dict unsignedLongLongForKey:@"category_type"];
            
            NSString *colorString = [dict stringForKey:@"color"];
            if (colorString) {
                _color = [UIColor colorFromWebHexValue:colorString];
            }
            
            _name = [dict stringForKey:@"name"];
            _creatorName = [dict stringForKey:@"creator_name"];
            _desc = [dict stringForKey:@"description"];
            _image = [dict stringForKey:@"image"];
            
            _flags = [dict unsignedIntForKey:@"flags"];
            _members = [dict unsignedLongLongForKey:@"members"];
            _membersDisplay = [dict stringForKey:@"members_display"];
            
            _indexable = [dict boolForKey:@"indexable"];
            
            _timeCreated = [dict unsignedIntForKey:@"time_created"];
            _timeModified = [dict unsignedIntForKey:@"time_modified"];
            _timeRemoved = [dict unsignedIntForKey:@"time_removed"];
            
            if (dict[@"subscribed"]) {
                _subscribed = [dict unsignedIntForKey:@"subscribed"];
            }
        }
    }
    return self;
}

- (BOOL)isBookmark
{
    return self.type == ForumGroupBookmarked || self.type == ForumGroupCreated || self.type == ForumGroupParticipated;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ForumGroup class]]) {
        ForumGroup *g2 = (ForumGroup *)object;
        return self.type == g2.type && self.identifier == g2.identifier;
    }
    return [super isEqual:object];
}

- (NSUInteger)hash
{
    NSString *key = [NSString stringWithFormat:@"%lu-%llu", self.type, self.identifier];
    return [key hash];
}

- (UIColor *)color
{
    if (_color) {
        return _color;
    }
    return GLOW_COLOR_PURPLE;
}

+ (ForumGroup *)topGroup
{
    static ForumGroup *sGroup = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *dict = @{@"id": @0,
                               @"name": @"TOP",
//                               @"description": @"Hot topics in Glow Community",
                               @"type": @(ForumGroupHot),
                               @"color": @"#fa5f44",
                               };
        sGroup = [[ForumGroup alloc] initWithDictionary:dict];
    });
    return sGroup;
}

+ (ForumGroup *)feedGroup
{
    static ForumGroup *sGroup = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *dict = @{@"id": @0,
                               @"name": @"NEW",
//                               @"description": @"Hot topics in Glow Community",
                               @"type": @(ForumGroupNew),
                               @"color": @"#fa5f44",
                               };
        sGroup = [[ForumGroup alloc] initWithDictionary:dict];
    });
    return sGroup;
}

+ (ForumGroup *)bookmarkedGroup
{
    static ForumGroup *sGroup = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *dict = @{@"id": @0,
                               @"name": @"Bookmarked",
//                               @"description": @"All your bookmarked topics",
                               @"type": @(ForumGroupBookmarked),
                               @"color": @"#333333",
//                               @"category_type": @(ForumCategoryTypeBookmarked),
                               };
        sGroup = [[ForumGroup alloc] initWithDictionary:dict];
    });
    return sGroup;
}

+ (ForumGroup *)createdGroup
{
    static ForumGroup *sGroup = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *dict = @{@"id": @0,
                               @"name": @"Created",
//                               @"description": @"All your created topics",
                               @"type": @(ForumGroupCreated),
                               @"color": @"#333333",
//                               @"category_type": @(ForumCategoryTypeCreated),
                               };
        sGroup = [[ForumGroup alloc] initWithDictionary:dict];
    });
    return sGroup;
}

+ (ForumGroup *)participatedGroup
{
    static ForumGroup *sGroup = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *dict = @{@"id": @0,
                               @"name": @"Participated",
//                               @"description": @"All your participated topics",
                               @"type": @(ForumGroupParticipated),
                               @"color": @"#333333",
//                               @"category_type": @(ForumCategoryTypeParticipated),
                               };
        sGroup = [[ForumGroup alloc] initWithDictionary:dict];
    });
    return sGroup;
}

+ (ForumGroup *)groupsGroup
{
    static ForumGroup *sGroup = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *dict = @{@"id": @0,
                               @"name": @"Groups",
//                               @"description": @"All groups",
                               @"type": @(ForumGroupGroups),
                               @"color": @"#9e9e9e",
                               };
        sGroup = [[ForumGroup alloc] initWithDictionary:dict];
    });
    return sGroup;
}

+ (ForumGroup *)rulesGroup
{
    static ForumGroup *sGroup = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *dict = @{@"id": @0,
                               @"name": @"Community Rules",
//                               @"description": @"All groups",
                               @"type": @(ForumGroupRules),
                               @"color": @"#5a62d2",
                               };
        sGroup = [[ForumGroup alloc] initWithDictionary:dict];
    });
    return sGroup;
}

+ (NSArray *)aggregatedGroups
{
    return @[[self bookmarkedGroup], [self createdGroup], [self participatedGroup]];
}

@end
