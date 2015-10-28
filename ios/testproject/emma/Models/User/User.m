//
//  User.m
//  emma
//
//  Created by Ryan Ye on 2/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DataStore.h"
#import "GlowFirst.h"
#import "Interpreter.h"
#import "JsInterpreter.h"
#import "LocalNotification.h"
#import "Network.h"
#import "Notification.h"
#import "PredictionRule.h"
#import "Settings.h"
#import "SyncableAttribute.h"

#import "UIImage+Resize.h"
#import "User.h"
#import "UserDailyData.h"
#import "UserMigration.h"
#import "Activity.h"
#import "VariousPurposesConstants.h"
#import "Predictor.h"
//#import "User+Fitbit.h"
#import "User+Jawbone.h"
#import "Nutrition.h"
#import "ChartData.h"
#import "HealthProfileData.h"
#import "Forum.h"
#import "NSDictionary+Accessors.h"
#import "Appointment.h"
#import "UserMedicalLog.h"
#import "DailyLogSummary.h"
#import "MedicalRecordsDataManager.h"
#import "StatusHistory.h"
#import "UserStatusDataManager.h"
#import "DailyTodo.h"
#import "FertilityTest.h"
#import "Period.h"

#define MAX_LIMITED_CYCLE 13
#define NETWORK_QUEUE_CAPACITY 1
#define DEFAULT_KEY_USER_ID @"userRealID"

@interface User () {
    BOOL networkQueueRunning;
}

@property (readonly) NSSet *modifiedMedicalLogs;
@property (readonly) NSSet *modifiedDailyData;
@property (readonly) NSSet *modifiedNotifications;
@property (readonly) NSSet *modifiedDailyTodos;
@property (readonly) NSMutableArray *networkQueue;
@end

@implementation User
@dynamic id;
@dynamic firstName;
@dynamic lastName;
@dynamic gender;
@dynamic birthday;
@dynamic notificationsRead;
@dynamic settings;
@dynamic partner;
@dynamic dailyData;
@dynamic medicalLogs;
@dynamic notifications;
@dynamic email;
@dynamic primary;
@dynamic predictionRules;
@dynamic fbId;
@dynamic mfpId;
@dynamic jawboneId;
@dynamic fitbitId;
@dynamic lastCalendarSync;
@dynamic lastSyncTime;
@dynamic events;
@dynamic onboarded;
@dynamic attemptLength;
@dynamic lastSeen;
@dynamic ovationStatus;
@dynamic rulesSignature;
@dynamic apnsDeviceToken;
@dynamic tutorialCompleted;
@dynamic encryptedToken;
@dynamic profileImageUrl;
@dynamic glowFirst;
@dynamic status;
@dynamic reminders;
@dynamic appointments;
@dynamic nutritions;
@dynamic insights;
@dynamic predictionMigrated0;
@dynamic appVersion;
@dynamic articles;
@dynamic statusHistory;
@dynamic statusHistoryDirty;
@dynamic periodDirty;
@dynamic todos;
@dynamic fertilityTest;
@dynamic periods;

@synthesize currentLocationCity;
@synthesize fbInfo;
@synthesize profileImage;
@synthesize currentLocation;
@synthesize firstPb = _firstPb;
@synthesize activityDirty;
@synthesize networkQueue=_networkQueue;
@synthesize autoSave;

- (NSDictionary *)attrMapper {
    return @{@"first_name"         : @"firstName",
             @"last_name"          : @"lastName",
             @"email"              : @"email",
             @"fb_id"              : @"fbId",
             @"birthday"           : @"birthday",
             @"gender"             : @"gender",
             @"id"                 : @"id",
             @"onboarded"          : @"onboarded",
             @"attempt_length"     : @"attemptLength",
             @"notifications_read" : @"notificationsRead",
             @"last_seen"          : @"lastSeen",
             @"ovation_status"     : @"ovationStatus",
             @"rules_signature"    : @"rulesSignature",
             @"apns_device_token"  : @"apnsDeviceToken",
             @"encrypted_token"    : @"encryptedToken",
             @"profile_image"      : @"profileImageUrl",
             @"tutorial_completed" : @"tutorialCompleted",
             @"status"             : @"status",
             @"mfp_id"             : @"mfpId",
             @"jawbone_id"         : @"jawboneId",
             @"fitbit_id"          : @"fitbitId",
             @"app_version"        : @"appVersion",
             @"prediction_migrated0" : @"predictionMigrated0",
             @"primary"            : @"primary",
             };
}

- (NSInteger)currentPurpose {
    NSInteger currentStatus = self.settings.currentStatus;
    if (currentStatus < AppPurposesEnumEnd && currentStatus >= AppPurposesEnumStart) {
        return currentStatus;
    }
    else {
        return AppPurposesTTC;
    }
}

- (BOOL)isAvoidingPregnancy {
    return [self currentPurpose] == AppPurposesAvoidPregnant;
}

- (BOOL)isPregnant {
    return [self currentPurpose] == AppPurposesAlreadyPregnant;
}

- (BOOL)isFertilityTreatmentUser
{
    return self.settings.currentStatus == AppPurposesTTCWithTreatment;
}

- (BOOL)isMale
{
    return [self.gender isEqual:MALE];
}

- (BOOL)isFemale
{
    return [self.gender isEqual:FEMALE];
}

- (BOOL)isIUIOrIVF {
    if (([self currentPurpose] == AppPurposesTTCWithTreatment) &&
        (self.settings.fertilityTreatment == FertilityTreatmentTypeIUI ||
         self.settings.fertilityTreatment == FertilityTreatmentTypeIVF)) {
        return YES;
    }
    return NO;
}

// This is a main-thread User instance
static User* _currentUser = nil;
static BOOL hasDirtyDailyData = NO;

+ (id)newInstance:(DataStore *)ds {
    // rewrite the basemodul new instance
    User *u = (User *)[super newInstance:ds];
    GlowFirst *gf = [GlowFirst newInstance:ds];
    u.glowFirst = gf;
    u.activityDirty = YES;
    return u;
}

+ (User *)userOwnsPeriodInfo
{
    User *user = [User currentUser];
    if (!user) {
        return nil;
    }
    if (user.isSecondary) {
        user.partner.dataStore = user.dataStore;
        return user.partner;
    }
    return user;
}

+ (User *)currentUser {
    //return [self mockUser];
    if (!_currentUser) {
        // only main thread can allocate
        if ([NSThread isMainThread]) {
            NSString *objId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userObjectID"];
            // added in v4.0.1, once all client is upgraded to v4.0.1, we should use this
            // userID instead of objId to instance the user
//            NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_KEY_USER_ID];
            
            NSString *store = [[NSUserDefaults standardUserDefaults] objectForKey:@"userDataStore"];
            if (objId && store) {
                _currentUser = (User *)[[DataStore storeWithName:store] objectWithURI:[NSURL URLWithString:objId]];
                _currentUser.dataStore = [DataStore storeWithName:store];
                [_currentUser subscribeChildrenUpdates];
                
                if (_currentUser.partner) {
                    _currentUser.partner.dataStore = _currentUser.dataStore;
                }
                [CrashReport setUserId:[NSString stringWithFormat:@"%@", _currentUser.id]];
                [[Logging getInstance] setUserId:_currentUser.id];
            }
        } else {
            [NSException raise:@"NotInMainQueueException" format:@"Can not get main-user instance in a non-main thread."];
            return nil;
        }
    }
    return _currentUser;
}

+ (User *)fetchById:(NSNumber *)userId dataStore:(DataStore *)ds {
    return (User *)[self fetchObject:@{@"id" : userId} dataStore:ds];
}

+ (id)upsertWithServerData:(NSDictionary *)data dataStore:(DataStore *)ds {
    User *user = [self fetchById: [data objectForKey:@"user_id"] dataStore:ds];
    if (!user) {
        user = [self newInstance:ds];
    }
    [user updateAttrsFromServerData:data];
    [user upsertChildren:data];
    if (data[@"misfit_id"]) {
        [User misfitFromServerInfo:data forUser:user];
    }
    return user;
}

+ (void)signInWithToken:(NSString *)token completionHandler:(PullCallback)back
{
    if (!token)
    {
        if (back)
        {
            back([NSError errorWithDomain:@"com.glow.error" code:0 userInfo:@{@"msg": @"Token invalid"}]);
        }
    }
    [[Network sharedNetwork] post:@"users/signin/token" data:@{@"token": token} requireLogin:NO completionHandler:^(NSDictionary *result, NSError *err) {
        GLLog(@"result:%@, err:%@", result, err);
        id userData = [result objectForKey:@"user"];
        NSString *msg = [userData objectForKey:@"msg"];
        if (err || msg) {
            if (!err)
            {
                err = [NSError errorWithDomain:@"com.glow.error" code:0 userInfo:@{@"msg":msg}];
            }
            if (back)
            {
                back(err);
            }
        } else if (userData != [NSNull null]) {
            User *user = [User upsertWithServerData:userData dataStore:[DataStore defaultStore]];
            [user save];
            [user login];
            if (back)
            {
                back(nil);
            }
        }
    }];
}

