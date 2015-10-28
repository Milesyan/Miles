//
//  ForumUser.m
//  emma
//
//  Created by Allen Hsu on 11/22/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/NSDictionary+Accessors.h>
#import <BlocksKit/NSArray+BlocksKit.h>
#import "ForumUser.h"
#import "Forum.h"
#import "ForumGroup.h"


@interface ForumUser ()

@property (nonatomic, assign) BOOL isReloadingSocialInfo;

@end


@implementation ForumUser

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            _identifier = [dict unsignedLongLongForKey:@"id"];
            _birthday = [dict longLongForKey:@"birthday"];
            _type = [dict unsignedIntForKey:@"type"];
            _firstName = [dict stringForKey:@"first_name"];
            _lastName = [dict stringForKey:@"last_name"];
            _profileImage = [dict stringForKey:@"profile_image"];
            _backgroundImage = [dict stringForKey:@"background_image"];
            _bio = [dict stringForKey:@"bio"];
            _location = [dict stringForKey:@"location"];
            _badge = [dict stringForKey:@"badge"];
            _buttonText = [dict stringForKey:@"button_text"];
            _buttonUrl = [dict stringForKey:@"button_url"];
            _gender = [dict stringForKey:@"gender"];
            _hidePosts = [dict unsignedIntegerForKey:@"hide_posts"];
            _groupsCount = [dict unsignedIntegerForKey:@"groups_count"];
            _followersCount = [dict unsignedIntegerForKey:@"followers_count"];
            _followingsCount = [dict unsignedIntegerForKey:@"followings_count"];
        }
    }
    return self;
}

- (void)updateWithDict:(NSDictionary *)dict
{
    self.followersCount = [dict unsignedIntegerForKey:@"followers_count"];
    self.followingsCount = [dict unsignedIntegerForKey:@"followings_count"];
    self.groupsCount = [dict unsignedIntegerForKey:@"groups_count"];
    self.hidePosts = [dict unsignedIntegerForKey:@"hide_posts"];
    self.type = [dict unsignedIntForKey:@"type"];
    self.badge = [dict stringForKey:@"badge"];
}

- (BOOL)isForumAdmin
{
    return (self.type == ForumUserTypeForumAdmin);
}

- (BOOL)isNormalUser
{
    return (self.type == 0 || self.type == ForumUserTypeNormal);
}

- (BOOL)isMyself
{
    ForumUser *myself = [Forum currentForumUser];
    return (myself.identifier == self.identifier);
}

- (BOOL)isAgeFiltered
{
    return [Forum isBirthdayFiltered:self.birthday];
}

- (BOOL)isMale
{
    return [self.gender isEqual:FORUM_MALE];
}

- (BOOL)isFemale
{
    return [self.gender isEqual:FORUM_FEMALE];
}

- (BOOL)shouldHideTopic
{
    if ([self isMyself]) {
        return NO;
    } else if (![self isNormalUser]) {
        return NO;
    } else {
        return [self isAgeFiltered];
    }
}


#pragma mark - social 


- (BOOL)isSubscribingGroup:(uint64_t)groupid
{
    for (ForumGroup *each in self.groups) {
        if (each.identifier == groupid) {
            return YES;
        }
    }
    return NO;
}


- (BOOL)isFollowingUser:(uint64_t)uid
{
    for (ForumUser *each in self.followings) {
        if (each.identifier == uid) {
            return YES;
        }
    }
    return NO;
}


- (BOOL)needFetchSocialInfo
{
    if (self.isReloadingSocialInfo) {
        return NO;
    }
    return !self.groups || !self.followers || !self.followings;
}


