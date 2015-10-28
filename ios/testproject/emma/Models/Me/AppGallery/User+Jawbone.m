
//
//  User+Jawbone.m
//  emma
//
//  Created by Eric Xu on 2/8/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "User+Jawbone.h"
#import "Network.h"
#import "Nutrition.h"
#import "DailyLogSummary.h"
#import "Settings.h"
#import "HealthProfileData.h"

@implementation User (Jawbone)



+ (void)signUpWithJawbone {
    GLLog(@"signUpWithJawbone");

	// Present login screen in a UIWebView.
	[[UPPlatform sharedPlatform] startSessionWithClientID:JAWBONE_APP_ID
                                             clientSecret:JAWBONE_APP_SECRET
                                                authScope:UPPlatformAuthScopeAll
                                               completion:^(UPSession *session, NSError *error) {
                                                   GLLog(@"compl:%@ %@", session, error);
                                                   if ((session != nil) && (session.authenticationToken != nil)) {
                                                       [UPUserAPI getCurrentUserWithCompletion:^(UPUser *upuser, UPURLResponse *response, NSError *error) {
                                                           GLLog(@"upuser: %@", upuser);
                                                           GLLog(@"resp: %@", response.data);
                                                           GLLog(@"error: %@", error);
                                                           [self fetchUserByJawboneID:upuser.xid
                                                                            dataStore:[DataStore defaultStore]
                                                                    completionHandler:^(User *user, NSError *error) {
                                                                        if (!error) {
                                                                            if (user) {
                                                                                [self publish:EVENT_USER_SIGNUP_FAILED
                                                                                         data:@"Your Jawbone UP account has already connected to an existing Glow account."];
                                                                                return;
                                                                            } else {
                                                                                NSMutableDictionary *respData = [NSMutableDictionary dictionaryWithDictionary:response.data];
                                                                                respData[@"token"] = session.authenticationToken;
                                                                                [self createAccountWithJawbone:respData
                                                                                                     dataStore:[DataStore defaultStore]
                                                                                             completionHandler:^(User *user, NSError *error) {
                                                                                                 [user login];
                                                                                             }];
                                                                            }
                                                                        }
                                                                    }];
                                                       }];

                                                   } else {
                                                       [self publish:EVENT_USER_SIGNUP_FAILED
                                                                data:@"Failed to connect with Jawbone UP service."];
                                                   }
                                               }];
}

+ (void)createAccountWithJawbone:(NSDictionary *)jawboneinfo dataStore:(DataStore *)ds completionHandler:(CreateAccountCallback)callback {
    [[Network sharedNetwork] post:@"users/jawbone"
                             data:@{@"jawboneinfo": jawboneinfo,
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
                        @"Jawbone"}];
                    callback(user, err);
                }];
}

+ (void)signInWithJawbone {
    GLLog(@"signInWithJawbone");
    
    [[UPPlatform sharedPlatform] validateSessionWithCompletion:^(UPSession *session, NSError *error) {
		if (!session) {
            [[UPPlatform sharedPlatform] startSessionWithClientID:JAWBONE_APP_ID
                                                     clientSecret:JAWBONE_APP_SECRET
                                                        authScope:UPPlatformAuthScopeAll
                                                       completion:^(UPSession *session, NSError *error) {
                                                           GLLog(@"lala~ %@ %@", session, error);
                                                           if (session) {
                                                               [self getUserInfoFromJawboneAndSignIn];
                                                           } else {
                                                               [self publish:EVENT_USER_LOGIN_FAILED
                                                                        data:@"Failed to connect with Jawbone UP service."];
                                                               return;
                                                           }
                                                       }];
		} else {
            [self getUserInfoFromJawboneAndSignIn];
        }
        
	}];
}

+ (void)getUserInfoFromJawboneAndSignIn {
    [UPUserAPI getCurrentUserWithCompletion:^(UPUser *user, UPURLResponse *response, NSError *error) {
        [self fetchUserByJawboneID:user.xid
                         dataStore:[DataStore defaultStore]
                 completionHandler:^(User *user, NSError *error) {
                     if (!error) {
                         if (!user) {
                             [self publish:EVENT_USER_LOGIN_FAILED
                                      data:@"There's no Glow account connected with your Jawbone UP account. Please sign up."];
                             return;
                         }
                         [user login];
                     }
                 }];
    }];
}