+ (void)signInWithEmail:(NSDictionary *)userInfo {

    [[Network sharedNetwork] post:@"users/signin" data:@{@"userinfo": userInfo} requireLogin:NO completionHandler:^(NSDictionary *result, NSError *err) {
        GLLog(@"result:%@, err:%@", result, err);
        id userData = [result objectForKey:@"user"];
        NSString *msg = [userData objectForKey:@"msg"];
        if (err || msg) {
            if (err.code == ERROR_CODE_SERVICE_UNAVAILBLE) {
                [self publish:EVENT_USER_LOGIN_FAILED data:@"Glow maintenance in progress. Please try again in a few minutes."];
            } else {
                [self publish:EVENT_USER_LOGIN_FAILED data:msg? msg:@"Failed to connect to server."];
            }
        } else if (userData != [NSNull null]) {
            User *user = [User upsertWithServerData:userData dataStore:[DataStore defaultStore]];
            [user save];
            [user login];
        }
    }];
}

+ (void)signUpWithEmail:(NSDictionary *)userInfo {
    
    NSDate *birthday = [userInfo objectForKey:USERINFO_KEY_BIRTHDAY];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    [dict setObject:@([birthday timeIntervalSince1970]) forKey:USERINFO_KEY_BIRTHDAY];

    NSTimeZone *localTime = [NSTimeZone systemTimeZone];
    [dict setObject:[localTime name] forKey:@"timezone"];

    NSDictionary *onboardingData = [Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS];
    NSMutableDictionary *onboardingInfo = [[Settings createPushRequestForNewUserWith:onboardingData] mutableCopy];
    [onboardingInfo addEntriesFromDictionary:dict];
    [[Network sharedNetwork] post:@"v2/users/signup" data:@{@"onboardinginfo":onboardingInfo} requireLogin:NO timeout:NETWORK_MULTIPART_TIMEOUT completionHandler:^(NSDictionary *result, NSError *err) {
        GLLog(@"result:%@, err:%@", result, err);
        id userData = [result objectForKey:@"user"];
        NSString *msg = [result objectForKey:@"msg"];
        if (err || msg) {
            if (err.code == ERROR_CODE_SERVICE_UNAVAILBLE) {
                [self publish:EVENT_USER_SIGNUP_FAILED data:@"Glow maintenance in progress. Please try again in a few minutes."];
            } else {
                [self publish:EVENT_USER_SIGNUP_FAILED data:msg? msg:@"Failed to connect to server."];
            }
        } else if (userData != [NSNull null]) {
            [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:nil];
            User *user = [User upsertWithServerData:userData dataStore:[DataStore defaultStore]];
            [user update:@"onboarded" value:@YES];
            [user save];
            [FBAppEvents logEvent:FBAppEventNameCompletedRegistration
                parameters:@{FBAppEventParameterNameRegistrationMethod:
                @"Email"}];
            [user login];
            
            if (user.isFemale && user.isSecondary) {
                [Utils setDefaultsForKey:USER_DEFAULTS_SIGN_UP_WARNING_TYPE_KEY withValue:SIGN_UP_WARNING_TYPE_FEMALE_PARTNER];
            }
            else if (user.isMale && result[@"disconnected"]) {
                [Utils setDefaultsForKey:USER_DEFAULTS_SIGN_UP_WARNING_TYPE_KEY withValue:SIGN_UP_WARNING_TYPE_MALE_INVITED_BY_MALE];
            }

        }
    }];
}

- (void)updateOnboardingInfoWithCompletionHandler:(PullCallback)back
{
    NSDictionary *onboardingData = [Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS];
    NSDictionary *dict = [self postRequest:@{@"onboardinginfo": [Settings createPushRequestForNewUserWith:onboardingData]}];
    
    [[Network sharedNetwork] post:@"users/update_onboarding" data:dict requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        GLLog(@"result:%@, err:%@", result, err);
        id userData = [result objectForKey:@"user"];
        NSString *msg = [userData objectForKey:@"msg"];
        
        if (err || msg) {
            if (!err)
            {
                err = [NSError errorWithDomain:@"com.glow.error" code:0 userInfo:@{@"msg":msg}];
            }
            if (back)
            {
                back(err);
            }
        }else if (userData != [NSNull null]) {
            User *user = [User upsertWithServerData:userData dataStore:[DataStore defaultStore]];
            [user update:@"onboarded" value:@YES];
            [user save];
            [user login];
            if (back)
            {
                back(nil);
            }
        }
    }];
}

- (void)logoutAndCleanDatabase
{
    [self publish:EVENT_TOKEN_EXPIRED];
    [self subscribeOnce:EVENT_USER_LOGGED_OUT handler:^(Event *e)
    {
        [Utils clearAllAppData];
    }];
}


- (void)updateUserTokenWithCompletionHandler:(PullCallback)back
{
    NSNumber *originalUserID = self.id;
    [[Network sharedNetwork] post:@"users/update_token" data:[self postRequest:@{}] requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (err)
        {
            if (back)
            {
                back(err);
            }
            return;
        }
        GLLog(@"result:%@, err:%@", result, err);
        NSString *newKey = [result objectForKey:@"key"];
        NSNumber *uid = [result objectForKey:@"uid"];
        NSNumber *partnerUID = [result objectForKey:@"puid"];
        
        if ([uid isEqualToNumber:originalUserID] && [uid isEqualToNumber:self.id])
        {
            self.encryptedToken = newKey;
            if (back)
            {
                back(nil);
            }
        }
        else if ([partnerUID isEqualToNumber:originalUserID])
        {
            [[Network sharedNetwork] post:@"users/partner_token" data:[self postRequest:@{}]
                             requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
                NSString *newKey = [result objectForKey:@"key"];
                if (newKey)
                {
                    self.encryptedToken = newKey;
                    if (back)
                    {
                        back(nil);
                    }
                }
                else
                {
                    if (!err)
                    {
                        err = [NSError errorWithDomain:@"com.glow.error" code:0 userInfo:nil];
                    }
                    if (back)
                    {
                        back(err);
                    }
                }
            }];
        }
        if (!err)
        {
            err = [NSError errorWithDomain:@"com.glow.error" code:0 userInfo:nil];
        }
        if (!([uid isEqualToNumber:originalUserID] || [partnerUID isEqualToNumber:originalUserID]))
        {
            [self logoutAndCleanDatabase];
        }
        else
        {
            if (back)
            {
                back(err);
            }
        }
    }];
}

+ (void)verifyPartnerEmail:(NSString *)email completion:(VerifyEmailCallback)completion
{
    [[Network sharedNetwork] post:@"users/verify_partner_email"
                             data:@{@"email": email}
                     requireLogin:NO
                completionHandler:^(NSDictionary *response, NSError *err) {
                    if (!completion) {
                        return;
                    }
                    
                    NSInteger rc = [response[@"rc"] integerValue];
                    if (err || rc != RC_SUCCESS) {
                        completion(NO, err);
                        return;
                    }
                    completion(YES, nil);
    }];
}

+ (void)signUpAsPartnerWithEmail:(NSDictionary *)userInfo {
    
    NSDate *birthday = [userInfo objectForKey:USERINFO_KEY_BIRTHDAY];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    [dict setObject:@([birthday timeIntervalSince1970]) forKey:USERINFO_KEY_BIRTHDAY];

    NSTimeZone *localTime = [NSTimeZone systemTimeZone];
    [dict setObject:[localTime name] forKey:@"timezone"];

    NSDictionary *onboardingData = [Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS];
    NSDictionary *data = @{
                           @"onboardinginfo": [Settings createPushRequestForNewUserWith:onboardingData],
                           @"userinfo": dict };
    
    [[Network sharedNetwork] post:@"users/partner_signup"
                             data:data
                     requireLogin:NO
                          timeout:NETWORK_MULTIPART_TIMEOUT
                completionHandler:^(NSDictionary *result, NSError *err) {
                    GLLog(@"result:%@, err:%@", result, err);
                    NSInteger rc = [result[@"rc"] integerValue];
                    NSString *msg = result[@"msg"] ? result[@"msg"] : @"Failed to connect to server.";
                    if (err || rc != RC_SUCCESS) {
                        [self publish:EVENT_USER_SIGNUP_FAILED data:msg];
                        return;
                    }
                    [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:nil];
                    User *user = [User upsertWithServerData:result[@"user"] dataStore:[DataStore defaultStore]];
                    [user save];
                    [FBAppEvents logEvent:FBAppEventNameCompletedRegistration
                        parameters:@{FBAppEventParameterNameRegistrationMethod:
                        @"Email_partner"}];
                    [user login];
            }];
}

