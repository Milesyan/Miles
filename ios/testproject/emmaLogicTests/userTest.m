//
//  userTest.m
//  emma
//
//  Created by Ryan Ye on 2/18/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <stdlib.h>
#import "userTest.h"
#import "Utils.h"
#import "User.h"
#import "Settings.h"
#import "DataStore.h"
#import "UserDailyData.h"
#import "CalendarEvent.h"
#import "Notification.h"
#import "Network.h"
#import "Interpreter.h"

@interface userTest() {
    NSConditionLock *condLock;
    NSTimeInterval timeout;
    DataStore *ds;
}
- (void)block:(NSInteger)condition;
- (void)unblock:(NSInteger)condition;
- (NSString *)randomString:(NSString *)prefix;
- (NSDictionary *)randomFbInfo;
- (User *)createRandomUser:(DataStore *)ds;
- (User *)createRandomUser:(DataStore *)ds fbInfo:(NSDictionary *)fbInfo;
- (void)notificationMockup:(User *)user;
- (void)blockingPullFromServer:(User *)user;
- (void)blockingPushToServer:(User *)user;
- (User *)blockingFetchByFbId:(NSString *)fbId dataStore:(DataStore *)ds;
@end

@implementation userTest
- (void)setUp {
    [super setUp];
    condLock = [NSConditionLock new];
    [[Network sharedNetwork] setCallbackQueue:[[NSOperationQueue alloc] init]];
    timeout = 3.0f;
    ds = [DataStore storeWithName:@"test"];
}

