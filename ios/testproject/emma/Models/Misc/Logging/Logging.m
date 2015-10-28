//
//  Logging.m
//  emma
//
//  Created by Jirong Wang on 4/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "Logging.h"
#import "Network.h"
#import "User.h"
#import "EmmaApplication.h"
#import "Events.h"

@interface Logging()

@property (nonatomic, strong) NSMutableArray *loggingQueue;
@property (nonatomic, strong) NSMutableArray *sendingQueue;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) UIBackgroundTaskIdentifier taskId;
@end

@implementation Logging

static Logging * _instance = nil;

static dispatch_queue_t _loggingQueueThread = 0;
+ (dispatch_queue_t)loggingQueueThread {
    if (!_loggingQueueThread) {
        _loggingQueueThread = dispatch_queue_create("com.emma.loggingQueue", NULL);
    }
    return _loggingQueueThread;
}

+ (Logging *)getInstance {
    if (!_instance) {
        _instance = [[Logging alloc] init];
    }
    return _instance;
}

- (id)init {
    self = [super init];
    if (self) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(applicationWillTerminate:)
                                   name:UIApplicationWillTerminateNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(applicationWillResignActive:)
                                   name:UIApplicationWillResignActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidEnterBackground:)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(applicationWillEnterForeground:)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
        [self loadFromDisk];
        [self startFlushTimer];
    }
    return self;
}

+ (int64_t)now {
    return (int64_t)[[NSDate date] timeIntervalSince1970];
}

- (void)push:(NSDictionary *)logData {
    // ensure all add / remove are in one thread
    dispatch_async([Logging loggingQueueThread], ^{
        [self.loggingQueue addObject:logData];
    });
}

+ (void)log:(NSString *)eventName eventData:(NSDictionary *)eventData {
    if (!EMMA_DISABLE_LOG) {
        Logging *logging = [Logging getInstance];
        [logging push:[logging prepareData:eventName eventData:eventData]];
    }
}

+ (void)log:(NSString *)eventName {
    [Logging log:eventName eventData:nil];
}

- (NSDictionary *)prepareData:(NSString *)eventName eventData:(NSDictionary *)eventData {
    NSMutableDictionary * _data = [[NSMutableDictionary alloc] initWithDictionary:eventData];
    // event code
    [_data setObject:eventName forKey:@"event_name"];
    
    // if we have user id
    if (self.userId) {
        [_data setObject:self.userId forKey:@"user_id"];
    }
    
    // event_time
    [_data setObject:@([Logging now]) forKey:@"event_time"];
    
    // version
    [_data setObject:@([Utils appVersionNumber]) forKey:@"version"];
    
    // device id
    [_data setObject:[Utils UUID] forKey:@"device_id"];
    
    // locale
    [_data setObject:[Utils localeString] forKey:@"locale"];
    
    // model
    [_data setObject:[Utils modelString] forKey:@"model"];
    
    return _data;
}

// synchronize log, send the log data to server immediately
+ (void)syncLog:(NSString *)eventName eventData:(NSDictionary *)eventData {
    [[Logging getInstance] syncLog:eventName eventData:eventData];
}

- (void)syncLog:(NSString *)eventName eventData:(NSDictionary *)eventData {
    dispatch_async([Logging loggingQueueThread], ^{
        NSArray *logList = @[[self prepareData:eventName eventData:eventData]];
        NSError *err = nil;
        [self sendToServer:logList error:&err];
        if (err) {
            [self.loggingQueue addObjectsFromArray:logList];
        }
    });
}

- (void)sendToServer:(NSArray *)logList error:(NSError **)error {
    GLLog(@"sendToServer: %@", logList);
    NSDictionary *data = @{@"log_list": logList};
    [[Network sharedNetwork] syncPost:@"users/sync_log" data:data requireLogin:NO timeout:NETWORK_TIMEOUT_INTERVAL error:error];
}

#pragma mark - Timer
- (void)startFlushTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:LOGGING_FLUSH_INTERVAL target:self selector:@selector(flush) userInfo:nil repeats:YES];
}

- (void)stopFlushTimer {
    if (self.timer) {
        [self.timer invalidate];
    }
    self.timer = nil;
}

- (void)flush {
    dispatch_async([Logging loggingQueueThread], ^{
        [self.sendingQueue addObjectsFromArray:self.loggingQueue];
        [self.loggingQueue removeAllObjects];
        if (self.sendingQueue.count == 0)
            return;
        NSError *err = nil;
        [self sendToServer:self.sendingQueue error:&err];
        // If events in sendingQueue has been successfully sent to server, clear sendingQueue.
        // Otherwise, keep them so that they could get pushed to server later.
        if (!err) {
            [self.sendingQueue removeAllObjects];
        }
    });
}

#pragma mark - Persistence
- (void)saveToDisk {
    // move all items in sending queue back to logging queue
    GLLog(@"Store loggingQueue to disk:%@", self.loggingQueue);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.loggingQueue forKey:@"Logging:logging_queue"];
    [defaults setObject:self.sendingQueue forKey:@"Logging:sending_queue"];
    [defaults synchronize];
}

- (void)loadFromDisk {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.loggingQueue = [(NSArray *)[defaults objectForKey:@"Logging:logging_queue"] mutableCopy];
    if (!self.loggingQueue) {
        self.loggingQueue = [[NSMutableArray alloc] init];
    }
    GLLog(@"Load loggingQueue:%@", self.loggingQueue);

    self.sendingQueue = [(NSArray *)[defaults objectForKey:@"Logging:sending_queue"] mutableCopy];
    if (!self.sendingQueue) {
        self.sendingQueue = [[NSMutableArray alloc] init];
    }
    GLLog(@"Load sendingQueue:%@", self.sendingQueue);
}

#pragma mark - UIApplication Notification
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self startFlushTimer];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    [self stopFlushTimer];
}

- (void)applicationDidEnterBackground:(NSNotificationCenter *)notification {
    self.taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        GLLog(@"Background task expired");
        [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
        self.taskId = UIBackgroundTaskInvalid;
    }];
    
    // When application enters background, push all pending events to server.
    // If failed, save them to disk so that they could be restored on next launch
    dispatch_async([Logging loggingQueueThread], ^{
        [self.sendingQueue addObjectsFromArray:self.loggingQueue];
        [self.loggingQueue removeAllObjects];
        if (self.sendingQueue.count == 0)
            return;
        NSError *err = nil;
        [self sendToServer:self.sendingQueue error:&err];
        GLLog(@"SendToServer when entering background: %@", err);
        if (!err) {
            [self.sendingQueue removeAllObjects];
        } else {
            [self saveToDisk];
        }
        if (self.taskId != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
            self.taskId = UIBackgroundTaskInvalid;
        }
    });
}

- (void)applicationWillEnterForeground:(NSNotificationCenter *)notification {
    if (self.taskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
        self.taskId = UIBackgroundTaskInvalid;
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    dispatch_async([Logging loggingQueueThread], ^{
        [self saveToDisk];
    });
}

@end
