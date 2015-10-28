//
//  Predictor.m
//  emma
//
//  Created by Xin Zhao on 13-3-7.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "Interpreter.h"
#import "PredictionRule.h"
#import "SyncableAttribute.h"
#import "User.h"

/*
 * NOTE   
 *   The json function does not support Recursion, which means, if you can NOT pass a 
 *   variable to the JSON.parse with double JSON.stringify.
 *   Currently, dailydata[@'notes'], dailytodo has these problem. Fortunately, dailytodo 
 *   is a JSON.stringify string with list of numbers, which does not have the problem.
 *   But, dailydata[@'notes'] has the problem, so we should remove "notes" before passing
 *   to the js worker.
 * -jirong@
 */

@implementation Interpreter

static UIWebView* webview = nil;
static BOOL predictionJsInterpreted = NO;
static BOOL activityRuleJsInterpreted = NO;
static BOOL fertileScoreJsInterpreted = NO;

+ (UIWebView *)jsWebView {
    if (!webview){
        webview = [[UIWebView alloc] init];
        predictionJsInterpreted = NO;
        activityRuleJsInterpreted = NO;
        fertileScoreJsInterpreted = NO;
    }
    return webview;
}

+ (void)setPredictionJsNeedsInterpret{
    predictionJsInterpreted = NO;
}

+ (void)setActivityRuleJsNeedsInterpret{
    activityRuleJsInterpreted = NO;
}

+ (void)setFertileScoreJsNeedsInterpret{
    fertileScoreJsInterpreted = NO;
}

+ (void)interpretPredictionJsFunction {
    SyncableAttribute *predictRule = (SyncableAttribute *)[SyncableAttribute tsetWithName:ATTRIBUTE_PREDICT_RULES];
    [[self jsWebView] stringByEvaluatingJavaScriptFromString:predictRule.stringifiedAttribute];
    predictionJsInterpreted = YES;
}

+ (void)interpretActivityRuleJsFunction {
    SyncableAttribute *activityRule = (SyncableAttribute *)[SyncableAttribute tsetWithName:ATTRIBUTE_ACTIVITY_RULES];
    [[self jsWebView] stringByEvaluatingJavaScriptFromString:activityRule.stringifiedAttribute];
    activityRuleJsInterpreted = YES;
}

+ (void)interpretFertileScoreJsFunction {
    SyncableAttribute *fertileScore = (SyncableAttribute *)[SyncableAttribute tsetWithName:ATTRIBUTE_FERTILE_SCORE];
    [[self jsWebView] stringByEvaluatingJavaScriptFromString:fertileScore.stringifiedAttribute];
    fertileScoreJsInterpreted = YES;
}

