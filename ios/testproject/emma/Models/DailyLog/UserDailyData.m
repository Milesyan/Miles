//
//  UserDailyData.m
//  emma
//
//  Created by Ryan Ye on 2/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "UserDailyData.h"
#import "User.h"
#import "DataStore.h"
#import "DailyLogConstants.h"
#import "UserDailyData+HealthKit.h"

@interface UserDailyData()
@end

@implementation UserDailyData

@dynamic date;
@dynamic nsdate;
@dynamic temperature;
@dynamic weight;
@dynamic period;
@dynamic cervicalMucus;
@dynamic intercourse;
@dynamic moods;
@dynamic physicalDiscomfort;
@dynamic physicalSymptom1;
@dynamic physicalSymptom2;
@dynamic emotionalSymptom1;
@dynamic emotionalSymptom2;
@dynamic ovulationTest;
@dynamic pregnancyTest;
@dynamic notes;
@dynamic expandPeriodCalendar;
@dynamic user;
@dynamic fromMfpFlag;
@dynamic alcohol;
@dynamic smoke;
@dynamic exercise;
@dynamic cervical;
@dynamic periodFlow;
@dynamic meds;
@dynamic stressLevel;
@dynamic sleep;

@dynamic erection;
@dynamic masturbation;
@dynamic heatSource;
@dynamic fever;

- (NSDictionary *)attrMapper {
    return @{@"date"                   : @"date",
             @"temperature"            : @"temperature",
             @"weight"                 : @"weight",
             @"period"                 : @"period",
             @"sleep"                  : @"sleep",
             @"cervical_mucus"         : @"cervicalMucus",
             @"intercourse"            : @"intercourse",
             @"moods"                  : @"moods",
             @"physical_discomfort"    : @"physicalDiscomfort",
             @"physical_symptom_1"     : @"physicalSymptom1",
             @"physical_symptom_2"     : @"physicalSymptom2",
             @"emotional_symptom_1"    : @"emotionalSymptom1",
             @"emotional_symptom_2"    : @"emotionalSymptom2",
             @"ovulation_test"         : @"ovulationTest",
             @"pregnancy_test"         : @"pregnancyTest",
             @"notes"                  : @"notes",
             @"expand_period_calendar" : @"expandPeriodCalendar",
             @"from_mfp_flag"          : @"fromMfpFlag",
             @"smoke"                  : @"smoke",
             @"alcohol"                : @"alcohol",
             @"exercise"               : @"exercise",
             @"cervical"               : @"cervical",
             @"period_flow"            : @"periodFlow",
             @"stress_level"           : @"stressLevel",
             @"meds"                   : @"meds",
             @"erection"               : @"erection",
             @"masturbation"           : @"masturbation",
             @"heat_source"            : @"heatSource",
             @"fever"                  : @"fever"
             };
}

- (NSSet *)attrAffectingPrediction {
    return [NSSet setWithObjects:@"temperature", @"period", @"cervicalMucus", @"ovulationTest", nil];
}

+ (BOOL)isSensitiveItem:(NSString *)itemKey
{
    return [DL_CELL_SENSITIVE_KEYS containsObject:itemKey];
}

+ (UserDailyData *)getUserDailyData:(NSString *)date forUser:(User *)user {
    if (!user)
        return nil;
    DataStore *ds = user.dataStore;
    UserDailyData *d = (UserDailyData *)[self fetchObject:@{@"user.id" : user.id, @"date" : date} dataStore:ds];
    return d? d: nil;
}


