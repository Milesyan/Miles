//
//  User+Fitbit.m
//  emma
//
//  Created by Eric Xu on 3/3/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//



#import "User+Fitbit.h"
#import "OAuth1_0.h"
#import "OAuth1Controller.h"
#import "Nutrition.h"


@implementation User (Fitbit)

+ (NSString *)fitbitOauthToken {
    return [Utils getDefaultsForKey:UDK_FITBIT_OAUTH_TOKEN];
}
+ (void)setFitbitOauthToken:(NSString *)fitbitOauthToken {
    [Utils setDefaultsForKey:UDK_FITBIT_OAUTH_TOKEN withValue:fitbitOauthToken];
}
+ (NSString *)fitbitOauthTokenSecret {
    return [Utils getDefaultsForKey:UDK_FITBIT_OAUTH_SECRET];
}
+ (void)setFitbitOauthTokenSecret:(NSString *)fitbitOauthTokenSecret {
    [Utils setDefaultsForKey:UDK_FITBIT_OAUTH_SECRET withValue:fitbitOauthTokenSecret];
}



+ (void)signUpWithFitbit {
    GLLog(@"signUpWithFitbit");
    
    [OAuth1Controller authWithConsumerKey:FITBIT_CONSUMER_KEY
                           consumerSecret:FITBIT_CONSUMER_SECRET
                                  authUrl:FITBIT_AUTH_URL
                         requestTokenPath:FITBIT_REQUEST_TOKEN_URL
                         authenticatePath:FITBIT_AUTHENTICATE_URL
                          accessTokenPath:FITBIT_ACCESS_TOKEN_URL
                              callbackURL:FITBIT_OAUTH_CALLBACK
                         andCallbackBlock:^(NSDictionary *ret, NSError *error) {
                             if (error) {
                                 [self publish:EVENT_USER_SIGNUP_FAILED data:@"Can not authenticate with Fitbit."];
                             } else {
                                 [self setFitbitOauthTokenSecret:ret[@"oauth_token_secret"]];
                                 [self setFitbitOauthToken:ret[@"oauth_token"]];
                                 
                                 NSString *fitbitid = ret[@"encoded_user_id"];
                                 
                                 [self fetchUserByFitbitID:fitbitid
                                                 dataStore:[DataStore defaultStore]
                                          completionHandler:^(User *user, NSError *error) {
                                              if (!error) {
                                                  if (user) {
                                                      [self setFitbitOauthTokenSecret:nil];
                                                      [self setFitbitOauthToken:nil];

                                                      [self publish:EVENT_USER_SIGNUP_FAILED
                                                               data:@"Your Fitbit account has already connected to an existing Glow account."];
                                                      return;
                                                  } else {
                                                      [OAuth1Controller getFromAPIUrl:FITBIT_API_URL
                                                                                 path:@"1/user/-/profile.json"
                                                                           parameters:nil
                                                                      WithConsumerKey:FITBIT_CONSUMER_KEY
                                                                       consumerSecret:FITBIT_CONSUMER_SECRET
                                                                           oauthToken:[User fitbitOauthToken]
                                                                          oauthSecret:[User fitbitOauthTokenSecret]
                                                                          andCallback:^(NSDictionary *ret, NSError *error) {
                                                                              GLLog(@"ret: %@ err: %@", ret, error);
                                                                              if (!error) {
                                                                                  NSMutableDictionary *respData = [NSMutableDictionary dictionaryWithDictionary:ret[@"user"]];
                                                                                  respData[@"oauth_token"] = [User fitbitOauthToken];
                                                                                  respData[@"oauth_secret"] = [User fitbitOauthTokenSecret];

                                                                                  [self createAccountWithFitbit:respData
                                                                                                      dataStore:[DataStore defaultStore]
                                                                                              completionHandler:^(User *user, NSError *error) {
                                                                                                   [user login];
                                                                                              }];
                                                                              }
                                                                          }];
                                                                                  
                                                      
                                                  }
                                              }

                                          }];
                             }

                         }];
}

