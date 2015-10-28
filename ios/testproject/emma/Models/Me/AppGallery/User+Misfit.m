//
//  User+Misfit.m
//  emma
//
//  Created by Xin Zhao on 10/28/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ChartData.h"
#import "Nutrition.h"
#import "User+Misfit.h"

@interface GLMisfit ()

@property (nonatomic, retain) NSString *misfitUserId;
@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *gender;
@property (nonatomic, retain) NSString *birthday;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSNumber *sessionSyncTime;
@property (nonatomic, retain) NSNumber *sleepSyncTime;

@end

@implementation GLMisfit

+ (NSMutableDictionary *)glMisfits {
    NSMutableDictionary *threadDictionary = [[NSThread currentThread]
        threadDictionary];
    NSMutableDictionary *glMisfits = [threadDictionary objectForKey:@"glMisfits"];
    if (!glMisfits) {
        glMisfits = [@{} mutableCopy];
        [threadDictionary setObject:glMisfits forKey:@"glMisfits"];
    }
    return glMisfits;
}

+ (GLMisfit *)sharedGLMisfitForId:(NSString *)id {
    if (!id) {
        return nil;
    }

    GLMisfit *glMisfit = [self glMisfits][id];
    NSDictionary *misfitProfile = [Utils getDefaultsForKey:
        catobj(DEFAULTS_MISFIT_PRE, id, nil)];
    if (!misfitProfile) {
        return nil;
    }
    glMisfit = [[GLMisfit alloc] init];
    [self _setupMisfit:glMisfit fromDict:misfitProfile];
    return glMisfit;
}

+ (GLMisfit *)GLMisfit {
    return [self GLMisfitWithDict:@{}];
}

+ (GLMisfit *)GLMisfitWithDict:(NSDictionary *)misfitProfile {
    GLMisfit *glMisfit = [[GLMisfit alloc] init];
    [self _setupMisfit:glMisfit fromDict:misfitProfile];
    return glMisfit;
}

+ (void)_setupMisfit:(GLMisfit *)glMisfit fromDict:(NSDictionary *)misfitProfile {
    glMisfit.misfitUserId = misfitProfile[@"userId"];
    glMisfit.accessToken = misfitProfile[@"access_token"];
    glMisfit.name = misfitProfile[@"name"];
    glMisfit.gender = misfitProfile[@"gender"];
    glMisfit.birthday = misfitProfile[@"birthday"];
    glMisfit.email = misfitProfile[@"email"];
    glMisfit.sessionSyncTime = misfitProfile[@"sessionSyncTime"];
    glMisfit.sleepSyncTime = misfitProfile[@"sleepSyncTime"];
}

- (void)save {
    [GLMisfit glMisfits][self.misfitUserId] = self;
    [Utils setDefaultsForKey:catobj(DEFAULTS_MISFIT_PRE, self.misfitUserId, nil)
        withValue:[self toDict]];
}

- (NSDictionary *)toDict {
    NSMutableDictionary *misfitProfile = [@{} mutableCopy];
    misfitProfile[@"userId"] = self.misfitUserId;
    misfitProfile[@"access_token"] = self.accessToken;
    if (!isEmptyObj(self.email)) {
        misfitProfile[@"email"] = self.email;
    }
    if (!isEmptyObj(self.name)) {
        misfitProfile[@"name"] = self.name;
    }
    if (!isEmptyObj(self.gender)) {
        misfitProfile[@"gender"] = self.gender;
    }
    if (!isEmptyObj(self.birthday)) {
        misfitProfile[@"birthday"] = self.birthday;
    }
    if (!isEmptyObj(self.sessionSyncTime)) {
        misfitProfile[@"sessionSyncTime"] = self.sessionSyncTime;
    }
    if (!isEmptyObj(self.sleepSyncTime)) {
        misfitProfile[@"sleepSyncTime"] = self.sleepSyncTime;
    }
    
    return misfitProfile;
}

@end

@interface User ()
@end

@implementation User (Misfit)