- (void)block:(NSInteger)condition {
    BOOL result = [condLock lockWhenCondition:condition beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
    STAssertTrue(result, @"Async operation timed out.");
}

- (void)unblock:(NSInteger)condition {
    [condLock unlockWithCondition:condition];
}

- (NSString *)randomString:(NSString *)prefix {
    return [NSString stringWithFormat:@"%@%d", prefix, arc4random_uniform(1 << 31)];
}

- (NSDictionary *)randomFbInfo {
    NSString *firstName = [self randomString:@"first"];
    NSString *lastName = [self randomString:@"last"];
    NSString *email = [NSString stringWithFormat:@"%@@upwlabs.com", firstName];
    NSString *fbId = [NSString stringWithFormat:@"%d", arc4random_uniform(1 << 31)];
    NSDictionary *fbInfo = @{
        @"first_name" : firstName,
        @"last_name" : lastName,
        @"email" : email,
        @"id" : fbId,
        @"birthday" : @"2013/07/28",
        @"timezone" : @8
    };
    return fbInfo;
}

- (User *)blockingFetchByFbId:(NSString *)fbId dataStore:(DataStore *)dataStore{
    int cond = arc4random_uniform(1 << 31); 
    __block User *result = nil; 
    [User fetchUserByFacebookID:fbId dataStore:dataStore completionHandler:^(User *user, NSError *err) {
        result = user;
        [self unblock:cond];
    }];
    [self block:cond];
    return result;
}

- (void)blockingPullFromServer:(User *)user {
    int cond = arc4random_uniform(1 << 31); 
    [user pullFromServer:^(NSError *err) {
        [self unblock:cond];
    }];
    [self block:cond];
}

- (void)blockingPushToServer:(User *)user {
    int cond = arc4random_uniform(1 << 31); 
    [user pushToServer:^(NSError *err) {
        [self unblock:cond];
    }];
    [self block:cond];
}

- (User *)createRandomUser:(DataStore *)dataStore {
    NSDictionary *fbInfo = [self randomFbInfo];
    return [self createRandomUser:dataStore fbInfo:fbInfo];
}

- (User *)createRandomUser:(DataStore *)dataStore fbInfo:(NSDictionary *)fbInfo {
    int cond = arc4random_uniform(1 << 31); 
    __block User *result = nil;
    [User createAccount:fbInfo dataStore:dataStore completionHandler:^(User *user, NSError *err) {
        result = user;
        [self unblock:cond];
    }];
    [self block:cond];
    return result;
}

- (void)testFetchObject {
    NSDictionary *fbInfo = [self randomFbInfo];
    [User createAccount:fbInfo dataStore:ds completionHandler:^(User *user, NSError *err) {
        User *fetched = [User fetchById:user.id dataStore:ds]; 
        STAssertEqualObjects(fetched.id, user.id, nil);
        [self unblock:1];
    }];
    [self block:1];
}

- (void)testCreateUser {
    NSDictionary *fbInfo = [self randomFbInfo];
    [User createAccount:fbInfo dataStore:ds completionHandler:^(User *user, NSError *err) {
        STAssertEqualObjects(user.firstName, [fbInfo valueForKey:@"first_name"], nil);
        STAssertEqualObjects(user.lastName, [fbInfo valueForKey:@"last_name"], nil);
        STAssertEqualObjects(user.email, [fbInfo valueForKey:@"email"], nil);
        STAssertEqualObjects(user.fbId, [fbInfo valueForKey:@"id"], nil);
        [self unblock:1];
    }];
    [self block:1];
}

- (void)testSettings {
    User *user = [self createRandomUser:ds];
    STAssertTrue(user.settings.periodCycle == 28, nil);
    STAssertTrue(user.settings.timeZone == -8, nil);
    STAssertTrue(user.settings.pushToCalendar == NO, nil);
}

- (void)testEvents {
    User *user = [self createRandomUser:ds];
    NSDate *baseTime = [Utils dateOfYear:2013 month:2 day:20];
    NSDate *startTime1 = [NSDate dateWithTimeInterval:3600 sinceDate:baseTime];
    NSDate *endTime1 = [NSDate dateWithTimeInterval:7200 sinceDate:baseTime];
    CalendarEvent *evt1 = [CalendarEvent createCoupleEvent:@"Test Event1" startTime:startTime1 endTime:endTime1 alertType:EMMA_ALERT_TYPE_DEFAULT byUser:user];
    STAssertEqualObjects(evt1.title, @"Test Event1", nil);
    STAssertTrue(evt1.type == EMMA_CALENDAR_TYPE_COUPLE, nil);
    STAssertTrue(evt1.alertType == EMMA_ALERT_TYPE_DEFAULT, nil);
    STAssertEqualObjects(evt1.startTime, startTime1, nil);
    STAssertEqualObjects(evt1.endTime, endTime1, nil);
    STAssertEqualObjects(evt1.creator, user, nil);
    STAssertEqualObjects(evt1.user, user, nil);

    NSDate *startTime2 = [NSDate dateWithTimeInterval:-48000 sinceDate:baseTime];
    NSDate *endTime2 = [NSDate dateWithTimeInterval:86400 sinceDate:baseTime];
    CalendarEvent *evt2 = [CalendarEvent createCoupleEvent:@"Test Event2" startTime:startTime2 endTime:endTime2 alertType:EMMA_ALERT_TYPE_DEFAULT byUser:user];

    NSArray *events = [user eventsOnDate:baseTime];
    STAssertTrue([events count] == 2, nil);
    events = [user eventsOnDate:[NSDate dateWithTimeInterval:-86400 sinceDate:baseTime]];
    STAssertTrue([events count] == 1, nil);
    [evt2 deleteEvent];
    [user save];
    events = [user eventsOnDate:baseTime];
    STAssertTrue([events count] == 1, nil);
}

- (void)testPullFromSystemEvent {
    NSDate *baseDate = [NSDate date];
    // create system calendar events
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:baseDate
                                                                 endDate:[NSDate dateWithTimeIntervalSinceNow:100000]
                                                               calendars:nil
                                                                 ];
    GLLog(@"SystemEvents:%@", [eventStore eventsMatchingPredicate:predicate]);
    for (EKEvent* evt in [eventStore eventsMatchingPredicate:predicate]) {
        [eventStore removeEvent:evt span:EKSpanThisEvent error:nil];
    }

    EKEvent *evt1  = [EKEvent eventWithEventStore:eventStore];
    evt1.calendar  = [eventStore defaultCalendarForNewEvents];
    evt1.title     = @"test event1";
    evt1.startDate = [NSDate dateWithTimeInterval:1000 sinceDate:baseDate];
    evt1.endDate = [NSDate dateWithTimeInterval:2000 sinceDate:baseDate];

    EKEvent *evt2  = [EKEvent eventWithEventStore:eventStore];
    evt2.calendar  = [eventStore defaultCalendarForNewEvents];
    evt2.title     = @"test event2";
    evt2.startDate = [NSDate dateWithTimeInterval:11000 sinceDate:baseDate];
    evt2.endDate = [NSDate dateWithTimeInterval:12000 sinceDate:baseDate];
    
    [eventStore saveEvent:evt1 span:EKSpanThisEvent error:nil];
    [eventStore saveEvent:evt2 span:EKSpanThisEvent error:nil];

    User *user = [self createRandomUser:ds];
    NSArray *events = [CalendarEvent pullEventsFromSystemCalendar:user 
                                                        startDate:baseDate
                                                          endDate:[NSDate dateWithTimeInterval:10000 sinceDate:baseDate] complete:^(NSArray *array){}
                                                        ];
    STAssertTrue([events count] == 1, nil);
    CalendarEvent *evt = [events lastObject];
    STAssertEqualObjects(evt.title, @"test event1", nil);
    STAssertEqualObjects(evt.startTime, evt1.startDate, nil);
    STAssertEqualObjects(evt.endTime, evt1.endDate, nil);
    STAssertTrue(evt.alertType == EMMA_ALERT_TYPE_NONE, nil);
    events = [CalendarEvent pullEventsFromSystemCalendar:user 
                                               startDate:baseDate
                                                 endDate:[NSDate dateWithTimeInterval:10000 sinceDate:baseDate] complete:^(NSArray *events) {}
                                                ];
    GLLog(@"events: %@", events);
    STAssertTrue([events count] == 0, nil);
}

