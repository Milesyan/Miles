//
//  JsInterpreter.m
//  emma
//
//  Created by Xin Zhao on 13-6-30.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "JsInterpreter.h"
#import "SyncableAttribute.h"
#import "User.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface JsInterpreter(){
    JSGlobalContextRef _JSContext;
//    JSContext *_context;
    JSContext *_context;
}

@end

@implementation JsInterpreter

#pragma mark - JavaScripCore caller
- (JSGlobalContextRef)JSContext
{
    if (_JSContext == NULL) {
        _JSContext = JSGlobalContextCreate(NULL);
    }
    return _JSContext;
}

- (NSString *)runJS:(NSString *)aJSString
{
    if (!aJSString) {
        GLLog(@"[JSC] JS String is empty!");
        return nil;
    }
    
    
    JSStringRef scriptJS = JSStringCreateWithUTF8CString([aJSString UTF8String]);
    JSValueRef exception = NULL;
    
    JSValueRef result = JSEvaluateScript([self JSContext], scriptJS, NULL, NULL, 0, &exception);
    NSString *res = nil;
    
    if (!result) {
        if (exception) {
            JSStringRef exceptionArg = JSValueToStringCopy([self JSContext], exception, NULL);
            NSString* exceptionRes = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, exceptionArg);
            
            JSStringRelease(exceptionArg);
            GLLog(@"[JSC] JavaScript exception: %@", exceptionRes);
        }
        
        GLLog(@"[JSC] No result returned");
    } else {
        JSStringRef jstrArg = JSValueToStringCopy([self JSContext], result, NULL);
        res = (__bridge_transfer NSString*)JSStringCopyCFString(kCFAllocatorDefault, jstrArg);
        
        JSStringRelease(jstrArg);
    }
    
    JSStringRelease(scriptJS);
    return res;
}

/**
 iOS7
 */
/*
- (JSContext *)iOS7JSContext {
    if (!_context) {
        _context = [[JSContext alloc] init];
        _context.exceptionHandler = ^(JSContext *con, JSValue *exception) {
            GLLog(@"JS exception %@", exception);
            con.exception = exception;
        };
    }
    return _context;
}
- (NSString *)iOS7RunJS:(NSString *)aJSString
{
    if (!aJSString) {
        GLLog(@"[JSC] JS String is empty!");
        return nil;
    }
    JSValue *value = [[self iOS7JSContext] evaluateScript:aJSString];
    NSString *result = [value toString];
    return result;
}
*/

/**
 Loads a JS library file from the app's bundle (without the .js extension)
 */
- (void)loadJSLibrary:(NSString*)libraryName
{
    NSString *library = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:libraryName ofType:@"js"]  encoding:NSUTF8StringEncoding error:nil];
    
    GLLog(@"[JSC] loading library %@...", libraryName);
    [self runJS:library];
}

#pragma mark - interpreter
static BOOL predictionJsInterpreted = NO;
static BOOL activityRuleJsInterpreted = NO;
static BOOL fertileScoreJsInterpreted = NO;
static BOOL healthRuleJsInterpreted = NO;
static JsInterpreter *_jsInterpreter = nil;

+ (JsInterpreter *)jsInterpreter {
    if (!_jsInterpreter) {
        _jsInterpreter = [[JsInterpreter alloc] init];
    }
    return _jsInterpreter;
}

