//
//  MFPDelegate.m
//  emma
//
//  Created by Xin Zhao on 13-9-16.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "User+MyFitnessPal.h"
#import "Network.h"
#import "Utils.h"
#import "Nutrition.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>


@implementation EmmaMFP

- (NSDictionary *)info
{
    NSTimeZone *localTime = [NSTimeZone systemTimeZone];
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                   @"id": self.id,
                                                                                   @"username": self.username,
                                                                                   @"timezone": [localTime name],
                                                                                   @"dob": self.dob,
                                                                                   @"access_token": self.accessToken,
                                                                                   @"refresh_token": self.refreshToken,
                                                                                   }];
    if (self.sex) {
        result[@"sex"] = self.sex;
    }
    if (self.heightInInches) {
        result[@"height_in_inches"] = self.heightInInches;
    }
    if (self.daily_calorie_goal) {
        result[@"daily_calorie_goal"] = self.daily_calorie_goal;
    }
    if (self.activity_factor) {
        result[@"activity_factor"] = self.activity_factor;
    }
    if (self.activity_level) {
        result[@"activity_level"] = self.activity_level;
    }
    if (self.diary_privacy_setting) {
        result[@"diary_privacy_setting"] = self.diary_privacy_setting;
    }

    return result;
}

@end

@implementation EmmaMFPDelegate
- (NSString *)MFP:(MFP *)MFP dictionaryToJSONString:(NSDictionary *)dict {
    return [Utils jsonStringify:dict];
}

- (NSDictionary *)MFP:(MFP *)MFP JSONStringToDictionary:(NSString *)string {
    return [Utils jsonParse:string];
}

- (void)MFPDidOpenApplication:(MFP *)MFP {
    /* Show connect to MFP modal here */
}

- (void)MFPAccessRevoked:(MFP *)MFP {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:MFP_ACCESS_TOKEN];
    [defaults removeObjectForKey:MFP_REFRESH_TOKEN];
    [defaults synchronize];
    
    [MFP setAccessToken:nil];
    [MFP setRefreshToken:nil];
}


- (void)MFP:(MFP *)MFP didAuthorize:(NSDictionary *)response {
    //current only support responseType=token
    NSString *accessToken = [response objectForKey:@"access_token"];
    NSString *refreshToken = [response objectForKey:@"refresh_token"];
    
    [MFP setAccessToken:accessToken];
    [MFP setRefreshToken:refreshToken];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:accessToken forKey:MFP_ACCESS_TOKEN];
    [defaults setObject:refreshToken forKey:MFP_REFRESH_TOKEN];
    [defaults synchronize];
    NSLog(@"mfp did auth: %@", response);
}


- (void)MFP:(MFP *)MFP failedToAuthorize:(NSDictionary *)response {
    [MFP setAccessToken:nil];
    [MFP setRefreshToken:nil];
}


- (void)MFP:(MFP *)MFP accessTokenRefreshed:(NSDictionary *)response {
    NSString *accessToken = [response objectForKey:@"access_token"];
    
    [MFP setAccessToken:accessToken];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:accessToken forKey:MFP_ACCESS_TOKEN];
    [defaults synchronize];
}


- (void)MFP:(MFP *)MFP requestSucceeded:(NSDictionary *)response {
    if (response) {
        GLLog(@"Request succeeded: %@", [response description]);
    }
    else
        GLLog(@"Request succeeded");
}


- (void)MFP:(MFP *)MFP requestFailed:(NSDictionary *)response {
    if (response) {
        GLLog(@"Request failed: %@", [response description]);
    }
    else
        GLLog(@"Request failed");
}
@end



@implementation User (MyFitnessPal)

static EmmaMFP *_mfp = nil;
static EmmaMFPDelegate *_mfpDelegate = nil;
static BOOL _alreadyCheckedMFPInstall;
#define kShownMFPInstallAlertNumber @"kShownMFPInstallAlertNumber"
#define kMaxNumberShowingMFPInstall 3