+ (NSString *)predictWith:(NSString *)pb0 cycleLength:(int)cl0 periodLength:(int)pl0 dailyData:(NSArray *)dailyData withApt:(NSDictionary *)apt around:(NSString *)dateLabel afterMigration:(BOOL)afterMigration{
    if (!predictionJsInterpreted) {
        [self interpretPredictionJsFunction];
    }
    // remove "notes" from dailyData
    NSMutableArray * modifiedDailyData = [[NSMutableArray alloc] init];
    for (NSDictionary * dailyDict in dailyData) {
        NSMutableDictionary * tempDict = [NSMutableDictionary dictionaryWithDictionary:dailyDict];
        [tempDict removeObjectForKey:@"notes"];
        [tempDict removeObjectForKey:@"meds"];
        [modifiedDailyData addObject:tempDict];
    }
    NSString *stringifiedDailyData = [Utils jsonStringify:modifiedDailyData];
//    NSString *stringifiedA = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[apt objectForKey:@"a"] options:0 error:nil] encoding:NSUTF8StringEncoding];
//    NSString *stringifiedP = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[apt objectForKey:@"p"] options:0 error:nil] encoding:NSUTF8StringEncoding];
//    NSString *stringifiedT = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[apt objectForKey:@"t"] options:0 error:nil] encoding:NSUTF8StringEncoding];

    NSString *jsToEval = nil;
    if (afterMigration) {
        jsToEval = [NSString stringWithFormat:@"\
            var pb0 = '%@';\
            var cl0 = %d;\
            var pl0 = %d;\
            var dailyData = JSON.parse('%@');\
            var a = emptyCycles(13);\
            var p = emptyCycles(13);\
            var t = emptyCycles(13);\
            initPredict(a, p, t, pb0, cl0, pl0);\
            predictCycle(a, p, t, 0, 13);\
            applyDailyDataAfterMigration(a, p, t, dailyData, 13, 0);\
            JSON.stringify({a:a, p:p, t:t});",
            pb0,
            cl0,
            pl0,
            stringifiedDailyData];
    }
    else {
        jsToEval = [NSString stringWithFormat:@"\
            var pb0 = '%@';\
            var cl0 = %d;\
            var pl0 = %d;\
            var dailyData = JSON.parse('%@');\
            var a = emptyCycles(13);\
            var p = emptyCycles(13);\
            var t = emptyCycles(13);\
            initPredict(a, p, t, pb0, cl0, pl0);\
            predictCycle(a, p, t, 0, 13);\
            applyDailyData(a, p, t, dailyData, 13, 0);\
            JSON.stringify({a:a, p:p, t:t});",
            pb0,
            cl0,
            pl0,
            stringifiedDailyData];
    }

    return [webview stringByEvaluatingJavaScriptFromString:jsToEval];
}

+ (NSString *)predictWith:(NSString *)pb0 cycleLength:(int)cl0 periodLength:(int)pl0 {
    if (!predictionJsInterpreted) {
        [self interpretPredictionJsFunction];
    }
    NSString *jsToEval = [NSString stringWithFormat:@"\
                          var pb0 = '%@';\
                          var cl0 = %d;\
                          var pl0 = %d;\
                          var a = emptyCycles(13);\
                          var p = emptyCycles(13);\
                          var t = emptyCycles(13);\
                          initPredict(a, p, t, pb0, cl0, pl0);\
                          JSON.stringify({a:a, p:p, t:t});", pb0, cl0, pl0];
    return [webview stringByEvaluatingJavaScriptFromString:jsToEval];
}

+ (NSDictionary *)calculateActivityScoreFrom:(NSString *)start to:(NSString *)end withPrediction:(NSArray *)p withDailyData:(NSArray *)dailyData withDailyTodos:(NSArray *)dailyTodos{
    @try {
        // no matter what error happens in this function
        // return a default value
        if (!activityRuleJsInterpreted) {
            [self interpretActivityRuleJsFunction];
        }
        // remove "notes" from dailyData
        NSMutableArray * modifiedDailyData = [[NSMutableArray alloc] init];
        for (NSDictionary * dailyDict in dailyData) {
            NSMutableDictionary * tempDict = [NSMutableDictionary dictionaryWithDictionary:dailyDict];
            [tempDict removeObjectForKey:@"notes"];
            [tempDict removeObjectForKey:@"meds"];
            [modifiedDailyData addObject:tempDict];
        }
        NSString *stringifiedP;
        if (!p) {
            stringifiedP = [Utils jsonStringify:@[]];
        } else {
            stringifiedP = [Utils jsonStringify:p];
        }
        NSString *stringifiedDailyData = [Utils jsonStringify:modifiedDailyData];
        NSString *stringifiedDailyTodos = [Utils jsonStringify:dailyTodos];
    
        NSString *jsToEval = [NSString stringWithFormat:@"\
                          var startDate = '%@';\
                          var endDate = '%@';\
                          var p = JSON.parse('%@');\
                          var dailyData = JSON.parse('%@');\
                          var dailyTodos = JSON.parse('%@');\
                          var result = getActivity(startDate, endDate, p, dailyData, dailyTodos);\
                          JSON.stringify(result);",
                          start,
                          end,
                          stringifiedP,
                          stringifiedDailyData,
                          stringifiedDailyTodos];
        //NSString *jsToEval = [NSString stringWithFormat:@"\
        //                      var dailyData = JSON.parse('%@');\
        //                      JSON.stringify(dailyData);",
        //                      stringifiedDailyData];
        NSString *stringifiedResult = [webview stringByEvaluatingJavaScriptFromString:jsToEval];
        GLLog(@"stringifiedResult %@", stringifiedResult);
        return [Utils jsonParse:stringifiedResult];
    } @catch (NSException * e) {
        return @{@"score": @(0),
                 @"level": @(ACTIVITY_INACTIVE)};
    }
}

