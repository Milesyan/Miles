//
//  pubSubTest.m
//  emma
//
//  Created by Ryan Ye on 3/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <libextobjc/EXTScope.h>
#import "pubSubTest.h"
#import "NSObject+PubSub.h"

@interface TestObject : NSObject
- (void)eventHandler:(Event *)evt;
@end

@implementation TestObject
- (void)eventHandler:(Event *)evt {
    pubSubTest *testObject = (pubSubTest *)evt.data;
    [testObject unblock:1];
}
@end

@interface pubSubTest() {
    NSConditionLock *condLock;
    NSTimeInterval timeout;
    NSObject *obj1;
    NSObject *obj2;
}
@end

@implementation pubSubTest
- (void)setUp {
    [super setUp];
    condLock = [NSConditionLock new];
    timeout = 0.5;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSObject setPubSubQueue:queue];
    obj1 = [[NSObject alloc] init];
    obj2 = [[NSObject alloc] init];
}

- (void)block:(NSInteger)condition {
    BOOL result = [condLock lockWhenCondition:condition beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
    STAssertTrue(result, @"Async operation timed out.");
}

- (void)shouldBlockForever:(NSInteger)condition {
    BOOL result = [condLock lockWhenCondition:condition beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
    STAssertFalse(result, @"shouldn't be unblocked");
}

- (void)unblock:(NSInteger)condition {
    [condLock unlockWithCondition:condition];
}

- (void)testPubSub {
    @weakify(self)
    // subscribe with event only
    [obj1 subscribe:@"event1" handler:^(Event *evt) {
        @strongify(self)
        [self unblock:1];
    }];
    [obj2 publish:@"event1" data:@1];
    [self block:1];

    [obj1 unsubscribe:@"event1"];
    [obj2 publish:@"event1"];
    [self shouldBlockForever:1];

    // subscribe with event and obj
    [obj1 subscribe:@"event1" obj:obj2 handler:^(Event *evt) {
        @strongify(self)
        [self unblock:1];
    }];
    [obj2 publish:@"event1"];
    [self block:1];

    [obj1 publish:@"event1"];
    [self shouldBlockForever:1];

    [obj2 publish:@"event2"];
    [self shouldBlockForever:1];

    TestObject *obj3 = [[TestObject alloc] init];
    [obj3 subscribe:@"event1" obj:obj1 selector:@selector(eventHandler:)];
    [obj1 publish:@"event1" data:self];
    [self block:1];
}

@end
