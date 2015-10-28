//
//  emmaLogicTests.m
//  emmaLogicTests
//
//  Created by Ryan Ye on 2/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "dataStoreTests.h"
#import "User.h"
#import "Config.h"
#import "Utils.h"

@implementation dataStoreTests
/*

- (void)setUp {
    [super setUp];
    // prepare some user data in database
    ds = [DataStore sharedStore];
    User *user = [User newInstance];
    user.firstName = @"Ryan";
    user.lastName = @"Ye";
    user.idToken = @"token01";
    user.lastModified = [NSDate dateWithTimeIntervalSinceNow:-100.0];
    [user save];
    [self mockPushToServer];
}

- (void)tearDown {
    [super tearDown];
    [ds clearAll];
}

- (void)mockPushToServer {
    [ds processPushResponse:@{@"rc" : @0}];
}

- (void)testNewObject {
    NSDate *startTime = [NSDate date];
    User *user = [User newInstance];
    user.firstName = @"Test";
    [user save];
    STAssertTrue(ds.hasLocalChanges, nil);
    STAssertTrue([ds.localNewObjects anyObject] == user, nil);
    STAssertTrue([user.lastModified timeIntervalSinceDate:startTime] >= 0, nil);
    [self mockPushToServer];
    STAssertTrue(ds.hasLocalChanges == NO, nil);
}

- (void)testModifyObject {
    User *user = [User objectWithToken:@"token01"];
    user.firstName = @"Mike";
    [user save];
    STAssertTrue([ds.localModifiedObjects anyObject] == user, nil);
    STAssertTrue([user.changedAttributes count] == 1, @"changedAttributes count: expect 1, get %d", [user.changedAttributes count]);
    STAssertTrue([user.changedAttributes containsObject:@"firstName"], @"changedAttributes check failed: %@", user.changedAttributes);
    NSDate *prevModifiedTime = [user.lastModified copy];
    user.lastName = @"Huang";
    [user save];
    STAssertTrue([user.changedAttributes count] == 2, @"changedAttributes count: expect 2, get %d", [user.changedAttributes count]);
    STAssertTrue([user.changedAttributes containsObject:@"lastName"], @"changedAttributes check failed: %@", user.changedAttributes);
    STAssertTrue([user.lastModified timeIntervalSinceDate:prevModifiedTime] > 0, nil);
}

- (void)testDeleteObject {
    User *user = [User objectWithToken:@"token01"];
    [User deleteInstance:user];
    [user save];
    STAssertTrue([ds.localDeletedObjects anyObject] == user, nil);
    user =[User objectWithToken:@"token01"];
    STAssertTrue(user == nil, nil);
}

- (void)testPersistentLocalChanges {
    User *u1 = [User objectWithToken:@"token01"];
    u1.firstName = @"User1";
    User *u2 = [User newInstance];
    u2.firstName = @"User2";
    [u1 save];
    
    STAssertTrue([[[ds.localModifiedObjects anyObject] valueForKey:@"firstName"] isEqual:@"User1"], nil);
    STAssertTrue([[[ds.localNewObjects anyObject] valueForKey:@"firstName"] isEqual:@"User2"], nil);
    
    [User deleteInstance:[User objectWithToken:@"token01"]];
    [u2 save];
    
    STAssertTrue([ds.localModifiedObjects count] == 0, nil);
    STAssertTrue([[[ds.localDeletedObjects anyObject] valueForKey:@"idToken"] isEqual:@"token01"], nil);
}

- (void)testPushRequest {
    User *u1 = [User objectWithToken:@"token01"];
    u1.firstName = @"User1";
    User *u2 = [User newInstance];
    u2.firstName = @"User2";
    [u1 save];
    // test modify and new request
    NSDictionary *request = [ds createPushRequest];
    NSArray *modifiedObjs = [request objectForKey:@"modified"];
    STAssertTrue([modifiedObjs count] == 1, nil);
    NSDictionary *obj = [modifiedObjs lastObject];
    STAssertEqualObjects([obj valueForKey:@"first_name"], @"User1", nil);
    STAssertEqualObjects([obj valueForKey:@"class"], @"User", nil);
    STAssertEqualObjects([obj valueForKey:@"id_token"], @"token01", nil);
    STAssertEqualObjects([obj valueForKey:@"time_modified"], [Utils dateToTimestamp:u1.lastModified], nil);
    
    NSArray *newObjs = [request objectForKey:@"new"];
    STAssertTrue([newObjs count] == 1, nil);
    obj = [newObjs lastObject];
    STAssertEqualObjects([obj valueForKey:@"first_name"], @"User2", nil);
    STAssertEqualObjects([obj valueForKey:@"class"], @"User", nil);
    STAssertEqualObjects([obj valueForKey:@"client_id"], u2.clientID, nil);
    STAssertEqualObjects([obj valueForKey:@"time_modified"], [Utils dateToTimestamp:u2.lastModified], nil);
    STAssertTrue([modifiedObjs count] == 1, nil);
    [self mockPushToServer];
    
    // test delete request
    [User deleteInstance:u1];
    [u1 save];
    request = [ds createPushRequest];
    NSArray *deletedObjs = [request objectForKey:@"deleted"];
    STAssertTrue([deletedObjs count] == 1, nil);
    obj = [deletedObjs lastObject];
    STAssertEqualObjects([obj valueForKey:@"id_token"], @"token01", nil);
    STAssertEqualObjects([obj valueForKey:@"class"], @"User", nil);
}

- (void)testPushResponse {
    User *user = [User newInstance];
    [user save];
    [ds processPushResponse: @{@"rc" : @0, @"id_tokens" : @{user.clientID : @"token02"}}];
    STAssertEqualObjects(user.idToken, @"token02", nil);
}

- (void)testPullNewObject {
    NSDate *date = [NSDate date];
    NSNumber *dateTimestamp = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
    [ds processPullResponse:@{
         @"rc": @0,
         @"new" : @[
         @{
            @"id_token" : @"token02",
            @"first_name" : @"User1",
            @"time_created" : dateTimestamp,
            @"class" : @"User"
         }]
     }
     ];
    User *user = [User objectWithToken:@"token02"];
    STAssertEqualObjects(user.firstName, @"User1", nil);
    STAssertEqualDate(user.lastModified, date, nil);
    STAssertTrue(user.changedAttributes == nil, nil);
    STAssertTrue(user.objState == EMMA_OBJ_STATE_CLEAN, nil);
    // objects pulled from server shouldn't be in localNewObjects
    STAssertTrue([ds.localNewObjects count] == 0, nil);
}

- (void)testPullDeleteObject {
    NSDate *date = [NSDate date];
    NSNumber *dateTimestamp = [NSNumber numberWithDouble:[date timeIntervalSince1970] - 200.0];
    [ds processPullResponse:@{
         @"rc": @0,
         @"deleted" : @[
         @{
            @"id_token" : @"token01",
            @"time_removed" : dateTimestamp,
            @"class" : @"User"
         }]
     }
     ];
    STAssertTrue([User objectWithToken:@"token01"] != nil, nil);
    dateTimestamp = [NSNumber numberWithDouble:[dateTimestamp doubleValue] + 200.0];
    [ds processPullResponse:@{
         @"rc": @0,
         @"deleted" : @[
         @{
            @"id_token" : @"token01",
            @"class" : @"User",
            @"time_removed" : dateTimestamp
         }]
     }
     ];
    STAssertTrue([User objectWithToken:@"token01"] == nil, nil);
}

- (void)testPullModifyObject {
    User *user = [User objectWithToken:@"token01"];
    user.firstName = @"Local";
    NSDate *localLastModified = [user.lastModified copy];
    [user save];
    // remote object is older than local object
    NSDate *date = [NSDate date];
    NSNumber *dateTimestamp = [NSNumber numberWithDouble:[date timeIntervalSince1970] - 200.0];
    [ds processPullResponse:@{
         @"rc": @0,
         @"modified" : @[
         @{
            @"id_token" : @"token01",
            @"class" : @"User",
            @"first_name" : @"Remote",
            @"last_name" : @"Wang",
            @"time_modified" : dateTimestamp
         }]
     }
     ];
    STAssertEqualObjects(user.firstName, @"Local", nil);
    STAssertEqualObjects(user.lastName, @"Wang", nil);
    STAssertEqualDate(user.lastModified, localLastModified, nil);
    STAssertTrue([user.changedAttributes count] == 1, nil);
    
    // remote object is newer than local object
    dateTimestamp = [NSNumber numberWithDouble:[dateTimestamp doubleValue] + 300.0];
    [ds processPullResponse:@{
         @"rc": @0,
         @"modified" : @[
         @{
            @"id_token" : @"token01",
            @"class" : @"User",
            @"first_name" : @"Remote",
            @"time_modified" : dateTimestamp
         }]
     }
     ];
    STAssertEqualObjects(user.firstName, @"Remote", nil);
    STAssertEqualObjects(user.lastName, @"Wang", nil);
    STAssertEqualDate(user.lastModified, [NSDate dateWithTimeIntervalSince1970:[dateTimestamp doubleValue]], nil);
    STAssertTrue(user.objState == EMMA_OBJ_STATE_CLEAN, nil);
}
*/

@end
