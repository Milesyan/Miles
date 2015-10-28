//
//  User+HomePageDailyContent.m
//  emma
//
//  Created by ltebean on 15-3-13.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "User+HomePageDailyContent.h"
#import "DailyArticle.h"
#import <objc/runtime.h>
#import "DailyTodo.h"

@implementation User (HomePageDailyContent)
static char lastFetchTimeDictKey;

- (NSMutableDictionary *)lastFetchTimeDict
{
    return objc_getAssociatedObject(self, &lastFetchTimeDictKey);
}

- (void)setLastFetchTimeDict:(NSMutableDictionary *)lastFetchTimeDict
{
    objc_setAssociatedObject(self, &lastFetchTimeDictKey, lastFetchTimeDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fetchDailyContentOnDate:(NSDate *)date forceSendCall:(BOOL)forceSendCall forceRenegerate:(BOOL)forceRegenerate completionHandler:(void (^)(BOOL, NSDate *))completionHandler;
{
    if (!self.lastFetchTimeDict) {
        self.lastFetchTimeDict = [NSMutableDictionary dictionary];
    }
    // fetch data every 5 miniutes
    NSDate *fetchDate = [date copy];
    NSDate *now = [NSDate date];
    NSString *dateLabel = date2Label(fetchDate);
    
    NSDate *lastFetchTime = self.lastFetchTimeDict[dateLabel];
    
    if (!forceSendCall && lastFetchTime && ([now timeIntervalSinceDate:lastFetchTime] <= 5 * 60)) {
        return;
    }
    
    self.lastFetchTimeDict[dateLabel] = now;
    
    NSDictionary *request = [[User currentUser] postRequest:@{@"date": dateLabel, @"force_regenerate": @(forceRegenerate)}];
    
    [[Network sharedNetwork] post:@"users/daily_content" data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (err) {
            return completionHandler(NO, fetchDate);
        }
        // in case the user has logged out
        if (!self) {
            return completionHandler(NO, fetchDate);
        }
        [DailyArticle updateWithServerData:result[@"articles"] onDate:dateLabel forUser:self];
        [DailyTodo updateWithServerData:result[@"daily_checks"] onDate:dateLabel forUser:self];

        return completionHandler(YES, fetchDate);
    }];
}
@end