+ (void)createAccountWithFitbit:(NSDictionary *)fitbitinfo dataStore:(DataStore *)ds completionHandler:(CreateAccountCallback)callback {
    [[Network sharedNetwork] post:@"users/fitbit"
                             data:@{@"fitbitinfo": fitbitinfo,
                                    @"onboardinginfo": [Settings createPushRequestForNewUserWith:[Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS]]}
                     requireLogin:NO
                completionHandler:^(NSDictionary *result, NSError *err) {
                    NSDictionary *userData = [result objectForKey:@"user"];
                    if (err || [userData objectForKey:@"msg"]) {
                        return;
                    }

                    [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:nil];
                    User *user = [User upsertWithServerData:userData dataStore:ds];
                    [user save];
                    [FBAppEvents logEvent:FBAppEventNameCompletedRegistration
                        parameters:@{FBAppEventParameterNameRegistrationMethod:
                        @"Fitbit"}];
                    callback(user, err);
                }];
}

+ (void)fetchUserByFitbitID:(NSString *)fitbitId dataStore:(DataStore *)ds completionHandler:(FetchUserCallback)callback {
    NSString *apiPath = [NSString stringWithFormat:@"users/fitbit/%@", fitbitId];
    [[Network sharedNetwork] get:apiPath completionHandler:^(NSDictionary *data, NSError *error){
        User *user = nil;
        if (!error) {
            id userData = [data objectForKey:@"user"];
            if (userData != [NSNull null]) {
                user = [User upsertWithServerData:userData dataStore:ds];
                [user save];
            }
        }
        callback(user, error);
    }];
}

+ (void)getUserInfoFromFitbitAndSignIn {
    [OAuth1Controller authWithConsumerKey:FITBIT_CONSUMER_KEY
                           consumerSecret:FITBIT_CONSUMER_SECRET
                                  authUrl:FITBIT_AUTH_URL
                         requestTokenPath:FITBIT_REQUEST_TOKEN_URL
                         authenticatePath:FITBIT_AUTHENTICATE_URL
                          accessTokenPath:FITBIT_ACCESS_TOKEN_URL
                              callbackURL:FITBIT_OAUTH_CALLBACK
                         andCallbackBlock:^(NSDictionary *ret, NSError *error) {
                             [self fetchUserByFitbitID:ret[@"encoded_user_id"]
                                             dataStore:[DataStore defaultStore]
                                     completionHandler:^(User *user, NSError *error) {
                                          if (!error) {
                                              if (!user) {
                                                  [self publish:EVENT_USER_LOGIN_FAILED
                                                           data:@"There's no Glow account connected with your Fitbit account. Please sign up."];
                                                  return;
                                              }
                                              [user login];
                                          }
                                      }];
                         }];
}

+ (void)signInWithFitbit {
    GLLog(@"signInWithFitbit");

    [OAuth1Controller authWithConsumerKey:FITBIT_CONSUMER_KEY
                           consumerSecret:FITBIT_CONSUMER_SECRET
                                  authUrl:FITBIT_AUTH_URL
                         requestTokenPath:FITBIT_REQUEST_TOKEN_URL
                         authenticatePath:FITBIT_AUTHENTICATE_URL
                          accessTokenPath:FITBIT_ACCESS_TOKEN_URL
                              callbackURL:FITBIT_OAUTH_CALLBACK
                         andCallbackBlock:^(NSDictionary *ret, NSError *error) {
                             GLLog(@"ret: %@ err:%@",ret, error);
                             if (error) {
                                 GLLog(@"error can not!!!!!!!!!: %@", error);
                                 [self publish:EVENT_USER_LOGIN_FAILED data:@"Can not authenticate with Fitbit."];
                             } else {
                                 [self setFitbitOauthTokenSecret:ret[@"oauth_token_secret"]];
                                 [self setFitbitOauthToken:ret[@"oauth_token"]];

                                 [self fetchUserByFitbitID:ret[@"encoded_user_id"]
                                                 dataStore:[DataStore defaultStore]
                                         completionHandler:^(User *user, NSError *error) {
                                             if (!error) {
                                                 if (!user) {
                                                     [self publish:EVENT_USER_LOGIN_FAILED
                                                              data:@"There's no Glow account connected with your Fitbit account. Please sign up."];
                                                     return;
                                                 }
                                                 [user login];
                                                 if (![User fitbitOauthToken] || ![User fitbitOauthTokenSecret]) {
                                                     [user renewFitbitToken];
                                                 }
                                             }
                                         }];
                             }
                         }];
 }
