//
//  Predictor.m
//  emma
//
//  Created by Allen Hsu on 12/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "Predictor.h"
#import "Interpreter.h"
#import "JsInterpreter.h"
#import "DailyLogConstants.h"

@interface Predictor ()

@property (readonly) NSMutableArray *a;
@property (readonly) NSMutableArray *t;

@end

@implementation Predictor

@synthesize prediction = _prediction;
@synthesize a = _a;
@synthesize t = _t;
@synthesize predictionArrayOfAllDays = _predictionArrayOfAllDays;
@synthesize historicalStatus = _historicalStatus;
@synthesize predictionArrayOffset = _predictionArrayOffset;
@synthesize scoreArrayOfAllDays = _scoreArrayOfAllDays;
@synthesize bmrArrayOfAllDays = _bmrArrayOfAllDays;

static dispatch_queue_t _predictionQueue = 0;
+ (dispatch_queue_t)predictionQueue {
    if (!_predictionQueue) {
        _predictionQueue = dispatch_queue_create("com.emma.prediction", NULL);
    }
    return _predictionQueue;
}

static NSMutableDictionary *_predictors = nil;
+ (Predictor *)predictorForUser:(User *)user
{
    User *threadSafeUser = (User *)[user makeThreadSafeCopy];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _predictors = [NSMutableDictionary dictionary];
    });
    Predictor *predictor = [_predictors objectForKey:threadSafeUser.id];
    if (!predictor) {
        predictor = [[Predictor alloc] init];
        [_predictors setObject:predictor forKey:threadSafeUser.id];
    }
    predictor.user = threadSafeUser;
    return predictor;
}

+ (void)calculateStatusOfHistoricalPeriods:(NSArray*)historicalPeriods
        result:(NSMutableDictionary*)historicalStatus {
   
    [historicalStatus removeAllObjects];
    
    //Generate historical period pairs
    if ([historicalPeriods count] > 0) {
        NSMutableArray *historicalCycles = [NSMutableArray array];
        int count = 0;
        for (UserDailyData *daily in historicalPeriods) {
            NSInteger dateIndex = [daily.nsdate toDateIndex];
            NSInteger archivedPeriod = ((daily.period >> ARCHIVED_PERIOD_SHIFT) %
                    CURRENT_PERIOD_MOD_BASE);
            if (1 != archivedPeriod && 0 == count) {
                continue;
            }
            if (archivedPeriod == LOG_VAL_PERIOD_BEGAN) {
                [historicalCycles addObject:[NSMutableDictionary
                        dictionaryWithDictionary:@{@"pb": @(dateIndex),
                        @"pl": @(DEFAULT_PL)}]];
                count++;
            }
            else if (archivedPeriod == LOG_VAL_PERIOD_ENDED) {
                NSMutableDictionary *current = historicalCycles[count - 1];
                int pl = dateIndex - [current[@"pb"] intValue];
                if (pl < 20 && pl > 0) {
                    current[@"pl"] = @(pl);
                    historicalCycles[count - 1] = current;
                }
            }
        }
        
        NSMutableArray *status = [NSMutableArray array];
        
        if ([historicalCycles count] > 0) {
            for (int i = 0; i < [historicalCycles count]; i++) {
                NSDictionary *cycle = historicalCycles[i];
                int pbIdx = [cycle[@"pb"] intValue];
                int pl = [cycle[@"pl"] intValue];
                int cl = pl;
                if (i + 1 < [historicalCycles count]) {
                    cl = [historicalCycles[i+1][@"pb"] intValue] - pbIdx;
                }
                
                for (int j = 0; j < pl; j++) {
                    [status addObject:PREDICTION_HISTORICAL_PERIOD];
                }
                for (int j = 0; j < cl - pl; j++) {
                    [status addObject:PREDICTION_PERIOD_NONE];
                }
            }
            historicalStatus[@"offset"] = historicalCycles[0][@"pb"];
            historicalStatus[@"status"] = status;
        }
    }
}

