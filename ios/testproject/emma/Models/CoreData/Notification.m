//
//  Notification.m
//  emma
//
//  Created by Ryan Ye on 3/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "Notification.h"
#import "User.h"
#import "DataStore.h"

@interface Notification () 

@end

@implementation Notification

@dynamic id;
@dynamic type;
@dynamic text;
@dynamic title;
@dynamic unread;
@dynamic button;
@dynamic action;
@dynamic actionContext;
@dynamic timeCreated;
@dynamic user;
@dynamic hidden;

- (NSDictionary *)attrMapper {
    return @{
             @"id"              : @"id",
             @"type"            : @"type",
             @"unread"          : @"unread",
             @"user_action"     : @"action",
             @"action_context"  : @"actionContext",
             @"text"            : @"text",
             @"title"           : @"title",
             @"time_created"    : @"timeCreated",
             @"button"          : @"button"
            };
}

+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user {
    Notification *notif = [Notification tset:[data objectForKey:@"id"] forUser:user];
    [notif updateAttrsFromServerData:data];
    return notif;
}

+ (id)tset:(NSNumber *)notifId forUser:(User *)user {
    Notification *obj = [self fetchObject:@{@"id" : notifId} dataStore:user.dataStore];
    if (!obj) {
        obj = [self newInstance:user.dataStore];
        obj.user = user;
    }
    return obj;
}

- (void)setDirty:(BOOL)val {
    [super setDirty:val];
    if (val)
        self.user.dirty = YES;
}

- (NSMutableDictionary *)createPushRequest {
    NSMutableDictionary *request = [super createPushRequest];
    [request setObject:self.user.id forKey:@"user_id"];
    [request setObject:self.id forKey:@"id"];
    return request;
}

- (void)updateUserAction:(UserAction)action {
    [self update:@"action" value:@(action)];
}

- (void)markAsRead {
    if (self.unread)
        self.unread = NO;
}

- (void)hide {
    if (!self.hidden) {
        self.hidden = YES;
    }
    [self.user save];
}

-(DataStore *)dataStore {
    return self.user.dataStore;
}

@end