- (void)disconnectFitbitForUser {
    GLLog(@"disconnectFitbitForUser");

    if (!self.fitbitId) return;
    NSDictionary *request = [self postRequest:@{@"fitbitid": self.fitbitId}];
    [[Network sharedNetwork] post:@"users/disconnect_fitbit" data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (err) {
            [self publish:EVENT_USER_DISCONNECT_FITBIT_FAILED data:@"Failed to connect to the server"];
        } else {
            [User setFitbitOauthTokenSecret:nil];
            [User setFitbitOauthToken:nil];
            self.fitbitId = nil;
            [self save];
            [self publish:EVENT_USER_FITBIT_UPDATED];
        }
    }];

}

- (BOOL)connectFitbitWithTokens {
    __block BOOL validToken = YES;

    [OAuth1Controller getFromAPIUrl:FITBIT_API_URL
                               path:@"1/user/-/profile.json"
                         parameters:nil
                    WithConsumerKey:FITBIT_CONSUMER_KEY
                     consumerSecret:FITBIT_CONSUMER_SECRET
                         oauthToken:[User fitbitOauthToken]
                        oauthSecret:[User fitbitOauthTokenSecret]
                        andCallback:^(NSDictionary *ret, NSError *error) {
                            GLLog(@"ret: %@ err: %@", ret, error);
                            if (error || !ret || ![ret count]) {
                                validToken = NO;
                            } else {
                                NSMutableDictionary *respData = [NSMutableDictionary dictionaryWithDictionary:ret[@"user"]];
                                respData[@"oauth_token"] = [User fitbitOauthToken];
                                respData[@"oauth_secret"] = [User fitbitOauthTokenSecret];
                                
                                NSDictionary *request = [self postRequest:@{@"fitbitinfo": respData}];
                                [[Network sharedNetwork] post:@"users/connect_fitbit" data:request requireLogin:YES completionHandler:^(NSDictionary *data, NSError *error){
                                    GLLog(@"post back data:%@  error:%@ %@", data, error, [error class]);
                                    [self publish:EVENT_USER_ADD_FITBIT_RETURNED];
                                    if (error) {
                                        [self publish:EVENT_USER_ADD_FITBIT_FAILED data:@"Failed to connect to the server"];
                                        [User setFitbitOauthToken:nil];
                                        [User setFitbitOauthTokenSecret:nil];
                                    } else if (data[@"error_msg"]) {
                                        [self publish:EVENT_USER_ADD_FITBIT_FAILED data:data[@"error_msg"]];
                                        [User setFitbitOauthToken:nil];
                                        [User setFitbitOauthTokenSecret:nil];
                                    }
                                    else {
                                        [self updateUserInfoWithFibitUserData:ret[@"user"]];
                                        [self publish:EVENT_USER_FITBIT_UPDATED];
                                    }
                                }];
                            }
                        }];
    return validToken;
}
- (void)connectFitbitForUser {
    GLLog(@"connectFitbitForUser");
    BOOL succeed = NO;
    
    if ([User fitbitOauthToken] && [User fitbitOauthTokenSecret]) {
        succeed = [self connectFitbitWithTokens];
    }
    
    if (!succeed) {
        [User setFitbitOauthToken:nil];
        [User setFitbitOauthTokenSecret:nil];
        
        [OAuth1Controller authWithConsumerKey:FITBIT_CONSUMER_KEY
                               consumerSecret:FITBIT_CONSUMER_SECRET
                                      authUrl:FITBIT_AUTH_URL
                             requestTokenPath:FITBIT_REQUEST_TOKEN_URL
                             authenticatePath:FITBIT_AUTHENTICATE_URL
                              accessTokenPath:FITBIT_ACCESS_TOKEN_URL
                                  callbackURL:FITBIT_OAUTH_CALLBACK
                             andCallbackBlock:^(NSDictionary *ret, NSError *error) {
                                 if (!error) {
                                     [User setFitbitOauthTokenSecret:ret[@"oauth_token_secret"]];
                                     [User setFitbitOauthToken:ret[@"oauth_token"]];
                                     
                                     [self connectFitbitWithTokens];
                                 } else {
                                     [self publish:EVENT_USER_ADD_FITBIT_FAILED data:@"Failed to authenticate with Fitbit."];
                                 }
                             }];

    }

    return;
}

