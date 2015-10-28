//
//  WatchDataController.h
//  emma
//
//  Created by Peng Gu on 5/9/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataController.h"

@interface WatchDataController : NSObject

+ (instancetype)sharedInstance;

- (NSDictionary *)passWatchData;
- (void)handleWatchRequest:(NSDictionary *)request withReply:(void (^)(NSDictionary *))reply;

@end
