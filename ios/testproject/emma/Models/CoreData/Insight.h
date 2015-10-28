//
//  Insight.h
//  emma
//
//  Created by Jirong Wang on 8/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"

#define EVENT_INSIGHT_UPDATED @"insight_updated"
#define EVENT_INSIGHT_WEB_CLICKED @"insight_web_clicked"

@class User;

@interface Insight : BaseModel

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * date;
@property (nonatomic) BOOL unread;
@property (nonatomic) int64_t type;
@property (nonatomic, retain) NSString * source;
@property (nonatomic) NSDate * expire;
@property (nonatomic) NSDate * timeCreated;
@property (nonatomic) int16_t priority;
@property (nonatomic) int32_t likeCount;
@property (nonatomic) int32_t shareCount;
@property (nonatomic) BOOL liked;
@property (nonatomic, retain) NSString *pageUrl;
@property (nonatomic, retain) User *user;

+ (NSArray *)sortedInsightsForCurrentUserWithDate:(NSString *)date;
+ (NSArray *)sortedInsightsForGenius:(User *)user;
+ (void)upsertInsightList:(NSArray *)insightList forUser:(User *)user;
+ (void)upsertTestInsightListForUser:(User *)user;
+ (NSArray *)createPushRequestForUser:(User *)user;
- (NSString *)insightPageUrl;
// + (void)removeReadInsights:(User *)user;
+ (void)setInsightsRead:(NSDate *)date;

@end