- (void)renewFitbitToken {
    __block BOOL ok = NO;
    if ([User fitbitOauthToken] && [User fitbitOauthTokenSecret]) {
        [OAuth1Controller getFromAPIUrl:FITBIT_API_URL
                                   path:@"1/user/-/profile.json"
                             parameters:nil
                        WithConsumerKey:FITBIT_CONSUMER_KEY
                         consumerSecret:FITBIT_CONSUMER_SECRET
                             oauthToken:[User fitbitOauthToken]
                            oauthSecret:[User fitbitOauthTokenSecret]
                            andCallback:^(NSDictionary *ret, NSError *error) {
                                GLLog(@"ret: %@ err: %@", ret, error);
                                if (!error) {
                                    ok = YES;
                                }
                            }];
    }

    if (!ok) {
        [User setFitbitOauthToken:nil];
        [User setFitbitOauthTokenSecret:nil];
        
        [OAuth1Controller authWithConsumerKey:FITBIT_CONSUMER_KEY
                               consumerSecret:FITBIT_CONSUMER_SECRET
                                      authUrl:FITBIT_AUTH_URL
                             requestTokenPath:FITBIT_REQUEST_TOKEN_URL
                             authenticatePath:FITBIT_AUTHENTICATE_URL
                              accessTokenPath:FITBIT_ACCESS_TOKEN_URL
                                  callbackURL:FITBIT_OAUTH_CALLBACK
                             andCallbackBlock:^(NSDictionary *ret, NSError *error) {
                                 if (!error) {
                                     [User setFitbitOauthTokenSecret:ret[@"oauth_token_secret"]];
                                     [User setFitbitOauthToken:ret[@"oauth_token"]];
                                 }
                             }];
        
    }
}

- (void)updateUserInfoWithFibitUserData:(NSDictionary *)data {
    
    self.fitbitId = data[@"encodedId"];
    
    NSString *fullname = data[@"fullName"];
    NSArray *a = [fullname componentsSeparatedByString:@" "];
    NSString *firstname = fullname;
    NSString *lastname = @"";
    if ([a count] > 1) {
        lastname = (NSString *)[a lastObject];
        firstname = [fullname stringByReplacingOccurrencesOfString:lastname withString:@""];
    }
    
    if (!self.firstName) {
        self.firstName = firstname;
    }
    if (!self.lastName) {
        self.lastName = lastname;
    }
    if (!self.fbId && !self.profileImageUrl) {
        self.profileImageUrl = data[@"avatar150"];
    }
    if (!self.gender) {
        self.gender = data[@"gender"] ? ([data[@"gender"] isEqualToString:@"MALE"]? @"M": @"F"): @"F";
    }
    
    if ([data[@"gender"] isEqualToString:@"FEMALE"]) {
        if (!self.settings.weight && [data[@"weight"] floatValue]) {
            float weight = [data[@"weight"] floatValue];
            if (![data[@"weightUnit"] isEqualToString:@"METRIC"]) {
                weight = weight * 0.4536;
            }
            [self.settings update:@"weight" floatValue:weight];
        }
        if (!self.settings.height && [data[@"height"] floatValue]) {
            float height = [data[@"height"] floatValue];
            if (![data[@"heightUnit"] isEqualToString:@"METRIC"]) {
                height = height * 2.54;
            }
            [self.settings update:@"height" floatValue:height];
        }
        
    }
    
    [self save];
}

- (BOOL)isFitbitConnected {
    return self.fitbitId != nil;
}

