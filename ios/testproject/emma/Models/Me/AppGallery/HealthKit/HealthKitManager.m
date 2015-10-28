
//
//  GLAPHealthKit.m
//  kaylee
//
//  Created by Bob on 14-9-16.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import "HealthKitManager.h"
#import "User.h"
#import <HealthKit/HealthKit.h>
#import "HKHealthStore+Util.h"
#import "DailyLogConstants.h"
#import "UserDailyData+HealthKit.h"

static NSString *HealthEnabledAccountID = @"HealthEnabledAccountID";

@interface HealthKitManager ()
@property (nonatomic) HKHealthStore *healthStore;
@end

@implementation HealthKitManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}


+ (BOOL)haveHealthKit
{
    return [HKHealthStore isHealthDataAvailable];
}


- (instancetype)init
{
    self = [super init];
    if (self && [[self class] haveHealthKit]) {
        self.healthStore = [[HKHealthStore alloc] init];
        
//        if (IOS9_OR_ABOVE) {
//            [self subscribe:EVENT_PREDICTION_UPDATE selector:@selector(pushPeriods)];
//        }
        return self;
    }
    return nil;
}


- (void)dealloc
{
//    if (IOS9_OR_ABOVE) {
//        [self unsubscribe:EVENT_PREDICTION_UPDATE];
//    }
}


#pragma mark - Connections
- (void)connect
{
    NSSet *writeDataTypes = [self dataTypesToWrite];
    NSSet *readDataTypes = [self dataTypesToRead];
    
    @weakify(self)
    [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
        @strongify(self);
        
        if (error || !success) {
            GLLog(@"You didn't allow HealthKit to access these read/write data types. The error was: %@. If you're using a simulator, try it on a device.", error);
            [Utils setDefaultsForKey:HealthEnabledAccountID withValue:@0];
            [Logging log:HEALTHKIT_ASK_PERMISSION eventData:@{@"result": @0}];
        }
        else {
            [Utils setDefaultsForKey:HealthEnabledAccountID withValue:[User currentUser].id];
            [Logging log:HEALTHKIT_ASK_PERMISSION eventData:@{@"result": @1}];
            
            
            // push height to health kit
            [self pushHeight:[User currentUser].settings.height];
            
            [UserDailyData pullFromHealthKitForDate:[NSDate date]];
            [UserDailyData pullFromHealthKitForDate:[Utils dateByAddingDays:-1 toDate:[NSDate date]]];
            
            if (IOS9_OR_ABOVE) {
                [self.healthStore deleteAllDataWithCompletion:^(BOOL success) {
                    for (UserDailyData *each in [User currentUser].dailyData) {
                        [each pushToHealthKit];
                    }
                    [self pushPeriods];
                }];
            }

        }
    }];
}


+ (BOOL)connected
{
    if ([NSThread isMainThread]) {
        return [[Utils getDefaultsForKey:HealthEnabledAccountID] isEqual:[User currentUser].id];
    }
    
    __block NSNumber *currentUserID = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        currentUserID = [User currentUser].id;
    });
    
    if (!currentUserID) {
        return NO;
    }
    return [[Utils getDefaultsForKey:HealthEnabledAccountID] isEqual:currentUserID];;
}


- (BOOL)isConnected
{
    return [[self class] connected];
}


- (void)disconnect
{
    [Utils setDefaultsForKey:HealthEnabledAccountID withValue:@0];
}


#pragma mark - HealthKit Permissions
- (NSSet *)dataTypesToWrite
{
    NSMutableSet *types = [NSMutableSet setWithObjects:
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight], nil];

    if (IOS9_OR_ABOVE) {
        [types addObjectsFromArray:[HKHealthStore pushableReproductiveHealthTypes]];
    }
    
    return types;
}

- (NSSet *)dataTypesToRead
{
    NSMutableSet *types = [NSMutableSet setWithObjects:
                           [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],
                           [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis],
                           [HKObjectType workoutType], nil];
    
    if (IOS9_OR_ABOVE) {
        [types addObjectsFromArray:[HKHealthStore pullableReproductiveHealthTypes]];
    }
    
    return types;
}


