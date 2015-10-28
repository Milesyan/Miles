//
//  User.h
//  emma
//
//  Created by Ryan Ye on 2/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "BaseModel.h"
#import "PredictionRule.h"
#import "Settings.h"
#import "UserDailyData.h"
#import "FacebookSDK/FacebookSDK.h"
#import "ActivityLevel.h"
#import "GlowFirst.h"
#import "Reminder.h"
#import "Insight.h"
#import "ForumTopic.h"
#import "Contact.h"
#import "FertilityTest.h"

#define DEFAULT_PB [Utils dateOfYear:2013 month:1 day:1]
#define DEFAULT_PB_LABEL @"2013/01/01"
#define DEFAULT_NUTRITION_GOAL_FAT 30
#define DEFAULT_NUTRITION_GOAL_CARB 50
#define DEFAULT_NUTRITION_GOAL_PROTEIN 20

#define EVENT_USER_LOGGED_IN @"user_logged_in"
#define EVENT_USER_LOGGED_OUT @"user_logged_out"
#define EVENT_USER_SYNC_STARTED @"user_sync_started"
#define EVENT_USER_SYNC_COMPLETED @"user_sync_completed"
#define EVENT_USER_SYNC_FAILED @"user_sync_failed"
#define EVENT_USER_PUSH_STARTED @"user_push_started"
#define EVENT_USER_PUSH_COMPLETED @"user_push_completed"
#define EVENT_USER_PUSH_FAILED @"user_push_failed"
#define EVENT_USER_PUSH_FAILED @"user_push_failed"
#define EVENT_USER_LOGIN_FAILED @"user_login_failed"
#define EVENT_USER_SIGNUP_FAILED @"user_signup_failed"
#define EVENT_RECOVERY_PASSWORD_FAILED @"event_recovery_email_failed"
#define EVENT_RECOVERY_PASSWORD_SUCCEEDED @"event_recovery_email_succeeded"
#define EVENT_RESET_PASSWORD_FAILED @"event_reset_email_failed"
#define EVENT_RESET_PASSWORD_SUCCEEDED @"event_reset_email_succeeded"
#define EVENT_USER_ONBOARDING_COMPLETED @"user_onboarding_completed"
#define EVENT_NEW_RULES_PULLED @"new_rules_pulled"
#define EVENT_USER_SETTINGS_UPDATED @"user_settings_updated"
#define EVENT_PARTNER_REMOVED @"partner_removed"
#define EVENT_PARTNER_REMOVED_FAILED @"partner_removed_failed"
#define EVENT_PARTNER_INVITED @"partner_invited"
#define EVENT_PARTNER_INVTTE_FAILED @"event_partner_invite_error"
#define EVENT_OPEN_RATE_DIALOG @"open_rate_dialog"
#define EVENT_PROFILE_IMAGE_UPDATE @"profile_image_updated"
#define EVENT_DAILY_DATA_DIRTIED @"daily_data_dirtied"

#define EVENT_DID_ENTER_PERIOD_EDITOR @"event_did_enter_period_editor"
#define EVENT_DID_LEAVE_PERIOD_EDITOR @"event_did_leave_period_editor"


#define EVENT_FUND_RENEW_PAGE @"event_fund_renew_page"

#define EVENT_DATA_SUMMARY_SENT @"event_data_summary_sent"

#define EVENT_TOOLTIP_KEYWORDS_RECEIVED @"event_tooltip_keywords_received"

#define USERINFO_KEY_EMAIL @"email"
#define USERINFO_KEY_PASSWORD @"password"
#define USERINFO_KEY_FIRSTNAME @"first_name"
#define USERINFO_KEY_LASTNAME @"last_name"
#define USERINFO_KEY_BIRTHDAY @"birthday"
#define USERINFO_KEY_GENDER @"gender"
#define USERINFO_KEY_EXERCISE @"exercise"
#define USERINFO_KEY_HEIGHT @"height"

#define USER_DEFAULTS_KEYWORDS @"UD_Keywords"
#define USER_DEFAULTS_MIN_PRED_DATE @"UD_min_pred_date"
#define USER_DEFAULTS_MAX_PRED_DATE @"UD_max_pred_date"