+ (void)calculatePredictionOfAllDaysAroundDate:(NSDate*)date perPrediction:
        (NSArray*)p resultOffset:(NSMutableArray*)resultO resultPrediction:
        (NSMutableArray*)resultP
{
    /*
     * This function will be called in a sub thread. So, this thread should not use any
     * variables under user instance.
     * NOTE - if both sub thread and main thread access one coredata variable under user,
     *        will cause the App crash (main thread break) or sub thread dead-lock
     *
     * Any modification for this function, please contact:  jirong@ / xzhao@upwlabs.com
     */
    NSInteger startCycle = 0;
    NSInteger endIdx = 99999;
    if (date) {
        NSString *dateLabel = [Utils dailyDataDateLabel:date];
        NSInteger startIndex = [[Utils findFirstPbIndexBefore:dateLabel inPrediction:p] intValue];
        if (startIndex < 0 || startIndex == 9999) {
            return;
        }
        startCycle = (startIndex - 1 < 0) ? 0 : (startIndex - 1);
        endIdx = [Utils dateToIntFrom20130101:date] + 30;
    }
   
    [resultP removeAllObjects];
    [resultO removeAllObjects];
   
    
    for (NSInteger j = startCycle; j < [p count]; j++) {
        NSDictionary *pN = [p objectAtIndex:j];
        NSString *pbN = [pN objectForKey:@"pb"];
        NSString *peN = [pN objectForKey:@"pe"];
        NSString *fbN = [pN objectForKey:@"fb"];
        NSString *feN = [pN objectForKey:@"fe"];
        NSInteger clN = [[pN objectForKey:@"cl"] intValue];
        NSInteger plN = [[pN objectForKey:@"pl"] intValue];
        NSInteger niN = [Utils daysBeforeDateLabel:fbN sinceDateLabel:peN] - 1;
        NSInteger flN = [Utils daysBeforeDateLabel:feN sinceDateLabel:fbN] + 1;
        NSInteger pbIdx = [Utils dateLabelToIntFrom20130101:pbN];
        
        if (startCycle == j) {
            [resultO addObject:@(pbIdx)];
        }
        
        for (NSInteger i = [resultP count]; i < pbIdx - [resultO[0] intValue]; i++) {
            [resultP addObject:PREDICTION_PERIOD_NONE];
        }
        for (NSInteger i = 0; i <= plN; i++) {
            [resultP addObject:PREDICTION_PERIOD_ONGOING];
        }
        for (NSInteger i = plN + 1; i <= plN + niN; i++) {
            [resultP addObject:PREDICTION_PERIOD_NONE];
        }
        for (NSInteger i = plN + niN + 1; i <= plN + niN + flN; i++ ) {
            [resultP addObject:PREDICTION_FERTILE];
        }
        for (NSInteger i = plN + niN + flN + 1; i < clN; i++) {
            [resultP addObject:PREDICTION_PERIOD_NONE];
        }
        if (pbIdx + clN >= endIdx) {
            //            GLLog(@"half way %@", _scoreArrayOfAllDays);
            return;
        }
    }
    //    GLLog(@"predictionArray %@", _scoreArrayOfAllDays);
    return;
}

- (void)onlyCalculateHistoricalStatusInMainQueue{
    User *user = (User *)[[User userOwnsPeriodInfo] makeThreadSafeCopy];
    NSArray *historicalPeriods = [UserDailyData
            getDailyDataWithPeriodIncludingHistoryForUser:user];
    
    if ([historicalPeriods count] == 0) {
        return;
    }
    
    if (!_historicalStatus) {
        _historicalStatus = [NSMutableDictionary dictionary];
    }
    [Predictor calculateStatusOfHistoricalPeriods:historicalPeriods result:
     _historicalStatus];
    [self publish:EVENT_PREDICTION_UPDATE];
}

- (void)recalculateAllInMainQueue
{
    [self clearScoreConstantForNormalDays];
    User *user = (User *)[self.user makeThreadSafeCopy];
    User *userOwnsPeriodInfo = (User *)[[User userOwnsPeriodInfo] makeThreadSafeCopy];

    BOOL hasPartner = user.partner ? YES : NO;
    
    NSInteger partnerAge = user.partner
    ? (user.isPrimary ? user.partner.age : user.age)
    : -1;
    
    
    NSArray *fertileScores = [RULES_INTERPRETER calculateFertileScoreWithPrediction:self.prediction
                                                                             momAge:user.motherAge
                                                                         hasPartner:hasPartner
                                                                         partnerAge:partnerAge];
   
    NSArray *historicalPeriods = [UserDailyData
            getDailyDataWithPeriodIncludingHistoryForUser:userOwnsPeriodInfo];
    
    if (!_predictionArrayOffset) {
        _predictionArrayOffset = [NSMutableArray arrayWithCapacity:1];
    }
    if (!_predictionArrayOfAllDays) {
        _predictionArrayOfAllDays = [NSMutableArray arrayWithCapacity:512];
    }
    if (!_historicalStatus) {
        _historicalStatus = [NSMutableDictionary dictionary];
    }
    _scoreArrayOfAllDays = [NSMutableArray arrayWithArray:fertileScores];
    
    dispatch_async([Predictor predictionQueue], ^{
        [Predictor calculatePredictionOfAllDaysAroundDate:nil perPrediction:
                self.prediction resultOffset:self.predictionArrayOffset
                resultPrediction:self.predictionArrayOfAllDays];
        dispatch_async(dispatch_get_main_queue(), ^{
            [Predictor calculateStatusOfHistoricalPeriods:historicalPeriods result: _historicalStatus];
            [self publish:EVENT_PREDICTION_UPDATE];
        });
        GLLog(@"all recolor done");
    });
}

