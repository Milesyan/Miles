//
//  UserDailyData.h
//  emma
//
//  Created by Ryan Ye on 2/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DailyLogConstants.h"
#import "BaseModel.h"

#define EVENT_DAILY_DATA_UPDATE @"daily_data_update"
#define EVENT_MULTI_DAILY_DATA_UPDATE @"multi_daily_data_update"

//Always use the macro instead of UserDailyData properties in form of string
//The marco used as 1)key path of UserDailyData entity, 2)global cell key to identify daily log cell corresponding to the data entry of same name
// #define DL_CELL_KEY_EXTRA @"EXTRA"
#define DL_CELL_KEY_SECTION_PHYSICAL      @"PhysicalSection"
#define DL_CELL_KEY_SECTION_EMOTIONAL     @"EmotionalSection"
#define DL_CELL_KEY_SECTION_FERTILITY     @"FertilitySection"
#define DL_CELL_KEY_SECTION_SPERM_HEALTH  @"SpermHealthSection"

#define DL_CELL_KEY_ALCOHOL              DAILY_LOG_ITEM_ALCOHOL
#define DL_CELL_KEY_BBT                  DAILY_LOG_ITEM_BBT
#define DL_CELL_KEY_CM                   DAILY_LOG_ITEM_CERVICAL_MUCUS
#define DL_CELL_KEY_INTERCOURSE          DAILY_LOG_ITEM_INTERCOURSE
#define DL_CELL_KEY_MOODS                DAILY_LOG_ITEM_EMOTION_SYMPTOM
#define DL_CELL_KEY_OVTEST               DAILY_LOG_ITEM_OVTEST
#define DL_CELL_KEY_PHYSICALDISCOMFORT   DAILY_LOG_ITEM_PHYSICAL_SYMPTOM
#define DL_CELL_KEY_PREGNANCYTEST        DAILY_LOG_ITEM_PREGNANCY_TEST
#define DL_CELL_KEY_SMOKE                DAILY_LOG_ITEM_SMOKE
#define DL_CELL_KEY_WEIGHT               DAILY_LOG_ITEM_WEIGHT
#define DL_CELL_KEY_EXERCISE             DAILY_LOG_ITEM_EXERCISE
#define DL_CELL_KEY_CERVICAL             DAILY_LOG_ITEM_CERVICAL_POSITION
#define DL_CELL_KEY_SLEEP                DAILY_LOG_ITEM_SLEEP
#define DL_CELL_KEY_PERIOD_FLOW          DAILY_LOG_ITEM_SPOTTING
#define DL_CELL_KEY_STRESS_LEVEL         DAILY_LOG_ITEM_STRESS_LEVEL

#define DL_CELL_KEY_ERECTION             DAILY_LOG_ITEM_ERECTION
#define DL_CELL_KEY_MASTURBATION         DAILY_LOG_ITEM_MASTURBATION
#define DL_CELL_KEY_HEAT_SOURCE          DAILY_LOG_ITEM_HEAT_SOURCE
#define DL_CELL_KEY_FEVER                DAILY_LOG_ITEM_FEVER

//meds(is property key in coredata) holds an array of 1 or more med
//each med is showing in cell MED
#define DL_CELL_KEY_MEDS                 DAILY_LOG_ITEM_MEDICATION
#define DL_CELL_KEY_MED_HEADER @"MED_HEADER"
#define DL_CELL_KEY_MED @"MED"
#define DL_CELL_KEY_ADD_MED @"ADD_MED"

#define DL_CELL_KEY_NOTES_HEADER @"NOTES_HEADER"
#define DL_CELL_KEY_NOTES_ENTRANCE @"NOTES_ENTRANCE"

#define DL_CELL_NORMAL_KEYS @[DL_CELL_KEY_ALCOHOL,DL_CELL_KEY_BBT,DL_CELL_KEY_CM,DL_CELL_KEY_INTERCOURSE,DL_CELL_KEY_MOODS,DL_CELL_KEY_OVTEST,DL_CELL_KEY_PHYSICALDISCOMFORT,DL_CELL_KEY_PREGNANCYTEST,DL_CELL_KEY_SMOKE,DL_CELL_KEY_WEIGHT,DL_CELL_KEY_EXERCISE,DL_CELL_KEY_CERVICAL,DL_CELL_KEY_PERIOD_FLOW,DL_CELL_KEY_STRESS_LEVEL, DL_CELL_KEY_SLEEP, PHYSICAL_SYMPTOM_ONE_KEY,PHYSICAL_SYMPTOM_TWO_KEY, EMOTIONAL_SYMPTOM_ONE_KEY, EMOTIONAL_SYMPTOM_TWO_KEY, DL_CELL_KEY_ERECTION, DL_CELL_KEY_MASTURBATION, DL_CELL_KEY_HEAT_SOURCE, DL_CELL_KEY_FEVER]

