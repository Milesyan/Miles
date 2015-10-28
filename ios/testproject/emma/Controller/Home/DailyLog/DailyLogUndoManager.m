//
//  DailyLogUndoManager.m
//  emma
//
//  Created by Xin Zhao on 5/7/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "DailyLogUndoManager.h"
#import "DailyLogDataProvider.h"
#import "UserDailyData+Symptom.h"

@implementation DailyLogUndoManager

- (id)init {
    self = [super init];
    if (self) {
        self.valueHistory = [@{} mutableCopy];
        self.actions = [@[] mutableCopy];
    }
    return self;
}

- (void)recordValueForKey:(DailyLogCellKey)key value:(id)value {
    if (!value) {
        value = [NSNull null];
    }
    if (!self.valueHistory[key]) {
        self.valueHistory[key] = [@[] mutableCopy];
    }
    [self.valueHistory[key] addObject:value];
}

- (void)recordValueMedsName:(NSString *)medName value:(id)value withPadding:
    (BOOL)paddingZero{
    if (!value) {
        value = [NSNull null];
    }
    
    if (!self.valueHistory[DL_CELL_KEY_MEDS]) {
        self.valueHistory[DL_CELL_KEY_MEDS] = [@{} mutableCopy];
    }
    if (!self.valueHistory[DL_CELL_KEY_MEDS][medName]) {
        self.valueHistory[DL_CELL_KEY_MEDS][medName] = paddingZero
            ? [@[@(0)] mutableCopy] : [@[] mutableCopy];
    }
    
    [self.valueHistory[DL_CELL_KEY_MEDS][medName] addObject:value];
}

- (void)recordValueMedsName:(NSString *)medName jsonValue:(id)value {
    if (value) {
        NSDictionary *dic = (NSDictionary *)[NSJSONSerialization
            JSONObjectWithData:(NSData *)value options:0 error:nil];
        if (dic[medName]) {
            [self recordValueMedsName:medName value:dic[medName] withPadding:NO];
            return;
        }
    }
    [self recordValueMedsName:medName value:@(0) withPadding:NO];
}

- (void)recordAction:(NSArray *)action {
    [self.actions addObject:action];
}

- (id)currentValueForKey:(DailyLogCellKey)key {
    if (!self.valueHistory[key] || [self.valueHistory[key] count] == 0 ||
        [key isEqual:DL_CELL_KEY_MEDS]) {
        return nil;
    }
    return [self.valueHistory[key] lastObject];
}

- (id)currentValueForMedName:(NSString *)medName {
    if (!self.valueHistory[DL_CELL_KEY_MEDS] ||
        !self.valueHistory[DL_CELL_KEY_MEDS][medName] ||
        [self.valueHistory[DL_CELL_KEY_MEDS][medName] count] == 0) {
        return nil;
    }
    return [self.valueHistory[DL_CELL_KEY_MEDS][medName] lastObject];
}

- (NSArray *)getValueHistoryForKey:(DailyLogCellKey)key {
    return self.valueHistory[key];
}

- (void)popStoricalValueForKey:(DailyLogCellKey)key {
    if (!self.valueHistory[key] || [self.valueHistory[key] count] == 0) {
        return;
    }
    [self.valueHistory[key] removeLastObject];
}

- (NSArray *)popLastAction {
    if ([self.actions count] == 0) {
        return nil;
    }
    NSArray *lastAction = [self.actions lastObject];
    [self.actions removeLastObject];
    return lastAction;
}

- (BOOL)hasChanges {
    for (DailyLogCellKey key in self.valueHistory) {
        /*
        if ([SYMPTOM_KEYS containsObject:key] && [self.valueHistory[key] count] > 1) {
            return YES;
        }
        */
        
        if ([self.valueHistory[key] count] <= 1 ||
            [key isEqual:DL_CELL_KEY_MEDS]) {
            continue;
        }
        if (([DL_CELL_KEY_WEIGHT isEqual:key] ||
            [DL_CELL_KEY_BBT isEqual:key]) &&
            ![[self.valueHistory[key] firstObject] isEqual:[NSNull null]] &&
            fabs([[self.valueHistory[key] firstObject] floatValue] -
            [[self.valueHistory[key] lastObject] floatValue]) < 1e-4 ) {
            
            continue;
        }
        if ([[self.valueHistory[key] firstObject] isEqual:
            [NSNull null]] &&
            [[self.valueHistory[key] lastObject] floatValue] <= 0) {
            
            continue;
        }
        if (![[self.valueHistory[key] lastObject] isEqual:
            [self.valueHistory[key] firstObject]]) {
        
            return YES;
        }
    }
    if (self.valueHistory[DL_CELL_KEY_MEDS]) {
        for (NSString *medName in self.valueHistory[DL_CELL_KEY_MEDS]) {
            
            if ([self.valueHistory[DL_CELL_KEY_MEDS][medName] count] > 1 &&
                ![[self.valueHistory[DL_CELL_KEY_MEDS][medName] lastObject]
                isEqual:[self.valueHistory[DL_CELL_KEY_MEDS][medName]
                firstObject]]) {
                
                return YES;
            }
        }
    }
    return NO;
}

- (void)popMed:(NSString *)medName {
    if (!self.valueHistory[DL_CELL_KEY_MEDS]) {
        return;
    }
    [self.valueHistory[DL_CELL_KEY_MEDS] removeObjectForKey:medName];
}
@end