- (BOOL)periodBeganInPredictionForDate:(NSDate *)date {
    NSString *dateLabel = [Utils dailyDataDateLabel:date];
    int index = [[Utils findFirstPbIndexBefore:dateLabel inPrediction:self.prediction] intValue];
    if (index < 0 || index == 9999) {
        return NO;
    }
    
    NSString *pPb = [[self.prediction objectAtIndex:index] objectForKey:@"pb"];
    
    return [dateLabel isEqualToString:pPb];
}

- (NSInteger)predictionAndScoreOffset
{
    if (!self.predictionArrayOffset || [self.predictionArrayOffset count] == 0)
        return 0;
    return [self.predictionArrayOffset[0] intValue];
}

- (NSNumber *)getPredictionOfDateIdx:(NSInteger)dateIdx {
    NSInteger indexInPredictionArray = dateIdx - self.predictionAndScoreOffset;
    if (indexInPredictionArray < 0 || indexInPredictionArray >=
            [_predictionArrayOfAllDays count]) {
        if (self.historicalStatus[@"offset"]) {
            NSArray *status = self.historicalStatus[@"status"];
            NSInteger indexInHistoricals = dateIdx - [self.historicalStatus[@"offset"] intValue];
            if (indexInHistoricals >= 0 && indexInHistoricals < [status count]) {
                return status[indexInHistoricals];
            }
        }
        return PREDICTION_PERIOD_NONE;
    }

    return [_predictionArrayOfAllDays objectAtIndex:dateIdx - self.predictionAndScoreOffset];
}

- (NSDictionary *)getPredictionsFromDate:(NSDate *)startDate toDate:(NSDate *)endDate {
    NSString *startLabel = [Utils dailyDataDateLabel:startDate];
    NSInteger startIdx = [[Utils findFirstPbIndexBefore:startLabel inPrediction:self.prediction] intValue];
    NSString *endLabel = [Utils dailyDataDateLabel:endDate];
    NSInteger endIdx = [[Utils findFirstPbIndexBefore:endLabel inPrediction:self.prediction] intValue];
    if (startIdx == 9999 || endIdx == -1) {
        return @{@"predictionSegment": @[], @"offset": @(-1)};
    }
    startIdx = (startIdx > -1) ? startIdx : 0;
    endIdx = (endIdx < 9999) ? endIdx : [self.prediction count] - 1;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSInteger i = startIdx; i <= endIdx ; i++) {
        [result addObject:[self.prediction objectAtIndex:i]];
    }
    return @{@"predictionSegment": result,
             @"offset": @(startIdx - 1)};
}

- (NSString *)dateLabelForNextPB:(BOOL)includeToday {
    if (self.prediction && [self.prediction count]) {
        NSInteger idx = [[Utils findFirstPbIndexBefore:[Utils dailyDataDateLabel:[NSDate date]] inPrediction:self.prediction] integerValue];
        
        if(idx > -1 && idx != 9999 && idx < [self.prediction count] - 1) {
        } else {
            idx = 0;
        }
        
        NSDictionary *pred = [self.prediction objectAtIndex:idx];
        NSString *pb = [pred objectForKey:@"pb"];
        
        if ([Utils daysBeforeDateLabel:pb sinceDateLabel:[Utils dailyDataDateLabel:[NSDate date]]] == 0 && includeToday) {
            return pb;
        } else if (idx < [self.prediction count] - 1) {
            return [[self.prediction objectAtIndex:idx + 1] objectForKey:@"pb"];
        }
        
    }
    return nil;
}

