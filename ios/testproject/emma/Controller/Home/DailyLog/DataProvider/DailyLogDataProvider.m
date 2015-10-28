//
//  DailyLogDataProvider.m
//  emma
//
//  Created by Xin Zhao on 13-11-22.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "DailyLogDataProvider.h"
#import "MedManager.h"

@implementation DailyLogDataProvider

+ (NSDictionary *)generateAbatractForUser:(User *)user dailyData:(UserDailyData *)dailyData {
    NSDictionary *medsAdded = [MedManager medsForUser:user];
    //NSDictionary *medsLogged = [dailyData medsLog];

    NSSet *set = [NSSet setWithArray:medsAdded.allKeys];
//    set = [set setByAddingObjectsFromSet:[medsLogged keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
//        return obj && [obj intValue] > 0;
//    }]];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES];
    NSArray *sortedArray = [set sortedArrayUsingDescriptors:@[sort]];
    
    return @{
             DAILYLOG_DP_ABSTRACT_IS_FEMALE: @([user isFemale]),
             DAILYLOG_DP_ABSTRACT_MEDS: sortedArray,
             DAILYLOG_DP_ABSTRACT_UID: [user.id stringValue],
             };
}

- (void)setIsEditing:(BOOL)isEditing {
    _isEditing = isEditing;
    if (isEditing) {
        [self.newlyHiddenLogKeys removeAllObjects];
        [self.newlyShownLogKeys removeAllObjects];
    }
}

- (void)fetchHiddenLogKeysFromDefaults {
    if (!self.hiddenLogKeys) {
        NSString *key = catstr(self.abstract[DAILYLOG_DP_ABSTRACT_UID],
            @"_", DEFAULTS_HIDDEN_LOG_KEYS_POSTFIX, nil);
        self.hiddenLogKeys = [NSMutableSet setWithArray:
            [Utils getDefaultsForKey:key]];
    }
    self.hiddenLogKeys = self.hiddenLogKeys ? self.hiddenLogKeys
            : [NSMutableSet setWithArray:@[]];
    self.newlyHiddenLogKeys = [NSMutableSet set];
    self.newlyShownLogKeys = [NSMutableSet set];
}

- (DailyLogCellKey)dailyLogCellKeyForIndexPath:(NSIndexPath *)indexPath{
    return [self dailyLogCellKeyOrderWithMeds][indexPath.row];
}

- (NSIndexPath *)indexPathForDailyLogCellKey:(DailyLogCellKey)cellKey{
    NSInteger row = [[self dailyLogCellKeyOrderWithMeds] indexOfObject:
        cellKey];
    return row == NSNotFound ? nil
        : [NSIndexPath indexPathForItem:row inSection:0];
}

- (NSInteger)indexOfMedicineForIndexPath:(NSIndexPath *)indexPath {
    NSArray *meds = self.abstract[DAILYLOG_DP_ABSTRACT_MEDS];
    NSInteger idx = indexPath.row - [[self dailyLogCellKeyOrder] count];
    if (idx >= 0 && idx < [meds count]) {
        return idx;
    }
    return NSNotFound;
}

- (NSString *)nameOfMedicineForIndexPath:(NSIndexPath *)indexPath {
    NSArray *meds = self.abstract[DAILYLOG_DP_ABSTRACT_MEDS];
    NSInteger idx = indexPath.row - [[self dailyLogCellKeyOrder] count] - 1;//-1 for header
    if (idx >= 0 && idx < [meds count]) {
        return meds[idx];
    }
    return @"";
}

- (NSArray *)physicalSectionKeys {
    if ([self.abstract[DAILYLOG_DP_ABSTRACT_IS_FEMALE] boolValue]) {
        return @[
                 DL_CELL_KEY_SECTION_PHYSICAL,
                 DL_CELL_KEY_EXERCISE,
                 DL_CELL_KEY_WEIGHT,
                 DL_CELL_KEY_SLEEP,
                 DL_CELL_KEY_SMOKE,
                 DL_CELL_KEY_ALCOHOL,
                 DL_CELL_KEY_PHYSICALDISCOMFORT
                 ];
    } else {
        return @[
                 DL_CELL_KEY_SECTION_PHYSICAL,
                 DL_CELL_KEY_EXERCISE,
                 DL_CELL_KEY_PHYSICALDISCOMFORT,
                 DL_CELL_KEY_SLEEP,
                 DL_CELL_KEY_SMOKE,
                 DL_CELL_KEY_ALCOHOL
                 ];
    }
}

