//
//  networkTest.m
//  emma
//
//  Created by Ryan Ye on 2/7/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "networkTest.h"
#import "Config.h"
#import "Utils.h"

@interface networkTest() {
    Network *network;
    NSConditionLock *condLock;
    NSTimeInterval defaultTimeout;
}
- (void)block:(NSInteger)condition;
- (void)block:(NSInteger)condition timeout:(NSTimeInterval)timeout;
- (void)unblock:(NSInteger)condition;
@end

@implementation networkTest
- (void)setUp {
    [super setUp];
    network = [Network sharedNetwork];
    condLock = [NSConditionLock new];
    defaultTimeout = 0.5f;
}

- (void)block:(NSInteger)condition {
  [self block:condition timeout:defaultTimeout];
}

- (void)block:(NSInteger)condition timeout:(NSTimeInterval)timeout {
    BOOL result = [condLock lockWhenCondition:condition beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
    STAssertTrue(result, @"Async operation timed out.");
}

- (void)unblock:(NSInteger)condition {
    [condLock unlockWithCondition:condition];
}

- (void)testPostJSON {
    [network post:@"http://localhost:8080/api/post-test" data:@{@"msg" : @"hello"} completionHandler:^(NSDictionary *data, NSError *err) {
        STAssertEqualObjects([data valueForKey:@"rc"], @0, nil);
        STAssertEqualObjects([data valueForKey:@"echo"], @"hello", nil);
        [self unblock:1];
    }];
    [self block:1];
}

- (void)testGetJSON {
    [network get:[Utils makeUrl:@"http://localhost:8080/api/get-test" query:@{@"msg" : @"hello", @"repeat": @2}] completionHandler:^(NSDictionary *data, NSError *err) {
        STAssertEqualObjects([data valueForKey:@"rc"], @0, nil);
        STAssertEqualObjects([data valueForKey:@"msg"], @"hellohello", nil);
        [self unblock:1];
    }];
    [self block:1];
}

- (void)testGetJSONWithoutQuery {
    [network get:@"http://localhost:8080/api/get-test" completionHandler:^(NSDictionary *data, NSError *err) {
        STAssertEqualObjects([data valueForKey:@"rc"], @0, nil);
        STAssertEqualObjects([data valueForKey:@"msg"], @"hello world", nil);
        [self unblock:1];
    }];
    [self block:1];
}

- (void)testServerError {
    [network get:@"http://localhost:8080/api/server-error" completionHandler:^(NSDictionary *data, NSError *err) {
        STAssertTrue(err.code == ERROR_CODE_SERVER_ERROR, nil);
        STAssertEqualObjects(err.domain, ERROR_DOMAIN_NETWORK, nil);
        [self unblock:1];
    }];
    [self block:1];
}
@end
