//
//  UserDailyData+HealthKit.m
//  emma
//
//  Created by Peng Gu on 12/3/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UserDailyData+HealthKit.h"
#import "HealthKitManager.h"
#import "User.h"
#import <HealthKit/HealthKit.h>

@implementation UserDailyData (HealthKit)


#pragma mark - Pull from healthkit

+ (void)pullFromHealthKitForDate:(NSDate *)date
{
    if (![HealthKitManager haveHealthKit] || ![HealthKitManager connected]) {
        return;
    }
    
    HealthKitManager *healthKit = [HealthKitManager sharedInstance];
    if (!healthKit.isConnected) {
        return;
    }
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    dispatch_group_t pullGroup = dispatch_group_create();
    
    dispatch_group_enter(pullGroup);
    [healthKit pullWeightWithDate:date found:^(NSNumber *value) {
        data[HEALTHKIT_KEY_WEIGHT] = value;
        dispatch_group_leave(pullGroup);
    } notFound:^{
        dispatch_group_leave(pullGroup);
    }];
    
    dispatch_group_enter(pullGroup);
    [healthKit pullSleepWithDate:date found:^(NSNumber *value) {
        data[HEALTHKIT_KEY_SLEEP] = value;
        dispatch_group_leave(pullGroup);
    } notFound:^{
        dispatch_group_leave(pullGroup);
    }];
    
    dispatch_group_enter(pullGroup);
    [healthKit pullExerciseWithDate:date found:^(NSNumber *value) {
        NSInteger exercise = 0;
        if (value.integerValue >= 60 * 60) {
            exercise = 16;
        }
        else if (value.integerValue >= 30 * 60) {
            exercise = 8;
        }
        else if (value.integerValue >= 15 * 60) {
            exercise = 4;
        }
        else if (value.integerValue > 0) {
            exercise = 2;
        }
        
        data[HEALTHKIT_KEY_EXERCISE] = @(exercise);
        dispatch_group_leave(pullGroup);
    } notFound:^{
        dispatch_group_leave(pullGroup);
    }];
    
    if (IOS9_OR_ABOVE) {
        dispatch_group_enter(pullGroup);
        [healthKit pullBasalBodyTemperatureWithDate:date found:^( NSNumber * _Nonnull value) {
            data[HEALTHKIT_KEY_BBT] = value;
            dispatch_group_leave(pullGroup);
        } notFound:^{
            dispatch_group_leave(pullGroup);
        }];
    
        dispatch_group_enter(pullGroup);
        [healthKit pullCervicalMucusWithDate:date found:^(NSNumber *_Nonnull value) {
            data[HEALTHKIT_KEY_CERVICAL_MUCUS] = value;
            dispatch_group_leave(pullGroup);
        } notFound:^{
            dispatch_group_leave(pullGroup);
        }];
        
        dispatch_group_enter(pullGroup);
        [healthKit pullIntercourseWithDate:date found:^(NSNumber *_Nonnull value) {
            data[HEALTHKIT_KEY_INTERCOURSE] = value;
            dispatch_group_leave(pullGroup);
        } notFound:^{
            dispatch_group_leave(pullGroup);
        }];
        
        dispatch_group_enter(pullGroup);
        [healthKit pullSpottingWithDate:date found:^(NSNumber *_Nonnull value) {
            data[HEALTHKIT_KEY_PERIOD_FLOW] = value;
            dispatch_group_leave(pullGroup);
        } notFound:^{
            dispatch_group_leave(pullGroup);
        }];
    }
    
    dispatch_group_notify(pullGroup, dispatch_get_main_queue(), ^{
        if (data.count <= 0) {
            return;
        }
        
        UserDailyData *dailyData = [UserDailyData tset:[Utils dailyDataDateLabel:date]
                                               forUser:[User currentUser]];
        
        BOOL didUpdate = NO;
        for (NSString *key in data) {
            didUpdate = [dailyData update:key valueFromHealthKit:data[key]];
        }
        
        if (didUpdate) {
            [dailyData save];
            [dailyData publish:EVENT_USERDAILYDATA_PULLED_FROM_HEALTH_KIT data:date];
        }
    });
}


- (BOOL)update:(NSString *)key valueFromHealthKit:(NSNumber *)value
{
    NSNumber *localValue = [self valueForKey:key];
    if (localValue && localValue.integerValue != 0) {
        NSLog(@"peng debug: %@, %@, %@", key, value, localValue);
        return NO;
    }
    
    NSDictionary *eventData = @{@"key": key,
                                @"value_from_hk": value,
                                @"value_in_db": @(localValue.integerValue),
                                @"date": self.date};
    
    [Logging log:HEALTHKIT_PULL_DATA eventData:eventData];
    [self update:key value:value];
    
    return YES;
}


NS_INLINE float numberRoundToTwo(NSNumber *number)
{
    if (!number) {
        return 0;
    }
    return roundf(100 * number.floatValue) / 100;
}


#pragma mark - Push to healthkit

- (NSArray *)pushableKeys
{
    return @[DL_CELL_KEY_BBT, DL_CELL_KEY_CM, DL_CELL_KEY_OVTEST,
             DL_CELL_KEY_INTERCOURSE, DL_CELL_KEY_PERIOD_FLOW];
}


- (void)pushToHealthKit
{
    for (NSString *key in [self pushableKeys]) {
        NSNumber *value = [self valueForKey:key];
        if (value) {
            [self pushToHealthKitForKey:key value:value];
        }
    }
}


- (void)pushToHealthKitForKey:(NSString *)key value:(NSNumber *)valueToPush
{
    if (!IOS9_OR_ABOVE) {
        return;
    }
    
    if (![valueToPush isKindOfClass:[NSNumber class]]) {
        return;
    }
    
    NSArray *keys = [self pushableKeys];
    if (![keys containsObject:key]) {
        return;
    }
    
    NSDate *date = [Utils dateWithDateLabel:self.date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    date = [calendar dateBySettingHour:12 minute:0 second:0 ofDate:date options:0];
    if ([Utils date:date isSameDayAsDate:[NSDate date]]) {
        date = [NSDate date];
    }
    
    HealthKitManager *hk = [HealthKitManager sharedInstance];
    if (!hk.connected) {
        return;
    }
    
    if ([key isEqual:DL_CELL_KEY_BBT]) {
        [hk pushTemperature:[valueToPush floatValue] withDate:date];
    }
    else if ([key isEqual:DL_CELL_KEY_CM]) {
        [hk pushCervicalMucus:valueToPush onDate:date];
    }
    else if ([key isEqual:DL_CELL_KEY_OVTEST]) {
        [hk pushOvulatioinTest:valueToPush onDate:date];
    }
    else if ([key isEqual:DL_CELL_KEY_INTERCOURSE]) {
        [hk pushIntercourse:valueToPush onDate:date];
    }
    else if ([key isEqual:DL_CELL_KEY_PERIOD_FLOW]) {
        [hk pushSpotting:valueToPush onDate:date];
    }
}


@end