- (NSString *)dateLabelForNextFB:(BOOL)includeToday {
    if (self.prediction && [self.prediction count]) {
        NSInteger idx = [[Utils findFirstPbIndexBefore:[Utils dailyDataDateLabel:[NSDate date]] inPrediction:self.prediction] integerValue];
        
        if(idx == -1 || idx == 9999) {
            idx = 0;
        }
        
        NSDictionary *currentPred = [self.prediction objectAtIndex:idx];
        NSString *fb = [currentPred objectForKey:@"fb"];
        
        NSInteger before = [Utils daysBeforeDateLabel:fb sinceDateLabel:[Utils dailyDataDateLabel:[NSDate date]]];
        if ( before > 0) {
            return fb;
        }else if (before == 0 && includeToday) {
            return fb;
        } else if (idx < [self.prediction count] - 1) {
            return [[self.prediction objectAtIndex:idx + 1] objectForKey:@"fb"];
        }
    }
    return nil;
}


- (DayType)predictionForDate:(NSDate *)date {
    NSInteger dateIdx = [Utils dateToIntFrom20130101:date];
    return [self predictionForDateIdx:dateIdx];
}

- (DayType)predictionForDateIdx:(NSInteger)dateIdx {
    NSNumber *predictionOfDate = (NSNumber *)[self getPredictionOfDateIdx:dateIdx];
    if ([predictionOfDate intValue] & [PREDICTION_HISTORICAL_PERIOD intValue]) {
        return kDayHistoricalPeriod;
    }
    else if ([predictionOfDate intValue] & [PREDICTION_PERIOD_BEGIN intValue] ||
            [predictionOfDate intValue] & [PREDICTION_PERIOD_ONGOING intValue] ||
            [predictionOfDate intValue] & [PREDICTION_PERIOD_ENDED intValue]) {
        return kDayPeriod;
    } else if ([predictionOfDate intValue] & [PREDICTION_FERTILE intValue] || [predictionOfDate intValue] & [PREDICTION_OVULATION intValue] || [predictionOfDate intValue] & [PREDICTION_PEAK intValue]){
        return kDayFertile;
    } else {
        return kDayNormal;
    }
}

- (void)jsPredictAround:(NSString *)dateLabel{
    User *user = (User *)[self.user makeThreadSafeCopy];
    Settings *settings = user.settings;
    
//    GLLog(@"=================== start");
//    GLLog(@"user.firstPb:%@", user.firstPb);
//    GLLog(@"user.settings:%@", user.settings);
    
//    if (!_a) {
//        NSString *resultString = [RULES_INTERPRETER predictWith:user.firstPb.date cycleLength:settings.periodCycle periodLength:settings.periodLength];
//        NSData *data = [resultString dataUsingEncoding:NSUTF8StringEncoding];
//        NSDictionary *r = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//        _a = [r objectForKey:@"a"];
//        _prediction = [r objectForKey:@"p"];
//        _t = [r objectForKey:@"t"];
//    }
    
    //    NSInteger pbIdx = [[Utils findFirstPbIndexBefore:dateLabel inPrediction:self.prediction] intValue];
    NSString *startDateLabel = nil;
    //    if (pbIdx <= 0) {
    //        startDateLabel = @"2013/01/01";
    //    } else if (pbIdx < 9999) {
    //        startDateLabel = [[self.prediction objectAtIndex:pbIdx - 1] objectForKey:@"fe"];
    //    } else {
    //        return;
    //    }
    startDateLabel = DEFAULT_PB_LABEL;
    NSArray *dailyDataArray = [UserDailyData userDailyDataToDict:[UserDailyData getUserDailyDataFrom:startDateLabel ForUser:user]];
//    GLLog(@"=================== data ready, with %d daily data", [dailyDataArray count]);
    //    GLLog(@"predict %@", _t);
    
//    GLLog(@"================ they are %@", dailyDataArray);
    NSString *resultString = nil;
    if (!user.predictionMigrated0) {
        resultString = [RULES_INTERPRETER predictWith:user.firstPb.date
                                          cycleLength:settings.periodCycle
                                         periodLength:settings.periodLength
                                            dailyData:dailyDataArray
                                              withApt:nil
                                               around:startDateLabel
                                       afterMigration:NO
                                             userInfo:[user toDictionaryWithServerAttrs]];
    }
    else {
        resultString = [RULES_INTERPRETER predictWith:user.firstPb.date
                                          cycleLength:settings.periodCycle
                                         periodLength:settings.periodLength
                                            dailyData:dailyDataArray
                                              withApt:nil
                                               around:startDateLabel
                                       afterMigration:YES
                                             userInfo:[user toDictionaryWithServerAttrs]];
    }
    NSDictionary *r = resultString ? [Utils jsonParse:resultString] : nil;
    _a = [r objectForKey:@"a"];
    _prediction = [r objectForKey:@"p"];
    _t = [r objectForKey:@"t"];
//    GLLog(@"prediction %@", self.prediction);
//    GLLog(@"=================== end");
}


