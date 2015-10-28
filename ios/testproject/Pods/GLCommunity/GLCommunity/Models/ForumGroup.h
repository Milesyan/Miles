//
//  ForumGroup.h
//  GLCommunity
//
//  Created by Allen Hsu on 11/4/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ForumCategory.h"

typedef NS_ENUM(NSUInteger, ForumGroupType) {
    ForumGroupNormal        = 0,
    ForumGroupParticipated  = 1,
    ForumGroupBookmarked    = 2,
    ForumGroupCreated       = 3,
    ForumGroupHot           = 4,
    ForumGroupNew           = 5,
    ForumGroupGroups        = 6,
    ForumGroupRules         = 7,
};

@interface ForumGroup : NSObject

@property (assign, nonatomic) ForumGroupType type;
//@property (assign, nonatomic) ForumCategoryType categoryType;

@property (assign, nonatomic) uint64_t identifier;
@property (assign, nonatomic) uint32_t categoryId;
@property (assign, nonatomic) uint64_t creatorId;

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *creatorName;
@property (strong, nonatomic) NSString *desc;
@property (strong, nonatomic) NSString *image;

@property (assign, nonatomic) uint32_t flags;
@property (assign, nonatomic) uint64_t members;
@property (strong, nonatomic) NSString *membersDisplay;
@property (assign, nonatomic) BOOL indexable;

@property (assign, nonatomic) uint32_t timeCreated;
@property (assign, nonatomic) uint32_t timeModified;
@property (assign, nonatomic) uint32_t timeRemoved;

@property (assign, nonatomic) uint32_t subscribed;

@property (strong, nonatomic) UIColor *color;

- (id)initWithDictionary:(NSDictionary *)dict;
- (BOOL)isBookmark;

+ (ForumGroup *)topGroup;
+ (ForumGroup *)feedGroup;
+ (ForumGroup *)bookmarkedGroup;
+ (ForumGroup *)createdGroup;
+ (ForumGroup *)participatedGroup;
+ (ForumGroup *)groupsGroup;
+ (ForumGroup *)rulesGroup;

+ (NSArray *)aggregatedGroups;

@end