#define DL_CELL_SENSITIVE_KEYS @[DL_CELL_KEY_PERIOD_FLOW, DL_CELL_KEY_CM, DL_CELL_KEY_CERVICAL, DL_CELL_KEY_PREGNANCYTEST, DL_CELL_KEY_WEIGHT, DL_CELL_KEY_ERECTION, DL_CELL_KEY_MASTURBATION, DL_CELL_KEY_HEAT_SOURCE]

@class User;

@interface UserDailyData : BaseModel

@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSDate * nsdate;
@property (nonatomic) float temperature;
@property (nonatomic) float weight;
@property (nonatomic) int16_t period;
@property (nonatomic) int64_t sleep;
@property (nonatomic) int16_t cervicalMucus;
@property (nonatomic) int64_t intercourse;
@property (nonatomic) int64_t moods;
@property (nonatomic) int64_t physicalDiscomfort;
@property (nonatomic) uint64_t physicalSymptom1;
@property (nonatomic) uint64_t physicalSymptom2;
@property (nonatomic) uint64_t emotionalSymptom1;
@property (nonatomic) uint64_t emotionalSymptom2;
@property (nonatomic) int16_t ovulationTest;
@property (nonatomic) int16_t pregnancyTest;
@property (nonatomic) int16_t expandPeriodCalendar;
@property (nonatomic) int16_t alcohol;
@property (nonatomic) int16_t smoke;
@property (nonatomic) int64_t exercise;
@property (nonatomic) int16_t cervical;
@property (nonatomic, retain) id meds;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) User *user;
@property (nonatomic) int32_t fromMfpFlag;
@property (nonatomic) int16_t periodFlow;
@property (nonatomic) int32_t stressLevel;

@property (nonatomic) int16_t erection;
@property (nonatomic) int16_t masturbation;
@property (nonatomic) int16_t heatSource;
@property (nonatomic) int16_t fever;

// TODO change NSDate to NSString
+ (UserDailyData *)getUserDailyData:(NSString *)date forUser:(User *)user;
+ (NSArray *)getUserDailyDataFrom:(NSString *)dateLabel ForUser:(User *)user;
+ (NSArray *)getUserDailyDataTo:(NSString *)dateLabel ForUser:(User *)user;
+ (NSArray *)getUserDailyDataFrom:(NSString *)start to:(NSString *)end ForUser:(User *)user;

+ (NSArray *)getDailyDataWithPeriodIncludingHistoryForUser:(User *)user;
+ (NSArray *)getDailyDataWithPeriodForUser:(User *)user;
+ (NSDate *)getEarliestDateForUser:(User *)user;
+ (UserDailyData *)getEarliestPbForUser:(User *)user;
+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user;
+ (id)tset:(NSString *)date forUser:(User *)user;
+ (BOOL)hasDataForDate:(NSString *)date forUser:(User *)user;
+ (BOOL)hasSexForDate:(NSString *)date forUser:(User*)user;
+ (void)enforcePeriod:(NSArray*)prediction forUser:(User*)dataStoreHolder;
+ (void)translateArchivedPeriodValueForPeriods:(NSArray*)historicalPeriods user:(User*)user;

+ (BOOL)isSensitiveItem:(NSString *)itemKey;

- (BOOL)hasData;
- (BOOL)hasPositiveData;
- (BOOL)hasSex;
- (NSUInteger)dataHash;
- (NSDictionary *)medsLog;
- (void)logMed:(NSString *)medName withValue:(id)val;
- (void)updatePeriodWithValue:(NSNumber *)val;
- (void)updateArchivedPeriod;
- (NSDictionary *)toDictionary;
+ (NSArray *)userDailyDataToDict:(NSArray *)sortedDailyData;
+ (NSArray *)userDailyDataInWeek:(NSDate *)date forUser:(User *)user;
+ (void)clearDataOnZeroDate; // fix invalid data with date "0000/00/00"

@end