+ (NSArray *)getUserDailyDataFrom:(NSString *)dateLabel ForUser:(User *)user {
    NSMutableArray* dailyDate = [NSMutableArray array];
    for (UserDailyData *d in user.dailyData) {
        if (strLargeEqual(d.date, dateLabel))
            [dailyDate addObject:d];
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"nsdate" ascending:YES];
    NSArray *sorted=[dailyDate sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    return sorted;
}

+ (NSArray *)getUserDailyDataTo:(NSString *)dateLabel ForUser:(User *)user {
    NSMutableArray* dailyDate = [NSMutableArray array];
    for (UserDailyData *d in user.dailyData) {
        if (strLessEqual(d.date, dateLabel))
            [dailyDate addObject:d];
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"nsdate" ascending:YES];
    NSArray *sorted=[dailyDate sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    return sorted;
}

+ (NSArray *)getUserDailyDataFrom:(NSString *)start to:(NSString *)end ForUser:(User *)user {
    NSMutableArray* dailyData = [NSMutableArray array];
    for (UserDailyData *d in user.dailyData) {
        if ((strLessEqual(d.date, end)) && (strLargeEqual(d.date, start)))
            [dailyData addObject:d];
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"nsdate" ascending:YES];
    NSArray *sorted=[dailyData sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    return sorted;
}

+ (NSArray *)getDailyDataWithPeriodIncludingHistoryForUser:(User *)user {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserDailyData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@ and period > 0", user.id];
    DataStore *ds = user.dataStore;
    NSArray *dailyData = [ds.context executeFetchRequest:fetchRequest error:nil];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"nsdate" ascending:YES];
    NSArray *sorted=[dailyData sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    return sorted;
}

+ (NSArray *)getDailyDataWithPeriodForUser:(User *)user {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserDailyData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@ and modulus:by:(period, 4) > 0", user.id];
    DataStore *ds = user.dataStore;
    NSArray *dailyData = [ds.context executeFetchRequest:fetchRequest error:nil];
    return dailyData;
}

+ (NSDate *)getEarliestDateForUser:(User *)user {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserDailyData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@", user.id];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"nsdate" ascending:YES]];
    DataStore *ds = user.dataStore;
    NSArray *dailydatas = [ds.context executeFetchRequest:fetchRequest error:nil];
    if (dailydatas.count > 0) {
        return ((UserDailyData *)dailydatas[0]).nsdate;
    }
    if (user.settings.firstPb && user.settings.firstPb.length > 0) {
        return [Utils dateWithDateLabel:user.settings.firstPb];
    }
    return nil;
}

+ (UserDailyData *)getEarliestPbForUser:(User *)user {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserDailyData"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@ and modulus:by:(period, 4) == 1 and period != 13", user.id];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"nsdate" ascending:YES]];
    DataStore *ds = user.dataStore;
    NSArray *pbs = [ds.context executeFetchRequest:fetchRequest error:nil];
    if ([pbs count] > 0 && ((UserDailyData *)pbs[0]).date) {
        return pbs[0];
    }
    if (!user.settings.firstPb || user.settings.firstPb.length == 0) {
        return nil;
    }
    UserDailyData *firstPb = [self tset:user.settings.firstPb forUser:user];
    if (!firstPb.period) {
        [firstPb update:@"period" value:@1];
    }
    return firstPb;
}

- (void)updateAttrsFromServerData:(NSDictionary *)data {
    for (NSString *attr in self.attrMapper) {
        // we no longer update period field from server
        if ([attr isEqualToString:@"period"]) {
            continue;
        }
        NSObject *remoteVal = [data objectForKey:attr];
        if (remoteVal) {
            NSString *clientAttr = [self.attrMapper valueForKey:attr];
            [self convertAndSetValue:remoteVal forAttr:clientAttr];
        }
    }
    [self clearState];
}


+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user {
    UserDailyData *daily = [UserDailyData tset:[data objectForKey:@"date"] forUser:user];
    [daily updateAttrsFromServerData:data];
    
    id m = [data objectForKey:@"meds"];
    if (m && ![m isKindOfClass:[NSNull class]]) {
        id meds = [m dataUsingEncoding: NSUTF8StringEncoding];
        [daily update:@"meds" value:meds];
    }
    
    [daily publish:EVENT_USERDAILYDATA_UPDATED_FROM_SERVER data:daily.date];
    [daily pushToHealthKit];
    return daily;
}

- (BOOL)hasData {
    return  (self.weight || self.temperature > 0 || self.cervicalMucus ||
             self.intercourse || self.moods || self.physicalDiscomfort ||
             self.ovulationTest || self.pregnancyTest || self.smoke ||
             self.alcohol || self.exercise || self.cervical || self.periodFlow ||
             self.meds || self.stressLevel || self.physicalSymptom1 || self.physicalSymptom2 ||
             self.emotionalSymptom1 || self.emotionalSymptom2 || self.sleep || self.erection ||
             self.masturbation || self.heatSource || self.fever);
}
- (BOOL)hasPositiveData {
    return  (self.weight || self.temperature > 0 ||
             ((self.cervicalMucus & 0xff) > 5 || ((self.cervicalMucus >> 8) & 0xff) > 5) ||
             self.intercourse > 1 || self.moods > 2 || self.physicalDiscomfort > 2 ||
             (self.ovulationTest % BRAND_MASK ) || (self.pregnancyTest % BRAND_MASK) || self.smoke > 1 ||
             self.alcohol > 1 || self.exercise > 1|| self.cervical ||
             self.periodFlow > 1 || self.stressLevel > 1 || self.physicalSymptom1 > 0 || self.physicalSymptom2 > 0 ||
             self.emotionalSymptom1 > 0 || self.emotionalSymptom2 > 0 || self.sleep > 0 || self.fever > 1);
}