- (void)fetchSocialInfoWithCompletion:(UserActionCompletion)completion
{
    if (self.isReloadingSocialInfo) {
        return;
    }
    
    self.isReloadingSocialInfo = YES;
    
    [Forum fetchSocialInfoForUser:self.identifier callback:^(NSDictionary *result, NSError *error) {
        self.isReloadingSocialInfo = NO;
        
        if (!error && result) {
            NSArray *groups = result[@"groups"];
            NSArray *followers = result[@"followers"];
            NSArray *followings = result[@"followings"];
            
            self.groups = [groups bk_map:^id(id obj) {
                return [[ForumGroup alloc] initWithDictionary:obj];
            }];
            
            self.followers = [followers bk_map:^id(id obj) {
                return [[ForumUser alloc] initWithDictionary:obj];
            }];
            
            self.followings = [followings bk_map:^id(id obj) {
                return [[ForumUser alloc] initWithDictionary:obj];
            }];
            
            self.groupsCount = self.groups.count;
            self.followersCount = self.followers.count;
            self.followingsCount = self.followings.count;
            
            if (completion) {
                completion(YES, nil);
            }
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}


- (void)followUser:(ForumUser *)user completion:(UserActionCompletion)completion
{
    @weakify(self)
    [Forum followUser:user.identifier callback:^(NSDictionary *result, NSError *error)
    {
        if (!error && [result[@"rc"] integerValue] == RC_SUCCESS) {
            @strongify(self)
            
            self.followingsCount += 1;
            self.followings = [self.followings arrayByAddingObject:user];
            
            user.followersCount += 1;
            if (user.followers) {
                user.followers = [user.followers arrayByAddingObject:self];
            }
            
            if (completion) {
                completion(YES, nil);
            }
            
            [self publish:kFollowingCountChangedNotification];
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
        
    }];
}


- (void)unfollowUser:(ForumUser *)user completion:(UserActionCompletion)completion
{
    @weakify(self)
    [Forum unfollowUser:user.identifier callback:^(NSDictionary *result, NSError *error)
    {
        if (!error && [result[@"rc"] integerValue] == RC_SUCCESS) {
            @strongify(self)
            
            self.followingsCount -= 1;
            self.followings = [self.followings bk_select:^BOOL(id obj) {
                return user.identifier != [(ForumUser *)obj identifier];
            }];
            
            user.followersCount -= 1;
            if (user.followers) {
                user.followers = [user.followers bk_select:^BOOL(id obj) {
                    return self.identifier != [(ForumUser *)obj identifier];
                }];
            }
            
            if (completion) {
                completion(YES, nil);
            }
            
            [self publish:kFollowingCountChangedNotification];
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
        
    }];
}


- (void)leaveGroup:(ForumGroup *)group completion:(UserActionCompletion)completion
{
    @weakify(self)
    [Forum leaveGroup:group.identifier callback:^(NSDictionary *result, NSError *error) {
        if (!error && [result[@"rc"] integerValue] == RC_SUCCESS) {
            @strongify(self)
            
            self.groupsCount -= 1;
            self.groups = [self.groups bk_select:^BOOL(id obj) {
                return group.identifier != [(ForumGroup *)obj identifier];
            }];
            
            if (completion) {
                completion(YES, nil);
            }
            
            [self publish:kJoinedGroupsCountChangedNotification];
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

- (void)joinGroup:(ForumGroup *)group completion:(UserActionCompletion)completion
{
    @weakify(self)
    [Forum joinGroup:group.identifier callback:^(NSDictionary *result, NSError *error) {
        if (!error && [result[@"rc"] integerValue] == RC_SUCCESS) {
            @strongify(self)
            
            self.groupsCount += 1;
            self.groups = [self.groups arrayByAddingObject:group];
            group.subscribed = YES;
            
            if (completion) {
                completion(YES, nil);
            }
            
            [self publish:kJoinedGroupsCountChangedNotification];
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}


- (NSString *)debugDescription
{
    NSDictionary *desc = @{
                           @"First name": self.firstName,
                           @"User id": @(self.identifier),
                           @"Groups Count": @(self.groupsCount),
                           @"Followers Count": @(self.followersCount),
                           @"Following Count": @(self.followingsCount),
                           @"type": @(self.type),
                           @"badge": self.badge};
    return [NSString stringWithFormat:@"%@", desc];
}


@end