- (void)syncFitbitNutritionsForDate:(NSString *)dateLabel {
    
    if (![User fitbitOauthToken] || ![User fitbitOauthTokenSecret]) {
        [self renewFitbitToken];
    }

    [OAuth1Controller getFromAPIUrl:FITBIT_API_URL
                               path:@"1/user/-/activities/goals/daily.json"
                         parameters:nil
                    WithConsumerKey:FITBIT_CONSUMER_KEY
                     consumerSecret:FITBIT_CONSUMER_SECRET
                         oauthToken:[User fitbitOauthToken]
                        oauthSecret:[User fitbitOauthTokenSecret]
                        andCallback:^(NSDictionary *ret, NSError *error) {
//                            GLLog(@"dic: %@", ret);
                            if (ret[@"goals"] && ret[@"goals"][@"caloriesOut"]) {
                                [Utils setDefaultsForKey:UDK_FITBIT_CALORIE_GOAL withValue:ret[@"goals"][@"caloriesOut"]];
                            }
                        }];
    NSString *fitbitDate = [dateLabel stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    [OAuth1Controller getFromAPIUrl:FITBIT_API_URL
                               path:[NSString stringWithFormat:@"1/user/-/foods/log/date/%@.json", fitbitDate]
                         parameters:nil
                    WithConsumerKey:FITBIT_CONSUMER_KEY
                     consumerSecret:FITBIT_CONSUMER_SECRET
                         oauthToken:[User fitbitOauthToken]
                        oauthSecret:[User fitbitOauthTokenSecret]
                        andCallback:^(NSDictionary *ret, NSError *error) {
                            GLLog(@"dic: %@", ret);
                            if (ret[@"summary"]) {
                                NSDictionary *summary = ret[@"summary"];

                                Nutrition *n = [Nutrition tset:dateLabel forUser:[User currentUser]];
                                if (summary[@"calories"] && ![summary[@"calories"] isKindOfClass:[NSNull class]]) {
                                    n.calorieIn = [summary[@"calories"] floatValue];
                                }
                                if (summary[@"carbs"] && ![summary[@"carbs"] isKindOfClass:[NSNull class]]) {
                                    n.carbohydrates = [summary[@"carbs"] floatValue];
                                }

                                if (summary[@"fat"] && ![summary[@"fat"] isKindOfClass:[NSNull class]]) {
                                    n.fat = [summary[@"fat"] floatValue];
                                }

                                if (summary[@"protein"] && ![summary[@"protein"] isKindOfClass:[NSNull class]]) {
                                    n.protein = [summary[@"protein"] floatValue];
                                }

                                n.updatedTime = [NSDate date];
                                n.src = NUTRITION_SRC_FITBIT;
                                n.nsdate = [Utils dateWithDateLabel:dateLabel];
                                GLLog(@"fgood; %@", n);
                                [n save];
                                
                                [self publish:EVENT_CHART_NEEDS_UPDATE_CALORIE];
                                [self publish:EVENT_CHART_NEEDS_UPDATE_NUTRITION];

                            }
                        }];
    [OAuth1Controller getFromAPIUrl:FITBIT_API_URL
                               path:[NSString stringWithFormat:@"1/user/-/activities/date/%@.json", fitbitDate]
                         parameters:nil
                    WithConsumerKey:FITBIT_CONSUMER_KEY
                     consumerSecret:FITBIT_CONSUMER_SECRET
                         oauthToken:[User fitbitOauthToken]
                        oauthSecret:[User fitbitOauthTokenSecret]
                        andCallback:^(NSDictionary *ret, NSError *error) {
                            GLLog(@"dic2: %@", ret);
                            if (ret[@"summary"]) {
                                NSDictionary *summary = ret[@"summary"];
                                
                                Nutrition *n = [Nutrition tset:dateLabel forUser:[User currentUser]];
                                if (summary[@"caloriesOut"] && ![summary[@"caloriesOut"] isKindOfClass:[NSNull class]]) {
                                    n.calorieOut = [summary[@"caloriesOut"] floatValue];
                                }

                                n.updatedTime = [NSDate date];
                                n.src = NUTRITION_SRC_FITBIT;
                                n.nsdate = [Utils dateWithDateLabel:dateLabel];
                                [n save];
                                
                                [self publish:EVENT_CHART_NEEDS_UPDATE_CALORIE];
                            }
                        }];


}

@end