+ (void)recoverPassword:(NSDictionary *)userInfo {
    NSAssert([userInfo objectForKey:@"email"], @"Recover password requires email.");

    [[Network sharedNetwork] post:@"users/recover_password"
                             data:@{@"userinfo": userInfo}
                     requireLogin:NO
                completionHandler:^(NSDictionary *result, NSError *err) {
                    GLLog(@"result:%@, err:%@", result, err);
                    id userData = [result objectForKey:@"user"];
                    NSString *msg = [userData objectForKey:@"msg"];
                    if (err || msg) {
                        [self publish:EVENT_RECOVERY_PASSWORD_FAILED data:msg? msg:@"Failed to connect to server."];
                    } else {
                        [self publish:EVENT_RECOVERY_PASSWORD_SUCCEEDED data: [userData objectForKey:@"email"]];
                    }
    }];
}

+ (void)resetPassword:(NSDictionary *)userInfo {
    [[Network sharedNetwork] post:@"users/reset_password"
                             data:@{@"userinfo": userInfo}
                     requireLogin:NO
                completionHandler:^(NSDictionary *result, NSError *err) {
                    GLLog(@"result:%@, err:%@", result, err);
                    id userData = [result objectForKey:@"user"];
                    NSString *msg = [userData objectForKey:@"msg"];
                    if (err || msg) {
                        [self publish:EVENT_RESET_PASSWORD_FAILED data:msg? msg:@"Failed to connect to server."];
                    } else if (userData != [NSNull null]) {
                        User *user = [User upsertWithServerData:userData dataStore:[DataStore defaultStore]];
                        [user save];
                        [user login];
                        [self publish:EVENT_RESET_PASSWORD_SUCCEEDED];
                    }
                }];
}

- (void)verifyPassword:(NSString *)password completion:(VerifyOrUpdatePassword)completion
{
    NSDictionary *userinfo = @{@"user_id":self.id, @"password":password};
    [[Network sharedNetwork] post:@"users/verify_password"
                             data:@{@"userinfo": userinfo}
                     requireLogin:NO
                completionHandler:^(NSDictionary *response, NSError *err) {
                    if (!completion) {
                        return;
                    }
                    
                    if (err) {
                        completion(NO, err);
                        return;
                    }
                    
                    if ([response[@"rc"] isEqual:@(1)]) {
                        completion(YES, nil);
                    }
                    else {
                        completion(NO, nil);
                    }
    }];
}

- (void)updatePassword:(NSString *)password completion:(VerifyOrUpdatePassword)completion
{
    NSDictionary *userinfo = @{@"user_id":self.id, @"password":password};
    [[Network sharedNetwork] post:@"users/update_password"
                             data:@{@"userinfo": userinfo}
                     requireLogin:NO
                completionHandler:^(NSDictionary *response, NSError *err) {
                    if (!completion) {
                        return;
                    }
                    
                    if (err) {
                        completion(NO, err);
                        return;
                    }
                    
                    completion(YES, nil);
                }];
}


- (void)subscribeChildrenUpdates {
    @weakify(self)
    [self subscribe:EVENT_MULTI_DAILY_DATA_UPDATE handler:^(Event *evt){
        @strongify(self)
        [self applyDailyDataFrom:[Utils dailyDataDateLabel:(NSDate *)evt.data]];
    }];
    [self subscribe:EVENT_NEW_RULES_PULLED handler:^(Event *evt){
        @strongify(self)
        [RULES_INTERPRETER setPredictionJsNeedsInterpret];
        [self applyDailyDataFrom:DEFAULT_PB_LABEL];
    }];
    [self subscribe:EVENT_USER_SETTINGS_UPDATED handler:^(Event *evt){
        @strongify(self)
        [self applyDailyDataFrom:DEFAULT_PB_LABEL];
    }];
    [self subscribe:EVENT_DAILY_DATA_DIRTIED handler:^(Event *evt){
        // @strongify(self)
        hasDirtyDailyData = YES;
    }];
    [self subscribe:EVENT_PREDICTION_UPDATE handler:^(Event *evt){
        @strongify(self)
        self.activityDirty = YES;
    }];
    [self subscribe:EVENT_APP_IDLE handler:^(Event *evt){
        @strongify(self)
        if (self.autoSave) {
            [self pushToServer];
        }
        
        if (self.activityDirty) {
            [Activity calActivityForCurrentMonth:self];
        }
    }];
    
    [self subscribeOnce:EVENT_TOOLTIP_KEYWORDS_RECEIVED
               selector:@selector(tooltipKeywordsUpdatedFromServer:)];

}

- (void)tooltipKeywordsUpdatedFromServer:(Event *)event;
{
    NSArray *arr = (NSArray *)event.data;
    if (arr && [arr count] > 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:arr forKey:USER_DEFAULTS_KEYWORDS];
        [defaults synchronize];
    }
}


- (void)upsertChildren:(NSDictionary *)data
{
    NSDictionary *settingsData = [data objectForKey:@"settings"];
    if(settingsData) {
        [Settings upsertWithServerData:settingsData forUser:self];
    }

    NSArray *statusHistory = [data objectForKey:@"status_history"];
    if (statusHistory) {
        [StatusHistory resetWithServerData:statusHistory forUser:self];
        self.statusHistoryDirty = NO;
    }
    
    NSDictionary *periodData = [data objectForKey:@"periods"];
    if (periodData) {
        [Period resetWithAlive:periodData[@"alive"] archived:periodData[@"archived"] forUser:self];
        self.periodDirty = NO;
    }

    
    NSDictionary *partnerData = [data objectForKey:@"partner"];
    if (partnerData) {
        GLLog(@"upsert partnerData: %@", partnerData); 
        if (partnerData.count == 0) {
            self.partner = nil;
        } else {
            if (!partnerData[@"user_id"]) {
                NSMutableDictionary * pData = [NSMutableDictionary dictionaryWithDictionary:partnerData];
                pData[@"user_id"] = self.partner.id;
                self.partner = [User upsertWithServerData:(NSDictionary *)pData dataStore:self.dataStore];
            } else {
                self.partner = [User upsertWithServerData:(NSDictionary *)partnerData dataStore:self.dataStore];
            }
        }
    } 
    NSArray *dailyDataList = [data objectForKey:@"daily_data"];
    if(dailyDataList && dailyDataList.count > 0) {
        for (NSDictionary *dailyData in dailyDataList) {
            [UserDailyData upsertWithServerData:dailyData forUser:self];
        }
        [self save];
        // if mom's daily data get updated, recalculate prediction
        if (!self.isSecondary) {
            [self publish:EVENT_NEW_RULES_PULLED];
        }
    }
    
    NSArray *medicalLogs = [data objectForKey:@"medical_logs"];
    if (medicalLogs) {
        for (NSDictionary *log in medicalLogs) {
            [UserMedicalLog upsertWithServerData:log forUser:self];
        }
    }
    
    NSArray *notifications = [data objectForKey:@"notifications"];
    if (notifications) {
        for (NSDictionary *notifData in notifications) {
            [Notification upsertWithServerData:notifData forUser:self];
        }
        [self sortAndPruneNotifications];
        [self save];
        [self publish:EVENT_NOTIFICATION_UPDATED];
    }
    // reminders
    NSArray * reminders = [data objectForKey:@"reminders"];
    if (reminders) {
        [Reminder upsertWithServerArray:reminders forUser:self];
    }
    // appointments
    NSArray * appointments = [data objectForKey:@"appointments"];
    if (appointments) {
        [Appointment upsertWithServerArray:appointments forUser:self];
    }
    
    NSArray *rulesList = [data objectForKey:@"rules"];
    if(rulesList) {
        for (NSDictionary *rule in rulesList) {
            [PredictionRule upsertWithServerData:rule forUser:self];
        }
    }
    NSDictionary *asyncables = [data objectForKey:@"syncable"];
    if (asyncables) {
        for (NSString *attrName in asyncables) {
            [SyncableAttribute upsertWithName:attrName WithServerData:[asyncables objectForKey:attrName] inDataStore:self.dataStore];
        }
    }
    
    // Insights
    [self upsertInsightsWithServerData:data];
}

- (void)upsertInsightsWithServerData:(NSDictionary *)data {
    // update insights
    NSArray *insights = [data objectForKey:@"insights"];
    if (insights) {
        [Insight upsertInsightList:insights forUser:self];
        [self postFeedInsights:insights];
    }
}

- (NSDictionary *)toDictionaryWithServerAttrs {
    NSMutableDictionary *selfDict = [[super toDictionaryWithServerAttrs]
            mutableCopy];
    selfDict[@"settings"] = [self.settings toDictionaryWithServerAttrs];
    return selfDict;
}

