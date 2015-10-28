//
//  HKHealthStore+Util.m
//  emma
//
//  Created by Peng Gu on 8/19/15.
//  Copyright © 2015 Upward Labs. All rights reserved.
//

#import "HKHealthStore+Util.h"


@implementation HKHealthStore (Util)

+ (NSArray<HKObjectType *> *)pullableReproductiveHealthTypes
{
    return @[ [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalBodyTemperature],
              [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierCervicalMucusQuality],
              [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSexualActivity],
              [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierIntermenstrualBleeding]];
}

+ (NSArray<HKObjectType *> *)pushableReproductiveHealthTypes
{
    return @[ [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalBodyTemperature],
              [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierCervicalMucusQuality],
              [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierMenstrualFlow],
              [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierOvulationTestResult],
              [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierSexualActivity],
              [HKObjectType categoryTypeForIdentifier:HKCategoryTypeIdentifierIntermenstrualBleeding]];
}


- (NSPredicate *)predicateForSamplesOnDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *startDate = [calendar startOfDayForDate:date];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    
    return [HKQuery predicateForSamplesWithStartDate:startDate
                                             endDate:endDate
                                             options:HKQueryOptionStrictEndDate];
}

#pragma mark - category

- (void)samplesForType:(HKSampleType *)type
             predicate:(NSPredicate *)predicate
                 limit:(NSUInteger)limit
               success:(void (^)(NSArray<__kindof HKSample *> *))success
              notFound:(void (^)())notFound;
{
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:type
                                                           predicate:predicate
                                                               limit:limit
                                                     sortDescriptors:@[sorter]
                                                      resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                          if (results.count > 0) {
                                                              success(results);
                                                          }
                                                          else {
                                                              notFound();
                                                          }
                                                      }];
    [self executeQuery:query];
}

- (void)mostRecentCategorySampleForTypeIdentifier:(NSString *)identifier
                                           onDate:(NSDate *)date
                                          success:(void (^)(HKCategorySample *))success
                                         notFound:(void (^)())notFound
{
    HKCategoryType *type = [HKCategoryType categoryTypeForIdentifier:identifier];
    NSPredicate *predicate = [self predicateForSamplesOnDate:date];
    [self samplesForType:type predicate:predicate limit:1 success:^(NSArray<HKCategorySample *> *samples) {
        success(samples.firstObject);
    } notFound:^{
        notFound();
    }];
}


- (void)categorySamplesForTypeIdentifier:(NSString *)identifier
                          onDate:(NSDate *)date
                         success:(void (^)(NSArray<HKCategorySample *> *))success
                                notFound:(void (^)())notFound
{
    HKCategoryType *type = [HKCategoryType categoryTypeForIdentifier:identifier];
    NSPredicate *predicate = [self predicateForSamplesOnDate:date];
    [self samplesForType:type predicate:predicate limit:HKObjectQueryNoLimit success:^(NSArray<HKCategorySample *> *samples) {
        success(samples);
    } notFound:^{
        notFound();
    }];
}


- (void)mostRecentQuantitySampleForTypeIdentifier:(NSString *)identifier
                                           onDate:(NSDate *)date
                                          success:(void (^)(HKQuantitySample *))success
                                         notFound:(void (^)())notFound
{
    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:identifier];
    NSPredicate *predicate = [self predicateForSamplesOnDate:date];
    [self samplesForType:type predicate:predicate limit:1 success:^(NSArray<HKQuantitySample *> *samples) {
        success(samples.firstObject);
    } notFound:^{
        notFound();
    }];
}


- (void)quantitySamplesForTypeIdentifier:(NSString *)identifier
                                  onDate:(NSDate *)date
                                 success:(void (^)(NSArray<HKQuantitySample *> *))success
                                notFound:(void (^)())notFound
{
    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:identifier];
    NSPredicate *predicate = [self predicateForSamplesOnDate:date];
    [self samplesForType:type predicate:predicate limit:HKObjectQueryNoLimit success:^(NSArray<HKQuantitySample *> *samples) {
        success(samples);
    } notFound:^{
        notFound();
    }];
}



