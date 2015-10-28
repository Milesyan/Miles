//
//  Nutrition.m
//  emma
//
//  Created by Eric Xu on 3/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "Nutrition.h"
#import "User.h"


@implementation Nutrition

@dynamic src;
@dynamic date;
@dynamic updatedTime;
@dynamic calorieOut;
@dynamic calorieIn;
@dynamic fat;
@dynamic carbohydrates;
@dynamic protein;
@dynamic nsdate;
@dynamic user;

- (NSDictionary *)attrMapper {
    return @{};
}

- (BOOL)hasCalories {
    return self.calorieIn > 0 || self.calorieOut > 0;
}

- (BOOL)hasNutritions {
    return self.carbohydrates > 0 || self.fat > 0 || self.protein > 0;
}

- (NSDictionary *)nutritionsDict {
    return @{
             NUTRITION_CARBOHYDRATE: @(self.carbohydrates),
             NUTRITION_FAT: @(self.fat),
             NUTRITION_PROTEIN: @(self.protein),
             NUTRITION_SRC: @(self.src),
             NUTRITION_SRC_NAME: [Nutrition srcName: self.src],
             };
}

- (void)setSynced:(BOOL)synced {
    [Nutrition setDataSynced:synced forDay:self.date];
}

- (BOOL)isSynced {
    return [Nutrition isDataSyncedForDay:self.date];
}

+ (void)setDataSynced:(BOOL)synced forDay:(NSString *)dateLabel {
    [Utils setDefaultsForKey:[Nutrition syncedDataKeyOfDay:dateLabel] withValue:@(synced)];
}

+ (BOOL)isDataSyncedForDay:(NSString *)dateLabel {
    return [[Utils getDefaultsForKey:[Nutrition syncedDataKeyOfDay:dateLabel]] boolValue];
}

+ (NSString *)syncedDataKeyOfDay:(NSString *)dateLabel {
    return [NSString stringWithFormat:@"SYNCED_%@", dateLabel];
}

+ (NSString *)srcName:(NUTRITION_SRC_VAL)src {
    switch (src) {
        case NUTRITION_SRC_FITBIT:
            return @"Fitbit";
        case NUTRITION_SRC_JAWBONE:
            return @"Jawbone UP";
        case NUTRITION_SRC_MFP:
            return @"MyFitnessPal";
        case NUTRITION_SRC_MISFIT:
            return @"Misfit";
        default:
            break;
    }
    
    return @"";
}

+ (Nutrition *)nutritionForDate:(NSString *)dateLabel forUser:(User *)user{
    for (Nutrition *n in user.nutritions) {
        if ([n.date isEqualToString:dateLabel]) {
            return n;
        }
    }
    return nil;
}

+ (NSArray *)nutritonsWithNutritionFromDate:(NSString *)fromDateLabel toDate:(NSString *)toDateLabel forUser:(User *)user{
    NSMutableArray* nutritions = [NSMutableArray array];
    for (Nutrition *n in user.nutritions) {
        if ([n hasNutritions] && strLargeEqual(n.date, fromDateLabel) && strLargeEqual(toDateLabel, n.date))
            [nutritions addObject:n];
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"nsdate" ascending:YES];
    NSArray *sorted=[nutritions sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    return sorted;
}

+ (NSArray *)nutritonsWithCalorieFromDate:(NSString *)fromDateLabel toDate:(NSString *)toDateLabel forUser:(User *)user{
    NSMutableArray* nutritionsArr = [NSMutableArray array];
    for (Nutrition *n in user.nutritions) {
        if ([n hasCalories] && strLargeEqual(n.date, fromDateLabel) && strLargeEqual(toDateLabel, n.date))
            [nutritionsArr addObject:n];
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"nsdate" ascending:YES];
    NSArray *sorted=[nutritionsArr sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    return sorted;
    
}

+ (NSDictionary *)nutritionForDate:(NSString *)dateLabel {
    Nutrition *n = [Nutrition tset:dateLabel forUser:[User currentUser]];
    return @{
             NUTRITION_CARBOHYDRATE: @(n.carbohydrates),
             NUTRITION_FAT: @(n.fat),
             NUTRITION_PROTEIN: @(n.protein),
             NUTRITION_SRC: @(n.src),
             };
}

+ (NSArray *)caloriesBurnedFromDate:(NSString *)fromDateLabel {
    return @[];
}

+ (float)caloriesBurnedFromDate:(NSString *)fromDateLabel toDate:(NSString *)toDateLabel {
    return 0;
}

+ (float)caloriesConsumedFromDate:(NSString *)fromDateLabel toDate:(NSString *)toDateLabel {
    return 0;
}

+ (id)tset:(NSString *)date forUser:(User *)user {
//    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"Nutrition tset %@", date]];
    NSString * _dateLabel = date;
    // we have a crash here, date is nil, we give it "today"
    
    if (!user) {
        return nil;
    }
    if ([Utils isEmptyString:date]) {
        _dateLabel = [[NSDate date] toDateLabel];
    }
    DataStore *ds = user.dataStore;
    Nutrition *nutrition = (Nutrition *)[self fetchObject:@{
                                                            @"user.id" : user.id,
                                                            @"date" : _dateLabel
                                                            }
                                                dataStore:ds];
    if (!nutrition) {
        nutrition = [Nutrition newInstance:ds];
        nutrition.date = _dateLabel;
        nutrition.nsdate = [Utils dateWithDateLabel:_dateLabel];
        nutrition.user = user;
    }
    return nutrition;
}

+ (Nutrition *)sampleNutrition
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:[User currentUser].dataStore.context];
    Nutrition *n = [[Nutrition alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
    
    n.src = 1;
    n.fat = 18.0;
    n.protein = 24.0;
    n.carbohydrates = 39.0;
    return n;
}




@end