+ (NSArray *)calculateFertileScoreWithPrediction:(NSArray *)prediction momAge:(int)momAge hasPartner:(BOOL)hasPartner partnerAge:(int)partnerAge{
    @try {
        if (!fertileScoreJsInterpreted) {
            [self interpretFertileScoreJsFunction];
        }
    
        NSMutableArray *predictionWithDateIdx = [NSMutableArray arrayWithCapacity:[prediction count]];
        for (NSDictionary *p in prediction) {
            NSMutableDictionary *pWithDateIdx = [NSMutableDictionary dictionary];
            pWithDateIdx[@"pb"] = @([Utils dateLabelToIntFrom20130101:p[@"pb"]]);
            pWithDateIdx[@"pe"] = @([Utils dateLabelToIntFrom20130101:p[@"pe"]]);
            pWithDateIdx[@"fb"] = @([Utils dateLabelToIntFrom20130101:p[@"fb"]]);
            pWithDateIdx[@"pk"] = @([Utils dateLabelToIntFrom20130101:p[@"pk"]]);
            pWithDateIdx[@"ov"] = @([Utils dateLabelToIntFrom20130101:p[@"ov"]]);
            pWithDateIdx[@"fe"] = @([Utils dateLabelToIntFrom20130101:p[@"fe"]]);
            pWithDateIdx[@"pl"] = p[@"pl"];
            pWithDateIdx[@"cl"] = p[@"cl"];
            pWithDateIdx[@"ol"] = p[@"ol"];
            [predictionWithDateIdx addObject:pWithDateIdx];
        }
        NSString *stringifiedP;
        stringifiedP = [Utils jsonStringify:predictionWithDateIdx];
    
        NSString *jsToEval = [NSString stringWithFormat:@"\
                              var p = JSON.parse('%@');\
                              var momAge = %d;\
                              var hasPartner = %d;\
                              var partnerAge = %d;\
                              var result = calculateFertileScores(p, momAge, hasPartner, partnerAge);\
                              JSON.stringify(result);",
                              stringifiedP,
                              momAge,
                              hasPartner,
                              partnerAge];
        NSString *stringifiedResult = [webview stringByEvaluatingJavaScriptFromString:jsToEval];
        return [Utils jsonParse:stringifiedResult];
    } @catch (NSException * e) {
        return @[];
    }
}

+ (float)calculateFertileScoreWithBase:(float)score  momAge:(int)momAge hasPartner:(BOOL)hasPartner partnerAge:(int)partnerAge
{
    @try {
        if (!fertileScoreJsInterpreted) {
            [self interpretFertileScoreJsFunction];
        }
        NSString *jsToEval = [NSString stringWithFormat:@"\
                              var score = %f;\
                              var momAge = %d;\
                              var hasPartner = %d;\
                              var partnerAge = %d;\
                              var result = getScoreConsideringAge(score, momAge, hasPartner, partnerAge);\
                              JSON.stringify({'r':result});",
                              score, momAge, hasPartner, partnerAge];
        NSString *stringifiedResult = [webview stringByEvaluatingJavaScriptFromString:jsToEval];
        return [[Utils jsonParse:stringifiedResult][@"r"] floatValue];
    } @catch (NSException * e) {
        return 3.0f;
    }
}
@end
