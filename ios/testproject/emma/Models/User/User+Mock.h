//
//  User+Mock.h
//  emma
//
//  Created by Ryan Ye on 12/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

#define EVENT_MOCKED_NOTIFICATIONS_ADDED @"event_mocked_notifications_added"

@interface User(Mock)
+ (User *)mockUser;

@end