+ (EmmaMFP*)getMFPConnection
{
    if (!_mfp) {
        _mfpDelegate = [[EmmaMFPDelegate alloc] init];
        _mfp = [[EmmaMFP alloc] initWithClientId:MFP_CLIENT_ID responseType:@"token" delegate:_mfpDelegate];
//        MFP_ACCESS_TOKEN]
        if ([Utils getDefaultsForKey:MFP_ACCESS_TOKEN]) {
            _mfp.accessToken = [Utils getDefaultsForKey:MFP_ACCESS_TOKEN];
        }
    }
    return _mfp;
}

+ (void)connectMFP:(MFPConnectCallback)callback {
    [User connectMFP:callback withPublishInstallError:YES inSignUp:NO];
}

+ (void)connectMFPInSignUp:(MFPConnectCallback)callback {
    [User connectMFP:callback withPublishInstallError:YES inSignUp:YES];
}


+ (void)connectMFP:(MFPConnectCallback)callback withPublishInstallError:(BOOL)publishInstallError inSignUp:(BOOL)inSignUp {
    /*
     * publishInstallError
     * We have 4 places to connectMFP
     *   1 - signup
     *   2 - signin
     *   3 - me page connect/disconnect.
     *   4 - sync Nutrition
     * 
     * for 1-3, we want to publish install error, since it is a user action
     * for 4, we don't publish install error, because it is not a user action
     */
    EmmaMFP *mfp = [self getMFPConnection];
    if (![mfp appIsInstalled]) {
//        [mfp installApp];
        
        NSUInteger times = [[NSUserDefaults standardUserDefaults] integerForKey:kShownMFPInstallAlertNumber];
        if (!_alreadyCheckedMFPInstall && times < kMaxNumberShowingMFPInstall) {
            
            [Logging log:MFP_INSTALL_ALERT_SHOWN];
            NSString * alertMsg = nil;
            if (inSignUp) {
                alertMsg = @"Glow cannot sync with your MyFitnessPal (MFP) account. Please install MFP from the App Store to proceed.";
            } else {
                alertMsg = @"Glow cannot sync with your MyFitnessPal (MFP) account. Please install MFP from the App Store to proceed. If you no longer wish to connect MFP, turn off MFP from Glow's ME page.";
            }
            
            [UIAlertView bk_showAlertViewWithTitle:@"Connection Broken"
                                           message:alertMsg
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@[@"Download"]
                                           handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                               if (buttonIndex != alertView.cancelButtonIndex) {
                                                   [Logging log:BTN_CLK_MFP_DOWNLOAD];
                                                   [mfp installApp];
                                               }
                                               if (publishInstallError) {
                                                   [self publish:EVENT_MFP_CONNECT_FAILED data:MFP_CONNECT_FAILED_MSG];
                                               }
                                           }];
            
            _alreadyCheckedMFPInstall = YES;
            [[NSUserDefaults standardUserDefaults] setInteger:times+1 forKey:kShownMFPInstallAlertNumber];
        } else {
            if (publishInstallError) {
                [self publish:EVENT_MFP_CONNECT_FAILED data:MFP_CONNECT_FAILED_MSG];
            }
        }
        return;
    }
    MFPCallback successCallback = ^(NSDictionary *r) {
        [Logging log:MFP_CONNECT_RETURN eventData:@{@"success": @(1)}];
        
        NSLog(@"success cb %@", r);
        if ((r==nil) || ([r allKeys].count == 0) || ([Utils isEmptyString:mfp.id])) {
            [self publish:EVENT_MFP_CONNECT_FAILED data:MFP_CONNECT_FAILED_MSG];
            return;
        }
        mfp.username = r[@"username"];
        mfp.dob = r[@"dob"];
        if ((mfp.username == nil) || (mfp.dob == nil) || (mfp.accessToken == nil)) {
            [self publish:EVENT_MFP_CONNECT_FAILED data:MFP_CONNECT_FAILED_MSG];
            return;
        }
        mfp.sex = r[@"sex"] ? r[@"sex"] : nil;
        mfp.heightInInches =  r[@"height_in_inches"] ? r[@"height_in_inches"] : nil;
        mfp.activity_factor = r[@"activity_factor"]? r[@"activity_factor"]: 0;
        mfp.activity_level = r[@"activity_level"]? r[@"activity_level"]: @"";
        mfp.diary_privacy_setting = r[@"diary_privacy_setting"]? r[@"diary_privacy_setting"]: @"";
        mfp.daily_calorie_goal = r[@"daily_calorie_goal"]? r[@"daily_calorie_goal"]: 0;
        callback(mfp);
    };
    MFPCallback failureCallback = ^(NSDictionary *r) {
        [Logging log:MFP_CONNECT_RETURN eventData:@{@"success": @(4)}];
        NSLog(@"failure cb %@", r);
    };
    
    [Logging log:MFP_CONNECT_START];
    [mfp authorizeWithScope:@"diary" onSuccess:^(NSDictionary *r) {
        [self fetchMfpUserInfo:mfp onSuccess:successCallback onFailure:failureCallback];
    } onFailure: ^(NSDictionary *r) {
        GLLog(@"authorize from mfp %@", r);
        [Logging log:MFP_CONNECT_RETURN eventData:@{@"success": @(2)}];
        [self publish:EVENT_MFP_CONNECT_FAILED data:MFP_CONNECT_FAILED_MSG];
    }];
}