static NSNumber *normalScore = nil;
- (void)clearScoreConstantForNormalDays
{
    normalScore = nil;
}

- (float)fertileScoreOfDate:(NSDate *)date {
    User *user = (User *)[self.user makeThreadSafeCopy];
    NSInteger dateIdx = [Utils dateToIntFrom20130101:date];
    if (dateIdx < self.predictionAndScoreOffset || dateIdx >= self.predictionAndScoreOffset + [_scoreArrayOfAllDays count]) {
        if ([NSThread isMainThread]) {
            //            SyncableAttribute *fertileScoreCoefAttr = [SyncableAttribute tsetWithName:ATTRIBUTE_FERTILE_SCORE_COEF inDataStore:self.dataStore];
            //            NSArray *coefs = [Utils jsonParse:fertileScoreCoefAttr.stringifiedAttribute];
            //            float coefForOver27 = [self getCoefForOver27WithCoefs:coefs];
            //            float result = 3.0 * coefForOver27;
            //            result = result < 1 ? 1 : result;
            if (!normalScore) {
                BOOL hasPartner = user.partner ? YES : NO;
                NSInteger partnerAge = user.partner
                ? (user.isPrimary ? user.partner.age : user.age)
                : -1;
                normalScore = @([RULES_INTERPRETER calculateFertileScoreWithBase:3.0f
                                                                          momAge:user.motherAge
                                                                      hasPartner:hasPartner
                                                                      partnerAge:partnerAge]);
            }
            return [normalScore floatValue];
        } else {
            return normalScore ? [normalScore floatValue] : 3.0;
        }
    }
    return [[_scoreArrayOfAllDays objectAtIndex:dateIdx - self.predictionAndScoreOffset] floatValue];
}

- (NSArray *)getA {
    return self.a;
}

- (void)calculateBMR {
    User *user = (User *)[self.user makeThreadSafeCopy];
    Settings *settings = user.settings;
    NSArray *dailyDataArray = [UserDailyData userDailyDataToDict:[UserDailyData getUserDailyDataFrom:DEFAULT_PB_LABEL ForUser:user]];
    NSDate *min = [Utils getDefaultsForKey:USER_DEFAULTS_MIN_PRED_DATE];
    NSDate *max = [Utils getDefaultsForKey:USER_DEFAULTS_MAX_PRED_DATE];
    
    if (min) {
        min = [Utils monthFirstDate:min];
    }
    
//    GLLog(@"calculateBMR: %f %f %f %d", user.age, settings.weight, settings.height, settings.exercise);
    NSArray *result = [RULES_INTERPRETER calculateBMRWithDailyData:dailyDataArray
                                                               age:user.age
                                                            weight:settings.weight
                                                            height:settings.height
                                              defaultActivityLevel:settings.exercise
                                                              from:min
                                                                to:max];
    self.bmrArrayOfAllDays = [NSMutableArray arrayWithArray:result];
}

- (NSInteger)bmrOfDate:(NSDate *)date
{
    NSInteger dateIdx = [Utils dateToIntFrom20130101:date];
    
    if (![_bmrArrayOfAllDays count] || [_bmrArrayOfAllDays count] <= dateIdx) {
        return 0;
    }
    
    NSNumber *obj = _bmrArrayOfAllDays[dateIdx];
    
    if (!obj || [obj isKindOfClass:[NSNull class]]) {
        return 0;
    } else {
        return [obj integerValue];
    }
}

- (void)clearPrediction {
    _a = nil;
    _t = nil;
    _prediction = nil;
    _predictionArrayOfAllDays = nil;
    _predictionArrayOffset = nil;
    _scoreArrayOfAllDays = nil;
    _bmrArrayOfAllDays = nil;
}

@end