- (NSUInteger)dataHash {
    NSString *dataStr = [NSString stringWithFormat:@"%@%@ - %f%f - %lld%lld%lld - %d%d%d%d - %lld%d%d%d%d - %lld%lld%lld%lld - %lld %hd",
                         self.user.id, self.date,
                         self.weight, self.temperature, self.intercourse,
                         self.moods, self.physicalDiscomfort,
                         self.ovulationTest, self.pregnancyTest, self.smoke, self.alcohol,
                         self.exercise, self.cervical, self.periodFlow, self.cervicalMucus,
                         self.stressLevel,
                         self.physicalSymptom1, self.physicalSymptom2, self.emotionalSymptom1, self.emotionalSymptom2, self.sleep, self.fever];
    return [dataStr hash];
}

- (BOOL)hasSex {
    return self.intercourse > 1;
}

- (NSDictionary *)medsLog {
    if (self.meds) {
        NSDictionary *ml = [NSJSONSerialization JSONObjectWithData:self.meds
                                                           options:0
                                                             error:nil];
        return ml;
    }
    return @{};
}

- (void)logMed:(NSString *)medName withValue:(id)val {
    NSDictionary *logged = [self medsLog];
    NSMutableDictionary *mLogged = [NSMutableDictionary dictionaryWithDictionary:logged];
    mLogged[medName] = val;
    id data = [NSJSONSerialization dataWithJSONObject:mLogged options:0 error:nil];
    [self update:DL_CELL_KEY_MEDS value:data];
}

+ (BOOL)hasDataForDate:(NSString *)date forUser:(User *)user {
    UserDailyData *d = [UserDailyData getUserDailyData:date forUser:user];
    return !d? NO: [d hasData];
}

+ (BOOL)hasSexForDate:(NSString *)date forUser:(User*)user {
    UserDailyData *d = [UserDailyData getUserDailyData:date forUser:user];
    return d && d.intercourse > 1;
}

+ (id)tset:(NSString *)date forUser:(User *)user {
    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"UserDailyData tset %@", date]];
    DataStore *ds = user.dataStore;
    UserDailyData *daily = (UserDailyData *)[self fetchObject:@{
                                                                @"user.id" : user.id,
                                                                @"date" : date
                                                                } dataStore:ds];
    if (!daily) {
        daily = [UserDailyData newInstance:ds];
        daily.date = date;
        daily.nsdate = [Utils dateWithDateLabel:date];
        daily.user = user;
    }
    return daily;
}

+ (void)clearDataOnZeroDate
{
    User *user = [User currentUser];
    if (!user) {
        return;
    }
    DataStore *ds = user.dataStore;
    UserDailyData *data = (UserDailyData *)[self fetchObject:@{
                                                                @"user.id" : user.id,
                                                                @"date" : @"0000/00/00"
                                                                } dataStore:ds];
    if (data) {
        [UserDailyData deleteInstance:data];
    }
    if (user.partner) {
        UserDailyData *partnerData = (UserDailyData *)[self fetchObject:@{
                                                                   @"user.id" : user.partner.id,
                                                                   @"date" : @"0000/00/00"
                                                                   } dataStore:ds];
        if (partnerData) {
            [UserDailyData deleteInstance:partnerData];
        }
    }
}

- (void)setDirty:(BOOL)val {
    [super setDirty:val];
    if (val) {
        self.user.dirty = YES;
        
    }
}

+ (void)translateArchivedPeriodValueForPeriods:(NSArray*)historicalPeriods
                                          user:(User*)user{
    for (UserDailyData *daily in historicalPeriods) {
        if (13 == daily.period ) {
            [daily update:@"period" value:@((3 << ARCHIVED_PERIOD_SHIFT))];
        }
        else if (11 == daily.period) {
            [daily update:@"period" value:@((1 << ARCHIVED_PERIOD_SHIFT))];
        }
    }
    [user save];
}

- (void)updatePeriodWithValue:(NSNumber *)val {
    int period = (((self.period >> ARCHIVED_PERIOD_SHIFT) << ARCHIVED_PERIOD_SHIFT) | [val intValue]);
    [self update:@"period" value:@(period)];
}

- (void)updateArchivedPeriod {
    int period = ((self.period % 4) << ARCHIVED_PERIOD_SHIFT);
    [self update:@"period" value:@(period)];
}

