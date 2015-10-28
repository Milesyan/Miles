//
//  LocalNotification.h
//  emma
//
//  Created by Eric Xu on 8/6/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NOTIF_USERINFO_KEY_EXT_ID @"extId"
#define NOTIF_USERINFO_KEY_TYPE @"type"
#define NOTIF_USERINFO_KEY_INFO @"info"
#define NOTIF_USERINFO_KEY_USER_ID @"userId"
#define NOTIF_USERINFO_VAL_TYPE_REMINDER @"reminder"

@interface LocalNotification : NSObject

+ (NSArray *)findNotification:(NSString *)extId;
+ (void)scheduleLocalNotification:(NSString *)localType title:(NSString *)title date:(NSDate *)date repeat:(NSInteger)repeatInterval id:(NSString *)extId userId:(NSNumber *)userId info:(id)info;
+ (void)cancelNotification:(NSString *)extId;
+ (void)cancelAllNotifications;
@end