#pragma mark - Pull
- (void)pullBasalBodyTemperatureWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound
{
    [self.healthStore mostRecentQuantitySampleForTypeIdentifier:HKQuantityTypeIdentifierBasalBodyTemperature
                                                         onDate:date
                                                        success:^(HKQuantitySample *sample)
    {
        HKUnit *unit = [HKUnit degreeCelsiusUnit];
        found(@([sample.quantity doubleValueForUnit:unit]));
    } notFound:^{
        notFound();
    }];
}

- (void)pullCervicalMucusWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound
{
    [self.healthStore mostRecentCategorySampleForTypeIdentifier:HKCategoryTypeIdentifierCervicalMucusQuality
                                                         onDate:date
                                                        success:^(HKCategorySample *sample)
    {
        NSInteger offset = 1280;
        NSDictionary *mapping = @{
                                  @(HKCategoryValueCervicalMucusQualityDry): @(offset + CM_TEXTURE_DRY),
                                  @(HKCategoryValueCervicalMucusQualitySticky): @(offset + CM_TEXTURE_STICKY),
                                  @(HKCategoryValueCervicalMucusQualityWatery): @(offset + CM_TEXTURE_WATERY),
                                  @(HKCategoryValueCervicalMucusQualityEggWhite): @(offset + CM_TEXTURE_EGGWHITE),
                                  @(HKCategoryValueCervicalMucusQualityCreamy): @(offset + CM_TEXTURE_CREAMY),
                                  };
        NSNumber *value = mapping[@(sample.value)];
        if (value) {
            found(value);
        }
        else {
            notFound();
        }
    } notFound:^{
        notFound();
    }];
}


- (void)pullIntercourseWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound
{
    [self.healthStore mostRecentCategorySampleForTypeIdentifier:HKCategoryTypeIdentifierSexualActivity
                                                         onDate:date
                                                        success:^(HKCategorySample *sample)
    {
        BOOL protectionUsed = [sample.metadata[HKMetadataKeySexualActivityProtectionUsed] boolValue];
        found(@(protectionUsed ? INTERCOURSE_NORMAL : INTERCOURSE_WITHOUT_PROTECTION));
    } notFound:^{
        notFound();
    }];
}

- (void)pullSpottingWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound
{
    [self.healthStore mostRecentCategorySampleForTypeIdentifier:HKCategoryTypeIdentifierIntermenstrualBleeding
                                                         onDate:date
                                                        success:^(HKCategorySample *sample)
    {
        found(@(SPOTTING_YES));
    } notFound:^{
        notFound();
    }];
}


- (void)pullWeightWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound
{
    [self.healthStore mostRecentQuantitySampleForTypeIdentifier:HKQuantityTypeIdentifierBodyMass
                                                         onDate:date
                                                        success:^(__kindof HKSample *sample)
    {
        HKUnit *unit = [HKUnit unitFromMassFormatterUnit:NSMassFormatterUnitKilogram];
        CGFloat value = [[(HKQuantitySample *)sample quantity] doubleValueForUnit:unit];
        found(@(value));
    } notFound:^{
        notFound();
    }];
}

- (void)pullSleepWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound
{
    [self.healthStore categorySamplesForTypeIdentifier:HKCategoryTypeIdentifierSleepAnalysis
                                                onDate:date
                                               success:^(NSArray<__kindof HKSample *> *samples)
    {
        NSTimeInterval total = 0;
        for (HKCategorySample *sample in samples) {
            if (sample.value == HKCategoryValueSleepAnalysisAsleep) {
                NSDate *startTime = sample.startDate;
                NSDate *endTime = sample.endDate;
                total += [endTime timeIntervalSinceDate:startTime];
            }
        }
        
        found(@(total));
    } notFound:^{
        notFound();
    }];
}