- (void)testPush {
    User *user = [self createRandomUser:ds];
    [user.settings update:@"periodCycle" value:@30];
    [user.settings update:@"periodLength" value:@10];
    [user.settings update:@"pushToCalendar" value:@YES];
    [user.settings update:@"notificationFlags" value:@0xff];
    [user save];
    NSDictionary *request = [user createPushRequest];
    request = [request objectForKey:@"settings"];
    STAssertEqualObjects([request objectForKey:@"period_cycle"], @30, nil);
    STAssertEqualObjects([request objectForKey:@"period_length"], @10, nil);
    STAssertEqualObjects([request objectForKey:@"push_to_calendar"], @YES, nil);
    STAssertEqualObjects([request objectForKey:@"notification_flags"], @0xff, nil);
    STAssertTrue([request objectForKey:@"time_zone"] == nil, nil);
}

- (void)testSync {
    DataStore *ds1 = [DataStore storeWithName:@"ds1"];
    NSDictionary *fbInfo = [self randomFbInfo];
    NSString *fbId = [fbInfo objectForKey:@"id"];
    NSDate *date = [Utils dateOfYear:2013 month:2 day:20];
    NSDate *startTime1 = [NSDate dateWithTimeInterval:7200 sinceDate:date];
    NSDate *endTime1 = [NSDate dateWithTimeInterval:10800 sinceDate:date];
    NSDate *startTime2 = [NSDate dateWithTimeInterval:14400 sinceDate:date];
    NSDate *endTime2 = [NSDate dateWithTimeInterval:18000 sinceDate:date];
    [User createAccount:fbInfo dataStore:ds1 completionHandler:^(User *user, NSError *err) {
        [user.settings update:@"periodCycle" value:@15];
        UserDailyData *daily = [user dailyDataOfDate:date];
        [daily update:@"cervicalMucus" value:@10];
        CalendarEvent *evt1 = [CalendarEvent createCoupleEvent:@"Test Event1" startTime:startTime1 endTime:endTime1 alertType:EMMA_ALERT_TYPE_DEFAULT byUser:user];
        CalendarEvent *evt2 = [CalendarEvent createCoupleEvent:@"Test Event2" startTime:startTime2 endTime:endTime2 alertType:EMMA_ALERT_TYPE_NONE byUser:user];
        [evt2 deleteEvent];
        [user save];
        [user syncWithServer];
        [self subscribe:EVENT_USER_SYNC_COMPLETED obj:user handler:^(Event *evt) {
            [self unblock:1];
        }];
    }];
    [self block:1];
    DataStore *ds2 = [DataStore storeWithName:@"ds2"];
    [User fetchUserByFacebookID:fbId dataStore:ds2 completionHandler:^(User *user, NSError *err) {
        STAssertEqualObjects(user.email, [fbInfo objectForKey:@"email"], nil);
        [user pullFromServer:^(NSError *err) {
            STAssertTrue(user.settings.periodCycle == 15, nil);
            UserDailyData *daily = [user dailyDataOfDate:date];
            STAssertTrue(daily.cervicalMucus == 10, nil);
            NSArray *events = [user eventsOnDate:date];
            STAssertTrue([events count] == 1, nil);
            CalendarEvent *evt = [events lastObject];
            STAssertEqualObjects(evt.title, @"Test Event1", nil);
            STAssertEqualObjects(evt.startTime, startTime1, nil);
            STAssertEqualObjects(evt.endTime, endTime1, nil);
            STAssertTrue(evt.type == EMMA_CALENDAR_TYPE_COUPLE, nil);
            STAssertTrue(evt.alertType == EMMA_ALERT_TYPE_DEFAULT, nil);
            [self unblock:2];
        }];
    }];
    [self block:2];
}