# pragma mark - public api
+ (void)misfitAuthForConnect {
    [[UIApplication sharedApplication] openURL:
        [NSURL URLWithString:[Utils makeUrl:MISFIT_AUTH_URL query:
        @{@"response_type": @"code",
          @"client_id": MISFIT_APP_KEY,
          @"scope": MISFIT_SCOPE,
          @"redirect_uri": MISFIT_REDIRECT_URL_CONNECT}]]];
}

+ (void)misfitAuthForSignup {
    [[UIApplication sharedApplication] openURL:
        [NSURL URLWithString:[Utils makeUrl:MISFIT_AUTH_URL query:
        @{@"response_type": @"code",
          @"client_id": MISFIT_APP_KEY,
          @"scope": MISFIT_SCOPE,
          @"redirect_uri": MISFIT_REDIRECT_URL_SIGNUP}]]];
}

+ (void)misfitAuthForSignin {
    [[UIApplication sharedApplication] openURL:
        [NSURL URLWithString:[Utils makeUrl:MISFIT_AUTH_URL query:
        @{@"response_type": @"code",
          @"client_id": MISFIT_APP_KEY,
          @"scope": MISFIT_SCOPE,
          @"redirect_uri": MISFIT_REDIRECT_URL_SIGNIN}]]];
}

+ (BOOL)misfitHandleForConnectWithCode:(NSString *)code {
    [self _exchangeWithCode:code redirectUri:MISFIT_REDIRECT_URL_CONNECT
        complete:^(NSDictionary *res, NSError *err) {
        if (err) return; //TODO(zhao): handle error here
        if (![User currentUser]) return;
        NSString *token = res[@"access_token"];
        [self profileWithToken:token complete:
            ^(NSDictionary *res, NSError *err) {
            if (err) return;
            NSMutableDictionary *misfitProfile = [res mutableCopy];
            misfitProfile[@"access_token"] = token;
            GLLog(@"zx debug profile %@", misfitProfile);
            User *user = [User currentUser];
            if (!user) return; //TODO(zhao): alarm no current user
            if ([user isConnectedWithMisfit]) {
                //TODO(zhao): alarm existing misfit connection
                return;
            }
            
            GLMisfit *glMisfit = [GLMisfit GLMisfitWithDict:misfitProfile];
            [glMisfit save];
            [user connectMisfit:glMisfit];
            GLLog(@"zx debug after connect: %d", [user isConnectedWithMisfit]);
        }];
    }];
    return YES;
}

+ (BOOL)misfitHandleForSignupWithCode:(NSString *)code {
    if ([User currentUser]) return NO;
    
    [[GLMisfit GLMisfit] publish:EVENT_MISFIT_TOKEN_AND_PROFILE_STAGE];
    [self _exchangeWithCode:code redirectUri:MISFIT_REDIRECT_URL_SIGNUP
        complete:^(NSDictionary *res, NSError *err) {
        if (err) {
            [[GLMisfit GLMisfit] publish:EVENT_MISFIT_AUTH_FAILED
                data:@"Failed to connect with Misfit. Please try again."];
            return;
        };
        NSString *token = res[@"access_token"];
        [self profileWithToken:token complete:
            ^(NSDictionary *res, NSError *err) {
            if (err) {
                [[GLMisfit GLMisfit] publish:EVENT_MISFIT_AUTH_FAILED
                    data:@"Failed to connect with Misfit. Please try again."];
                return;
            };
            NSMutableDictionary *misfitProfile = [res mutableCopy];
            misfitProfile[@"access_token"] = token;
            GLLog(@"zx debug profile %@", misfitProfile);
            
            GLMisfit *glMisfit = [GLMisfit GLMisfitWithDict:misfitProfile];
            [glMisfit save];
            [User createAccountWithMisfit:misfitProfile
                dataStore:[DataStore defaultStore]];
        }];
    }];
    return YES;
}