- (NSArray *)emotionalSectionKeys {
    if ([self.abstract[DAILYLOG_DP_ABSTRACT_IS_FEMALE] boolValue]) {
        return @[
                 DL_CELL_KEY_SECTION_EMOTIONAL,
                 DL_CELL_KEY_STRESS_LEVEL,
                 DL_CELL_KEY_MOODS
                 ];
    } else {
        return @[
                 DL_CELL_KEY_SECTION_EMOTIONAL,
                 DL_CELL_KEY_MOODS
                 ];
    }
}

- (NSArray *)fertilitySectionKeys {
    return @[
             DL_CELL_KEY_SECTION_FERTILITY,
             DL_CELL_KEY_PERIOD_FLOW,
             DL_CELL_KEY_INTERCOURSE,
             DL_CELL_KEY_CM,
             DL_CELL_KEY_BBT,
             DL_CELL_KEY_OVTEST,
             DL_CELL_KEY_PREGNANCYTEST,
             DL_CELL_KEY_CERVICAL
             ];
}

- (NSArray *)_dailyLogCellKeyOrderConfig {
    //Subclass should implement it.
    return nil;
}

- (NSArray *)_dailyLogCellKeyOrderConfigWithHiddensRemoved {
    NSMutableArray *_configured = [[self _dailyLogCellKeyOrderConfig]
        mutableCopy];
    
    NSSet *hiddens = self.hiddenLogKeys;
    for (DailyLogCellKey key in hiddens) {
        [_configured removeObject:key];
    }
    
    // show physcial section cell or not
    BOOL found = NO;
    for (DailyLogCellKey k in [self physicalSectionKeys]) {
        if ([k isEqualToString:DL_CELL_KEY_SECTION_PHYSICAL]) {
            continue;
        }
        if ([_configured indexOfObject:k] != NSNotFound) {
            found = YES;
            break;
        }
    }
    if (!found) {
        [_configured removeObject:DL_CELL_KEY_SECTION_PHYSICAL];
    }
    
    // show emotional section cell or not
    found = NO;
    for (DailyLogCellKey k in [self emotionalSectionKeys]) {
        if ([k isEqualToString:DL_CELL_KEY_SECTION_EMOTIONAL]) {
            continue;
        }
        if ([_configured indexOfObject:k] != NSNotFound) {
            found = YES;
            break;
        }
    }
    if (!found) {
        [_configured removeObject:DL_CELL_KEY_SECTION_EMOTIONAL];
    }
    
    // show fertility section cell or not
    found = NO;
    for (DailyLogCellKey k in [self fertilitySectionKeys]) {
        if ([k isEqualToString:DL_CELL_KEY_SECTION_FERTILITY]) {
            continue;
        }
        if ([_configured indexOfObject:k] != NSNotFound) {
            found = YES;
            break;
        }
    }
    if (!found) {
        [_configured removeObject:DL_CELL_KEY_SECTION_FERTILITY];
    }
    
    return _configured;
}

- (NSArray *)dailyLogCellKeyOrder;
{
    if (!self.isEditing) {
        return [self _dailyLogCellKeyOrderConfigWithHiddensRemoved];
    }
    return [self _dailyLogCellKeyOrderConfig];
}

- (NSArray *)dailyLogCellKeyOrderWithMeds{
    NSMutableArray *order = [[self dailyLogCellKeyOrder] mutableCopy];
    
    [order addObject:DL_CELL_KEY_MED_HEADER];
//    NSArray *meds = self.abstract[DAILYLOG_DP_ABSTRACT_MEDS];
//    for (NSInteger i = 0; i < [meds count]; i++) {
//        [order addObject:DL_CELL_KEY_MED];
//    }
    [order addObject:DL_CELL_KEY_ADD_MED];
    
    return [NSArray arrayWithArray:order];
}

