//
//  JsInterpreter.h
//  emma
//
//  Created by Xin Zhao on 13-6-30.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JsInterpreter : NSObject

+ (void)setPredictionJsNeedsInterpret;
+ (void)setActivityRuleJsNeedsInterpret;
+ (void)setFertileScoreJsNeedsInterpret;
+ (void)setHealthRuleJsNeedsInterpret;

+ (NSString *)predictWith:(NSString *)pb0 cycleLength:(NSInteger)cl0
        periodLength:(NSInteger)pl0 dailyData:(NSArray *)dailyData
        withApt:(NSDictionary *)apt around:(NSString *)dateLabel
        afterMigration:(BOOL)afterMigration userInfo:(NSDictionary *)userInfo;

//+ (NSString *)predictWith:(NSString *)pb0 cycleLength:(NSInteger)cl0 periodLength:(NSInteger)pl0;

+ (NSDictionary *)calculateActivityScoreFrom:(NSString *)start to:(NSString *)end withPrediction:(NSArray *)p withDailyData:(NSArray *)dailyData withDailyTodos:(NSArray *)dailyTodos;

+ (NSArray *)calculateFertileScoreWithPrediction:(NSArray *)prediction momAge:(NSInteger)momAge hasPartner:(BOOL)hasPartner partnerAge:(NSInteger)partnerAge;
+ (float)calculateFertileScoreWithBase:(float)score  momAge:(NSInteger)momAge hasPartner:(BOOL)hasPartner partnerAge:(NSInteger)partnerAge;

+ (NSArray *)calculateBMRWithDailyData:(NSArray *)dailyData age:(NSInteger)age weight:(float)weight height:(NSInteger)height defaultActivityLevel:(NSInteger)level from:(NSDate *)sinceDate to:(NSDate *)endDate;
@end