+ (BOOL)misfitHandleForSigninWithCode:(NSString *)code {
    if ([User currentUser]) return NO;

    [[GLMisfit GLMisfit] publish:EVENT_MISFIT_TOKEN_AND_PROFILE_STAGE];
    [self _exchangeWithCode:code redirectUri:MISFIT_REDIRECT_URL_SIGNIN
        complete:^(NSDictionary *res, NSError *err) {
        if (err) {
            [[GLMisfit GLMisfit] publish:EVENT_MISFIT_AUTH_FAILED
                data:@"Failed to connect with Misfit. Please try again."];
            return;
        };
        NSString *token = res[@"access_token"];
        [self profileWithToken:token complete:
            ^(NSDictionary *res, NSError *err) {
            if (err) {
                [[GLMisfit GLMisfit] publish:EVENT_MISFIT_AUTH_FAILED
                    data:@"Failed to connect with Misfit. Please try again."];
                return;
            };
            NSMutableDictionary *misfitProfile = [res mutableCopy];
            misfitProfile[@"access_token"] = token;
            GLLog(@"zx debug profile %@", misfitProfile);
            
            GLMisfit *glMisfit = [GLMisfit GLMisfitWithDict:misfitProfile];
            [glMisfit save];
            [User signinWithMisfitId:glMisfit.misfitUserId];
        }];
    }];
    return YES;
}

+ (void)misfitFromServerInfo:(NSDictionary *)info forUser:(User *)user {
    NSString *misfitId = info[@"misfit_id"];
    [user setMisfitId:misfitId];
    
    if (![GLMisfit sharedGLMisfitForId:misfitId] && info[@"misfit"]) {
        GLMisfit *glMisfit = [GLMisfit GLMisfitWithDict:info[@"misfit"]];
        [glMisfit save];
    }
}

# pragma mark - fetch resource
+ (void)activityName:(NSString *)name
                from:(NSString *)start
                  to:(NSString *)end
             forUser:(User*)user
            complete:(JSONResponseHandler) completion {
    if (!completion) return;
    
    GLMisfit *glMisfit = [GLMisfit sharedGLMisfitForId:[user getMisfitId]];
    if (!glMisfit) {
        completion(nil, [self misfitErrorWithType:MisfitErrorTypeNotConnected]);
        return;
    }
    NSString *startStr = [start stringByReplacingOccurrencesOfString:@"/"
        withString:@"-"];
    NSString *endStr = [end stringByReplacingOccurrencesOfString:@"/"
        withString:@"-"];
    NSString *sessionUrl = [NSString stringWithFormat:MISFIT_SESSION_URL,
        name, startStr, endStr];
    [self _resourceWithUrl:sessionUrl token:glMisfit.accessToken complete:
        ^(NSDictionary *response, NSError *err) {
        GLLog(@"zx debug sessions: %@ \n %@", response, err);
        if (!completion) return;
        if (err) {
            completion(nil, err);
            return;
        }
        completion(response, err);
    }];
}

+ (void)profileWithToken:(NSString *)token
                complete:(JSONResponseHandler)completion {
    [self _resourceWithUrl:MISFIT_PROFILE_URL token:token
        complete:completion];
}

#pragma mark - auth, exchange code
+ (void)_exchangeWithCode:(NSString *)code
              redirectUri:(NSString *)redirectUri
                 complete:(JSONResponseHandler)completion{
    [[Network sharedNetwork] post:MISFIT_TOKEN_URL data:
        @{@"grant_type": @"authorization_code", @"code": code,
          @"redirect_uri": redirectUri, @"client_id": MISFIT_APP_KEY,
          @"client_secret":MISFIT_APP_SECRET}
                     requireLogin:NO
        timeout:NETWORK_MULTIPART_TIMEOUT completionHandler:
        ^(NSDictionary *response, NSError *err) {
        GLLog(@"exchange res %@\n err %@", response, err);
        if (completion) {
            completion(response, err);
        }
    }];
}