- (void)testInvitePartner {
    DataStore *ds1 = [DataStore storeWithName:@"ds1"];
    NSDictionary *fbInfo1 = [self randomFbInfo];
    NSDictionary *fbInfo2 = [self randomFbInfo];
    [User createAccount:fbInfo1 dataStore:ds1 completionHandler:^(User *user, NSError *err) {
        [user invitePartnerOnFacebook:fbInfo2 completionHandler:^(User *user, NSError *err) {
            STAssertEqualObjects(user.partner.firstName, [fbInfo2 valueForKey:@"first_name"], nil);
            STAssertEqualObjects(user.partner.lastName, [fbInfo2 valueForKey:@"last_name"], nil);
            STAssertEqualObjects(user.partner.fbId, [fbInfo2 valueForKey:@"id"], nil);
            [user save];
            [self unblock:1];
        }];
    }];
    [self block:1];
    DataStore *ds2 = [DataStore storeWithName:@"ds2"];
    [User createAccount:fbInfo2 dataStore:ds2 completionHandler:^(User *another, NSError *err) {
        [another pullFromServer:^(NSError *err){
            STAssertEqualObjects(another.partner.firstName, [fbInfo1 valueForKey:@"first_name"], nil);
            STAssertEqualObjects(another.partner.lastName, [fbInfo1 valueForKey:@"last_name"], nil);
        [self unblock:2];
        }];
    }];
    [self block:2];
}

- (void)notificationMockup:(User *)user {
    int cond = arc4random_uniform(1 << 31); 
    [[Network sharedNetwork] post:@"users/notification_mockup" data:nil completionHandler:^(NSDictionary *data, NSError *err) {
        [self unblock:cond];
    }];
    [self block:cond];
}

- (void)testNotifications {
    DataStore *ds1 = [DataStore storeWithName:@"ds1"];
    User *u1 = [self createRandomUser:ds1];
    [self notificationMockup:u1];
    [self blockingPullFromServer:u1];
    STAssertTrue([u1.notifications count] == 1, nil);
    Notification *notif = [u1.notifications lastObject];
    STAssertTrue([notif.text rangeOfString:@"check your basal temperature"].location != NSNotFound, nil);
    STAssertTrue(notif.unread == YES, nil);
    [u1 clearUnreadNotifications];
    STAssertTrue(notif.unread == NO, nil);
    [notif updateUserAction:EMMA_USER_ACTION_ACCEPT];
    [self blockingPushToServer:u1];
    
    DataStore *ds2 = [DataStore storeWithName:@"ds2"];
    User *u2 = [self blockingFetchByFbId:u1.fbId dataStore:ds2];
    [self blockingPullFromServer:u2];
    STAssertTrue([u2.notifications count] == 1, nil);
    notif = [u2.notifications lastObject];
    STAssertTrue(notif.unread == NO, nil);
    STAssertTrue(notif.action == EMMA_USER_ACTION_ACCEPT, nil);
}

