//
//  Predictor.h
//  emma
//
//  Created by Xin Zhao on 13-3-7.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Interpreter : NSObject

+ (void)setPredictionJsNeedsInterpret;
+ (void)setActivityRuleJsNeedsInterpret;
+ (void)setFertileScoreJsNeedsInterpret;
+ (NSString *)predictWith:(NSString *)pb0 cycleLength:(int)cl0 periodLength:(int)pl0 dailyData:(NSArray *)dailyData withApt:(NSDictionary *)apt around:(NSString *)dateLabel afterMigration:(BOOL)afterMigration;
+ (NSString *)predictWith:(NSString *)pb0 cycleLength:(int)cl0 periodLength:(int)pl0;
+ (NSDictionary *)calculateActivityScoreFrom:(NSString *)start to:(NSString *)end withPrediction:(NSArray *)p withDailyData:(NSArray *)dailyData withDailyTodos:(NSArray *)dailyTodos;
+ (NSArray *)calculateFertileScoreWithPrediction:(NSArray *)prediction momAge:(int)momAge hasPartner:(BOOL)hasPartner partnerAge:(int)partnerAge;
+ (float)calculateFertileScoreWithBase:(float)score  momAge:(int)momAge hasPartner:(BOOL)hasPartner partnerAge:(int)partnerAge;
@end
