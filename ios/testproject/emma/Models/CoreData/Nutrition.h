//
//  Nutrition.h
//  emma
//
//  Created by Eric Xu on 3/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"

#define NUTRITION_CARBOHYDRATE @"nutritionCarbohydrate"
#define NUTRITION_FAT @"nutritionFat"
#define NUTRITION_PROTEIN @"nutritionProtein"
#define NUTRITION_SRC @"nutritionSrc"
#define NUTRITION_SRC_NAME @"nutritionSrcName"
@class User;

typedef enum {
    NUTRITION_SRC_MFP = 1,
    NUTRITION_SRC_FITBIT = 2,
    NUTRITION_SRC_JAWBONE = 3,
    NUTRITION_SRC_MISFIT = 4,
} NUTRITION_SRC_VAL;

@interface Nutrition : BaseModel

@property (nonatomic) int16_t  src;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSDate * updatedTime;
@property (nonatomic) float calorieOut;
@property (nonatomic) float calorieIn;
@property (nonatomic) float fat;
@property (nonatomic) float carbohydrates;
@property (nonatomic) float protein;
@property (nonatomic, retain) NSDate * nsdate;
@property (nonatomic, retain) User *user;

- (BOOL)hasCalories;
- (BOOL)hasNutritions;
- (NSDictionary *)nutritionsDict;
- (void)setSynced:(BOOL)synced;
- (BOOL)isSynced;
+ (void)setDataSynced:(BOOL)synced forDay:(NSString *)dateLabel;
+ (BOOL)isDataSyncedForDay:(NSString *)dateLabel;
+ (NSString *)syncedDataKeyOfDay:(NSString *)dateLabel;
+ (id)tset:(NSString *)date forUser:(User *)user;
+ (NSString *)srcName:(NUTRITION_SRC_VAL)src;
+ (Nutrition *)nutritionForDate:(NSString *)dateLabel forUser:(User *)user;
+ (NSArray *)nutritonsWithNutritionFromDate:(NSString *)fromDateLabel toDate:(NSString *)toDateLabel forUser:(User *)user;
+ (NSArray *)nutritonsWithCalorieFromDate:(NSString *)fromDateLabel toDate:(NSString *)toDateLabel forUser:(User *)user;
+ (Nutrition *)sampleNutrition;

//+ (NSArray *)caloriesBurnedFromDate:(NSString *)fromDateLabel;
//+ (NSArray *)caloriesBurnedFromDate:(NSString *)fromDateLabel;
//+ (float)caloriesBurnedFromDate:(NSString *)fromDateLabel toDate:(NSString *)toDateLabel;
//+ (float)caloriesConsumedFromDate:(NSString *)fromDateLabel toDate:(NSString *)toDateLabel;
@end
