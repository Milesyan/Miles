//
//  Predictor.h
//  emma
//
//  Created by Allen Hsu on 12/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

#define PREDICTION_PERIOD_BEGIN @0x1
#define PREDICTION_PERIOD_ENDED @0x2
#define PREDICTION_PERIOD_ONGOING @0x4
#define PREDICTION_PERIOD_NONE @0x8
#define PREDICTION_FERTILE @0x10
#define PREDICTION_OVULATION @0x20
#define PREDICTION_PEAK @0x40
#define PREDICTION_HISTORICAL_PERIOD @0x80

@interface Predictor : NSObject

@property (nonatomic, strong) User *user;
@property (nonatomic, retain) NSMutableArray *predictionArrayOfAllDays;
@property (nonatomic, retain) NSMutableDictionary *historicalStatus;
@property (nonatomic, retain) NSMutableArray *scoreArrayOfAllDays;
@property (nonatomic, retain) NSMutableArray *predictionArrayOffset;
@property (nonatomic, retain) NSMutableArray *bmrArrayOfAllDays;
@property (readonly) NSMutableArray *prediction;

+ (dispatch_queue_t)predictionQueue;
+ (Predictor *)predictorForUser:(User *)user;

+ (void)calculatePredictionOfAllDaysAroundDate:(NSDate*)date perPrediction:
        (NSArray*)p resultOffset:(NSMutableArray*)resultO resultPrediction:
        (NSMutableArray*)resultP;
- (NSDictionary *)getPredictionsFromDate:(NSDate *)startDate toDate:(NSDate *)endDate;
- (BOOL)periodBeganInPredictionForDate:(NSDate *)date;
- (DayType)predictionForDate:(NSDate *)date;
- (DayType)predictionForDateIdx:(NSInteger)dateIdx;
- (NSString *)dateLabelForNextPB:(BOOL)includeToday;
- (NSString *)dateLabelForNextFB:(BOOL)includeToday;
- (void)jsPredictAround:(NSString *)dateLabel;
- (float)fertileScoreOfDate:(NSDate *)date;
- (NSArray *)getA;

- (void)onlyCalculateHistoricalStatusInMainQueue;
- (void)recalculateAllInMainQueue;

- (void)calculateBMR;
- (NSInteger)bmrOfDate:(NSDate *)date;

- (void)clearPrediction;

@end