+ (NSString *)runJs:(NSString *)jsToEval {
    NSString *resultString = nil;
//    if (IOS7_OR_ABOVE) {
//        resultString = [[self jsInterpreter] iOS7RunJS:jsToEval];
//    }
//    else {
//        resultString = [[self jsInterpreter] runJS:jsToEval];
//    }
    resultString = [[self jsInterpreter] runJS:jsToEval];
    return resultString;
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

+ (void)setHealthRuleJsNeedsInterpret {
    healthRuleJsInterpreted = NO;
}

+ (void)interpretPredictionJsFunction {
    SyncableAttribute *predictRule = (SyncableAttribute *)[SyncableAttribute tsetWithName:ATTRIBUTE_PREDICT_RULES];
    [self runJs:predictRule.stringifiedAttribute];
    predictionJsInterpreted = YES;
}

+ (void)interpretActivityRuleJsFunction {
    SyncableAttribute *activityRule = (SyncableAttribute *)[SyncableAttribute tsetWithName:ATTRIBUTE_ACTIVITY_RULES];
    [self runJs:activityRule.stringifiedAttribute];
    activityRuleJsInterpreted = YES;
}

+ (void)interpretFertileScoreJsFunction {
    SyncableAttribute *fertileScore = (SyncableAttribute *)[SyncableAttribute tsetWithName:ATTRIBUTE_FERTILE_SCORE];
    [self runJs:fertileScore.stringifiedAttribute];
    fertileScoreJsInterpreted = YES;
}

+ (void)interpretHealthJsFunction {
    SyncableAttribute *healthRules = (SyncableAttribute *)[SyncableAttribute tsetWithName:ATTRIBUTE_HEALTH_RULES];
//    GLLog(@"run health js: %@", healthRules.stringifiedAttribute);
    if (healthRules.stringifiedAttribute) {
        [self runJs:healthRules.stringifiedAttribute];
        healthRuleJsInterpreted = YES;
    }
}

+ (NSString *)predictWith:(NSString *)pb0 cycleLength:(NSInteger)cl0
        periodLength:(NSInteger)pl0 dailyData:(NSArray *)dailyData
        withApt:(NSDictionary *)apt around:(NSString *)dateLabel
        afterMigration:(BOOL)afterMigration userInfo:(NSDictionary *)userInfo{
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
    NSString *stringifiedUserInfo = userInfo
            ? [Utils jsonStringify:userInfo]
            : [Utils jsonStringify:@{}];
    
    NSString *jsToEval = nil;
    if (afterMigration) {
        jsToEval = [NSString stringWithFormat:@"\
            var pb0 = '%@';\
            var cl0 = %ld;\
            var pl0 = %ld;\
            var dailyData = %@;\
            var userInfo = %@;\
            var r = predictRulesMain(dailyData, pb0, cl0, pl0, true, userInfo);\
            JSON.stringify(r);",
            pb0,
            cl0,
            pl0,
            stringifiedDailyData,
            stringifiedUserInfo];
    }
    else {
        jsToEval = [NSString stringWithFormat:@"\
            var pb0 = '%@';\
            var cl0 = %ld;\
            var pl0 = %ld;\
            var dailyData = %@;\
            var userInfo = %@;\
            var r = predictRulesMain(dailyData, pb0, cl0, pl0, true, userInfo);\
            JSON.stringify(r);",
            pb0,
            cl0,
            pl0,
            stringifiedDailyData,
            stringifiedUserInfo];
    }
    
    NSString *stringifiedResult = [self runJs:jsToEval];
    return stringifiedResult;
}
//
//+ (NSString *)predictWith:(NSString *)pb0 cycleLength:(NSInteger)cl0 periodLength:(NSInteger)pl0 {
//    if (!predictionJsInterpreted) {
//        [self interpretPredictionJsFunction];
//    }
//    NSString *jsToEval = [NSString stringWithFormat:@"\
//                          var pb0 = '%@';\
//                          var cl0 = %d;\
//                          var pl0 = %d;\
//                          var a = emptyCycles(13);\
//                          var p = emptyCycles(13);\
//                          var t = emptyCycles(13);\
//                          initPredict(a, p, t, pb0, cl0, pl0);\
//                          JSON.stringify({a:a, p:p, t:t});", pb0, cl0, pl0];
//
//    NSString *stringifiedResult = [self runJs:jsToEval];
//    return stringifiedResult;
//}

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
                          var p = %@;\
                          var dailyData = %@;\
                          var dailyTodos = %@;\
                          var result = getActivity(startDate, endDate, p, dailyData, dailyTodos);\
                          JSON.stringify(result);",
                          start,
                          end,
                          stringifiedP,
                          stringifiedDailyData,
                          stringifiedDailyTodos];
        NSString *stringifiedResult = [self runJs:jsToEval];
        return [Utils jsonParse:stringifiedResult];
    } @catch (NSException * e) {
        return @{@"score": @(0),
                 @"level": @(ACTIVITY_INACTIVE)};
    }
}