+ (void)fetchUserByJawboneID:(NSString *)jawboneId dataStore:(DataStore *)ds completionHandler:(FetchUserCallback)callback {
    NSString *apiPath = [NSString stringWithFormat:@"users/jawbone/%@", jawboneId];
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

- (void)disconnectJawboneForUser {
    GLLog(@"disconnectForUser");
    if (!self.jawboneId) return;
    NSDictionary *request = [self postRequest:@{@"jawboneid": self.jawboneId}];
    [[Network sharedNetwork] post:@"users/disconnect_jawbone" data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (err) {
            [self publish:EVENT_USER_DISCONNECT_JAWBONE_FAILED data:@"Failed to connect to the server"];
        } else {
            [[UPPlatform sharedPlatform] endCurrentSession];
            self.jawboneId = nil;
            [self save];
            [self publish:EVENT_USER_JAWBONE_UPDATED];
        }
    }];

}
- (void)connectJawboneForUser {
    GLLog(@"connectJawboneForUser");
    [UPPlatform sharedPlatform].enableNetworkLogging = YES;

    [[UPPlatform sharedPlatform] startSessionWithClientID:JAWBONE_APP_ID
                                             clientSecret:JAWBONE_APP_SECRET
                                                authScope:UPPlatformAuthScopeAll
                                               completion:^(UPSession *session, NSError *error) {
                                                   if (session != nil && session.authenticationToken) {
                                                       [UPUserAPI getCurrentUserWithCompletion:^(UPUser *user, UPURLResponse *response, NSError *error) {

                                                           GLLog(@"resp: %@ %@", response, error);
                                                           NSMutableDictionary *respData = [NSMutableDictionary dictionaryWithDictionary:response.data];
                                                           respData[@"token"] = session.authenticationToken;

                                                           NSDictionary *request = [self postRequest:@{@"jawboneinfo": respData}];
                                                           [[Network sharedNetwork] post:@"users/connect_jawbone" data:request requireLogin:YES completionHandler:^(NSDictionary *data, NSError *error){
                                                               [self publish:EVENT_USER_ADD_JAWBONE_RETURNED];
                                                               if (error) {
                                                                   [self publish:EVENT_USER_ADD_JAWBONE_FAILED data:@"Failed to connect to the server"];
                                                                   self.jawboneId = nil;
                                                                   [self save];
                                                                   [[UPPlatform sharedPlatform] endCurrentSession];
                                                               } else if (data[@"error_msg"]) {
                                                                   [self publish:EVENT_USER_ADD_JAWBONE_FAILED data:data[@"error_msg"]];
                                                                   self.jawboneId = nil;
                                                                   [self save];
                                                                   [[UPPlatform sharedPlatform] endCurrentSession];

                                                               }
                                                               else {
                                                                   [self updateUserInfoWithJawboneUser:user andResponseData:response.data];
                                                                   [self publish:EVENT_USER_JAWBONE_UPDATED];
                                                               }
                                                           }];
                                                       }];
                                                   } else {
                                                       [self publish:EVENT_USER_ADD_JAWBONE_RETURNED];
                                                       [self publish:EVENT_USER_ADD_JAWBONE_FAILED data:@"Failed to authenticate with Jawbone."];

//                                                       [[[UIAlertView alloc] initWithTitle:@"Error"
//                                                                                   message:@"Can not authenticate with Jawbone, please try again later."
//                                                                                  delegate:nil
//                                                                         cancelButtonTitle:@"OK"
//                                                                         otherButtonTitles:nil] show];
                                                   }
                                               }];
    GLLog(@"started one?? ");
}

- (void)updateUserInfoWithJawboneUser:(UPUser *)u andResponseData:(NSDictionary *)data {
    
    self.jawboneId = u.xid;
    
    if (!self.firstName) {
        self.firstName = u.firstName;
    }
    if (!self.lastName) {
        self.lastName = u.lastName;
    }
    if (!self.fbId && !self.profileImageUrl) {
        self.profileImageUrl = u.imageURL;
    }
    if (!self.gender) {
        self.gender = data[@"gender"] ? ([data[@"gender"] intValue] == UPUserGenderMale? @"M": @"F"): @"F";
    }
    
    if ([data[@"gender"] intValue] == UPUserGenderFemale) {
        if (!self.settings.weight && [data[@"weight"] floatValue]) {
            [self.settings update:@"weight" floatValue:[data[@"weight"] floatValue] * 100];
        }
        if (!self.settings.height && [data[@"height"] floatValue]) {
            [self.settings update:@"height" floatValue:[data[@"height"] floatValue] ];
        }
    }
    
    [self save];
}

- (BOOL)isJawboneConnected {
    GLLog(@"self.jawboneID: %@", self.jawboneId);
    return self.jawboneId != nil;
}