#pragma mark - Connect(signup/login) flow
+ (void)fetchUserByMfpID:(NSString *)mfpID dataStore:(DataStore *)ds completionHandler:(FetchUserCallback)callback {
    NSString *apiPath = [NSString stringWithFormat:@"users/mfp/%@", mfpID];
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

+ (void)createAccountWithMfp:(EmmaMFP*)MFP dataStore:(DataStore *)ds completionHandler:(CreateAccountCallback)callback {
    [[Network sharedNetwork] post:@"users/mfp"
            data:@{@"mfpinfo": MFP.info,
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
                    @"MyFitnessPal"}];
                callback(user, err);
            }];
}

+ (void)fetchMfpUserInfo:(EmmaMFP*)MFP onSuccess:(MFPCallback)successCallback onFailure:(MFPCallback)failureCallback {
    [MFP APIrequestNamed:@"subscribe_to_user_updates" params:@{@"subscribe_to_events": @"diary"}
                onSuccess:^(NSDictionary *r){
                    GLLog(@"user id %@", r);
                    MFP.id = [r objectForKey:@"subscribed_user_id"];
                    [MFP APIrequestNamed:@"fetch_user_info" params:@{} onSuccess:successCallback onFailure:failureCallback];
                }
                onFailure:^(NSDictionary *r) {
                    [Logging log:MFP_CONNECT_RETURN eventData:@{@"success": @(3)}];
                    failureCallback(r);
                }];
}

+ (void)signUpWithMFP {
    [self connectMFPInSignUp:^(EmmaMFP *mfp) {
        [self fetchUserByMfpID:mfp.id dataStore:[DataStore defaultStore] completionHandler:^(User *user, NSError *error) {
            if (!error) {
                if (user) {
                    [self publish:EVENT_USER_SIGNUP_FAILED 
                             data:@"Your MyFitnessPal account has already connected to an existing Glow account."];
                    return;
                }
                [self createAccountWithMfp:mfp dataStore:[DataStore defaultStore] completionHandler:^(User *user, NSError *error) {
                    [user login];
                }];
            }
        }];
    }];
}

+ (void)signInWithMFP {
    [self connectMFP:^(EmmaMFP *mfp) {
        [self fetchUserByMfpID:mfp.id dataStore:[DataStore defaultStore] completionHandler:^(User *user, NSError *error) {
            if (!error) {
                if (!user) {
                    [self publish:EVENT_USER_LOGIN_FAILED 
                             data:@"There's no Glow account connected with your MyFitnessPal account. Please sign up."];
                    return;
                }
                [user login];
            }
        }];
    }];
}