+ (NSArray *)calculateFertileScoreWithPrediction:(NSArray *)prediction momAge:(NSInteger)momAge hasPartner:(BOOL)hasPartner partnerAge:(NSInteger)partnerAge{
    @try {
        if (!fertileScoreJsInterpreted) {
            [self interpretFertileScoreJsFunction];
        }
    
        NSString *stringifiedP;
        stringifiedP = [Utils jsonStringify:prediction];
    
        NSString *jsToEval = [NSString stringWithFormat:@"\
                              var p = %@;\
                              var momAge = %ld;\
                              var hasPartner = %d;\
                              var partnerAge = %ld;\
                              var result = calculateFertileScores(p, momAge, hasPartner, partnerAge);\
                              JSON.stringify(result);",
                              stringifiedP,
                              momAge,
                              hasPartner,
                              partnerAge];
        NSString *stringifiedResult = [self runJs:jsToEval];
        return [Utils jsonParse:stringifiedResult];
    } @catch (NSException * e) {
        return @[];
    }
}

+ (float)calculateFertileScoreWithBase:(float)score  momAge:(NSInteger)momAge hasPartner:(BOOL)hasPartner partnerAge:(NSInteger)partnerAge
{
    @try {
        if (!fertileScoreJsInterpreted) {
            [self interpretFertileScoreJsFunction];
        }
        NSString *jsToEval = [NSString stringWithFormat:@"\
                              var score = %f;\
                              var momAge = %ld;\
                              var hasPartner = %d;\
                              var partnerAge = %ld;\
                              var result = getScoreConsideringAge(score, momAge, hasPartner, partnerAge);\
                              JSON.stringify({'r':result});",
                              score, momAge, hasPartner, partnerAge];
        NSString *stringifiedResult = [self runJs:jsToEval];
        return [[Utils jsonParse:stringifiedResult][@"r"] floatValue];
    } @catch (NSException * e) {
        return 3.0f;
    }
}

+ (NSArray *)calculateBMRWithDailyData:(NSArray *)dailyData age:(NSInteger)age weight:(float)weight height:(NSInteger)height defaultActivityLevel:(NSInteger)level from:(NSDate *)sinceDate to:(NSDate *)endDate
{
    @try {
        if (!healthRuleJsInterpreted) {
            [self interpretHealthJsFunction];
//            GLLog(@"js loaded?");
        }

        if (healthRuleJsInterpreted) {
//            GLLog(@"height: %d", height);
//            GLLog(@"defaultExercise: %d", level);
            //TODO: User should have height/weight/activityLevel when onboarding/switching to health tracking.height
            //        float earliestWeight = 0;
            NSMutableArray * modifiedDailyData = [[NSMutableArray alloc] init];
            for (NSDictionary * dailyDict in dailyData) {
                NSMutableDictionary * tempDict = [NSMutableDictionary dictionaryWithDictionary:dailyDict];
                [tempDict removeObjectForKey:@"notes"];
                [tempDict removeObjectForKey:@"meds"];
                [modifiedDailyData addObject:tempDict];
                //            if ([dailyDict objectForKey:@"alcohol"] || [dailyDict objectForKey:@"smoke"] || [dailyDict objectForKey:@"intercourse"]) {
                //                GLLog(@"DATE: %@", dailyDict);
                //            }
                //            if (earliestWeight == 0 && [dailyDict objectForKey:@"weight"]) {
                //                earliestWeight = [[dailyDict objectForKey:@"weight"] floatValue];
                //            }
                //            GLLog(@"dailydataforBMR: %@", tempDict);
            }
            NSString *stringifiedDailyData = [Utils jsonStringify:modifiedDailyData];
            
            NSString *jsToEval = [NSString stringWithFormat:@"\
                                  var d = %@;\
                                  var momAge = %ld;\
                                  var weight = %f;\
                                  var height = %ld;\
                                  var defaultActivityLevel = %ld;\
                                  var sinceDate = '%@';\
                                  var endDate = '%@';\
                                  var result = calculateBMR(d, momAge, weight, height, defaultActivityLevel, sinceDate, endDate);\
                                  JSON.stringify(result);",
                                  stringifiedDailyData,
                                  age,
                                  weight,
                                  height,
                                  level,
                                  [Utils dailyDataDateLabel:sinceDate? sinceDate: [Utils dateByAddingDays:-150 toDate:[NSDate date]]],
                                  [Utils dailyDataDateLabel:endDate? endDate: [Utils dateByAddingDays:120 toDate:[NSDate date]]]];
            NSString *stringifiedResult = [self runJs:jsToEval];
//            GLLog(@"BMR: %@", stringifiedResult);
            
            return [Utils jsonParse:stringifiedResult];
        } else
            return @[];

    } @catch (NSException * e) {
        return @[];
    }
}

@end
