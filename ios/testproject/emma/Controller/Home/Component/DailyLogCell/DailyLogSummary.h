//
//  DailyLogSummary.h
//  emma
//
//  Created by Eric Xu on 12/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserDailyData.h"
#import "UILinkLabel.h"

@interface DailyLogSummary : NSObject

+ (NSString *)plainSummaryForDate:(NSString *)date;

- (id)initWithDailyData:(UserDailyData *)dailyData;
- (void)setDailyData:(UserDailyData *)data;
- (UIView *)getSummaryView;
- (NSInteger)getSummaryShortHeight;
- (NSInteger)getSummaryFullHeight;
- (BOOL)hasMore;
- (void)refresh;
- (BOOL)isAllDataSensitive;
+ (void)clearPlainSummary;

@end

