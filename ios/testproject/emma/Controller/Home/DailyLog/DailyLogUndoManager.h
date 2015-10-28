//
//  DailyLogUndoManager.h
//  emma
//
//  Created by Xin Zhao on 5/7/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define MAX_UNDO_ACTIONS_NUM 50

@interface DailyLogUndoManager : NSObject

@property (strong, nonatomic) NSMutableDictionary *valueHistory;
@property (strong, nonatomic) NSMutableArray *actions;

- (void)recordValueForKey:(DailyLogCellKey)key value:(id)value;
- (void)recordValueMedsName:(NSString *)medName value:(id)value withPadding:
    (BOOL)paddingZero;
- (void)recordValueMedsName:(NSString *)medName jsonValue:(id)value;
- (void)recordAction:(NSArray *)action;
- (id)currentValueForKey:(DailyLogCellKey)key;
- (id)currentValueForMedName:(NSString *)medName;
- (NSArray *)getValueHistoryForKey:(DailyLogCellKey)key;
- (void)popStoricalValueForKey:(DailyLogCellKey)key;
- (NSArray *)popLastAction;
- (void)popMed:(NSString *)medName;
- (BOOL)hasChanges;
@end