+ (void)_resourceWithUrl:(NSString *)urlString
                   token:(NSString *)token
                complete:(JSONResponseHandler)completion {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:
        [NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:token forHTTPHeaderField:@"access_token"];
    [request setTimeoutInterval:NETWORK_MULTIPART_TIMEOUT];
    [NSURLConnection sendAsynchronousRequest:request
        queue:[NSOperationQueue currentQueue] completionHandler:
        ^(NSURLResponse *response, NSData *data, NSError *error) {
        GLLog(@"authorized request: %@\n%@\n%@", response, data, error);
        if (!error) {
//            error = [self checkErrorFromHttpResponse:(NSHTTPURLResponse *)response data:data];
        }
        if (!completion) {
            return;
        }
        if (error) {
            completion(nil, error);
        } else {
            NSError *decodeErr = nil;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data
                options:0 error:&decodeErr];
            completion(result, decodeErr);
        }
    }];
}

# pragma mark - instance methods

static NSNumber *currentUserId;
static NSString *currentMisfitId;

- (NSString *)getMisfitId {
    if (![self.id isEqual:currentMisfitId]) {
        currentMisfitId = [Utils getDefaultsForKey:
            catobj(DEFAULTS_USER_MISFIT_PRE, self.id, nil)];
        currentUserId = self.id;
    }
    return currentMisfitId;
}

- (void)setMisfitId:(NSString *)misfitId {
    currentUserId = self.id;
    [Utils setDefaultsForKey:catobj(DEFAULTS_USER_MISFIT_PRE, self.id, nil)
        withValue:misfitId];
    currentMisfitId = misfitId;
}

- (BOOL)isConnectedWithMisfit {
    return [GLMisfit sharedGLMisfitForId:[self getMisfitId]] ? YES : NO;
}

- (void)cleanupMisfitOnLogout {
    [Utils setDefaultsForKey:catobj(DEFAULTS_USER_MISFIT_PRE, self.id, nil)
        withValue:nil];
    currentMisfitId = nil;
    currentMisfitId = nil;
}
//
//- (void)connectMisfitWithProfile:(NSDictionary *)misfitProfile {
//    if (!misfitProfile[@"userId"] || !misfitProfile[@"access_token"]) {
//        //TODO(zhao): alert connect failed
//        return;
//    }
//    [Utils setDefaultsForKey: catobj(DEFAULTS_MISFIT_PRE, self.id, nil)
//        withValue:misfitProfile];
//}


+ (void)createAccountWithMisfit:(NSDictionary *)misfitinfo
                      dataStore:(DataStore *)ds
{
    [[Network sharedNetwork] post:@"users/misfit" data:
        @{@"misfitinfo": misfitinfo,
        @"onboardinginfo": [Settings createPushRequestForNewUserWith:
        [Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS]]}
                     requireLogin:NO
        completionHandler:^(NSDictionary *result, NSError *err) {
        
        NSDictionary *userData = [result objectForKey:@"user"];
        if (err || userData[@"msg"]) {
            [self publish:EVENT_USER_SIGNUP_FAILED data:
                userData[@"msg"] ? userData[@"msg"]
                : @"Failed to signup. Please try again later."];
            return;
        }

        [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:nil];
        User *user = [User upsertWithServerData:userData dataStore:ds];
        [user save];
        [FBAppEvents logEvent:FBAppEventNameCompletedRegistration
            parameters:@{FBAppEventParameterNameRegistrationMethod:
            @"Misfit"}];
        [user login];
    }];
}

+ (void)signinWithMisfitId:(NSString *)misfitId {
    NSString *apiPath = [NSString stringWithFormat:@"users/misfit/%@",
        misfitId];
    [[Network sharedNetwork] get:apiPath completionHandler:
        ^(NSDictionary *result, NSError *error){
        User *user = nil;
        NSString *msg = result[@"msg"] ? result[@"msg"]
            : @"Failed to sign in. Please try again later.";
        if (!error) {
            id userData = [result objectForKey:@"user"];
            if (userData != [NSNull null]) {
                user = [User upsertWithServerData:userData dataStore:
                    [DataStore defaultStore]];
                [user save];
                [user login];
            } else {
                msg = @"There's no Glow account connected with your Misfit account. Please sign up.";
            }
        }
        if (!user) {
            [[GLMisfit GLMisfit] publish:EVENT_USER_LOGIN_FAILED data:msg];
        }
    }];
}

