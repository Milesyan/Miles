//
//  User+Misfit.h
//  emma
//
//  Created by Xin Zhao on 10/28/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "User.h"
#import "Network.h"

#define EVENT_USER_ADD_MISFIT_RETURNED @"user_add_misfit_returned"
#define EVENT_USER_ADD_MISFIT_FAILED @"user_add_misfit_failed"
#define EVENT_USER_DISCONNECT_MISFIT_FAILED @"user_disconnect_misfit_failed"
#define EVENT_MISFIT_AUTH_FAILED @"misfit_auth_failed"
#define EVENT_MISFIT_TOKEN_AND_PROFILE_STAGE @"misfit_token_and_profile_stage"

#define MISFIT_AUTH_URL @"https://api.misfitwearables.com/auth/dialog/authorize"
#define MISFIT_TOKEN_URL @"https://api.misfitwearables.com/auth/tokens/exchange"
#define MISFIT_PROFILE_URL @"https://api.misfitwearables.com/move/resource/v1/user/me/profile"
#define MISFIT_SESSION_URL @"https://api.misfitwearables.com/move/resource/v1/user/me/activity/%@?start_date=%@&end_date=%@"
#define MISFIT_SCOPE @"public,birthday,email"
#define OAUTH_TYPE_MISFIT @"oauthTypeMisfit"
#define OAUTH_KEYCHAIN_GROUP_MISFIT @"oauthKeychainGroupMisfit"

#define MISFIT_CONST_STARTTIME    @"startTime"
#define MISFIT_CONST_DURATION     @"duration"
#define MISFIT_CONST_ACTIVITYTYPE @"activityType"
#define MISFIT_CONST_CALORIES     @"calories"
#define MISFIT_CONST_WALKING      @"Walking"

typedef enum {
    MisfitErrorTypeNotConnected = 0,
} MisfitErrorType;

@interface GLMisfit : NSObject

@end

@interface User (Misfit)


+ (void)misfitAuthForSignup;
+ (void)misfitAuthForSignin;
+ (void)misfitAuthForConnect;
+ (BOOL)misfitHandleForSignupWithCode:(NSString *)code;
+ (BOOL)misfitHandleForSigninWithCode:(NSString *)code;
+ (BOOL)misfitHandleForConnectWithCode:(NSString *)code;
+ (void)misfitFromServerInfo:(NSDictionary *)info forUser:(User *)user;

- (NSString *)getMisfitId;
- (void)setMisfitId:(NSString *)misfitId;
- (void)cleanupMisfitOnLogout;
- (BOOL)isConnectedWithMisfit;
- (void)disconnectMisfit;
- (void)syncMisfitActivitiesForDate:(NSString *)end forced:(BOOL)forced;
- (void)misfitSessionsFrom:(NSString *)start
                        to:(NSString *)end
                    forced:(BOOL)isForced;
- (void)misfitSleepsFrom:(NSString *)start
                      to:(NSString *)end
                  forced:(BOOL)isForced;

@end
