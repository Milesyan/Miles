//
//  MFPDelegate.h
//  emma
//
//  Created by Xin Zhao on 13-9-16.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFP.h"
#import "User.h"

#define EVENT_USER_ADD_MFP_RETURNED @"user_add_mfp_returned"
#define EVENT_USER_ADD_MFP_FAILED @"user_add_mfp_failed"
#define EVENT_USER_DISCONNECT_MFP_FAILED @"user_disconnect_mfp_failed"
#define EVENT_MFP_CONNECT_FAILED @"mfp_connect_failed"
#define EVENT_USER_MFP_UPDATED @"user_mfp_updated"

#define MFP_CONNECT_FAILED_MSG @"Can not connect to MyFitnessPal"

#define MFP_LAST_SYNC_TIME_CALORIE @"mfp_last_sync_time_calorie"
#define MFP_LAST_SYNC_TIME_NUTRITION @"mfp_last_sync_time_nutrition"
#define MFP_SYNC_INTERVAL 60*60

#define MFP_ACCESS_TOKEN [NSString stringWithFormat:@"mfp_access_token - %@", [[User currentUser] id]]
#define MFP_REFRESH_TOKEN [NSString stringWithFormat:@"mfp_refresh_token - %@", [[User currentUser] id]]

@interface EmmaMFP : MFP
@property (strong, nonatomic) NSString *id;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *timezone;
@property (strong, nonatomic) NSString *sex;
@property (strong, nonatomic) NSString *dob;
@property (strong, nonatomic) NSNumber *heightInInches;

@property (strong, nonatomic) NSNumber *activity_factor;
@property (strong, nonatomic) NSString *activity_level;
@property (strong, nonatomic) NSNumber *daily_calorie_goal;
@property (strong, nonatomic) NSString *diary_privacy_setting;

- (NSDictionary *)info;
@end


@interface EmmaMFPDelegate : NSObject<MFPDelegate>
@end


typedef void (^MFPConnectCallback)(EmmaMFP *mfp);


@interface User (MyFitnessPal)

@property (readonly) BOOL isMFPConnected;
+ (EmmaMFP*)getMFPConnection;
+ (void)signUpWithMFP;
+ (void)signInWithMFP;
- (void)disconnectForUser;
- (void)addMFPConnectForUser;

- (void)syncNutritionsForDate:(NSString *)dateLabel;
//- (void)syncCalorieOutForDate:(NSString *)dateLabel;
@end
