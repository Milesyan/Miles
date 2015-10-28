//
//  User+Facebook.h
//  emma
//
//  Created by Ryan Ye on 12/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

#define EVENT_USER_ADD_FACEBOOK_RETURNED @"user_add_facebook_returned"
#define EVENT_USER_ADD_FACEBOOK_FAILED @"user_add_facebook_failed"
#define EVENT_USER_DISCONNECT_FACEBOOK_FAILED @"user_disconnect_facebook_failed"
#define EVENT_FB_CONNECT_FAILED @"fb_connect_failed"

#define FB_CONNECT_FAILED_MSG @"Can not connect to Facebook"

typedef void (^FBConnectCallback)(NSDictionary<FBGraphUser> *fbInfo);
typedef void (^FetchFacebookInfoCallback)(NSDictionary *fbInfo, NSError *error);

@interface User(Facebook)
@property (readonly) BOOL isFacebookConnected;

+ (FBSession *)session;
+ (void)clearFBSession;
+ (void)signInWithFacebook;
+ (void)signUpWithFacebook;
+ (void)signUpAsPartnerWithFacebook;
- (void)invitePartnerOnFacebook:(NSDictionary *)partnerFbInfo completionHandler:(InvitePartnerCallback)callback;
- (void)addFacebook;
- (void)disconnectFacebook;
- (void)fetchFacebookInfo:(FetchFacebookInfoCallback)callback;
@end