- (void)testEmptyAttrs {
    UserDailyData *daily = [UserDailyData newInstance:ds];
    [daily update:@"moods" intValue:0];
    STAssertTrue([daily.emptyAttrs containsObject:@"moods"] == NO, nil);
    [daily remove:@"moods"];
    STAssertTrue([daily.emptyAttrs containsObject:@"moods"] == YES, nil);
}

- (void)testApplyRules {
    DataStore *ds1 = [DataStore storeWithName:@"ds1"];
    NSDictionary *fbInfo = [self randomFbInfo];
    [User createAccount:fbInfo dataStore:ds1 completionHandler:^(User *user, NSError *err) {
        [user pullFromServer:^(NSError *err) {
            [user publish:EVENT_USER_SYNC_COMPLETED];
            PredictionRule *rule = [user predictionRule:@"TestInvoker"];
            GLLog(@"User prediction rule: %@", [rule getBody]);
            GLLog(@"User prediction rule: %@", [[user predictionRule:@"TestInvokee"] getBody]);
            Interpreter *interpreter = [[Interpreter alloc] init];
            interpreter.predictionOwner = user;
            id r = [interpreter exeDsl:[rule getBody] withArgs:[NSDictionary dictionaryWithObjectsAndKeys:@2, @"s", nil]];
            GLLog(@"User exe TestInvoker: %@", r);
            STAssertTrue([r isEqual:@30], nil);
        }];
        [self subscribe:EVENT_USER_SYNC_COMPLETED obj:user handler:^(Event *evt) {
            [self unblock:1];
        }];
    }];
    [self block:1];
}

- (void)testGetDailyData {
    DataStore *ds1 = [DataStore storeWithName:@"ds1"];
    NSDictionary *fbInfo = [self randomFbInfo];
    [User createAccount:fbInfo dataStore:ds1 completionHandler:^(User *user, NSError *err) {
        [user pullFromServer:^(NSError *err) {
            UserDailyData *daily = [user dailyDataOfDate:[Utils dateOfYear:2013 month:3 day:1]];
            [daily update:@"cervicalMucus" value:@10];
            UserDailyData *daily1 = [user dailyDataOfDate:[Utils dateOfYear:2013 month:2 day:20]];
            [daily1 update:@"cervicalMucus" value:@10];
            
            NSArray *dailyDataToNow = [UserDailyData getUserDailyDataTo:@"2013/02/25" ForUser:user];
            GLLog(@"temp test %@", dailyDataToNow);
            STAssertTrue([dailyDataToNow count] == 1, nil);
            STAssertTrue([((UserDailyData *)[dailyDataToNow objectAtIndex:0]).date isEqual:@"2013/02/20"], nil);
            NSArray *dailyDataFromNow = [UserDailyData getUserDailyDataFrom:@"2013/02/25" ForUser:user];
            GLLog(@"temp test %@", dailyDataFromNow);
            STAssertTrue([dailyDataFromNow count] == 1, nil);
            STAssertTrue([((UserDailyData *)[dailyDataFromNow objectAtIndex:0]).date isEqual:@"2013/03/01"], nil);
            
            UserDailyData *firstPb = [UserDailyData getEarliestPbForUser:user];
            GLLog(@"temp test %@", firstPb);
            STAssertTrue(firstPb.date == nil, nil);
            [daily1 update:@"period" value:@1];
            firstPb = [UserDailyData getEarliestPbForUser:user];
            GLLog(@"temp test %@", firstPb);
            STAssertTrue([firstPb.date isEqual:@"2013/02/20"], nil);
            
            
            [user publish:EVENT_USER_SYNC_COMPLETED];
        }];
        [self subscribe:EVENT_USER_SYNC_COMPLETED obj:user handler:^(Event *evt) {
            [self unblock:1];
        }];
    }];
    [self block:1];
}