#pragma mark -

- (void)fetchSumOfSamplesForDate:(NSDate *)date
                            type:(HKQuantityType *)quantityType
                      completion:(void (^)(HKQuantity *, NSError *))completionHandler
{
    NSPredicate *predicate = [self predicateForSamplesOnDate:date];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType
                                                       quantitySamplePredicate:predicate
                                                                       options:HKStatisticsOptionCumulativeSum
                                                             completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
                                                                 HKQuantity *sum = [result sumQuantity];
                                                                 
                                                                 if (completionHandler) {
                                                                     completionHandler(sum, error);
                                                                 }
                                                             }];
    
    [self executeQuery:query];
}

- (void)addSampleWorkout
{
    HKQuantity *energyBurned = [HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:425.0];
    HKQuantity *distance = [HKQuantity quantityWithUnit:[HKUnit mileUnit] doubleValue:3.2];
    NSArray *intervals = @[[NSDate date], [NSDate dateWithTimeIntervalSinceNow:3600]];
    
    // Provide summary information when creating the workout.
    HKWorkout *run = [HKWorkout workoutWithActivityType:HKWorkoutActivityTypeRunning
                                              startDate:intervals[0]
                                                endDate:intervals[1]
                                               duration:3600
                                      totalEnergyBurned:energyBurned
                                          totalDistance:distance
                                               metadata:nil];
    
    [self saveObject:run withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            // Perform proper error handling here...
            NSLog(@"*** An error occurred while saving the "
                  @"workout: %@ ***", error.localizedDescription);
            
            abort();
        }
        
        // Add optional, detailed information for each time interval
        
        HKQuantityType *distanceType = [HKObjectType quantityTypeForIdentifier: HKQuantityTypeIdentifierDistanceWalkingRunning];
        HKQuantity *distancePerInterval = [HKQuantity quantityWithUnit:[HKUnit mileUnit] doubleValue:3.2];
        HKQuantitySample *distancePerIntervalSample = [HKQuantitySample quantitySampleWithType:distanceType
                                                                                      quantity:distancePerInterval
                                                                                     startDate:intervals[0]
                                                                                       endDate:intervals[1]];
        
        HKQuantityType *energyBurnedType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
        HKQuantity *energyBurnedPerInterval = [HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:15.5];
        HKQuantitySample *energyBurnedPerIntervalSample = [HKQuantitySample quantitySampleWithType:energyBurnedType
                                                                                          quantity:energyBurnedPerInterval
                                                                                         startDate:intervals[0]
                                                                                           endDate:intervals[1]];
        
        HKQuantityType *heartRateType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        HKQuantity *heartRateForInterval = [HKQuantity quantityWithUnit:[HKUnit unitFromString:@"count/min"] doubleValue:95.0];
        HKQuantitySample *heartRateForIntervalSample = [HKQuantitySample quantitySampleWithType:heartRateType
                                                                                       quantity:heartRateForInterval
                                                                                      startDate:intervals[0]
                                                                                        endDate:intervals[1]];
        
        NSMutableArray *samples = [NSMutableArray array];
        [samples addObject:distancePerIntervalSample];
        [samples addObject:energyBurnedPerIntervalSample];
        [samples addObject:heartRateForIntervalSample];
        
        // Add all the samples to the workout.
        [self addSamples:samples toWorkout:run completion:^(BOOL success, NSError *error) {
            if (!success) {
                // Perform proper error handling here...
                NSLog(@"*** An error occurred while adding a "
                      @"sample to the workout: %@ ***",
                      error.localizedDescription);
                
                abort();
            }
        }];
    }];
}


- (void)saveQuantity:(HKQuantity *)quantity withType:(HKQuantityType *)type date:(NSDate *)date
{
    NSDictionary *metadata = @{HKMetadataKeyWasUserEntered : @YES};
    HKQuantitySample *sample = [HKQuantitySample quantitySampleWithType:type
                                                               quantity:quantity
                                                              startDate:date
                                                                endDate:date
                                                               metadata:metadata];
    [self saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
        
    }];
}