#define USER_DEFAULTS_LATER_SHARE_CLIKE_TIME @"UD_later_share_click_time"

#define USER_DEFAULTS_KEY_FORUM_SEEN_TIMES  @"user_defaults_key_forum_seen_times"
#define USER_DEFAULTS_KEY_ASK_LOCATION      @"user_defaults_key_ask_location"
#define USER_DEFAULTS_KEY_CAMERA_ASKED      @"user_defaults_key_camera_asked"

#define USER_DEFAULTS_KEY_PREDICTION_SWITCH_INITED @"user_defaults_key_prediction_switch_inited"
// a is normal,  b is top
#define AB_TEST_ONBOARDING_PICKER_NORMAL  1
#define AB_TEST_ONBOARDING_PICKER_TOP     2

#define kResetPassword @"resetPassword"
#define kResetPasswordUserToken @"resetPasswordUserToken"

#define MALE @"M"
#define FEMALE @"F"

#define OVATION_STATUS_NONE         0
#define OVATION_STATUS_UNDER_REVIEW 1
#define OVATION_STATUS_PASS_REVIEW  2
#define OVATION_STATUS_FAIL_REVIEW  3
#define OVATION_STATUS_UNDER_FUND   4
#define OVATION_STATUS_UNDER_FUND_DELAY 5
#define OVATION_STATUS_EXIT_FUND    6
#define OVATION_STATUS_PREGNANT     7
#define OVATION_STATUS_GET_FUND     8
#define OVATION_STATUS_DEMO         9 

#define USER_STATUS_NORMAL 0
#define USER_STATUS_TEMP 1

#define PRIMARY_UNKNOWN 0
#define PRIMARY_TRUE    1
#define PRIMARY_FALSE   2

#define NETWORK_OP_SYNC @"sync"
#define NETWORK_OP_PUSH @"push"

#define USER_KEY_ATTEMPT_LENGTH @"attemptLength"

#define USER_DEFAULTS_SIGN_UP_WARNING_TYPE_KEY @"user_defaults_sign_up_warning_type"
#define SIGN_UP_WARNING_TYPE_FEMALE_PARTNER @"sign_up_warning_type_female_partner"
#define SIGN_UP_WARNING_TYPE_MALE_INVITED_BY_MALE @"sign_up_warning_type_male_invited_by_male"

//#define PURPOSE_TTC 0
//#define PURPOSE_HEALTH 1
////If use settings.currentStatus to store purpose, 2 is used for Pregnant.
//#define PURPOSE_AVOID 3

@class User;
@class Predictor;
@class UserMedicalLog;

typedef void (^FetchUserCallback)(User *user, NSError *error);
typedef void (^CreateAccountCallback)(User *user, NSError *error);
typedef void (^InvitePartnerCallback)(User *user, NSError *error);
typedef void (^LoadProfileImageCallback)(UIImage *image, NSError *error);
typedef void (^PushCallback)(NSError *error, NSDictionary *result);
typedef void (^PullCallback)(NSError *error);
typedef void (^CheckEmailCallback)(BOOL isAvailable);
typedef void (^VerifyEmailCallback)(BOOL success, NSError *error);
typedef void (^UpdateUserCallback)(BOOL success, NSString *errorMessage);
typedef void (^VerifyOrUpdatePassword)(BOOL success, NSError *error);
typedef void (^SharePregnantCallback)(NSError *error);
typedef void (^FetchHealthCompletionRateCallback)(CGFloat rate);
typedef void (^NudgePartnerCallback)(BOOL success);
typedef void (^ClearLocalDataCallback)(BOOL success, NSString *errMsg);
typedef void (^PullStatusHistoryCallback)(BOOL success);
typedef void (^PullFertilityTestsCallback)(BOOL success, NSArray *data);

typedef enum {
    kDayPeriod = 1,
    kDayFertile = 2,
    kDayNormal = 3,
    kDayHistoricalPeriod = 4,
} DayType;

