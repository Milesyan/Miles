//
//  GLAPHealthKit.h
//  kaylee
//
//  Created by Bob on 14-9-16.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^PullFromHealthKitFound)(NSNumber *value);
typedef void(^PullFromHealthKitNotFound)();

@interface HealthKitManager : NSObject

@property (nonatomic, readonly, getter = isConnected) BOOL connected;

+ (instancetype)sharedInstance;

+ (BOOL)connected;
+ (BOOL)haveHealthKit;
- (void)connect;
- (void)disconnect;

#pragma mark - Pull

- (void)pullWeightWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound;
- (void)pullSleepWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound;
- (void)pullExerciseWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound;

- (void)pullBasalBodyTemperatureWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound;
- (void)pullCervicalMucusWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound;
- (void)pullIntercourseWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound;
- (void)pullSpottingWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound;

#pragma mark - Push

- (void)pushHeight:(int)heightInCM;

- (void)pushTemperature:(float)temperatureInCelcius withDate:(NSDate *)date;
- (void)pushCervicalMucus:(NSNumber *)value onDate:(NSDate *)date;
- (void)pushIntercourse:(NSNumber *)value onDate:(NSDate *)date;
- (void)pushSpotting:(NSNumber *)value onDate:(NSDate *)date;
- (void)pushOvulatioinTest:(NSNumber *)value onDate:(NSDate *)date;

- (void)pushPeriods;

@end