- (NSMutableDictionary *)createPushRequest {
    NSMutableDictionary *request = [super createPushRequest];
    
    id settings = [self.settings createPushRequest];
    if (settings) {
        [request setObject:[self.settings createPushRequest] forKey:@"settings"];
    }
    
    
    NSMutableArray *dailyDataRequest = [[NSMutableArray alloc] init];
    for (UserDailyData *data in self.modifiedDailyData) {
        [dailyDataRequest addObject:[data createPushRequest]];
    }
    [request setObject:dailyDataRequest forKey:@"daily_data"];

    NSMutableArray *medicalLogRequest = [NSMutableArray array];
    for (UserMedicalLog *log in self.modifiedMedicalLogs) {
        [medicalLogRequest addObject:[log createPushRequest]];
    }
    [request setObject:medicalLogRequest forKey:@"medical_logs"];
    
    NSMutableArray *notifRequest = [[NSMutableArray alloc] init];
    for (Notification *notif in self.modifiedNotifications) {
        [notifRequest addObject:[notif createPushRequest]];
    }
    [request setObject:notifRequest forKey:@"notifications"];
    
    NSMutableArray *dailyTodosRequest = [[NSMutableArray alloc] init];
    for (DailyTodo *todo in self.modifiedDailyTodos) {
        [dailyTodosRequest addObject:[todo createPushRequest]];
    }
    [request setObject:dailyTodosRequest forKey:@"daily_checks"];

    NSArray *readInsights = [Insight createPushRequestForUser:self];
    if (readInsights && readInsights.count > 0) {
        [request setObject:readInsights forKey:@"insights"];
    }
    
    // add reminders
    // before local migration, we do not push andy reminder data to server
    if ([Reminder finishedMigrationForUser:self]) {
        // push reminders
        [request setObject:[Reminder createPushRequestList:self] forKey:@"reminders"];
    }
    
    // status history
    if (self.statusHistoryDirty) {
        NSMutableArray *statusHistoryRequest = [NSMutableArray array];
        for (StatusHistory *history in [StatusHistory allHistoryForUser:self]) {
            [statusHistoryRequest addObject:[history createPushRequest]];
        }
        [request setObject:statusHistoryRequest forKey:@"status_history"];
    }
    
    // period
    if (self.periodDirty) {
        NSMutableArray *periodsRequest = [NSMutableArray array];
        for (Period *period in self.periods) {
            [periodsRequest addObject:[period createPushRequest]];
        }
        [request setObject:@{@"alive": periodsRequest, @"archived": @[]} forKey:@"periods"];
    }
    
    [request setObject:@([[self.lastSyncTime toTimestamp] intValue]) forKey:@"last_sync_time"];
    
    return request;
}

- (NSSet *)modifiedMedicalLogs
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dirty == YES"];
    return [self.medicalLogs filteredSetUsingPredicate:predicate];
}

- (NSSet *)modifiedEvents {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dirty == YES"];
    return [self.events filteredSetUsingPredicate:predicate];
}

- (NSSet *)modifiedDailyData {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dirty == YES"];
    return [self.dailyData filteredSetUsingPredicate:predicate];
}

- (NSSet *)modifiedNotifications {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dirty == YES"];
    return [[self.notifications set] filteredSetUsingPredicate:predicate];
}

- (NSSet *)modifiedDailyTodos {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dirty == YES"];
    return [self.todos filteredSetUsingPredicate:predicate];
}


#pragma mark - post Queue related

- (NSMutableArray *)networkQueue {
    if (!_networkQueue) {
        _networkQueue = [NSMutableArray array];
    }
    return _networkQueue;
}

- (void)pushToServer {
    [CrashReport leaveBreadcrumb:@"pushToServer"];
    if ([self.networkQueue count] < NETWORK_QUEUE_CAPACITY) {
        [self.networkQueue addObject:NETWORK_OP_PUSH];
    }
    [self startNetworkQueue];
}

- (void)syncWithServer {
    [CrashReport leaveBreadcrumb:@"syncWithServer"];
    // Since syncing with server already includes a push operation, 
    // we could remove last push operation in the queue
    if ([[self.networkQueue lastObject] isEqual:NETWORK_OP_PUSH]) {
        [self.networkQueue removeLastObject];
    }
    if ([self.networkQueue count] < NETWORK_QUEUE_CAPACITY) {
        [self.networkQueue addObject:NETWORK_OP_SYNC];
    } 
    [self startNetworkQueue];
}

- (void)startNetworkQueue {
    if (networkQueueRunning)
        return;
    GLLog(@"debug: startNetworkQueue");
    networkQueueRunning = YES;
    [self processNextNetworkQueueItem];
}

- (void)processNextNetworkQueueItem {
    if ([self.networkQueue count] == 0) {
        GLLog(@"debug: networkQueue empty");
        networkQueueRunning = NO;
        return;
    } 
    NSString *op = self.networkQueue[0];
    [self.networkQueue removeObject:op];
    [BaseModel lockByServer];
    if ([op isEqual:NETWORK_OP_PUSH]) {
        [self publish:EVENT_USER_PUSH_STARTED];
        [self pushToServer:^(NSError *err, NSDictionary *result) {
            if (!err || [err code] == ERROR_CODE_SERVER_ERROR) {
                // When we encounter an error, if it's a network connection error, we should NOT clear dirty states,
                // since it's very likely that the user has a bad connection at the moment.
                // On the other hand, if it's a server error, we should clear dirty states otherwise they won't
                // be able to upload other data afterwards. 
                [self clearStateWithServerResult:result];
            }
            [BaseModel unlockByServer];
            if (err) {
                [self publish:EVENT_USER_PUSH_FAILED];
                [self clearNetworkQueue];
            } else {
                [self publish:EVENT_USER_PUSH_COMPLETED];
                [self processNextNetworkQueueItem];
            }
        }];
    } else if ([op isEqual:NETWORK_OP_SYNC]) {
        [self publish:EVENT_USER_SYNC_STARTED];
        [self pushToServer:^(NSError *pushError, NSDictionary *result) {
            if (pushError) {
                [self publish:EVENT_USER_SYNC_FAILED];
                [BaseModel unlockByServer];
                [self clearNetworkQueue];
                return;
            }
            [self clearStateWithServerResult:result];
            [self pullFromServer:^(NSError *pullError) {
                [BaseModel unlockByServer];
                if (pullError) {
                    [self publish:EVENT_USER_SYNC_FAILED];
                    [self clearNetworkQueue];
                } else {
                    [self publish:EVENT_USER_SYNC_COMPLETED];
                    [self processNextNetworkQueueItem];
                }
            }];
        }];
    }
}

- (void)clearNetworkQueue {
    [self.networkQueue removeAllObjects];
    networkQueueRunning = NO;
}

- (void)pushToServer:(PushCallback)callback {
    NSString *apnsDeviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"apnsDeviceToken"];
    if (![self.apnsDeviceToken isEqual:apnsDeviceToken] && apnsDeviceToken != nil) {
        [self update:@"apnsDeviceToken" value:apnsDeviceToken];
    }
    if (!self.dirty) {
        if (callback) callback(nil, nil);
        return;
    }
    [self save];
    
    NSString *url = @"v2/users/push";
    NSDictionary *request = [self postRequest:@{@"data": [self createPushRequest]}];
//    NSLog(@"push to server: %@", request);
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        // update insights
        if (result[@"user"]) {
            [self upsertInsightsWithServerData:result[@"user"]];
        }
        if (callback) callback(err, result[@"result"]);
    }];
}

- (void)pullFromServer:(PullCallback)callback {
    GLLog(@"pull from server timestamp:%@", self.lastSyncTime);
    NSMutableDictionary *queryDictionary =
            [NSMutableDictionary dictionaryWithObjectsAndKeys:
            @([[self.lastSyncTime toTimestamp] intValue]), @"ts",
                                            self.rulesSignature ? self.rulesSignature : @"", @"rs",
                                            self.encryptedToken, @"ut",
                                            [SyncableAttribute getAllSyncableAttributeSignatures], @"sign",
                                            nil];
    NSString *url = [Utils apiUrl:@"v2/users/pull" query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            // update data in another thread
            User *userCopy = (User *)[self makeThreadSafeCopy];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
                [userCopy updateDataFromPullResult:result];
                if (callback) {
                    dispatch_sync(dispatch_get_main_queue(), ^() {
                        callback(err);
                    });
                }
            });
        } else {
            if (callback) {
                callback(err);
            }
        }
        if (self.encryptedToken) {
            [Utils syncUserDefaultsForUserId:[self.id stringValue] token:self.encryptedToken];
        }
    }];
}

