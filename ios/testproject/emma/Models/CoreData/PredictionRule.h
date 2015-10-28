//
//  PredictionRules.h
//  emma
//
//  Created by Xin Zhao on 13-3-6.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"

@class User;

@interface PredictionRule : BaseModel

@property (nonatomic, retain) NSString * args;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) User * user;

+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user;
+ (id)tset:(NSString *)name forUser:(User *)user;
+ (id)getInstance:(NSString *)name forUser:(User *)user;
- (NSArray *)getBody;
- (NSArray *)getArgs;
+ (void)loadLocalRulesForUser:(User *)user;
@end