- (void)pullExerciseWithDate:(NSDate *)date found:(PullFromHealthKitFound)found notFound:(PullFromHealthKitNotFound)notFound
{
    HKWorkoutType *type = [HKWorkoutType workoutType];
    NSPredicate *predicate = [HKQuery predicateForWorkoutsWithOperatorType:NSGreaterThanPredicateOperatorType duration:0];
    
    [self.healthStore samplesForType:type predicate:predicate limit:HKObjectQueryNoLimit
                             success:^(NSArray<__kindof HKSample *> *samples)
    {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSTimeInterval timeInterval = [[calendar startOfDayForDate:date] timeIntervalSince1970];
        NSTimeInterval total = 0;
        
        for (HKWorkout *workout in samples) {
            if (workout.startDate.timeIntervalSince1970 >= timeInterval &&
                workout.endDate.timeIntervalSince1970 <= timeInterval + 24 * 3600) {
                total += workout.duration;
            }
        }
        
        found(@(total));
    } notFound:^{
        notFound();
    }];
}



#pragma mark - push
- (void)pushHeight:(int)heightInCM
{
    if (![self canWriteQuantityType:HKQuantityTypeIdentifierHeight]) {
        return;
    }
    
    HKUnit *unit = [HKUnit unitFromLengthFormatterUnit:NSLengthFormatterUnitCentimeter];
    HKQuantity *quantity = [HKQuantity quantityWithUnit:unit doubleValue:heightInCM];
    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];

    [self.healthStore saveQuantity:quantity withType:type date:[NSDate date]];
    
    NSDictionary *data = @{@"key": HEALTHKIT_KEY_HEIGHT,
                           @"value": @(heightInCM),
                           @"date": [Utils dailyDataDateLabel:[NSDate date]]};
    [Logging log:HEALTHKIT_PUSH_DATA eventData:data];
}


- (void)pushTemperature:(float)temperatureInCelcius withDate:(NSDate *)date
{
    if (![self canWriteQuantityType:HKQuantityTypeIdentifierBasalBodyTemperature]) {
        return;
    }
    
    [self.healthStore recentSavedQuantitySamplesForTypeIdentifier:HKQuantityTypeIdentifierBasalBodyTemperature
                                                         onDate:date
                                                        success:^(NSArray<__kindof HKSample *> *samples)
     {
         [self.healthStore deleteObjects:samples withCompletion:^(BOOL success, NSError * _Nullable error) {
             [self saveTemperature:temperatureInCelcius onDate:date];
         }];
     } notFound:^{
         [self saveTemperature:temperatureInCelcius onDate:date];
     }];
}


- (void)saveTemperature:(float) temperatureInCelcius onDate:(NSDate *)date
{
    if (temperatureInCelcius == 0) {
        return;
    }
    
    HKUnit *unit = [HKUnit degreeCelsiusUnit];
    HKQuantity *quantity= [HKQuantity quantityWithUnit:unit doubleValue:temperatureInCelcius];
    
    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalBodyTemperature];
    [self.healthStore saveQuantity:quantity withType:type date:date];
}


- (void)pushCervicalMucus:(NSNumber *)value onDate:(NSDate *)date
{
    if (![self canWriteCategoryType:HKCategoryTypeIdentifierCervicalMucusQuality]) {
        return;
    }
    
    [self.healthStore recentSavedCategorySamplesForTypeIdentifier:HKCategoryTypeIdentifierCervicalMucusQuality
                                                         onDate:date
                                                        success:^(NSArray<__kindof HKSample *> *samples)
     {
         [self.healthStore deleteObjects:samples withCompletion:^(BOOL success, NSError * _Nullable error) {
             [self saveCervicalMucus:value onDate:date];
         }];
     } notFound:^{
         [self saveCervicalMucus:value onDate:date];
     }];
}