- (void)updateDataFromPullResult:(NSDictionary *)result
{
    NSDictionary *userData = [result objectForKey:@"user"];
    NSNumber * fundStatusObj = [userData objectForKey:@"ovation_status"];
   
    BOOL needRefreshFundPage = NO;
    if (fundStatusObj && ![fundStatusObj isKindOfClass:[NSNull class]]) {
        needRefreshFundPage = ([fundStatusObj intValue] != self.ovationStatus);
    }

    [self updateAttrsFromServerData:userData];
    [self upsertChildren:userData];
    
    NSDate *syncTime = [NSDate date];
    NSNumber *serverTime = result[@"server_time"];
    if (serverTime && [serverTime floatValue] > 0.0) {
        syncTime = [NSDate dateWithTimeIntervalSince1970:[serverTime doubleValue]];
    }
    self.lastSyncTime = syncTime;
    
    [self save];
    
    if ([userData objectForKey:@"daily_data"] || [userData objectForKey:@"daily_todos"]) {
        [self publish:EVENT_USERDAILYDATAORTODO_PULLED_FROM_SERVER data:@{
            @"daily_data" : @([userData objectForKey:@"daily_data"] != nil),
            @"daily_todos" : @([userData objectForKey:@"daily_todos"] != nil)
        }];
    }
    
    NSArray *rulesList = [userData objectForKey:@"rules"];
    if(rulesList) {
        [self publish:EVENT_NEW_RULES_PULLED];
    }
    if (needRefreshFundPage) {
        [self publish:EVENT_FUND_RENEW_PAGE data:@{@"rc": @(RC_SUCCESS)}];
    }
    
    if ([userData objectForKey:@"tooltip_keys"]) {
        [self publish:EVENT_TOOLTIP_KEYWORDS_RECEIVED data:[userData objectForKey:@"tooltip_keys"]];
    }
    
    if (userData[@"global_conf"]) {
        NSDictionary *globalConf = userData[@"global_conf"];
        GLLog(@"global conf: %@", userData[@"global_conf"]);
        for (NSString *k in [globalConf allKeys]) {
            [Utils setDefaultsForKey:k withValue:globalConf[k]];
        }
    }
    
    if (userData[@"misfit_id"]) {
        [User misfitFromServerInfo:userData forUser:self];
    }
}

- (void)updateLastSeen {
    NSString * now = date2Label([NSDate date]);
    NSString * day = date2Label(self.lastSeen);
    if (![day isEqualToString:now]) {
        [self update:@"lastSeen" value:[NSDate date]];
    }
}


- (void)clearStateWithServerResult:(NSDictionary *)result
{
    if (!result) {
        return;
    }
    BOOL settings = [result boolForKey:@"settings"];
    if (settings) {
        [self.settings clearState];
    }
    
    BOOL statusHistory = [result boolForKey:@"status_history"];
    if (statusHistory) {
        self.statusHistoryDirty = NO;
    }
    
    BOOL periods = [result boolForKey:@"periods"];
    if (periods) {
        self.periodDirty = NO;
    }
    
    NSArray *medicalLogs = [result arrayForKey:@"medical_logs"];
    if (medicalLogs) {
        for (NSDictionary *dict in medicalLogs) {
            NSString *date = [dict stringForKey:@"date"];
            NSString *key = [dict stringForKey:@"data_key"];
            UserMedicalLog *medicalLog = [UserMedicalLog medicalLogWithKey:key date:date user:self];
            [medicalLog clearState];
        }
    }
    
    NSArray *dailyData = [result arrayForKey:@"daily_data"];
    if (dailyData) {
        if (dailyData.count == self.modifiedDailyData.count) {
            hasDirtyDailyData = NO;
        }
        for (NSDictionary *dict in dailyData) {
            NSString *date = [dict stringForKey:@"date"];
            UserDailyData *dailyData = [UserDailyData getUserDailyData:date forUser:self];
            [dailyData clearState];
        }
    }
   
    BOOL todos = [result boolForKey:@"daily_checks"];
    if (todos) {
        for (DailyTodo *todo in self.modifiedDailyTodos) {
            [todo clearState];
        }
    }

    
    for (Insight * ins in self.insights) {
        [ins clearState];
    }
    
    NSArray *reminders = [result arrayForKey:@"reminders"];
    if (reminders) {
        for (NSDictionary *dict in reminders) {
            NSString *uuid = [dict stringForKey:@"uuid"];
            Reminder *reminder = [Reminder getReminderByUUID:uuid];
            [reminder clearState];
            
            Appointment *appointment = [Appointment appointmentByReminderUUID:uuid];
            [appointment clearState];
        }
    }
    
    self.notificationsRead = NO;
    
    NSNumber *completed = [result numberForKey:@"completed"];
    if (completed && [completed boolValue]) {
        [self clearState];
    }
    
    [self save];
}

#pragma mark -

- (void)login {
    
    [self _initAfterLogin];
    [self pullFromServer:^(NSError *pullError) {
        [self publish:EVENT_USER_LOGGED_IN];
        [Forum fetchGroupsPageCallback:nil];
    }];

}

- (void)_initAfterLogin
{
    [CrashReport leaveBreadcrumb:@"User login"];
    [CrashReport setUserId:[NSString stringWithFormat:@"%@", self.id]];
    [[Logging getInstance] setUserId:self.id];
    _currentUser = self;
    [_currentUser subscribeChildrenUpdates];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *objId = [[self.objectID URIRepresentation] absoluteString];
    [defaults setObject:objId forKey:@"userObjectID"];
    [defaults setObject:self.dataStore.name forKey:@"userDataStore"];
    // added in v4.0.1, in the feature, we should use userId, not objectId to instance the user
    [defaults setObject:self.id forKey:DEFAULT_KEY_USER_ID];
    
    // remove userFundSummary, it is based on user
    // do not remove fundsSummary, it is for all users
    [defaults removeObjectForKey:@"userFundSummary"];
    [defaults synchronize];
    [self applyDailyDataFrom:DEFAULT_PB_LABEL];
    
    _currentUser.activityDirty = YES;
    
    // migrate old reminders
    [Reminder migrateOldRemindersForUser:self];
    [self doInitalCalorieAndNutritionSync];

}

- (BOOL)isUserFirstLogin {
    /*
     This function now is used to check if we should show the activity bar in menuViewController
     Now, the implementation of this function is very tricky:
       - when user first login, at the moment "menuViewController" is instance, she does not 
         complete the tutorial.
       - we should not call this function again if she finishes the tutorial
     
     In the future, we may add a "timeCreated" value in user's coredata, use it to check the 
     user login time.
     */
    return !self.tutorialCompleted;
}

- (void)_clearForLogout {
    [User clearFBSession];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"userObjectID"];
    [defaults removeObjectForKey:DEFAULT_KEY_USER_ID];
    [defaults removeObjectForKey:@"userDataStore"];
    // remove userFundSummary, it is based on user
    [defaults removeObjectForKey:@"userFundSummary"];
    // remove fund quit demo date
    [defaults removeObjectForKey:USER_DEFAULT_FUND_QUIT_DEMO_DATE];
    [defaults removeObjectForKey:UDK_FITBIT_OAUTH_SECRET];
    [defaults removeObjectForKey:UDK_FITBIT_OAUTH_TOKEN];
    // remove share success story
    [defaults removeObjectForKey:USER_DEFAULTS_LATER_SHARE_CLIKE_TIME];
    // remove ask location info
    [defaults removeObjectForKey:USER_DEFAULTS_KEY_ASK_LOCATION];
    [defaults removeObjectForKey:USER_DEFAULTS_KEY_FORUM_SEEN_TIMES];
    // end
    
    [defaults synchronize];
    
    [self cleanupMisfitOnLogout];
    
    
    [LocalNotification cancelAllNotifications];
    
    // unsubscribe all event, because we are subscribe events in user login
    [self unsubscribeAll];
    // user publish logged out event, but user should not subscribe this event, because we unsubscribe all event
    _currentUser = nil;
    
    // remove daily log summary
    // because dailyLogSummary is not a single instance, so no one can handle "LOGGED_OUT" event. I have to delete it here
    [DailyLogSummary clearPlainSummary];
    
    [[MedicalRecordsDataManager sharedInstance] clearData];
}

- (void)logout {
    [CrashReport leaveBreadcrumb:@"User logout"];
    [[Logging getInstance] setUserId:nil];
    [self _clearForLogout];
    [self publish:EVENT_USER_LOGGED_OUT];
}

- (void)invitePartnerByEmail:(NSDictionary *)partnerInfo completionHandler:(InvitePartnerCallback)callback {
    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"invitePartnerByEmail:%@", partnerInfo[@"email"]]];
    NSString *url = @"users/partner/email";
    NSDictionary *data = [self postRequest:@{
                          @"email" : partnerInfo[@"email"],
                          @"is_mom" : @([self.gender isEqual:FEMALE] == NO),
                          @"name" : partnerInfo[@"name"]
                          }];
    [[Network sharedNetwork] post:url data:data requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        [self handleInvitePartnerResponse:result error:err callback:callback];
    }];
}