- (void)update:(NSString *)attr value:(NSObject *)val {
    /*
     * Main interface for UserDailyData update value
     * If attr is "notes", the input value will be a NSDictionary
     */
    
    if ([attr isEqualToString:@"notes"]) {
        NSString *serizlizedNotes = [Utils jsonStringify:val];
        [super update:attr value:serizlizedNotes];
    } else {
        [super update:attr value:val];
    }
    
    if ([attr isEqual:@"period"] && self.user.firstPb.date &&
        [Utils daysBeforeDateLabel:self.user.firstPb.date sinceDateLabel:
         self.date] >= 0 &&
        [((NSNumber*)val) intValue] % 4 == 1) {
        self.user.firstPb = nil;
    }
    if ([attr isEqualToString:@"temperature"]) {
        [self publish:EVENT_CHART_NEEDS_UPDATE_TEMP];
    }
    if ([attr isEqualToString:@"weight"] && [self belongsToCurrentUser]) {
        [self publish:EVENT_CHART_NEEDS_UPDATE_WEIGHT];
    }
//    
//    [self pushToHealthKitForKey:attr value:val];
}

- (BOOL)belongsToCurrentUser
{
    return self.user == [User currentUser];
}

- (NSMutableDictionary *)createPushRequest {
    NSMutableDictionary *request = [super createPushRequest];
    [request setObject:self.date forKey:@"date"];
    [request setObject:self.user.id forKey:@"user_id"];
    
    NSString *medsString = [[NSString alloc] initWithData:self.meds
                                                 encoding:NSUTF8StringEncoding];
    [request setObject:medsString forKey:@"meds"];
    
    return request;
}

-(DataStore *)dataStore {
    return self.user.dataStore;
}

+ (void)enforcePeriod:(NSArray*)prediction forUser:(User*)dataStoreHolder
{
    NSArray *dailyDataWithPeriod = [UserDailyData getDailyDataWithPeriodForUser:dataStoreHolder];
    for (UserDailyData *dailyData in dailyDataWithPeriod) {
        [dailyData update:@"period" value:0];
    }
    
    BOOL updated = NO;
    NSString *today = [Utils dailyDataDateLabel:[NSDate date]];
    for (NSDictionary *p in prediction) {
        NSString *pb = p[@"pb"];
        NSString *pe = [Utils dateLabelAfterDateLabel:p[@"pe"] withDays:1];
        if ([Utils daysBeforeDateLabel:pb sinceDateLabel:today] > 0 ) {
            break;
        }
        UserDailyData *dailyData = [UserDailyData tset:pb forUser:dataStoreHolder];
        if (dailyData.period != LOG_VAL_PERIOD_BEGAN) {
            [dailyData update:@"period" value:@(LOG_VAL_PERIOD_BEGAN)];
            updated = YES;
        }
        dailyData = [UserDailyData tset:pe forUser:dataStoreHolder];
        if (dailyData.period != LOG_VAL_PERIOD_ENDED) {
            [dailyData update:@"period" value:@(LOG_VAL_PERIOD_ENDED)];
            updated = YES;
        }
    }
    if (updated)
        [dataStoreHolder save];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return 0;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *dailyDataDict = [NSMutableDictionary dictionary];
    for (NSString *serverAttr in self.attrMapper) {
        NSString *clientAttr = [self.attrMapper objectForKey:serverAttr];
        id value = [self valueForKey:clientAttr];
        if (value) {
            [dailyDataDict setObject:value forKey:clientAttr];
        }
    }
    return dailyDataDict;
}

+ (NSArray *)userDailyDataToDict:(NSArray *)sortedDailyData {
    NSMutableArray *dailyDataArray = [NSMutableArray arrayWithCapacity:[sortedDailyData count]];
    for (UserDailyData *dailyData in sortedDailyData) {
        NSMutableDictionary *dailyDataDict = [NSMutableDictionary dictionaryWithCapacity: [dailyData.attrMapper count]];
        for (NSString *attr in [dailyData attrMapper]) {
            id value = [dailyData valueForKey:[dailyData.attrMapper objectForKey:attr]];
            if (value) {
                [dailyDataDict setObject:value forKey:attr];
            }
        }
        [dailyDataArray addObject:dailyDataDict];
    }
    return dailyDataArray;
}

+ (NSArray *)userDailyDataInWeek:(NSDate *)date forUser:(User *)user {
    // return an array, with length = 7
    int start = 1 - [date getWeekDay];
    
    NSMutableArray * result = [[NSMutableArray alloc] init];
    NSString * dateLabel = [date toDateLabel];
    for (int i=0; i<7; i++) {
        NSString * l = [Utils dateLabelAfterDateLabel:dateLabel withDays:i+start];
        UserDailyData * d = [UserDailyData getUserDailyData:l forUser:user];
        [result addObject:([d hasData] ? d : [NSNull null])];
    }
    return result;
}

@end