- (void)connectMisfit:(GLMisfit *)glMisfit {
    NSDictionary *request = [self postRequest:
        @{@"misfitinfo":[glMisfit toDict]}];
    [[Network sharedNetwork] post:@"users/connect_misfit" data:request requireLogin:YES
        completionHandler:^(NSDictionary *data, NSError *error){
        [self publish:EVENT_USER_ADD_MISFIT_RETURNED];
        if (error) {
            [self publish:EVENT_USER_ADD_MISFIT_FAILED
                data:@"Failed to connect to Misfit. Please try again later."];
        } else if (data[@"error_msg"]) {
            [self publish:EVENT_USER_ADD_MISFIT_FAILED data:data[@"error_msg"]];
        }
        else {
            if (self) {
                [self setMisfitId:glMisfit.misfitUserId];
            }
        }
    }];
}

- (void)disconnectMisfit {
    if (![self isConnectedWithMisfit]) return;
    
    NSDictionary *request = [self postRequest:
        @{@"misfit_id":[self getMisfitId]}];
    [[Network sharedNetwork] post:@"users/disconnect_misfit" data:request requireLogin:YES
        completionHandler:^(NSDictionary *data, NSError *error){
        [self publish:EVENT_USER_ADD_MISFIT_RETURNED];
        if (error) {
            [self publish:EVENT_USER_DISCONNECT_MISFIT_FAILED
                data:@"Failed to disconnect to Misfit. Please try again later."];
        } else if (data[@"error_msg"]) {
            [self publish:EVENT_USER_DISCONNECT_MISFIT_FAILED
                data:data[@"error_msg"]];
        }
        else {
            if (self) {
                [self setMisfitId:nil];
            }
        }
    }];
}

- (void)syncMisfitActivitiesForDate:(NSString *)end forced:(BOOL)forced{
    NSString *start = [[Utils dateByAddingDays:-7 toDate:
        [Utils dateWithDateLabel:end]] toDateLabel];
    [self misfitSessionsFrom:start to:end forced:forced];
    [self misfitSleepsFrom:start to:end forced:forced];
}

- (void)misfitSessionsFrom:(NSString *)start
                        to:(NSString *)end
                    forced:(BOOL)isForced
{
    if (!isForced) {
        NSNumber *lastSync = [GLMisfit sharedGLMisfitForId:[self getMisfitId]]
            .sessionSyncTime;
        if (lastSync && [[NSDate date] timeIntervalSince1970] -
            [lastSync doubleValue] < 86400) {
            return;
        }
    }

    [User activityName:@"sessions" from:start to:end forUser:self complete:
        ^(NSDictionary *response, NSError *err) {
        if (err) {
            //TODO(zhao): handle fetching err
            return;
        }
        NSDictionary *converted = [User convertMisfitSession:
            response[@"sessions"]];
        GLLog(@"zx debug fetch sessions %@", converted);
        User *safeUser = [ChartData getThreadSafeUser];
        NSDictionary *dailyExercise = converted[@"dailyExercise"];
        for (NSString *date in dailyExercise) {
            float duration = [dailyExercise[date] floatValue];
            UserDailyData *dailyData = [UserDailyData tset:date
                forUser:safeUser];
            if (2 > dailyData.exercise) {
                [dailyData update:@"exercise" intValue:
                    duration > 3600 ? 0x10 : (duration > 1800 ? 0x8 : 0x4)];
            }
        }
        [safeUser save];
        NSDictionary *caloriesOut = converted[@"caloriesOut"];
        for (NSString *date in caloriesOut) {
            float calOut = [caloriesOut[date] floatValue];
            Nutrition *nutrition = [Nutrition tset:date forUser:safeUser];
            if (nutrition.calorieOut < 1) {
                nutrition.calorieOut = calOut;
                nutrition.nsdate = [Utils dateWithDateLabel:date];
                nutrition.updatedTime = [NSDate date];
                nutrition.src = NUTRITION_SRC_MISFIT;
                [nutrition save];
            }
        }
        GLMisfit *glMisfit = [GLMisfit sharedGLMisfitForId:
            [safeUser getMisfitId]];
        glMisfit.sessionSyncTime =
            @([[NSDate date] timeIntervalSince1970]);
        [glMisfit save];
    }];
}