- (void)handleInvitePartnerResponse:(NSDictionary *)result error:(NSError *)err callback:(InvitePartnerCallback)callback {
    NSDictionary *userData = [result objectForKey:@"partner"];
    if (err || [userData objectForKey:@"msg"]) {
        NSString *errMsg = @"Can not complete the request right now.";
        if ([userData objectForKey:@"msg"]) {
            errMsg = [userData objectForKey:@"msg"];
        }
        if (callback) 
            callback(self, [NSError errorWithDomain:ERROR_DOMAIN_USER 
                                               code:ERROR_CODE_CANNOT_INVITE_PARTNER 
                                           userInfo:@{@"msg": errMsg}]);
    } else {
        self.partner = [User upsertWithServerData:[result objectForKey:@"partner"] dataStore:self.dataStore];
        self.partner.dataStore = self.dataStore;
        GLLog(@"Parnter added: %@", self.partner.id);
        // the reason we clear all existing daily data is because after partner added, 
        // all daily data (possibly from the partner) will be returned in the next sync call.
        // [self clearDailyData];
        [self save];
        self.firstPb = nil;

        [self syncWithServer];
        [self publish:EVENT_PARTNER_INVITED];
        if (callback) callback(self, err);
    }
}

- (void)removePartner {
    [CrashReport leaveBreadcrumb:@"removePartner"];
    [[Network sharedNetwork] post:@"users/remove_partner" data:[self postRequest:@{}] requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        
        NSString * errMsg = nil;
        if (err) {
            errMsg = @"Can not disconnect right now.";
        } else {
            NSNumber * rc = [result objectForKey:@"rc"];
            NSString * msg = [result objectForKey:@"msg"];
            if (!rc) {
                // old server
            } else if ([rc integerValue] == RC_SUCCESS) {
                // good response
            } else {
                errMsg = msg;
            }
        }
        if (errMsg) {
            [self publish:EVENT_PARTNER_REMOVED_FAILED data:@{@"msg": errMsg}];
        } else {
            self.partner = nil;
            
            if (self.primary != PRIMARY_TRUE) {
                self.medicalLogs = nil;
                self.primary = PRIMARY_TRUE;
            }

            [self save];
            self.firstPb = nil;
            [self syncWithServer];
            [self publish:EVENT_PARTNER_REMOVED];
        }
    }];
}


- (NSFetchRequest *) notificationFetchRequest {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@ and (hidden == NO || hidden == nil)", self.id];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"timeCreated" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDesc];
    [fetchRequest setFetchBatchSize:20];
    return fetchRequest;
}

- (void)clearUnreadNotifications {
    [self update:@"notificationsRead" value:@YES];
    for (Notification *notif in self.notifications) {
        [notif markAsRead]; 
    }
    [self save];
    [self publish:EVENT_UNREAD_NOTIFICATIONS_CLEARED];
}

- (void)sortAndPruneNotifications {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@", self.id];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO]];
    NSArray *sorted = [self.dataStore.context executeFetchRequest:fetchRequest error:nil];
    self.notifications = [NSOrderedSet orderedSetWithArray:sorted range:NSMakeRange(0, MIN([sorted count], EMMA_NOTIFICATION_WATERMARK_LIMIT)) copyItems:NO];
}

- (NSUInteger)unreadNotificationCount {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"unread == YES"];
    return [[[self.notifications set] filteredSetUsingPredicate:predicate] count];
}

- (NSUInteger)unreadInsightCount {
    int cnt = 0;
    NSString * todayLabel = [[NSDate date] toDateLabel];
    for (Insight * ins in self.insights) {
        if ((ins.unread == YES) && ([ins.date isEqualToString:todayLabel])) {
            cnt ++;
            // currently, in genius page, we only show 3 insights
            if (cnt >= 3) {
                break;
            }
        }
    }
    return cnt;
}

- (void)completeOnboarding {
    [CrashReport leaveBreadcrumb:@"completeOnboarding"];
    [self update:@"onboarded" value:@YES];
    self.appVersion = [Utils appVersion];
    [self save];
    
    @weakify(self)
    [self subscribeOnce:EVENT_USER_SYNC_COMPLETED handler:^(Event *evt){
        @strongify(self)
        [self publish:EVENT_USER_ONBOARDING_COMPLETED];
    }];
    [self syncWithServer];
}

- (void)completeTutorial {
    [CrashReport leaveBreadcrumb:@"completeTutorial"];
    if (!self.tutorialCompleted) {
        [self update:@"tutorialCompleted" value:@YES];
        [self save];
        //[self pushToServer];
    }
}

- (void)loadProfileImage:(LoadProfileImageCallback)callback {
    if (!self.profileImage) {
        self.profileImage = [UIImage imageWithContentsOfFile:self.profileImageFilePath];
    }
    if (self.profileImage) {
        callback(self.profileImage, nil);
        return;
    }
    if (self.profileImageUrl || self.fbId) {
        NSString *profileImageUrl = self.profileImageUrl? self.profileImageUrl : [NSString stringWithFormat:@"https://graph.facebook.com/v2.1/%@/picture?width=100&height=100", self.fbId];
        GLLog(@"profile image url: %@", profileImageUrl);
        [[Network sharedNetwork] getImage:profileImageUrl completionHandler:^(UIImage *image, NSError *err) {
            if (!err) {
                self.profileImage = image;
                NSData *data1 = [NSData dataWithData:UIImageJPEGRepresentation(image, 0.8)];
                [data1 writeToFile:self.profileImageFilePath atomically:YES];
            }
            callback(self.profileImage, err);
        }];
    } else {
        callback(nil, nil);
    }
}


- (void)refresh {
    [self syncWithServer];
}

#pragma mark - Prediction
- (void)cleanPrediction {
    [self.predictor clearPrediction];
}

- (PredictionRule *)predictionRule:(NSString *)name {
    for (PredictionRule *rule in self.predictionRules) {
        if ([rule.name isEqual:name]) {
            return rule;
        }
    }
    [PredictionRule loadLocalRulesForUser:self];
    for (PredictionRule *rule in self.predictionRules) {
        if ([rule.name isEqual:name]) {
            return rule;
        }
    }
    return nil;
}

- (BOOL)canDoPrediction{
    return self.firstPb != nil;
}

- (Predictor *)predictor
{
    return [Predictor predictorForUser:self];
}

- (NSMutableArray *)prediction
{
    NSMutableArray *result = [@[] mutableCopy];
    NSMutableSet *pbs = [NSMutableSet set];
    for (NSDictionary *cycle in [self.predictor getA]) {
        if (cycle[@"pb"]) {
            [pbs addObject:cycle[@"pb"]];
        }
    }
    for (NSDictionary *cycle in self.predictor.prediction) {
        NSMutableDictionary *cycleInResult = [cycle mutableCopy];
        if ([pbs containsObject:cycleInResult[@"pb"]]) {
            cycleInResult[@"solid"] = @YES;
        }
        [result addObject:cycleInResult];
    }
    return result;
}

- (NSArray *)a
{
    return [self.predictor getA];
}
- (DayType)predictionForDate:(NSDate *)date
{
    return [self.predictor predictionForDate:date];
}

- (DayType)predictionForDateIdx:(NSInteger)dateIdx
{
    return [self.predictor predictionForDateIdx:dateIdx];
}

- (NSString *)dateLabelForNextPB:(BOOL)includeToday
{
    return [self.predictor dateLabelForNextPB:includeToday];
}

- (NSString *)dateLabelForNextFB:(BOOL)includeToday
{
    return [self.predictor dateLabelForNextFB:includeToday];
}

- (float)fertileScoreOfDate:(NSDate *)date
{
    return [self.predictor fertileScoreOfDate:date];
}

- (void)applyDailyDataFrom:(NSString *)dateLabel {
    [self applyDailyDataFrom:dateLabel withLimit:3];
}

- (void)applyDailyDataFrom:(NSString *)dateLabel withLimit:(NSInteger)limitedCycle {
    GLLog(@"CP init !!, thread = %@", [NSOperationQueue currentQueue]);
    // must be call on MainThread, otherwise, "makeThreadSafeCopy" will get a wrong copy
    if ([NSThread isMainThread]) {
        [self applyDailyDataInMainQueueFrom:dateLabel withLimit:limitedCycle];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self applyDailyDataInMainQueueFrom:dateLabel withLimit:limitedCycle];
        });
    }
}

- (void)applyDailyDataInMainQueueFrom:(NSString *)dateLabel withLimit:(NSInteger)limitedCycle {
    // calcuate mom's periods
    User *user = [User userOwnsPeriodInfo];
    
    NSArray *historicalPeriods = [UserDailyData
            getDailyDataWithPeriodIncludingHistoryForUser:user];
    [UserDailyData translateArchivedPeriodValueForPeriods:historicalPeriods user:user];
    
    if (![user canDoPrediction]){
        [user.predictor onlyCalculateHistoricalStatusInMainQueue];
        return;
    }

    [user.predictor calculateBMR];

    GLLog(@"predict start");
    [user.predictor jsPredictAround:dateLabel];
    GLLog(@"jsPredict done");
    
    [user.predictor recalculateAllInMainQueue];

    return;
}

- (NSInteger)bmrOfDate:(NSDate *)date
{
    float cal = [[ChartData getInstance] getRecommendedCaloire];
    if (cal > 0) {
        return (NSInteger)cal;
    } else
        return [self.predictor bmrOfDate:date];
}