- (void)testInitPredictionAndUpdateARules {
    DataStore *ds1 = [DataStore storeWithName:@"ds1"];
    NSDictionary *fbInfo = [self randomFbInfo];
    [User createAccount:fbInfo dataStore:ds1 completionHandler:^(User *user, NSError *err) {
        [user pullFromServer:^(NSError *err) {
            PredictionRule *rule = [user predictionRule:@"InitPredictRule"];
            Interpreter *interpreter = [[Interpreter alloc] init];
            interpreter.predictionOwner = user;
            NSMutableArray *a = [Utils emptyPrediction];
            NSMutableArray *p = [Utils emptyPrediction];
            NSMutableArray *t = [Utils emptyPrediction];
            NSString *pb0 = @"2013/01/01";
            NSNumber *cl0 = @20;
            NSNumber *pl0 = @5;
            [interpreter exeDsl:[rule getBody] withArgs:[NSDictionary dictionaryWithObjectsAndKeys:a, @"a", p, @"p", t, @"t", pb0, @"pb0", cl0, @"cl0", pl0, @"pl0", nil]];;
            GLLog(@"testInitPredictionRules a: %@", a);
            GLLog(@"testInitPredictionRules p: %@", p);
            GLLog(@"testInitPredictionRules t: %@", t);
            
            rule = [user predictionRule:@"PredictCycleRule"];
            [interpreter exeDsl:[rule getBody] withArgs:[NSDictionary dictionaryWithObjectsAndKeys:a, @"a", p, @"p", t, @"t", @0, @"n", nil]];
            GLLog(@"testPredictCycleRules a: %@", a);
            GLLog(@"testPredictCycleRules p: %@", p);
            GLLog(@"testPredictCycleRules t: %@", t);
            
            rule = [user predictionRule:@"UpdateARule"];
            [[a objectAtIndex:4] setObject:@"2013/03/25" forKey:@"pb"];
            id r = [interpreter exeDsl:[rule getBody] withArgs:@{@"idx":@0, @"a":a, @"t":t, @"daily_data":@[@{@"date":@"2013/02/11", @"period":@1, @"ovulation_test":[NSNull null], @"temperature":[NSNull null]}]}];
            GLLog(@"testUpdateARules %@", r);
            STAssertTrue([r intValue] == 1, nil);
            STAssertTrue([[[a objectAtIndex:2] objectForKey:@"pb"] isEqual:@"2013/02/11"], nil);
            r = [interpreter exeDsl:[rule getBody] withArgs:@{@"idx":@0, @"a":a, @"t":t, @"daily_data":@[@{@"date":@"2013/04/04", @"period":@1, @"ovulation_test":[NSNull null], @"temperature":[NSNull null]}]}];
            GLLog(@"testUpdateARules %@", r);
            STAssertTrue([r intValue] == 3, nil);
            STAssertTrue([[[a objectAtIndex:5] objectForKey:@"pb"] isEqual:@"2013/04/04"], nil);
            r = [interpreter exeDsl:[rule getBody] withArgs:@{@"idx":@0, @"a":a, @"t":t, @"daily_data":@[@{@"date":@"2013/01/22", @"period":@1, @"ovulation_test":[NSNull null], @"temperature":[NSNull null]}]}];
            GLLog(@"testUpdateARules %@", r);
            STAssertTrue([r intValue] == 0, nil);
            STAssertTrue([[[a objectAtIndex:1] objectForKey:@"pb"] isEqual:@"2013/01/22"], nil);
            r = [interpreter exeDsl:[rule getBody] withArgs:@{@"idx":@0, @"a":a, @"t":t, @"daily_data":@[@{@"date":@"2013/01/26", @"period":@0, @"ovulation_test":@1, @"temperature":[NSNull null]}]}];
            GLLog(@"testUpdateARules %@", r);
            STAssertTrue([r intValue] == 0, nil);
            STAssertTrue([[[a objectAtIndex:1] objectForKey:@"ov"] isEqual:@"2013/01/27"], nil);
            r = [interpreter exeDsl:[rule getBody] withArgs:@{@"idx":@0, @"a":a, @"t":t, @"daily_data":@[@{@"date":@"2012/01/26", @"period":@0, @"ovulation_test":@1, @"temperature":[NSNull null]}]}];
            GLLog(@"testUpdateARules %@", r);
            STAssertTrue([r intValue] == 9999, nil);
            
            rule = [user predictionRule:@"ApplyDailyData"];
            [interpreter exeDsl:[rule getBody] withArgs:@{
                @"a": a,
                @"p": p,
                @"t": t,
                @"daily_data": @[@{@"date": @"2013/02/11", @"period":@1}, @{@"date": @"2013/03/25", @"period":@1}, @{@"date": @"2013/05/23", @"period":@1}]
             }];
            GLLog(@"testApplyDailyData a: %@", a);
            GLLog(@"testApplyDailyData p: %@", p);
            GLLog(@"testApplyDailyData t: %@", t);

            
            [user publish:EVENT_USER_SYNC_COMPLETED];
        }];
        [self subscribe:EVENT_USER_SYNC_COMPLETED obj:user handler:^(Event *evt) {
            [self unblock:1];
        }];
    }];
    [self block:1];
}