- (NSString *)dailyDataDateLabelFromJawboneDateLabel:(NSNumber *)num {
    GLLog(@"d: %d", [num intValue]);
    NSInteger x = [num integerValue];
    NSInteger m = (x % 10000)/100;
    NSInteger d = x % 100;
    return [NSString stringWithFormat:@"%ld/%@%ld/%@%ld", x/10000, m < 10? @"0": @"", (long)m, d < 10? @"0": @"", (long)d];
}

- (void)getTrends:(NSString *)dateLabel {
    [UPUserAPI getTrendsWithEndDate:[Utils dateWithDateLabel:dateLabel]
                          rangeType:UPUserTrendsRangeTypeDays
                      rangeDuration:30
                         bucketSize:UPUserTrendsBucketSizeDays
                         completion:^(NSArray *trends, UPURLResponse *response, NSError *error) {
                             if (response.data && response.data[@"data"]) {
                                 for (NSArray *d in response.data[@"data"]) {
                                     //                GLLog(@"d1:%@", d[1]);
                                     NSString *dateLabel = [self dailyDataDateLabelFromJawboneDateLabel:d[0]];
                                     //                GLLog(@"d0:%@", dateLabel);
                                     NSDictionary *dic = d[1];
                                     if (dateLabel && dic) {
                                         Nutrition *n = [Nutrition tset:dateLabel forUser:[User currentUser]];
                                         BOOL hasData = NO;
                                         if (dic[@"e_calories"] && ![dic[@"e_calories"] isKindOfClass:[NSNull class]]) {
                                             n.calorieIn = [dic[@"e_calories"] floatValue];
                                             hasData = YES;
                                         }
                                         if (dic[@"e_carbs"] && ![dic[@"e_carbs"] isKindOfClass:[NSNull class]]) {
                                             n.carbohydrates = [dic[@"e_carbs"] floatValue];
                                             hasData = YES;
                                         }
                                         if (dic[@"e_protein"] && ![dic[@"e_protein"] isKindOfClass:[NSNull class]]) {
                                             n.protein = [dic[@"e_protein"] floatValue];
                                             hasData = YES;
                                         }
                                         
                                         if (dic[@"e_sat_fat"]  && ![dic[@"e_sat_fat"] isKindOfClass:[NSNull class]]) {
                                             n.fat = [dic[@"e_sat_fat"] floatValue];
                                             hasData = YES;
                                         }
                                         if (dic[@"e_unsat_fat"]  && ![dic[@"e_unsat_fat"] isKindOfClass:[NSNull class]]) {
                                             n.fat = n.fat + [dic[@"e_unsat_fat"] floatValue];
                                             hasData = YES;
                                         }
                                         if (dic[@"m_total_calories"] && ![dic[@"m_total_calories"] isKindOfClass:[NSNull class]]) {
                                             n.calorieOut = [dic[@"m_total_calories"] floatValue];
                                             hasData = YES;
                                         }
                                         if (hasData) {
                                             n.updatedTime = [NSDate date];
                                             n.src = NUTRITION_SRC_JAWBONE;//[Nutrition srcName:NUTRITION_SRC_JAWBONE];
                                             n.nsdate = [Utils dateWithDateLabel:dateLabel];
                                             [n save];
                                             
                                             GLLog(@"nutrition: %@", n);
                                         }
                                         
                                     }
                                 }
                             }
                             
                             [self publish:EVENT_CHART_NEEDS_UPDATE_CALORIE];
                             [self publish:EVENT_CHART_NEEDS_UPDATE_NUTRITION];
                         }];
}

- (void)syncJawboneNutritionsForDate:(NSString *)dateLabel {
//    NSDate *lastSync = [Utils getDefaultsForKey:JAWBONE_LAST_SYNC_TIME_CALORIE];
//    if (lastSync && [lastSync timeIntervalSinceNow] > -1*JAWBONE_SYNC_INTERVAL) {
//        return;
//    }
    [[UPPlatform sharedPlatform] validateSessionWithCompletion:^(UPSession *session, NSError *error) {
        if (session != nil && session.authenticationToken) {
            [self getTrends:dateLabel];
        }
    }];
}

