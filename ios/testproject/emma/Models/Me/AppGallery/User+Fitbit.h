//
//  User+Fitbit.h
//  emma
//
//  Created by Eric Xu on 3/3/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "User.h"


#define EVENT_USER_ADD_FITBIT_RETURNED @"user_add_fitbit_returned"
#define EVENT_USER_ADD_FITBIT_FAILED @"user_add_fitbit_failed"
#define EVENT_USER_DISCONNECT_FITBIT_FAILED @"user_disconnect_fitbit_failed"
#define EVENT_FITBIT_CONNECT_FAILED @"fitbit_connect_failed"
#define EVENT_USER_FITBIT_UPDATED @"user_fitbit_updated"

#define UDK_FITBIT_OAUTH_TOKEN @"fitbitOauthToken"
#define UDK_FITBIT_OAUTH_SECRET @"fitbitOauthSecret"
#define UDK_FITBIT_CALORIE_GOAL @"fitbitCalorieGoal"

#define FITBIT_CONNECT_FAILED_MSG @"Can not connect to Fitbit"


//#define FITBIT_CONSUMER_KEY @"15a2a4fefe294a50bbf2f2ac9de3ef32"
//#define FITBIT_CONSUMER_SECRET @"115c740c4d6d4ab09be0e5b08ee11c4b"
//#define FITBIT_BASE_URL @"api.fitbit.com"
//#define FITBIT_REQUEST_TOKEN_URL @"/oauth/request_token"
//#define FITBIT_ACCESS_TOKEN_URL @"/oauth/access_token"
//#define FITBIT_AUTHORIZE_URL @"/oauth/authorize"

#define FITBIT_OAUTH_CALLBACK       @"https://glowing.com"
#define FITBIT_AUTH_URL             @"https://api.fitbit.com/"
#define FITBIT_REQUEST_TOKEN_URL    @"oauth/request_token"
#define FITBIT_AUTHENTICATE_URL     @"oauth/authorize"
#define FITBIT_ACCESS_TOKEN_URL     @"oauth/access_token"
#define FITBIT_API_URL              @"https://api.fitbit.com/"
//#define OAUTH_SCOPE_PARAM    @""

#define REQUEST_TOKEN_METHOD @"POST"
#define ACCESS_TOKEN_METHOD  @"POST"


@interface User (Fitbit)

//@property (nonatomic, strong) NSString *fitbitOauthToken;
//@property (nonatomic, strong) NSString *fitbitOauthTokenSecret;
//@property (nonatomic, strong) NSString *encodedUserId;

+ (void)signUpWithFitbit;
+ (void)signInWithFitbit;
- (void)disconnectFitbitForUser;
- (void)connectFitbitForUser;
- (BOOL)isFitbitConnected;
- (void)syncFitbitNutritionsForDate:(NSString *)dateLabel;

@end