- (void)testPrediction {
    DataStore *ds1 = [DataStore storeWithName:@"ds1"];
    NSDictionary *fbInfo = [self randomFbInfo];
    [User createAccount:fbInfo dataStore:ds1 completionHandler:^(User *user, NSError *err) {
        [user pullFromServer:^(NSError *err) {
            [user.settings update:@"periodCycle" value:@20];
            [user.settings update:@"periodLength" value:@4];
            [user subscribeChildrenUpdates];
            

            UserDailyData *daily1 = [user dailyDataOfDate:[Utils dateOfYear:2013 month:1 day:2]];
            GLLog(@"test prediction after onboarding %@", user.prediction);
            UserDailyData *daily2 = [user dailyDataOfDate:[Utils dateOfYear:2013 month:3 day:5]];
            [daily2 update:@"period" value:@1];
            [daily1 update:@"cervicalMucus" value:@10];
            UserDailyData *daily3 = [user dailyDataOfDate:[Utils dateOfYear:2013 month:4 day:17]];
            [daily3 update:@"period" value:@1];
            GLLog(@"test prediction %@", user.prediction);
            
            
            
//            STAssertTrue([[user getPredictionOfDate:[Utils dateOfYear:2013 month:1 day:18]] isEqual:PREDICTION_PERIOD_NONE], nil);
//            STAssertTrue([[user getPredictionOfDate:[Utils dateOfYear:2013 month:3 day:5]] isEqual:PREDICTION_PERIOD_BEGIN], nil);
//            STAssertTrue([[user getPredictionOfDate:[Utils dateOfYear:2013 month:3 day:7]] isEqual:PREDICTION_PERIOD_ONGOING], nil);
//            
//            STAssertTrue([[user getPredictionOfDate:[Utils dateOfYear:2013 month:4 day:21]] isEqual:PREDICTION_PERIOD_ENDED], nil);
//            STAssertTrue([[user getPredictionOfDate:[Utils dateOfYear:2013 month:6 day:29]] isEqual:PREDICTION_OVULATION], nil);
//            STAssertTrue([[user getPredictionOfDate:[Utils dateOfYear:2013 month:4 day:26]] isEqual:PREDICTION_PEAK], nil);
//            STAssertTrue([[user getPredictionOfDate:[Utils dateOfYear:2013 month:9 day:22]] isEqual:PREDICTION_FERTILE], nil);
//            STAssertTrue([[user getPredictionOfDate:[Utils dateOfYear:2013 month:3 day:17]] isEqual:PREDICTION_PERIOD_NONE], nil);
            
            [user publish:EVENT_USER_SYNC_COMPLETED];
        }];
        [self subscribe:EVENT_USER_SYNC_COMPLETED obj:user handler:^(Event *evt) {
            [self unblock:1];
        }];
    }];
    [self block:1];
    
}