- (void)saveCervicalMucus:(NSNumber *)value onDate:(NSDate *)date
{
    if (value.integerValue == 0) {
        return;
    }
    
    NSDictionary *mapping = @{
                              @(CM_TEXTURE_DRY): @(HKCategoryValueCervicalMucusQualityDry),
                              @(CM_TEXTURE_STICKY): @(HKCategoryValueCervicalMucusQualitySticky),
                              @(CM_TEXTURE_WATERY): @(HKCategoryValueCervicalMucusQualityWatery),
                              @(CM_TEXTURE_EGGWHITE): @(HKCategoryValueCervicalMucusQualityEggWhite),
                              @(CM_TEXTURE_CREAMY): @(HKCategoryValueCervicalMucusQualityCreamy),
                              };
    NSInteger mucus = [mapping[@(value.integerValue & 0xff)] integerValue];
    if (mucus == 0) {
        mucus = HKCategoryValueCervicalMucusQualityDry;
    }
    
    NSString *type = HKCategoryTypeIdentifierCervicalMucusQuality;
    [self.healthStore saveCategoryWithIdentifier:type value:mucus date:date meta:nil];
}


- (void)pushIntercourse:(NSNumber *)value onDate:(NSDate *)date
{
    if (![self canWriteCategoryType:HKCategoryTypeIdentifierSexualActivity]) {
        return;
    }
    
    [self.healthStore recentSavedCategorySamplesForTypeIdentifier:HKCategoryTypeIdentifierSexualActivity
                                                         onDate:date
                                                        success:^(NSArray<__kindof HKSample *> *samples)
     {
         [self.healthStore deleteObjects:samples withCompletion:^(BOOL success, NSError * _Nullable error) {
             [self saveIntercourse:value onDate:date];
         }];
     } notFound:^{
         [self saveIntercourse:value onDate:date];
     }];
}


- (void)saveIntercourse:(NSNumber *)value onDate:(NSDate *)date
{
    if (value.integerValue >= INTERCOURSE_NORMAL) {
        NSString *type = HKCategoryTypeIdentifierSexualActivity;
        NSDictionary *meta = nil;
        if (value.integerValue > INTERCOURSE_NORMAL) {
            BOOL protected = value.integerValue != INTERCOURSE_WITHOUT_PROTECTION;
            meta = @{HKMetadataKeySexualActivityProtectionUsed: @(protected)};
        }
        
        [self.healthStore saveCategoryWithIdentifier:type value:HKCategoryValueNotApplicable
                                                date:date meta:meta];
    }
}


- (void)pushSpotting:(NSNumber *)value onDate:(NSDate *)date
{
    if (![self canWriteCategoryType:HKCategoryTypeIdentifierIntermenstrualBleeding]) {
        return;
    }
    
    [self.healthStore recentSavedCategorySamplesForTypeIdentifier:HKCategoryTypeIdentifierIntermenstrualBleeding
                                                         onDate:date
                                                        success:^(NSArray<__kindof HKSample *> *samples)
     {
         [self.healthStore deleteObjects:samples withCompletion:^(BOOL success, NSError * _Nullable error) {
             [self saveSpotting:value onDate:date];
         }];
     } notFound:^{
         [self saveSpotting:value onDate:date];
     }];
}


- (void)saveSpotting:(NSNumber *)value onDate:(NSDate *)date
{
    if (value.integerValue >= SPOTTING_YES) {
        NSString *type = HKCategoryTypeIdentifierIntermenstrualBleeding;
        
        [self.healthStore saveCategoryWithIdentifier:type value:HKCategoryValueNotApplicable
                                                date:date meta:nil];
    }
}


- (void)pushOvulatioinTest:(NSNumber *)value onDate:(NSDate *)date
{
    if (![self canWriteCategoryType:HKCategoryTypeIdentifierOvulationTestResult]) {
        return;
    }
    
    [self.healthStore recentSavedCategorySamplesForTypeIdentifier:HKCategoryTypeIdentifierOvulationTestResult
                                                         onDate:date
                                                        success:^(NSArray<__kindof HKSample *> *samples)
     {
         [self.healthStore deleteObjects:samples withCompletion:^(BOOL success, NSError * _Nullable error) {
             [self saveOvulatioinTest:value onDate:date];
         }];
     } notFound:^{
         [self saveOvulatioinTest:value onDate:date];
     }];
}