#pragma mark - Disconnect/Reconnect flow
- (void)addMFPConnectForUser {
    return [User connectMFP:^(EmmaMFP *mfp) {
        NSLog(@"peng debug connect mfp call back: %@", mfp);
        if (self.mfpId) return;
        if (mfp.heightInInches && ![mfp.sex isEqualToString:@"M"] && self.settings.height < 10) {
            [self.settings update:@"height" floatValue:[mfp.heightInInches floatValue] * 2.54];
        }
        if (mfp.daily_calorie_goal) {
            [self.settings update:@"mfpDailyCalorieGoal" value:mfp.daily_calorie_goal];
        }
        if (mfp.diary_privacy_setting) {
            [self.settings update:@"mfpDiaryPrivacySetting" value:mfp.diary_privacy_setting];
        }
        if (mfp.activity_level) {
            [self.settings update:@"mfpActivityLevel" value:mfp.activity_level];
        }
        if (mfp.activity_factor) {
            [self.settings update:@"mfpActivityFactor" value:mfp.activity_factor];
        }
        [self save];

        NSDictionary *request = [self postRequest:@{@"mfpinfo": mfp.info}];
        [[Network sharedNetwork] post:@"users/add_mfp" data:request requireLogin:YES completionHandler:^(NSDictionary *data, NSError *error){
            NSLog(@"peng debug post add mfp:%@ \n %@", data, error);
            [self publish:EVENT_USER_ADD_MFP_RETURNED];
            if (error) {
                [self publish:EVENT_USER_ADD_MFP_FAILED data:@"Failed to connect to the server"];
            } else if (data[@"error_msg"]) {
                [self publish:EVENT_USER_ADD_MFP_FAILED data:data[@"error_msg"]];
            }
            else {
                self.mfpId = mfp.id;
                [self save];
                [self publish:EVENT_USER_MFP_UPDATED];
            }
        }];
    }];
}

- (void)disconnectForUser {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MFP_ACCESS_TOKEN];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MFP_REFRESH_TOKEN];
    
    if (!self.mfpId) return;
    NSDictionary *request = [self postRequest:@{@"mfpid": self.mfpId}];
    [[Network sharedNetwork] post:@"users/disconnect_mfp" data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (err) {
            [self publish:EVENT_USER_DISCONNECT_MFP_FAILED data:@"Failed to connect to the server"];
        } else {
            self.mfpId = nil;
            [self save];
            _mfp = nil;
            [self publish:EVENT_USER_MFP_UPDATED];
        }
    }];
}

- (BOOL) isMFPConnected {
    return self.mfpId != nil;
}

