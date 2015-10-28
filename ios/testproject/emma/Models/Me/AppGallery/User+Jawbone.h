//
//  User+Jawbone.h
//  emma
//
//  Created by Eric Xu on 2/8/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "User.h"
#import "UP.h"


#define EVENT_USER_ADD_JAWBONE_RETURNED @"user_add_jawbone_returned"
#define EVENT_USER_ADD_JAWBONE_FAILED @"user_add_jawbone_failed"
#define EVENT_USER_DISCONNECT_JAWBONE_FAILED @"user_disconnect_jawbone_failed"
#define EVENT_JAWBONE_CONNECT_FAILED @"jawbone_connect_failed"
#define EVENT_USER_JAWBONE_UPDATED @"user_jawbone_updated"

#define JAWBONE_CONNECT_FAILED_MSG @"Can not connect to Jawbone"

#define JAWBONE_LAST_SYNC_TIME_CALORIE @"jawbone_last_sync_time_calorie"
#define JAWBONE_LAST_SYNC_TIME_NUTRITION @"jawbone_last_sync_time_nutrition"
#define JAWBONE_SYNC_INTERVAL 60*60

#define JAWBONE_FAT_GOAL @"jawbone_fat_goal"
#define JAWBONE_CARB_GOAL @"jawbone_carb_goal"
#define JAWBONE_PROTEIN_GOAL @"jawbone_protein_goal"

@interface User (Jawbone)



+ (void)signUpWithJawbone;
+ (void)signInWithJawbone;
- (void)disconnectJawboneForUser;
- (void)connectJawboneForUser;
- (BOOL)isJawboneConnected;
- (void)syncJawboneNutritionsForDate:(NSString *)dateLabel;

- (void)jawboneOnDailyDataUpdated:(NSDate *)date;
- (void)postFeedMood:(long)moods at:(NSDate *)date;
- (void)postFeedWorkout:(long)workout at:(NSDate *)date;
- (void)postFeedInsights:(NSArray *)insights;
- (void)postFeedPregnancyPercentage:(float)percentage note:(NSString *)note;
- (void)getNutritionGoalsFromJawbone;
@end
