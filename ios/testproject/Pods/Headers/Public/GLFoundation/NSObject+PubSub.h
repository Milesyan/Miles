//
//  NSObject+PubSub.h
//  emma
//
//  Created by Ryan Ye on 3/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Event;
typedef void (^GLEventHandler)(Event *event);

@interface Event : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSObject *obj;
@property (nonatomic, retain) NSObject *data;
- (id)initWithName:(NSString *)name obj:(id)obj data:(id)data;
@end

@interface NSObject (PubSub)
+ (void)setPubSubQueue:(NSOperationQueue *)queue;
- (void)publish:(NSString *)name;
- (void)publish:(NSString *)name data:(id)data;
- (id)subscribe:(NSString *)eventName selector:(SEL)selector;
- (id)subscribe:(NSString *)eventName obj:(id)object selector:(SEL)selector;
- (id)subscribe:(NSString *)eventName handler:(GLEventHandler)handler;
- (id)subscribe:(NSString *)eventName obj:(id)obj handler:(GLEventHandler)handler;
- (id)subscribeOnce:(NSString *)eventName selector:(SEL)selector;
- (id)subscribeOnce:(NSString *)eventName obj:(id)object selector:(SEL)selector;
- (id)subscribeOnce:(NSString *)eventName handler:(GLEventHandler)handler;
- (id)subscribeOnce:(NSString *)eventName obj:(id)obj handler:(GLEventHandler)handler;
- (void)unsubscribe:(NSString *)eventName;
- (void)unsubscribeAll;

@end