@interface User : BaseModel
    
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, assign) int16_t primary;
@property (nonatomic, retain) NSString * fbId;
@property (nonatomic, retain) NSString * mfpId;
@property (nonatomic, retain) NSString *jawboneId;
@property (nonatomic, retain) NSString *fitbitId;
@property (nonatomic, retain) NSDate * birthday;
@property (nonatomic, retain) NSDictionary * fbInfo;
@property (nonatomic) BOOL notificationsRead;
@property (nonatomic, retain) Settings *settings;
@property (nonatomic, retain) User *partner;
@property (nonatomic, retain) NSSet *dailyData;
@property (nonatomic, retain) NSSet *medicalLogs;
@property (nonatomic, retain) FertilityTest *fertilityTest;
@property (nonatomic, retain) NSOrderedSet *notifications;
@property (nonatomic, retain) NSOrderedSet *reminders;
@property (nonatomic, retain) NSOrderedSet *appointments;
@property (nonatomic, retain) NSOrderedSet *statusHistory;
@property (nonatomic, retain) NSOrderedSet *periods;
@property (nonatomic, retain) NSSet *nutritions;
@property (nonatomic, retain) NSSet *events;
@property (nonatomic, retain) NSSet *predictionRules;
@property (nonatomic, retain) NSDate *lastCalendarSync;
@property (nonatomic, retain) NSDate *lastSyncTime;
@property (nonatomic, retain) NSDate *lastSeen;
@property (nonatomic, assign) BOOL onboarded;
@property (nonatomic) int16_t ovationStatus;
@property (nonatomic) int16_t status;
@property (nonatomic, retain) NSString *attemptLength;
@property (nonatomic, retain) UIImage *profileImage;
@property (readonly) NSUInteger unreadNotificationCount;
@property (readonly) NSUInteger unreadInsightCount;
@property (nonatomic) NSString *rulesSignature;
@property (nonatomic, retain) NSString * apnsDeviceToken;
@property (nonatomic, assign) BOOL tutorialCompleted;
@property (nonatomic, retain) NSString *encryptedToken;
@property (nonatomic, retain) CLLocation *currentLocation;
@property (nonatomic, copy) NSString *currentLocationCity;
@property (nonatomic, retain) UserDailyData *firstPb;
@property (nonatomic, retain) GlowFirst *glowFirst;
@property (nonatomic, retain) NSSet *insights;
@property (nonatomic, assign) BOOL predictionMigrated0;
@property (nonatomic, retain) NSString *appVersion;
@property (nonatomic) BOOL activityDirty;
@property (nonatomic) BOOL statusHistoryDirty;
@property (nonatomic) BOOL periodDirty;
@property (nonatomic, retain) NSSet *articles;
@property (nonatomic, retain) NSSet *todos;
@property (nonatomic, retain) NSString * profileImageUrl;
@property (readonly) NSString *fullName;
@property (readonly) float age;
@property (readonly) NSString *pronoun;

@property (readonly) NSInteger currentPurpose;
@property (nonatomic) BOOL autoSave;
@property (readonly) Predictor *predictor;
@property (readonly) NSMutableArray *prediction;
@property (readonly) NSArray *a;

@property (nonatomic, assign, readonly) BOOL isFertilityTreatmentUser;
@property (nonatomic, assign, readonly) BOOL isFemale;

+ (User *)userOwnsPeriodInfo;
+ (User *)currentUser;
+ (User *)fetchById:(NSNumber *)userId dataStore:(DataStore *)ds;
+ (void)signInWithToken:(NSString *)token completionHandler:(PullCallback)back;
+ (void)signInWithEmail:(NSDictionary *)userInfo;
+ (void)signUpWithEmail:(NSDictionary *)userInfo;
+ (void)verifyPartnerEmail:(NSString *)email completion:(VerifyEmailCallback)completion;
+ (void)signUpAsPartnerWithEmail:(NSDictionary *)userInfo;
+ (void)recoverPassword:(NSDictionary *)userInfo;
+ (void)resetPassword:(NSDictionary *)userInfo;
- (void)verifyPassword:(NSString *)password completion:(VerifyOrUpdatePassword)completion;
- (void)updatePassword:(NSString *)password completion:(VerifyOrUpdatePassword)completion;
- (void)login;
- (void)logout;
- (BOOL)isUserFirstLogin;
- (void)invitePartnerByEmail:(NSDictionary *)partnerInfo completionHandler:(InvitePartnerCallback)callback;
- (void)handleInvitePartnerResponse:(NSDictionary *)result error:(NSError *)err callback:(InvitePartnerCallback)callback;
- (void)removePartner;
- (void)updateGender:(BOOL)updateToFemale completion:(UpdateUserCallback)completion;

