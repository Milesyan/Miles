//
//  ForumUser.h
//  emma
//
//  Created by Allen Hsu on 11/22/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FORUM_MALE      @"M"
#define FORUM_FEMALE    @"F"

#define kJoinedGroupsCountChangedNotification @"kJoinedGroupsCountChangedNotification"
#define kFollowingCountChangedNotification @"kFollowingCountChangedNotification"

@class ForumUser;
@class ForumGroup;

typedef NS_ENUM(NSUInteger, ForumUserType) {
    ForumUserTypeNormal         = 10,
    ForumUserTypeAdmin          = 3,
    ForumUserTypeForumAdmin     = 11,
};

typedef void(^UserActionCompletion)(BOOL success, NSError *error);
typedef void(^FetchUserCompletion)(ForumUser *user, NSError *error);

@interface ForumUser : NSObject

@property (assign, nonatomic) uint64_t identifier;
@property (assign, nonatomic) unsigned int type;
@property (assign, nonatomic) int64_t birthday;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *profileImage;
@property (strong, nonatomic) NSString *backgroundImage;
@property (strong, nonatomic) NSString *bio;
@property (strong, nonatomic) NSString *location;
@property (strong, nonatomic) NSString *badge;

@property (strong, nonatomic) NSString *gender;
@property (assign, nonatomic) int16_t hidePosts;

@property (strong, nonatomic) NSString *buttonText;
@property (strong, nonatomic) NSString *buttonUrl;

@property (strong, nonatomic) UIImage *cachedProfileImage;
@property (strong, nonatomic) UIImage *cachedBackgroundImage;

// social info
@property (assign, nonatomic) NSUInteger groupsCount;
@property (assign, nonatomic) NSUInteger followersCount;
@property (assign, nonatomic) NSUInteger followingsCount;

@property (strong, nonatomic) NSArray *groups;
@property (strong, nonatomic) NSArray *followers;
@property (strong, nonatomic) NSArray *followings;

@property (assign, nonatomic) BOOL isGuest;


- (id)initWithDictionary:(NSDictionary *)dict;
- (void)updateWithDict:(NSDictionary *)dict;
- (BOOL)isForumAdmin;
- (BOOL)isNormalUser;
- (BOOL)isMyself;
- (BOOL)isAgeFiltered;
- (BOOL)shouldHideTopic;
- (BOOL)isMale;
- (BOOL)isFemale;

- (BOOL)isSubscribingGroup:(uint64_t)groupid;
- (BOOL)isFollowingUser:(uint64_t)uid;
- (BOOL)needFetchSocialInfo;
- (void)fetchSocialInfoWithCompletion:(UserActionCompletion)completion;

- (void)followUser:(ForumUser *)user completion:(UserActionCompletion)completion;
- (void)unfollowUser:(ForumUser *)user completion:(UserActionCompletion)completion;

- (void)leaveGroup:(ForumGroup *)group completion:(UserActionCompletion)completion;
- (void)joinGroup:(ForumGroup *)group completion:(UserActionCompletion)completion;

@end