- (void)saveCategoryWithIdentifier:(NSString *)identifier
                             value:(NSInteger)value
                              date:(NSDate *)date
                              meta:(NSDictionary *)meta
{
    HKCategoryType *type = [HKCategoryType categoryTypeForIdentifier:identifier];
    HKCategorySample *sample = [HKCategorySample categorySampleWithType:type
                                                                  value:value
                                                              startDate:date
                                                                endDate:date
                                                               metadata:meta];
    [self saveObject:sample withCompletion:^(BOOL success, NSError * _Nullable error) {
        
    }];
}


- (BOOL)canWriteCategoryType:(NSString *)typeIdentifier
{
    HKCategoryType *type = [HKCategoryType categoryTypeForIdentifier:typeIdentifier];
    return [self authorizationStatusForType:type] == HKAuthorizationStatusSharingAuthorized;
}


- (BOOL)canWriteQuantityType:(NSString *)typeIdentifier
{
    HKQuantityType *type = [HKQuantityType quantityTypeForIdentifier:typeIdentifier];
    return [self authorizationStatusForType:type] == HKAuthorizationStatusSharingAuthorized;
}


- (void)recentSavedCategorySamplesForTypeIdentifier:(NSString *)identifier
                                             onDate:(NSDate *)date
                                            success:(void (^)(NSArray<__kindof HKSample *> *))success
                                           notFound:(void (^)())notFound
{
    HKSampleType *type = [HKCategoryType categoryTypeForIdentifier:identifier];
    NSArray *predicates = @[[self predicateForSamplesOnDate:date],
                            [HKQuery predicateForObjectsFromSource:[HKSource defaultSource]]];
    NSCompoundPredicate *andPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
 
    [self samplesForType:type predicate:andPredicate limit:HKObjectQueryNoLimit success:^(NSArray<__kindof HKSample *> *samples) {
        success(samples);
    } notFound:^{
        notFound();
    }];
}


- (void)recentSavedQuantitySamplesForTypeIdentifier:(NSString *)identifier
                                             onDate:(NSDate *)date
                                            success:(void (^)(NSArray<__kindof HKSample *> *))success
                                           notFound:(void (^)())notFound
{
    HKSampleType *type = [HKQuantityType quantityTypeForIdentifier:identifier];
    NSArray *predicates = @[[self predicateForSamplesOnDate:date],
                            [HKQuery predicateForObjectsFromSource:[HKSource defaultSource]]];
    NSCompoundPredicate *andPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    
    [self samplesForType:type predicate:andPredicate limit:HKObjectQueryNoLimit success:^(NSArray<__kindof HKSample *> *samples) {
        success(samples);
    } notFound:^{
        notFound();
    }];
}




#pragma mark - Deletion

- (void)deleteAllDataWithCompletion:(void (^)(BOOL))completion
{
    dispatch_group_t deleteGroup = dispatch_group_create();
    NSArray *types = [HKHealthStore pushableReproductiveHealthTypes];
    __block BOOL result = YES;
    
    for (HKSampleType *each in types) {
        dispatch_group_enter(deleteGroup);
        [self deleteAllDataWithType:each completion:^(BOOL success) {
            result = success;
            dispatch_group_leave(deleteGroup);
        }];
    }
    
    dispatch_group_notify(deleteGroup, dispatch_get_main_queue(), ^{
        completion(result);
    });
}

- (void)deleteAllDataWithType:(HKSampleType *)type completion:(void (^)(BOOL))completion
{
    NSPredicate *predicate = [HKQuery predicateForObjectsFromSource:[HKSource defaultSource]];
    [self samplesForType:type predicate:predicate limit:HKObjectQueryNoLimit success:^(NSArray<__kindof HKSample *> *samples) {
        [self deleteObjects:samples withCompletion:^(BOOL success, NSError * _Nullable error) {
            completion(success);
        }];
        
    } notFound:^{
        completion(NO);
    }];
}




@end