- (void)misfitSleepsFrom:(NSString *)start
                      to:(NSString *)end
                  forced:(BOOL)isForced
{
    if (!isForced) {
        NSNumber *lastSync = [GLMisfit sharedGLMisfitForId:[self getMisfitId]]
            .sleepSyncTime;
        if (lastSync && [[NSDate date] timeIntervalSince1970] -
            [lastSync doubleValue] < 86400) {
            return;
        }
    }

    [User activityName:@"sleeps" from:start to:end forUser:self complete:
        ^(NSDictionary *response, NSError *err) {
        if (err) {
            //TODO(zhao): handle fetching err
            return;
        }
        NSDictionary *sleepsDict = [User convertMisfitSleeps:
            response[@"sleeps"]];
        GLLog(@"zx debug fetch sleeps %@", sleepsDict);
        User *safeUser = [ChartData getThreadSafeUser];
        for (NSString *date in sleepsDict) {
            int duration = [sleepsDict[date] intValue];
            UserDailyData *dailyData = [UserDailyData tset:date
                forUser:safeUser];
            if (duration > 0) {
                [dailyData update:@"sleep" intValue:duration];
            }
        }
        [safeUser save];
        GLMisfit *glMisfit = [GLMisfit sharedGLMisfitForId:
            [safeUser getMisfitId]];
        glMisfit.sleepSyncTime =
            @([[NSDate date] timeIntervalSince1970]);
        [glMisfit save];
    }];
}

# pragma mark - helper
+ (NSError *)misfitErrorWithType:(MisfitErrorType)type {
    switch (type) {
        case MisfitErrorTypeNotConnected:
            return [NSError errorWithDomain:@"MisfitErrorDomain" code:100
                userInfo:@{NSLocalizedDescriptionKey:@"No Misfit connected."}];
        default:
            return nil;
    }
}

+ (NSDictionary *)convertMisfitSession:(NSArray *)sessions {
    NSMutableDictionary *calOut = [@{} mutableCopy];
    NSMutableDictionary *daily = [@{} mutableCopy];
    
    for (NSDictionary *session in sessions) {
        if (!session[MISFIT_CONST_STARTTIME] ||
            !session[MISFIT_CONST_DURATION] ||
            !session[MISFIT_CONST_ACTIVITYTYPE]) {
            continue;
        }
        NSString *date = [[session[MISFIT_CONST_STARTTIME] substringToIndex:10] stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
        NSNumber *duration = session[MISFIT_CONST_DURATION];
        NSNumber *calories = session[MISFIT_CONST_CALORIES];
        daily[date] = daily[date] ? daily[date] : @(0);
        daily[date] = @([daily[date] floatValue] + [duration floatValue]);
        if (calories) {
            calOut[date] = calOut[date] ? calOut[date] : @(0);
            calOut[date] = @([calOut[date] floatValue] + [calories floatValue]);
        }
    }
    return @{@"caloriesOut": calOut, @"dailyExercise": daily};
}

+ (NSDictionary *)convertMisfitSleeps:(NSArray *)sleeps {
    NSMutableDictionary *sleepsDict = [@{} mutableCopy];
    
    for (NSDictionary *sleep in sleeps) {
        if (!sleep[MISFIT_CONST_STARTTIME] ||
            !sleep[MISFIT_CONST_DURATION]) {
            continue;
        }
        NSString *date = [[sleep[MISFIT_CONST_STARTTIME] substringToIndex:10] stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
        NSNumber *duration = sleep[MISFIT_CONST_DURATION];
        sleepsDict[date] = sleepsDict[date] ? sleepsDict[date] : @(0);
        sleepsDict[date] = @([sleepsDict[date] floatValue] + [duration floatValue]);
    }
    return sleepsDict;
}

@end
