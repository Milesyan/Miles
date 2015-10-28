//
//  Notification.h
//  emma
//
//  Created by Ryan Ye on 3/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"

#define EMMA_NOTIF_TYPE_NONE 0
#define EMMA_NOTIF_TYPE_WELCOME        1
#define EMMA_NOTIF_TYPE_1DAY_BEFORE_FB 2
#define EMMA_NOTIF_TYPE_1ST_REMIND_SEX 3
#define EMMA_NOTIF_TYPE_3DAY_NO_SEX    4
#define EMMA_NOTIF_TYPE_OVULATION_SEX  5
#define EMMA_NOTIF_TYPE_NO_PERIOD_INFO 6
#define EMMA_NOTIF_TYPE_EVENT_IN_FW    7
#define EMMA_NOTIF_TYPE_MOM_SAD        8
#define EMMA_NOTIF_TYPE_MOM_3DAY_SAD   9

#define EMMA_USER_ACTION_ACCEPT 1 
#define EMMA_USER_ACTION_REJECT 2
#define EMMA_USER_ACTION_ALARM_SET 3 

#define EMMA_NOTIF_BUTTON_SET_ALARM   1
#define EMMA_NOTIF_BUTTON_SEND_SMS    2
#define EMMA_NOTIF_BUTTON_CONTACT_US  4
#define EMMA_NOTIF_BUTTON_CHECK_IT_OUT      8
#define EMMA_NOTIF_BUTTON_CHECK_THEM_OUT    9
#define EMMA_NOTIF_BUTTON_BUY_TESTKIT       10
#define EMMA_NOTIF_BUTTON_RESPOND_NOW       11
#define EMMA_NOTIF_BUTTON_GO_REMINDER       12
#define EMMA_NOTIF_BUTTON_GO_PROMO          13
#define EMMA_NOTIF_BUTTON_FORUM_TAKE_A_LOOK 14
#define EMMA_NOTIF_BUTTON_DOWNLOAD 15
#define EMMA_NOTIF_BUTTON_CHECK_OUT_GROUP 16
#define EMMA_NOTIF_BUTTON_CHECK_OUT_PERIOD 17
#define EMMA_NOTIF_BUTTON_BIRTH_CONTROL_REFILL 18
#define EMMA_NOTIF_BUTTON_CHECK_COMMENT     19

#define EMMA_NOTIF_BUTTON_GO_GLOW_FIRST     21
#define EMMA_NOTIF_BUTTON_GO_DAILY_LOG      22
#define EMMA_NOTIF_BUTTON_GO_FORUM_PROFILE  24

typedef int UserAction;

@class User;

@interface Notification : BaseModel

@property (nonatomic, retain) NSNumber *id;
@property (nonatomic) int16_t type;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDate *timeCreated;
@property (nonatomic) int16_t action;
@property (nonatomic) int16_t button;
@property (nonatomic, retain) NSDictionary *actionContext;
@property (nonatomic) BOOL unread;
@property (nonatomic) BOOL hidden;
@property (nonatomic, retain) User *user;

+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user;
+ (id)tset:(NSNumber *)notifId forUser:(User *)user;
- (void)updateUserAction:(UserAction)action;
- (void)markAsRead;
- (void)hide;
@end
