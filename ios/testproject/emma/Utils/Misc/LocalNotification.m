//
//  LocalNotification.m
//  emma
//
//  Created by Eric Xu on 8/6/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "LocalNotification.h"

@implementation LocalNotification

+ (void)scheduleLocalNotification:(NSString *)localType title:(NSString *)title date:(NSDate *)date repeat:(NSInteger)repeatInterval id:(NSString *)extId userId:(NSNumber *)userId info:(id)info {
    [LocalNotification cancelNotification:extId];
    if ([date timeIntervalSinceNow] <= 0) {
        return;
    }
    UILocalNotification* localNotif = [[UILocalNotification alloc] init];
    localNotif.fireDate = date;
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
    localNotif.alertBody = title;
    localNotif.repeatInterval = repeatInterval;
    localNotif.soundName = @"alarm.caf";
    localNotif.userInfo = @{
                            NOTIF_USERINFO_KEY_EXT_ID : extId,
                            NOTIF_USERINFO_KEY_USER_ID: userId,
                            NOTIF_USERINFO_KEY_TYPE: localType,
                            NOTIF_USERINFO_KEY_INFO: info,
                            };
    // GLLog(@"add notifcation for alarm: %@", localNotif);
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}


+ (void)cancelAllNotifications {
    UIApplication *app = [UIApplication sharedApplication];
	for (UILocalNotification *localNotif in [app scheduledLocalNotifications]) {
        [app cancelLocalNotification:localNotif];
    }
}

+ (void)cancelNotification:(NSString *)extId {
    NSArray *notifs = [LocalNotification findNotification:extId];
    if (notifs) {
        for (UILocalNotification *notif in notifs ) {
            [[UIApplication sharedApplication] cancelLocalNotification:notif];
        }
    }
}

+ (NSArray *)findNotification:(NSString *)extId {
    UIApplication *app = [UIApplication sharedApplication];
	NSArray *localNotifs = [app scheduledLocalNotifications];
    NSMutableArray *mArr = [NSMutableArray array];
    
	for (UILocalNotification *localNotif in localNotifs) {
		if ([[localNotif.userInfo valueForKey:NOTIF_USERINFO_KEY_EXT_ID] isEqual:extId]){
            // GLLog(@"clear notification for alarm:%@", localNotif);
            [mArr addObject:localNotif];
		}
	}
    
    return mArr;
}

@end