- (NSInteger)calorieInOfDate:(NSDate *)date {
    return [[ChartData getInstance] getCalorieInForDateIdx:[Utils dateToIntFrom20130101:date]];
}

- (User *)makeThreadSafeCopy {
    User *userCopy = (User *)[super makeThreadSafeCopy];
    if (self.partner) {
        userCopy.partner.dataStore = userCopy.dataStore;
    }
    return userCopy;
}

- (NSDictionary *)postRequest:(NSDictionary *)request {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:request];
    [result setObject:self.encryptedToken forKey:@"ut"];
    return result;
}

- (UserDailyData *)firstPb {
    if (!_firstPb || !_firstPb.date) {
        _firstPb = [UserDailyData getEarliestPbForUser:self];
    }
    return _firstPb;
}

//- (void)checkCanRate {
//    NSString *url = @"users/can_rate";
//    NSDictionary *request = [self postRequest:@{}];
//    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
//        NSInteger canRate = [[result objectForKey:@"can_rate"] intValue];
//        if (canRate)
//            [self publish:EVENT_OPEN_RATE_DIALOG];
//    }];
//}
//
//- (BOOL)askForRating {
//    if ((!self.tutorialCompleted) || (!self.onboarded)) {
//        return NO;
//    }
//    // check if we should open the rating alert dialog
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSInteger launchTimes = [[defaults objectForKey:@"launchTimes"] integerValue];
//    NSDate *firstLaunch = [defaults objectForKey:@"firstLaunch"];
//    NSDate *remindRateTime = [defaults objectForKey:@"remindRateTime"];
//    
//    if (([firstLaunch timeIntervalSinceNow] <= -86400 * USED_DAYS_BEFORE_RATE)
//        && (launchTimes >= LAUNCH_TIMES_BEFORE_RATE)
//        && ([remindRateTime timeIntervalSinceNow] <= 0)) {
//        [self checkCanRate];
//        return YES;
//    } else {
//        return NO;
//    }
//}

- (BOOL)isSecondary {
    if (self.primary != PRIMARY_UNKNOWN) {
        return self.primary == PRIMARY_FALSE;
    } else {
        if (self.partner && [self.gender isEqualToString:@"M"])
            return YES;
        else
            return NO;
    }
}

- (BOOL)isPrimary {
    if (self.primary != PRIMARY_UNKNOWN) {
        return self.primary == PRIMARY_TRUE;
    } else {
        if (self.partner && [self.gender isEqualToString:@"F"])
            return YES;
        else
            return NO;
    }
}

- (BOOL)isSingle {
    return self.partner ? NO : YES;
}

- (BOOL)isPrimaryOrSingle {
    return [self isSingle] ? YES : [self isPrimary];
}

- (BOOL)isPrimaryOrSingleMom {
    return [self isSingle] ? [self isFemale] : [self isPrimary];
}

- (BOOL)isSecondaryOrSingleMale {
    return [self isSingle] ? [self isMale] : [self isSecondary];
}

- (float)age {
    int diff = [self.birthday timeIntervalSinceNow];
    return (float)abs(diff) / 86400 / 365;
}

- (float)motherAge {
    int diff;
    if ([self isPrimary]) {
        diff = [self.birthday timeIntervalSinceNow];
    } else {
        diff = [self.partner.birthday timeIntervalSinceNow];
    }
    return (float)abs(diff) / 86400 / 365;
}

- (BOOL)canEditPeriod
{
    if (self.isSecondary) {
        return NO;
    }
    if (self.isMale) {
        return NO;
    }
    return YES;
}


- (void)updateProfileImage:(UIImage *)originImage {
    [CrashReport leaveBreadcrumb:@"updateProfileImage"];
    UIImage *image = [originImage resizedImage:CGSizeMake(256, 256) interpolationQuality:kCGInterpolationMedium];
    
    self.profileImage = image;
    [self publish:EVENT_PROFILE_IMAGE_UPDATE data:image];

    NSString *url = @"users/update_profile_image";
    [[Network sharedNetwork] post:url data:[self postRequest:@{}] requireLogin:YES image:image completionHandler:^(NSDictionary *result, NSError *err) {
        GLLog(@"updateprofileimage:%@ err:%@", result, err);
    }];
    NSData *data1 = [NSData dataWithData:UIImageJPEGRepresentation(image, 0.8)];
    [data1 writeToFile:self.profileImageFilePath atomically:YES];
    
}

- (NSString *)profileImageFilePath {
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/%lu.jpg",docDir, (unsigned long)[[self.id stringValue] hash]];
}

- (void)clearDailyData {
    GLLog(@"clearDailyData");
    for (UserDailyData *d in [self.dailyData copy]) {
        d.user = nil;
        [UserDailyData deleteInstance:d];
    }
}

#pragma mark - reminders
- (NSOrderedSet *)activeReminders:(BOOL)isAppt {
    NSArray * reminders = [Reminder getDisplayedReminders:nil isAppointment:isAppt];
    NSMutableArray * result = [[NSMutableArray alloc] init];
    for (Reminder * rmd in reminders) {
        if (rmd.on == YES) {
            [result addObject:rmd];
        }
    }
    return [NSOrderedSet orderedSetWithArray:result];
}

- (NSOrderedSet *)sortedValidReminders:(BOOL)isAppt {
    NSArray * sortDescriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:@"on" ascending:NO],
        [NSSortDescriptor sortDescriptorWithKey:@"nextWhen" ascending:YES]
    ];
    NSArray *sorted = [Reminder getDisplayedReminders:sortDescriptors isAppointment:isAppt];
    return [NSOrderedSet orderedSetWithArray:sorted];
}

- (void)exportReport:(NSString *)email withUnit:(NSString *)unit
{
    [CrashReport leaveBreadcrumb:@"exportReport"];
    NSString *url = @"users/export";
    NSDictionary *request = [self postRequest:@{@"email": email, @"unit": unit}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        GLLog(@"ret: %@", result);
        [self publish:EVENT_DATA_SUMMARY_SENT];
    }];

}

- (NSOrderedSet *)sortedAppointmentHistory {
    NSArray * sortDescriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:@"when" ascending:NO]
    ];
    NSArray * sorted = [Appointment getAppointments:sortDescriptors onlyHistory:YES];
    return [NSOrderedSet orderedSetWithArray:sorted];
}


- (NSString *)fullName {
    if ([self.lastName length] == 0)
        return self.firstName;
    else
        return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

- (NSString *)pronoun {
    return [self.gender isEqualToString:@"M"] ? @"him" : @"her";
}

- (void)checkEmailAvailability:(NSString *)email handler:(CheckEmailCallback)handler {
    if ([email isEqual:self.email]) {
        handler(YES);
    } else {
        [[Network sharedNetwork] post:@"users/check_email" data:@{@"email": email} requireLogin:NO completionHandler:^(NSDictionary *result, NSError *err) {
            if (!err)
                handler([result[@"is_available"] boolValue]);
        }];
    }
}

- (BOOL)isMissingInfo {
    return !([self.email length] && [self.firstName length] && [self.gender length] && self.birthday != nil);
}

- (void)sharePregnant:(NSString *)story withTitle:(NSString *)title andPhotos:(NSDictionary *)dict anonymously:(BOOL)anonymous callback:(SharePregnantCallback)cb
{
    NSString *url = @"users/share_pregnant";
    NSMutableDictionary *request = [[self postRequest:@{@"html": story, @"anonymous": @(anonymous? 1: 0)}] mutableCopy];
    if (title) {
        [request setObject:title forKey:@"title"];
    }
    [[Network sharedNetwork] post:url data:request requireLogin:YES images:dict completionHandler:^(NSDictionary *result, NSError *err) {
        GLLog(@"result of share_pregnant: %@ %@",result, err);
        if (cb) {
            cb(err);
        }
    }];

}

- (NSString *)pathForUserDirectory
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *userHash = [NSString stringWithFormat:@"%lu", (unsigned long)[[self.id stringValue] hash]];
    NSString *path = [docDir stringByAppendingPathComponent:userHash];
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir] || !isDir) {
        [fileManager removeItemAtPath:path error:NULL];
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return path;
}

- (void)sharedInsight:(Insight *)insight {
    [insight update:@"shareCount" intValue:(insight.shareCount + 1)];
    [insight save];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        [[Network sharedNetwork] post:@"users/insight/shared"
                                 data:[self postRequest: @{@"insight_type": @(insight.type)}]
                         requireLogin:YES
                    completionHandler:^(NSDictionary *response, NSError *err) {
                        GLLog(@"response: %@", response);
                        GLLog(@"err: %@", err);
                    }
         ];
    });
}