- (void)updateOnboardingInfoWithCompletionHandler:(PullCallback)callback;
- (void)updateUserTokenWithCompletionHandler:(PullCallback)callback;
- (void)clearUnreadNotifications;
- (void)pushToServer;
- (void)pullFromServer:(PullCallback)callback;
- (void)syncWithServer;
- (PredictionRule *)predictionRule:(NSString *)name;
- (void)applyDailyDataFrom:(NSString *)date;

- (void)completeOnboarding;
- (void)completeTutorial;
- (void)loadProfileImage:(LoadProfileImageCallback)callback;
- (void)refresh;
- (float)fertileScoreOfDate:(NSDate *)date;
- (DayType)predictionForDate:(NSDate *)date;
- (DayType)predictionForDateIdx:(NSInteger)dateIdx;
- (void)cleanPrediction;
- (NSString *)dateLabelForNextPB:(BOOL)includeToday;
- (NSString *)dateLabelForNextFB:(BOOL)includeToday;
- (NSInteger)bmrOfDate:(NSDate *)date;
- (NSInteger)calorieInOfDate:(NSDate *)date;

- (void)updateLastSeen;
- (void)subscribeChildrenUpdates;
- (NSFetchRequest *) notificationFetchRequest;

//- (BOOL)askForRating;

- (BOOL)isSingle;
- (BOOL)isPrimary;
- (BOOL)isSecondary;
- (BOOL)isPrimaryOrSingle;
- (BOOL)isPrimaryOrSingleMom;
- (BOOL)isSecondaryOrSingleMale;
- (BOOL)isMale;
- (BOOL)isFemale;

- (BOOL)isAvoidingPregnancy;
- (BOOL)isPregnant;
- (BOOL)isIUIOrIVF;
- (float)motherAge;

- (BOOL)canEditPeriod;

- (void)updateProfileImage:(UIImage *)image;
- (NSDictionary *)postRequest:(NSDictionary *)request;

- (NSOrderedSet *)activeReminders:(BOOL)isAppt;
- (NSOrderedSet *)sortedValidReminders:(BOOL)isAppt;
- (NSOrderedSet *)sortedAppointmentHistory;

- (void)exportReport:(NSString *)email withUnit:(NSString *)unit;
- (void)checkEmailAvailability:(NSString *)email handler:(CheckEmailCallback)handler;
- (BOOL)isMissingInfo;
- (void)sharePregnant:(NSString *)story withTitle:(NSString *)title andPhotos:(NSDictionary *)dict anonymously:(BOOL)anonymous callback:(SharePregnantCallback)cb;

- (NSString *)pathForUserDirectory;

- (void)likeInsight:(Insight *)insight;
- (void)sharedInsight:(Insight *)insight;

- (void)syncNutritionsAndCaloriesForDate:(NSString *)dateLabel;
- (BOOL)isConnectedWith3rdPartyHealthApps;
- (void)doInitalCalorieAndNutritionSync;

- (NSInteger)nutritionGoalFat;
- (NSInteger)nutritionGoalCarb;
- (NSInteger)nutritionGoalProtein;

- (BOOL)shouldHaveFertileScore;

- (void)fetchRemoteHealthProfileCompletionRate:(FetchHealthCompletionRateCallback)completion;
- (void)nudgePartner:(NudgePartnerCallback)completion;
- (void)clearLocalData:(ClearLocalDataCallback)completion;
- (void)pullStatusHistory:(PullStatusHistoryCallback)completion;
- (void)pullFertilityTests:(PullFertilityTestsCallback)completion;
- (void)pushFertilityTests:(NSArray *)data completion:(void(^)(BOOL))completionHandler;
@end

#import "User+Facebook.h"
#import "User+MyFitnessPal.h"
#import "User+Jawbone.h"
#import "User+Fitbit.h"
#import "User+Misfit.h"
#import "User+DailyData.h"

#define NUTRITION_DATA_MANUALLY_SYNCED @"nutrition_data_manually_synced"
#define NUTRITION_DATA_AUTO_SYNC_INTERVAL 60*60*24*15 //15 Days