- (void)saveOvulatioinTest:(NSNumber *)value onDate:(NSDate *)date
{
    if (value.integerValue > 0) {
        NSInteger testValue = value.integerValue % BRAND_MASK;
        NSInteger testResult = 0;
        if (testValue == OVULATION_TEST_YES) {
            testResult = HKCategoryValueOvulationTestResultPositive;
        }
        else if (testValue == OVULATION_TEST_NO) {
            testResult = HKCategoryValueOvulationTestResultNegative;
        }
        else if (testValue == OVULATION_TEST_HIGH) {
            testResult = HKCategoryValueOvulationTestResultIndeterminate;
        }
        
        if (testResult == 0) {
            return;
        }
        
        NSString *type = HKCategoryTypeIdentifierOvulationTestResult;
        [self.healthStore saveCategoryWithIdentifier:type value:testResult date:date meta:nil];
    }
}


#pragma mark - periods

- (void)pullPeriodsWithCompletion:(void (^)(NSArray<__kindof HKSample *> *))completion
{
    HKCategoryType *type = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierMenstrualFlow];
    NSPredicate *predicate = [HKQuery predicateForObjectsFromSource:[HKSource defaultSource]];
    
    [self.healthStore samplesForType:type predicate:predicate limit:HKObjectQueryNoLimit
                             success:^(NSArray<__kindof HKSample *> *samples)
     {
         completion(samples);
     } notFound:^{
         completion(nil);
     }];
}


- (void)deletePeriodsWithCompletion:(void (^)(BOOL))completion
{
//    HKCategoryType *type = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierMenstrualFlow];
//    NSPredicate *predicate = [HKQuery predicateForObjectsFromSource:[HKSource defaultSource]];
//    
//    [self.healthStore deleteObjectsOfType:type predicate:predicate withCompletion:^(BOOL success, NSUInteger deletedObjectCount, NSError * _Nullable error) {
//        
//    }];
    
    // The above code won't work at the time of writing, should be an Apple's bug
    // To work around, pull period first and delete them
    
    [self pullPeriodsWithCompletion:^(NSArray<__kindof HKSample *> *samples) {
        if (samples.count == 0) {
            completion(YES);
        }
        
        [self.healthStore deleteObjects:samples withCompletion:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"Peng debug deleted %ld objects in health kit", samples.count);
            completion(success);
        }];
    }];
}


- (void)pushPeriods
{
    if (![self canWriteCategoryType:HKCategoryTypeIdentifierMenstrualFlow]) {
        return;
    }
    
    [self deletePeriodsWithCompletion:^(BOOL success) {
        if (success) {
            NSArray *samples = [self makePeriodSamplesFromLocal];
            [self.healthStore saveObjects:samples
                           withCompletion:^(BOOL success, NSError * _Nullable error)
            {
                NSLog(@"Peng debug saved %ld period records into health kit", samples.count);
            }];
        }
    }];
}


- (NSArray *)makePeriodSamplesFromLocal
{
    HKCategoryType *type = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierMenstrualFlow];
    NSDictionary *meta = @{HKMetadataKeyMenstrualCycleStart: @(YES)};
    NSInteger value = HKCategoryValueMenstrualFlowUnspecified;
    
    NSArray *periods = [[User currentUser] prediction];
    NSMutableArray *samples = [NSMutableArray array];
    NSDate *today = [NSDate date];
    
    for (NSDictionary *each in periods) {
        NSDate *startDate = [Utils dateWithDateLabel:each[@"pb"]];
        NSDate *endDate = [Utils dateWithDateLabel:each[@"pe"]];
        
        if ([startDate timeIntervalSinceDate:today] > 0) {
            break;
        }
        
        HKCategorySample *sample = [HKCategorySample categorySampleWithType:type
                                                                      value:value
                                                                  startDate:startDate
                                                                    endDate:endDate
                                                                   metadata:meta];
        [samples addObject:sample];
    }
    return samples;
}


- (BOOL)canWriteCategoryType:(NSString *)typeIdentifier
{
    return self.isConnected && [self.healthStore canWriteCategoryType:typeIdentifier];
}

- (BOOL)canWriteQuantityType:(NSString *)typeIdentifier
{
    return self.isConnected && [self.healthStore canWriteQuantityType:typeIdentifier];
}

@end