- (void)jawboneOnDailyDataUpdated:(NSDate *)date {
    [[UPPlatform sharedPlatform] validateSessionWithCompletion:^(UPSession *session, NSError *error) {
        if (session != nil && session.authenticationToken) {
            NSString *dateLabel = [Utils dailyDataDateLabel:date];
            UserDailyData *dailyData = [UserDailyData getUserDailyData:dateLabel forUser:[User currentUser]];
            
            BOOL jawboneMoodPosted = [[Utils getDefaultsForKey:[NSString stringWithFormat:@"MOOD:%@", dateLabel]] boolValue];
            if (!jawboneMoodPosted) {
                [self postFeedMood:dailyData.moods at:date];
            }

            GLLog(@"will post pregnancy stuff");
            double delayInSeconds = 5.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                NSString *summary = [DailyLogSummary plainSummaryForDate:dateLabel];
                GLLog(@"posting: %@", summary);
                [self postFeedPregnancyPercentage:[[User currentUser] fertileScoreOfDate:date] note:summary];
            });


//            BOOL jawboneExercisePosted = [[Utils getDefaultsForKey:[NSString stringWithFormat:@"EXERCISE:%@", dateLabel]] boolValue];
//            if (!jawboneExercisePosted) {
//                [self postFeedWorkout:dailyData.exercise at:date];
//            }
        }
    }];
}

- (void)postFeedMood:(long)moods at:(NSDate *)date{
    if (!self.jawboneId) {
        return;
    }
    
//    GLLog(@"[Utils getDefaultsForKey:@post_jawbone_feed] %@", [Utils getDefaultsForKey:@"post_jawbone_feed"]);
    if ([Utils getDefaultsForKey:@"post_jawbone_feed"] && ![[Utils getDefaultsForKey:@"post_jawbone_feed"] boolValue]) {
        GLLog(@"server prevents posting ");
        return;
    }
    
    if (![Utils date:date isSameDayAsDate:[NSDate date]]) {
        return;
    }

    NSInteger moodType = 0;
    NSString *moodTitle = @"";
//    @16: @"sad",
//    @32: @"angry",
//    @64: @"stressed",
//    @128: @"moody",
//    @256: @"anxious",

    if (moods & 64){
        moodType = UPMoodTypeExhausted;
        moodTitle = @"Stressed";
    } else if (moods & 16){
        moodType = UPMoodTypeDragging;
        moodTitle = @"Sad";
    } else if (moods & 128) {
        moodType = UPMoodTypeMeh;
        moodTitle = @"Moody";
    }
    
    if (moodType == 0) {
        return;
    }

    UPMood *mood = [UPMood moodWithType:moodType title:moodTitle];
    [UPMoodAPI postMood:mood completion:^(UPMood *mood, UPURLResponse *response, NSError *error) {
        GLLog(@"post mood: %@ %@ %@", mood, response, error);
    }];
    
    [Utils setDefaultsForKey:[NSString stringWithFormat:@"MOOD:%@", [Utils dailyDataDateLabel:date]] withValue:@YES];
}

- (void)postFeedWorkout:(long)exercise at:(NSDate *)date{
    if (!self.jawboneId) {
        return;
    }
    if ([Utils getDefaultsForKey:@"post_jawbone_feed"] && ![[Utils getDefaultsForKey:@"post_jawbone_feed"] boolValue]) {
        return;
    }

//    @4: @" for $$15-30$$ mins",
//    @8: @" for $$30-60$$ mins",
//    @16:@" for $$60+$$ mins"
    NSInteger lenth = 0;
    NSInteger intensity = 0;
    if (exercise & 4) {
        lenth = 30;
        intensity = 1;
    } else if (exercise & 8) {
        lenth = 60;
        intensity = 3;
    } else if (exercise & 16) {
        lenth = 120;
        intensity = 5;
    }
    
    if (lenth == 0) {
        return;
    }

    NSDate *beginDate = date? date: [NSDate date];
    UPWorkout *workout = [UPWorkout workoutWithType:UPWorkoutTypeRun startTime:[beginDate dateByAddingTimeInterval:(-60 * lenth)] endTime:beginDate intensity:intensity caloriesBurned:nil];
    [UPWorkoutAPI postWorkout:workout completion:^(UPWorkout *workout, UPURLResponse *response, NSError *error) {
        GLLog(@"post workout: %@ %@ %@ ", workout, response, error);
    }];
    
    [Utils setDefaultsForKey:[NSString stringWithFormat:@"EXERCISE:%@", [Utils dailyDataDateLabel:date]] withValue:@YES];
}