- (void)getCardio:(NSString *)dateLabel {
    [[User getMFPConnection] APIrequestNamed:@"get_cardio_exercises"
                                      params:@{@"date": [dateLabel stringByReplacingOccurrencesOfString:@"/" withString:@"-"]}
                                   onSuccess:^(NSDictionary *data) {
                                       //
                                       GLLog(@"data of calories: %@", data);
                                       NSArray *arr = @[];
                                       if ([data isKindOfClass:[NSArray class]]) {
                                           arr = (NSArray *)data;
                                       }
                                       float calorie = 0;
                                       for (NSDictionary *v in arr) {
                                           if ([v isKindOfClass:[NSDictionary class]]) {
                                               //
                                               calorie += [v[@"calories"] floatValue];
                                           }
                                       }
                                       
                                       if (calorie > 0) {
                                           Nutrition *n = [Nutrition tset:dateLabel forUser:[User currentUser]];
                                           n.calorieOut = calorie;
                                           n.src = NUTRITION_SRC_MFP;
                                           n.updatedTime = [NSDate date];
                                           n.date = dateLabel;
                                           n.nsdate = [Utils dateWithDateLabel:dateLabel];
                                           [n save];
                                           
                                           [self publish:EVENT_CHART_NEEDS_UPDATE_CALORIE];
                                       }
                                       
                                       [Utils setDefaultsForKey:MFP_LAST_SYNC_TIME_CALORIE withValue:[NSDate date]];
                                       
                                       [self getFoodSummaryForDateLabel:dateLabel];
                                   }
                                   onFailure:^(NSDictionary *data) {
                                       //
                                       GLLog(@"failed: %@", data);
                                       [Utils setDefaultsForKey:MFP_LAST_SYNC_TIME_CALORIE withValue:[NSDate date]];
                                       [self getFoodSummaryForDateLabel:dateLabel];
                                   }];
}
- (void)syncNutritionsForDate:(NSString *)dateLabel {
//    NSDate *lastSync = [Utils getDefaultsForKey:MFP_LAST_SYNC_TIME_CALORIE];
//    if (lastSync && [lastSync timeIntervalSinceNow] > -1*MFP_SYNC_INTERVAL) {
//        return;
//    }

//    Nutrition *n = [Nutrition tset:dateLabel forUser:[User currentUser]];
    
    if ([self isMFPConnected] && [Utils getDefaultsForKey:MFP_ACCESS_TOKEN] != nil) {
        [self getCardio:dateLabel];
    }
    else {
        if (self.mfpId) {
            GLLog(@"peng --- reconnect to mfp ---");
            [User connectMFP:^(EmmaMFP *mfp) {
                if (mfp.accessToken) {
                    [self getCardio:dateLabel];
                }
            } withPublishInstallError:NO inSignUp:NO];
        }
    }
}

- (void)getFoodSummaryForDateLabel:(NSString *)dateLabel {
    
    [[User getMFPConnection] APIrequestNamed:@"get_food_summary"
                                      params:@{@"date": [dateLabel stringByReplacingOccurrencesOfString:@"/" withString:@"-"]}
                                   onSuccess:^(NSDictionary *data) {
                                       //
                                       GLLog(@"data for food: %@", data);
                                       NSArray *arr = @[];
                                       if ([data isKindOfClass:[NSArray class]]) {
                                           arr = (NSArray *)data;
                                       }
                                       
                                       float carb = 0, fat = 0, protein = 0, calorie = 0;
                                       for (NSDictionary *v in arr) {
                                           if ([v isKindOfClass:[NSDictionary class]]) {
                                               //
                                               carb += [v[@"carbs"] floatValue];
                                               fat += [v[@"fat"] floatValue];
                                               protein  += [v[@"protein"] floatValue];
                                               calorie += [v[@"energy_consumed"] floatValue];
                                           }
                                       }
                                       
                                       if (carb + fat + protein + calorie > 0) {
                                           Nutrition *n = [Nutrition tset:dateLabel forUser:[User currentUser]];
                                           if (carb > 0) {
                                               n.carbohydrates = carb;
                                           }
                                           if (fat > 0) {
                                               n.fat = fat;
                                           }
                                           if (protein > 0) {
                                               n.protein = protein;
                                           }
                                           if (calorie > 0) {
                                               n.calorieIn = calorie;
                                           }
                                           n.src = NUTRITION_SRC_MFP;
                                           n.updatedTime = [NSDate date];
                                           n.date = dateLabel;
                                           n.nsdate = [Utils dateWithDateLabel:dateLabel];
                                           [n save];
                                           
                                           [self publish:EVENT_CHART_NEEDS_UPDATE_NUTRITION];
                                           if (calorie > 0) {
                                               [self publish:EVENT_CHART_NEEDS_UPDATE_CALORIE];
                                           }
                                       }
                                       
                                       [Utils setDefaultsForKey:MFP_LAST_SYNC_TIME_NUTRITION withValue:[NSDate date]];
                                   }
                                   onFailure:^(NSDictionary *data) {
                                       GLLog(@"failed: %@", data);
                                       [Utils setDefaultsForKey:MFP_LAST_SYNC_TIME_NUTRITION withValue:[NSDate date]];
                                   }];
}
@end
