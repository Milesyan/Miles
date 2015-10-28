//
//  HKHealthStore+Util.h
//  emma
//
//  Created by Peng Gu on 8/19/15.
//  Copyright © 2015 Upward Labs. All rights reserved.
//

#import <HealthKit/HealthKit.h>

@interface HKHealthStore (Util)

- (BOOL)canWriteCategoryType:(NSString *)typeIdentifier;
- (BOOL)canWriteQuantityType:(NSString *)typeIdentifier;

- (NSPredicate *)predicateForSamplesOnDate:(NSDate *)date;

- (void)fetchSumOfSamplesForDate:(NSDate *)date
                            type:(HKQuantityType *)quantityType
                      completion:(void (^)(HKQuantity *, NSError *))completionHandler;

- (void)samplesForType:(HKSampleType *)type
             predicate:(NSPredicate *)predicate
                 limit:(NSUInteger)limit
               success:(void (^)(NSArray<__kindof HKSample *> *))success
              notFound:(void (^)())notFound;

- (void)mostRecentCategorySampleForTypeIdentifier:(NSString *)identifier
                                           onDate:(NSDate *)date
                                          success:(void (^)(HKCategorySample *))success
                                         notFound:(void (^)())notFound;

- (void)categorySamplesForTypeIdentifier:(NSString *)identifier
                                  onDate:(NSDate *)date
                                 success:(void (^)(NSArray<HKCategorySample *> *))success
                                notFound:(void (^)())notFound;

- (void)mostRecentQuantitySampleForTypeIdentifier:(NSString *)identifier
                                           onDate:(NSDate *)date
                                          success:(void (^)(HKQuantitySample *))success
                                         notFound:(void (^)())notFound;

- (void)quantitySamplesForTypeIdentifier:(NSString *)identifier
                                  onDate:(NSDate *)date
                                 success:(void (^)(NSArray<HKQuantitySample *> *))success
                                notFound:(void (^)())notFound;

- (void)saveCategoryWithIdentifier:(NSString *)identifier
                             value:(NSInteger)value
                              date:(NSDate *)date
                              meta:(NSDictionary *)meta;
- (void)saveQuantity:(HKQuantity *)quantity withType:(HKQuantityType *)type date:(NSDate *)date;

- (void)deleteAllDataWithCompletion:(void (^)(BOOL success))completion;

- (void)recentSavedQuantitySamplesForTypeIdentifier:(NSString *)identifier
                                            onDate:(NSDate *)date
                                            success:(void (^)(NSArray<__kindof HKSample *> *))success
                                          notFound:(void (^)())notFound;

- (void)recentSavedCategorySamplesForTypeIdentifier:(NSString *)identifier
                                            onDate:(NSDate *)date
                                            success:(void (^)(NSArray<__kindof HKSample *> *))success
                                          notFound:(void (^)())notFound;

+ (NSArray<HKObjectType *> *)pullableReproductiveHealthTypes;
+ (NSArray<HKObjectType *> *)pushableReproductiveHealthTypes;

@end