- (void)likeInsight:(Insight *)insight {
    [insight update:@"liked" boolValue:!insight.liked];
    NSInteger likeCount = insight.likeCount + (insight.liked ? 1: -1);
    if (likeCount < 0) {
        likeCount = 0;
    }
    [insight update:@"likeCount" intValue:likeCount];
    [insight save];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        [[Network sharedNetwork] post:@"users/insight/like"
                                 data:[self postRequest: @{
                                                           @"insight_type": @(insight.type),
                                                           @"like":@(insight.liked)
                                                           }]
                         requireLogin:YES
                    completionHandler:^(NSDictionary *response, NSError *err) {
                        GLLog(@"response: %@", response);
                        GLLog(@"err: %@", err);
                    }
         ];
    });
    
}


- (void)syncNutritionsAndCaloriesForDate:(NSString *)dateLabel {
    GLLog(@"syncing for date: %@", dateLabel);

    if (![self isConnectedWith3rdPartyHealthApps] || [[Utils dateWithDateLabel:dateLabel] timeIntervalSinceNow] > 0) {
        //Do not sync for future days
        return;
    }

    [Nutrition setDataSynced:YES forDay:dateLabel];

    if ([self isMFPConnected]) {
        [self syncNutritionsForDate:dateLabel];
    } else if (self.jawboneId) {
        [self syncJawboneNutritionsForDate:dateLabel];
    } else if (self.fitbitId) {
        [self syncFitbitNutritionsForDate:dateLabel];
    }
}

- (void)syncNutritionGoals {
    if ([self isMFPConnected]) {
        //
    } else if (self.jawboneId) {
        [self getNutritionGoalsFromJawbone];
    } else if (self.fitbitId) {
        //
    }
}

- (BOOL)isConnectedWith3rdPartyHealthApps {
    return [self isMFPConnected] || self.jawboneId || self.fitbitId ||
        [self isConnectedWithMisfit];
}

- (void)doInitalCalorieAndNutritionSync {
    if ([self isConnectedWith3rdPartyHealthApps]) {
        //Check recent week.

        dispatch_async([self nutritionSyncingThread], ^{
            NSDate *today = [[NSDate date] truncatedSelf];
            NSInteger todayIdx = [Utils dateToIntFrom20130101:today];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self syncNutritionsAndCaloriesForDate:[Utils dateIndexToDateLabelFrom20130101:todayIdx]];
                [self syncNutritionGoals];
                if ([self isConnectedWithMisfit]) {
                    [self syncMisfitActivitiesForDate:[today toDateLabel]
                        forced:NO];
                }
            });
            
            for (NSInteger i=1; i< 7; i++) {
                if (![Nutrition isDataSyncedForDay:[Utils dateIndexToDateLabelFrom20130101:todayIdx - i]] || i < 3) {
                    [NSThread sleepForTimeInterval:1.0];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self syncNutritionsAndCaloriesForDate:[Utils dateIndexToDateLabelFrom20130101:todayIdx - i]];
                    });
                }
            }
        });
        
    }

}

static dispatch_queue_t _syncingThread = 0;
- (dispatch_queue_t)nutritionSyncingThread {
    if (!_syncingThread) {
        _syncingThread = dispatch_queue_create("com.emma.nutritionSync", NULL);
    }
    return _syncingThread;
}

- (NSInteger)nutritionGoalFat {

    if (self.mfpId) {
        //goal or default
    } else if (self.fbId) {
            //Fitbit does not have API to fetch fat goal yet.
    } else if (self.jawboneId) {
        id g = [Utils getDefaultsForKey:JAWBONE_FAT_GOAL];
        if (g && [g integerValue] > 0) {
            return [g integerValue];
        }
    }

    return DEFAULT_NUTRITION_GOAL_FAT;
}

- (NSInteger)nutritionGoalCarb {
    if (self.mfpId) {
        //goal or default
    } else if (self.fbId) {
        //Fitbit does not have API to fetch fat goal yet.
    } else if (self.jawboneId) {
        id g = [Utils getDefaultsForKey:JAWBONE_CARB_GOAL];
        if (g && [g integerValue] > 0) {
            return [g integerValue];
        }
    }
    
    return DEFAULT_NUTRITION_GOAL_CARB;
}

- (NSInteger)nutritionGoalProtein {
    if (self.mfpId) {
        //goal or default
    } else if (self.fbId) {
        //Fitbit does not have API to fetch fat goal yet.
    } else if (self.jawboneId) {
        id g = [Utils getDefaultsForKey:JAWBONE_PROTEIN_GOAL];
        if (g && [g integerValue] > 0) {
            return [g integerValue];
        }
    }
    
    return DEFAULT_NUTRITION_GOAL_PROTEIN;
}

- (BOOL)shouldHaveFertileScore {
    if (self.settings.currentStatus == AppPurposesTTCWithTreatment) {
        return NO;
    }
    if (self.settings.currentStatus == AppPurposesAvoidPregnant) {
        return (self.settings.birthControl == SETTINGS_BC_NONE) ||
            (self.settings.birthControl == SETTINGS_BC_CONDOM) ||
            (self.settings.birthControl == SETTINGS_BC_WITHDRAWAL) ||
            (self.settings.birthControl == SETTINGS_BC_FAM);
    }
    return YES;
}


- (void)fetchRemoteHealthProfileCompletionRate:(FetchHealthCompletionRateCallback)completion
{
    [[Network sharedNetwork] post:@"users/health_profile_completion_rate"
                             data:[self postRequest:@{@"user_id": self.id}]
                     requireLogin:YES
                completionHandler:^(NSDictionary *response, NSError *err) {
                    if (!err && completion) {
                        completion([response[@"rc"] floatValue]);
                    }
                }];
}

- (void)nudgePartner:(NudgePartnerCallback)completion
{
    [[Network sharedNetwork] post:@"users/partner/nudge"
                             data:[self postRequest:@{@"user_id": self.id}]
                     requireLogin:YES
                completionHandler:^(NSDictionary *response, NSError *err) {
                    if (!err) {
                        completion(YES);
                    } else {
                        completion(NO);
                    }
                }];
}


- (void)updateGender:(BOOL)updateToFemale completion:(UpdateUserCallback)completion
{
    [[Network sharedNetwork] post:@"users/change_gender"
                             data:[self postRequest:@{@"user_id": self.id,
                                                      @"update_to_female": @(updateToFemale)}]
                     requireLogin:YES
                completionHandler:^(NSDictionary *response, NSError *err) {
                    if (err) {
                        completion(NO, err.localizedDescription);
                    }
                    else {
                        completion([response[@"rc"] integerValue] == RC_SUCCESS, response[@"error_msg"]);
                    }
                }];
}

- (void)resetLocalDataByServer:(NSDictionary *)serverUser {
    [self.dataStore clearAllExceptObjs:@[self]];
    [self updateAttrsFromServerData:serverUser];
    self.lastSyncTime = nil;
    self.lastCalendarSync = nil;
    [self save];
    [self _clearForLogout];
    [self _initAfterLogin];
}

- (void)clearLocalData:(ClearLocalDataCallback)completion;
{
    NSString *url = @"users/clear_local_data";
    NSDictionary *request = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (err) {
            return completion(NO, @"Network is currently unavailable");
        }
        if ([result[@"rc"] intValue] != RC_SUCCESS) {
            return completion(NO, result[@"msg"]);
        }
        [self resetLocalDataByServer:result[@"user"]];
        [self pullFromServer:^(NSError *error) {
            if (!error) {
                [self publish:EVENT_USER_SYNC_COMPLETED];
                return completion(YES, nil);
            } else {
                return completion(NO, @"Failed to fetch server data, please try again");
            }
        }];
    }];
}

- (void)pullStatusHistory:(PullStatusHistoryCallback)completion
{
    NSDictionary *queryDictionary = @{@"ut": self.encryptedToken};
    NSString *url = [Utils apiUrl:@"v2/users/pull/status_history" query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:^(NSDictionary *response, NSError *err) {
        if (err) {
            return completion(NO);
        }
        NSArray *statusHistory = response[@"status_history"];
        if (!statusHistory || statusHistory.count == 0) {
            return completion(NO);
        } else {
            [StatusHistory resetWithServerData:statusHistory forUser:[User userOwnsPeriodInfo]];
            return completion(YES);
        }
    }];
}


- (void)pullFertilityTests:(PullFertilityTestsCallback)completion
{
    NSDictionary *queryDictionary = @{@"ut": self.encryptedToken};
    NSString *url = [Utils apiUrl:@"v2/users/pull/fertility_tests" query:queryDictionary];
    [[Network sharedNetwork] get:url completionHandler:^(NSDictionary *response, NSError *err) {
        if (err) {
            return completion(NO, nil);
        }
        NSArray *data = response[@"fertility_tests"];
        return completion(YES, data);
    }];
}

- (void)pushFertilityTests:(NSArray *)data completion:(void(^)(BOOL))completionHandler
{
    [[Network sharedNetwork] post:@"v2/users/push/fertility_tests" data:@{@"data": data, @"ut": self.encryptedToken} requireLogin:YES completionHandler:^(NSDictionary *response, NSError *err) {
        if (err) {
            return completionHandler(NO);
        } else {
            return completionHandler(YES);
        }
    }];
}



@end




