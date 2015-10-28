//
//  User+Mock.m
//  emma
//
//  Created by Ryan Ye on 12/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "User+Mock.h"
#import "Notification.h"
#import "Predictor.h"

@implementation User(Mock)
+ (User *)mockUser {
    static User *_mockUser = nil; 
    if (!_mockUser) {
        DataStore *ds = [DataStore defaultStore];
        NSNumber *userId = @348023;
        User *user = [User fetchById:userId dataStore:ds];
        if(!user) {
            GLLog(@"Create mockup data for notifciation view");
            user = [User newInstance:ds];
            user.id = userId;
            int notifIdBase = 10001;
            for (int i = 10; i > 0; i--) {
                Notification *notif = [Notification newInstance:ds];
                notif.id = @(notifIdBase+i);
                if (i % 2) {
                   notif.type = EMMA_NOTIF_TYPE_1DAY_BEFORE_FB;
                    notif.text = @"You have an all-day event scheduled on **Feb 16**. Consider rescheduling so you and **Kevin** can make spend more time together during **fertile window**.";
                } else {
                    notif.type = EMMA_NOTIF_TYPE_NONE;
                    notif.text = @"**Your fertile window** has started! Your chance for pregnacy wil be the high. Have as much sexual intercourse with Kevin as possible in the next few days!";
                }
                notif.timeCreated = [NSDate dateWithTimeIntervalSinceNow:(i - 20) * 86400]; 
                notif.unread = (i > 5);
                notif.user = user;
            }
            user.firstName = @"Marvel";
            user.lastName = @"Uz";
            user.gender = @"F";
        }
        [user save];
        _mockUser = user;
        [_mockUser subscribeChildrenUpdates];
    }
    return _mockUser;
}

- (void)addMockedNotifications {
    NSDate *haveSexDay = [NSDate date];
    float fertileScore = [self.predictor fertileScoreOfDate:haveSexDay];
    while(fertileScore < 30.0f) {
        haveSexDay = [Utils dateByAddingDays:1 toDate:haveSexDay];
        fertileScore = [self.predictor fertileScoreOfDate:haveSexDay];
    }

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.dateFormat = @"MMMM dd";
    
    Notification *notif1 = [Notification tset:@(arc4random_uniform(1 << 31)) forUser:self]; 
    notif1.type = EMMA_NOTIF_TYPE_1ST_REMIND_SEX;
    notif1.unread = YES;
    if (self.isPrimaryOrSingleMom) {
        notif1.text = [NSString stringWithFormat:@"Hi, your fertile window has started! Try having sexual intercourse with %@ for the next few nights. Be sure to **have sex at least every other day**. The most important day to have sex is **%@**.", self.partner.firstName, [dateFormatter stringFromDate:haveSexDay]]; 
    notif1.title = [NSString stringWithFormat:@"Woohoo! you're ovulating!"];
    } else {
        notif1.text = [NSString stringWithFormat:@"Hi, %@'s fertile window has started! Try having sexual intercourse with %@ for the next few nights. Be sure to **have sex at least every other day**. The most important day to have sex is **%@**.", self.partner.firstName, self.partner.firstName, [dateFormatter stringFromDate:haveSexDay]]; 
        notif1.title = [NSString stringWithFormat:@"Woohoo! %@ is ovulating!", self.partner.firstName];
    }
    notif1.timeCreated = [NSDate date];
    
    if (!self.isPrimaryOrSingleMom) {
        Notification *notif2 = [Notification tset:@(arc4random_uniform(1 << 31)) forUser:self];
        notif2.type = EMMA_NOTIF_TYPE_MOM_SAD;
        notif2.unread = YES;
        notif2.title = [NSString stringWithFormat:@"Cheer %@ up!", self.partner.firstName]; 
        notif2.text = [NSString stringWithFormat:@"It seems %@ is feeling **stressed** today. Would you like to send her a quick note to cheer her up?", self.partner.firstName];
        notif2.timeCreated = [NSDate date];
    }
    [self save];
    [self publish:EVENT_MOCKED_NOTIFICATIONS_ADDED];
}

@end
