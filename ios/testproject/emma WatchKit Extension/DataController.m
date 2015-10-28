//
//  DataController.m
//  emma
//
//  Created by Peng Gu on 5/11/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DataController.h"
#import "MMWormhole.h"
#import <WatchKit/WatchKit.h>


@interface DataController ()

@property (nonatomic, strong) MMWormhole *wormhole;
@property (nonatomic, strong, readwrite) NSDictionary *todayData;
@property (nonatomic, strong, readwrite) NSArray *predictionData;
@property (nonatomic, strong, readwrite) NSDictionary *glanceData;
@property (atomic, assign) BOOL isSendingRequest;

@end


@implementation DataController


+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static DataController *dc;
    dispatch_once(&onceToken, ^{
        dc = [[DataController alloc] init];
    });
    return dc;
}


- (NSDictionary *)todayData
{
    if (!_todayData) {
        NSDictionary *message = [self.wormhole messageWithIdentifier:kWormholeWatchData];
        _todayData = message[kTodayData];
    }
    return _todayData;
}


- (NSArray *)predictionData
{
    if (!_predictionData) {
        NSDictionary *message = [self.wormhole messageWithIdentifier:kWormholeWatchData];
        _predictionData = message[kPredictionData];
    }
    return _predictionData;
}


- (NSDictionary *)glanceData
{
    if (!_glanceData) {
        NSDictionary *message = [self.wormhole messageWithIdentifier:kWormholeWatchData];
        _glanceData = message[kGlanceData];
    }
    return _glanceData;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString* appGroups = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"AppGroups"];
        _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:appGroups
                                                         optionalDirectory:kWormholeDirectory];
        
        [_wormhole listenForMessageWithIdentifier:kWormholeWatchData
                                         listener:^(id messageObject)
        {
            NSLog(@"Received data from wormhole.");
            
            if ([messageObject[kNoUserAvailable] integerValue] == YES) {
                NSLog(@"User not available");
                self.noUserAvailable = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWatchDataUpdated
                                                                    object:self];
                return;
            }

            self.noUserAvailable = NO;
            self.todayData = messageObject[kTodayData];
            self.predictionData = messageObject[kPredictionData];
            self.glanceData = messageObject[kGlanceData];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWatchDataUpdated
                                                                object:self];
         }];
    }
    return self;
}


- (void)sendRequestToParentApp:(RequestType)requestType reply:(ReplyCallback)reply
{
    if (self.isSendingRequest) {
        return;
    }
    
    self.isSendingRequest = YES;
    [WKInterfaceController openParentApplication:@{kRequestType: @(requestType)}
                                           reply:^(NSDictionary *replyInfo, NSError *error)
    {
        NSLog(@"Got reply for request %ld from parent app.", requestType);
        self.isSendingRequest = NO;
        
        if (!replyInfo || error) {
            return;
        }
        
        if ([replyInfo[kNoUserAvailable] boolValue]) {
            self.noUserAvailable = YES;
            reply(replyInfo, error);
            return;
        }

        self.noUserAvailable = NO;
        self.todayData = replyInfo[kTodayData];
        self.predictionData = replyInfo[kPredictionData];
        self.glanceData = replyInfo[kGlanceData];
        
        reply(replyInfo, error);
    }];
}




@end