- (BOOL)canHideRowAtIndexPath:(NSIndexPath *)indexPath{
    DailyLogCellKey key = [self dailyLogCellKeyForIndexPath:indexPath];
    return ![DL_CELL_KEY_SECTION_PHYSICAL isEqual:key] &&
        ![DL_CELL_KEY_SECTION_EMOTIONAL isEqual:key] &&
        ![DL_CELL_KEY_SECTION_FERTILITY isEqual:key] &&
        ![DL_CELL_KEY_ADD_MED isEqual:key] &&
        ![DL_CELL_KEY_MED isEqual:key] &&
        ![DL_CELL_KEY_MED_HEADER isEqual:key];
}

- (BOOL)isCellHiddenWith:(DailyLogCellKey)key {
    return [self.hiddenLogKeys containsObject:key];
}

- (BOOL)isCellHiddenAtIndexPath:(NSIndexPath *)indexPath{
    DailyLogCellKey key = [self dailyLogCellKeyForIndexPath:indexPath];
    BOOL result = [self isCellHiddenWith:key];
    return result;
}

- (void)hideCellAtIndexPath:(NSIndexPath *)indexPath{
    DailyLogCellKey key = [self dailyLogCellKeyForIndexPath:indexPath];
    [Logging log:BTN_CLK_SWITH_DAILY_LOG_VISIBILITY
        eventData:@{@"cell_key":key, @"switch_on":@1}];

    [self.hiddenLogKeys addObject:key];
    if ([self.newlyShownLogKeys containsObject:key]) {
        [self.newlyShownLogKeys removeObject:key];
    }
    else {
        [self.newlyHiddenLogKeys addObject:key];
    }
    
    NSString *hiddenskey = catstr(
        self.abstract[DAILYLOG_DP_ABSTRACT_UID], @"_",
        DEFAULTS_HIDDEN_LOG_KEYS_POSTFIX, nil);
    [Utils setSyncableDefautsForKey:hiddenskey withValue:
        [self.hiddenLogKeys allObjects]];
}

- (void)unhideCellAtIndexPath:(NSIndexPath *)indexPath{
    DailyLogCellKey key = [self dailyLogCellKeyForIndexPath:indexPath];
    [Logging log:BTN_CLK_SWITH_DAILY_LOG_VISIBILITY
        eventData:@{@"cell_key":key, @"switch_on":@0}];
    
    [self.hiddenLogKeys removeObject:key];
    if ([self.newlyHiddenLogKeys containsObject:key]) {
        [self.newlyHiddenLogKeys removeObject:key];
    }
    else {
        [self.newlyShownLogKeys addObject:key];
    }
    NSString *hiddenskey = catstr(
        self.abstract[DAILYLOG_DP_ABSTRACT_UID], @"_",
        DEFAULTS_HIDDEN_LOG_KEYS_POSTFIX, nil);
    [Utils setSyncableDefautsForKey:hiddenskey withValue:
        [self.hiddenLogKeys allObjects]];
}


- (NSString *)rowEditingSummary {
    NSInteger countHidden = [self.newlyHiddenLogKeys count];
    NSInteger countShown = [self.newlyShownLogKeys count];
    if (countHidden == 0 && countShown == 0) {
        return nil;
    }
    NSString *result = @"";
    if (countHidden > 0) {
        result = [NSString stringWithFormat:
            countHidden > 1 ? @"%ld rows hidden" : @"%ld row hidden",
            (long)countHidden];
    }
    if (countHidden > 0 && countShown > 0) {
        result = [NSString stringWithFormat:@"%@ and ", result];
    }
    if (countShown > 0) {
        result = [NSString stringWithFormat:@"%@%@", result,
            [NSString stringWithFormat:
            countShown > 1 ? @"%ld rows shown" : @"%ld row shown",
            (long)countShown]];
    }
    return result;
}

- (void)refreshMedsAbstractForUser:(User *)user dailyData:(UserDailyData *)dailyData  {
    NSDictionary *newAbstract = [DailyLogDataProvider generateAbatractForUser:
        user dailyData:dailyData];
    self.abstract = @{
         DAILYLOG_DP_ABSTRACT_IS_FEMALE: self.abstract[DAILYLOG_DP_ABSTRACT_IS_FEMALE],
         DAILYLOG_DP_ABSTRACT_MEDS: newAbstract[DAILYLOG_DP_ABSTRACT_MEDS],
         DAILYLOG_DP_ABSTRACT_UID:
            self.abstract[DAILYLOG_DP_ABSTRACT_UID]
    };
}
@end
