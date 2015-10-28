//
//  NSObject+PubSub.m
//  emma
//
//  Created by Ryan Ye on 3/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "NSObject+PubSub.h"
#import <objc/runtime.h>

@implementation Event
- (id)initWithName:(NSString *)name obj:(id)obj data:(id)data {
    if (self = [super init]) {
        self.name = name;
        self.obj = obj;
        self.data = data;
    }
    return self;
}
@end

@implementation NSObject (PubSub)

static NSOperationQueue *_pubSubQueue = nil;
static char SUBSCRIPTIONS;
+ (void)setPubSubQueue:(NSOperationQueue *)queue {
    _pubSubQueue = queue;
}

- (void)publish:(NSString *)name {
    [self publish:name data:nil];
}

- (void)publish:(NSString *)name data:(id)data {
    NSDictionary *userInfo = nil;
    if (data != nil) {
        userInfo = @{@"data": data};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

- (id)subscribe:(NSString *)eventName handler:(GLEventHandler)handler {
    return [self subscribe:eventName obj:nil handler:handler];
}

- (id)subscribe:(NSString *)eventName obj:(id)obj handler:(GLEventHandler)handler {
    [self unsubscribe:eventName];
    id observer =  [[NSNotificationCenter defaultCenter] addObserverForName:eventName object:obj queue:_pubSubQueue usingBlock:^(NSNotification *note) {
        Event *event = [[Event alloc] initWithName:eventName obj:note.object data:[note.userInfo objectForKey:@"data"]];
        handler(event);
    }];
    NSMutableDictionary *subscriptions = (NSMutableDictionary *)objc_getAssociatedObject(self, &SUBSCRIPTIONS);
    if (!subscriptions) {
        subscriptions = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, &SUBSCRIPTIONS, subscriptions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSMutableSet *observers = [subscriptions objectForKey:eventName];
    if (!observers) {
        observers = [[NSMutableSet alloc] init];
        [subscriptions setObject:observers forKey:eventName];
    }
    [observers addObject:observer];
    return observer;
}

- (id)subscribe:(NSString *)eventName selector:(SEL)selector {
    return [self subscribe:eventName obj:nil selector:selector];
}

- (id)subscribeOnce:(NSString *)eventName selector:(SEL)selector {
    return [self subscribeOnce:eventName obj:nil selector:selector];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (id)subscribe:(NSString *)eventName obj:(id)obj selector:(SEL)selector {
    NSMethodSignature *sig = [self methodSignatureForSelector:selector];
    //  The hidden arguments self and _cmd (of type SEL) are at indices 0 and 1; method-specific arguments begin at index 2
    BOOL passEventObj = ([sig numberOfArguments] == 3);
    __weak NSObject *weakSelf = self;
    return [self subscribe:eventName obj:obj handler:^(Event *event) {
        if (passEventObj)
            [weakSelf performSelector:selector withObject:event];
        else
            [weakSelf performSelector:selector];
    }];
}

- (id)subscribeOnce:(NSString *)eventName obj:(id)obj selector:(SEL)selector {
    NSMethodSignature *sig = [self methodSignatureForSelector:selector];
    //  The hidden arguments self and _cmd (of type SEL) are at indices 0 and 1; method-specific arguments begin at index 2
    BOOL passEventObj = ([sig numberOfArguments] == 3);
    __weak NSObject *weakSelf = self;
    return [self subscribe:eventName obj:obj handler:^(Event *event) {
        [weakSelf unsubscribe:eventName];
        if (passEventObj)
            [weakSelf performSelector:selector withObject:event];
        else
            [weakSelf performSelector:selector];
    }];
}

#pragma clang diagnostic pop

- (id)subscribeOnce:(NSString *)eventName handler:(GLEventHandler)handler {
    __weak NSObject *weakSelf = self;
    return [self subscribe:eventName handler:^(Event *evt) {
         [weakSelf unsubscribe:eventName];
         handler(evt);
    }];
}

- (id)subscribeOnce:(NSString *)eventName obj:(id)obj handler:(GLEventHandler)handler {
    __weak NSObject *weakSelf = self;
    return [self subscribe:eventName obj:obj handler:^(Event *evt) {
         [weakSelf unsubscribe:eventName];
         handler(evt);
    }];
}

- (void)unsubscribe:(NSString *)eventName {
    NSMutableDictionary *subscriptions = (NSMutableDictionary *)objc_getAssociatedObject(self, &SUBSCRIPTIONS);
    if (!subscriptions)
        return;
    NSDictionary *observers = [subscriptions objectForKey:eventName];
    if (observers) {
        for (id observer in observers) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }
        [subscriptions removeObjectForKey:eventName];
    }
}

- (void)unsubscribeAll {
    NSMutableDictionary *subscriptions = (NSMutableDictionary *)objc_getAssociatedObject(self, &SUBSCRIPTIONS);
    if (!subscriptions)
        return;
    for (NSString *eventName in subscriptions) {
        NSDictionary *observers = [subscriptions objectForKey:eventName];
        for (id observer in observers) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }
    }
    [subscriptions removeAllObjects];
}

@end
