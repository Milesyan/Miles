//
//  Logging.h
//  emma
//
//  Created by Jirong Wang on 4/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "LoggingData.h"
#import "LoggingDataV2.h"

@interface Logging : NSObject

@property (nonatomic, strong)NSNumber *userId;

// Two main interfaces
+ (void)log:(NSString *)eventName;
+ (void)log:(NSString *)eventName eventData:(NSDictionary *)eventData;
+ (void)syncLog:(NSString *)eventName eventData:(NSDictionary *)eventData;

// Below used by networkwithlog
+ (Logging *)getInstance;

@end