- (void)postFeedPregnancyPercentage:(float)percentage note:(NSString *)note {

    GLLog(@"in post pregnancy stuff");

    if (!self.jawboneId) {
        return;
    }

    [[UPPlatform sharedPlatform] validateSessionWithCompletion:^(UPSession *session, NSError *error) {
        if (session != nil && session.authenticationToken) {
//            'Your next period is in 16 days. (This is only visible to you)'
            NSString *title = [NSString stringWithFormat:@"Your fertility prediction percentage is %.1f%%. (This is only visible to you) ", percentage];

            if (self.settings.birthControl != SETTINGS_BC_CONDOM && self.settings.birthControl != SETTINGS_BC_WITHDRAWAL && self.settings.birthControl != SETTINGS_BC_FAM) {
                NSString * todayLabel = [Utils dailyDataDateLabel:[NSDate date]];
                NSInteger pbIndex = [[Utils findFirstPbIndexBefore:todayLabel
                                                inPrediction:self.prediction] integerValue] + 1;
                if (pbIndex < self.prediction.count) {
                    NSInteger days = [Utils daysBeforeDateLabel:self.prediction[pbIndex][@"pb"]
                                           sinceDateLabel:todayLabel];
                    title = [NSString stringWithFormat:@"Your next period is in %ld day%@. (This is only visible to you)", (long)days, days==1?@"":@"s"];
                }
            }
            
            
            UPGenericEvent *e = [UPGenericEvent eventWithTitle:title verb:@"updated daily log" attributes:@{} note:note imageURL:nil];
            e.shared = @(NO);
            [UPGenericEventAPI postGenericEvent:e completion:^(UPGenericEvent *event, UPURLResponse *response, NSError *error) {
                GLLog(@"post prediction percentage: %@ %@ %@", event, response, error);
            }];

        }
    }];
}

- (void)postFeedInsights:(NSArray *)insights {
    
    if (!self.jawboneId) {
        return;
    }
    if ([Utils getDefaultsForKey:@"post_jawbone_feed"] && ![[Utils getDefaultsForKey:@"post_jawbone_feed"] boolValue]) {
        return;
    }
    if (!insights) {
        return;
    }
    
    [[UPPlatform sharedPlatform] validateSessionWithCompletion:^(UPSession *session, NSError *error) {
        if (session != nil && session.authenticationToken) {
            for (NSDictionary *insight in insights) {
                if (![insight[@"title"] hasPrefix:@"Task completed:"]) {
                    continue;
                }
                
                UPGenericEvent *e = [UPGenericEvent eventWithTitle:[NSString stringWithFormat:@"%@ (This is only visible to you)", insight[@"title"]] verb:@"completed a task" attributes:@{} note:insight[@"body"] imageURL:[NSString stringWithFormat:@"%@/insight/image/%@", EMMA_BASE_URL, insight[@"type"]]];
                e.shared = @(NO);
                
                [UPGenericEventAPI postGenericEvent:e completion:^(UPGenericEvent *event, UPURLResponse *response, NSError *error) {
                    GLLog(@"post insight: %@ %@ %@", event, response, error);
                }];
            }
        }
    }];

}

- (void)getNutritionGoalsFromJawbone {
    [[UPPlatform sharedPlatform] validateSessionWithCompletion:^(UPSession *session, NSError *error) {
        if (session != nil && session.authenticationToken) {
            NSDictionary *params = @{};
            UPURLRequest *request = [UPURLRequest getRequestWithEndpoint:@"nudge/api/users/@me/goals" params:params];

            [[UPPlatform sharedPlatform] sendRequest:request completion:^(UPURLRequest *request, UPURLResponse *response, NSError *error) {
                if (error == nil && response.data)
                {
                    id sfat = response.data[@"eat_sat_fat"];
                    id ufat = response.data[@"eat_unsat_fat"];
                    if (![sfat isKindOfClass:[NSNull class]] || ![ufat isKindOfClass:[NSNull class]]) {
                        NSInteger fat = 0;
                        if (![sfat isKindOfClass:[NSNull class]]) {
                            fat += [sfat integerValue];
                        }
                        if (![ufat isKindOfClass:[NSNull class]]) {
                            fat += [ufat integerValue];
                        }
                        if (fat > 0) {
                            [Utils setDefaultsForKey:JAWBONE_FAT_GOAL withValue:@(fat)];
                        }
                    }
                    id carb = response.data[@"eat_carbs"];
                    if (![carb isKindOfClass:[NSNull class]]) {
                        [Utils setDefaultsForKey:JAWBONE_CARB_GOAL withValue:@([carb integerValue])];
                    }
                    id prot = response.data[@"eat_protein"];
                    if (![prot isKindOfClass:[NSNull class]]) {
                        [Utils setDefaultsForKey:JAWBONE_PROTEIN_GOAL withValue:@([prot integerValue])];
                    }
                }
            }];
        }
    }];

}


@end