- (void)testTempRiseRule {
    DataStore *ds1 = [DataStore storeWithName:@"ds1"];
    NSDictionary *fbInfo = [self randomFbInfo];
    [User createAccount:fbInfo dataStore:ds1 completionHandler:^(User *user, NSError *err) {
        [user pullFromServer:^(NSError *err) {
            PredictionRule *rule = [user predictionRule:@"TempRiseRule"];
            Interpreter *interpreter = [[Interpreter alloc] init];
            interpreter.predictionOwner = user;
            NSArray *dailyData =
                @[@{@"date":@"2013/01/01", @"temperature":@38},
                @{@"date":@"2013/01/02", @"temperature":@38},
                @{@"date":@"2013/01/03", @"temperature":@38},
                @{@"date":@"2013/01/04", @"temperature":@38},
                @{@"date":@"2013/01/05", @"temperature":@38},
                @{@"date":@"2013/01/06", @"temperature":@38},
                @{@"date":@"2013/01/07", @"temperature":@38},
                @{@"date":@"2013/01/09", @"temperature":@38},
                @{@"date":@"2013/01/10", @"temperature":@38}];
            id r = [interpreter exeDsl:[rule getBody] withArgs:@{@"idx":@8, @"daily_data":dailyData}];
            GLLog(@"User TempRise: %@", r);
            STAssertFalse([r boolValue], nil);
            
            dailyData =
            @[@{@"date":@"2013/01/02", @"temperature":@38},
              @{@"date":@"2013/01/03", @"temperature":@38},
              @{@"date":@"2013/01/04", @"temperature":@38},
              @{@"date":@"2013/01/05", @"temperature":@38.1f},
              @{@"date":@"2013/01/06", @"temperature":@38},
              @{@"date":@"2013/01/07", @"temperature":@38.1},
              @{@"date":@"2013/01/08", @"temperature":@38.2},
              @{@"date":@"2013/01/09", @"temperature":@38.2},
              @{@"date":@"2013/01/10", @"temperature":@38.2}];
            r = [interpreter exeDsl:[rule getBody] withArgs:@{@"idx":@8, @"daily_data":dailyData}];
            GLLog(@"User TempRise: %@", r);
            STAssertFalse([r boolValue], nil);

            dailyData =
            @[@{@"date":@"2013/01/02", @"temperature":@38},
              @{@"date":@"2013/01/03", @"temperature":@38},
              @{@"date":@"2013/01/04", @"temperature":@38},
              @{@"date":@"2013/01/05", @"temperature":@38},
              @{@"date":@"2013/01/06", @"temperature":@37.9},
              @{@"date":@"2013/01/07", @"temperature":@38.1},
              @{@"date":@"2013/01/08", @"temperature":@38.1},
              @{@"date":@"2013/01/09", @"temperature":@38.1},
              @{@"date":@"2013/01/10", @"temperature":@38.3}];
            r = [interpreter exeDsl:[rule getBody] withArgs:@{@"idx":@8, @"daily_data":dailyData}];
            GLLog(@"User TempRise: %@", r);
            STAssertTrue([r boolValue], nil);
            
            dailyData =
            @[@{@"date":@"2013/01/02", @"temperature":@38},
              @{@"date":@"2013/01/03", @"temperature":@38},
              @{@"date":@"2013/01/04", @"temperature":@38},
              @{@"date":@"2013/01/05", @"temperature":@38},
              @{@"date":@"2013/01/06", @"temperature":@38},
              @{@"date":@"2013/01/07", @"temperature":@38.1},
              @{@"date":@"2013/01/08", @"temperature":@38.1},
              @{@"date":@"2013/01/09", @"temperature":@38.1},
              @{@"date":@"2013/01/10", @"temperature":@38.1}];
            r = [interpreter exeDsl:[rule getBody] withArgs:@{@"idx":@8, @"daily_data":dailyData}];
            GLLog(@"User TempRise: %@", r);
            STAssertTrue([r boolValue], nil);
            
            [user publish:EVENT_USER_SYNC_COMPLETED];
        }];
        [self subscribe:EVENT_USER_SYNC_COMPLETED obj:user handler:^(Event *evt) {
            [self unblock:1];
        }];
    }];
    [self block:1];
}

@end
