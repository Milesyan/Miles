//
//  GLPeriodCell.h
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-23.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLCycleData.h"
#import "GLSwipeToDeleteCell.h"

#define EVENT_PERIOD_EDITOR_TABLE_CELL_SHOULD_BACK_TO_NORMAL @"event_period_editor_table_cell_should_back_to_normal"

@class GLPeriodCell;

@protocol GLPeriodCellDelegate <NSObject>
- (void)periodCell:(GLPeriodCell *)cell needsDeleteCycleData:(GLCycleData *)cycleData;
- (void)periodCell:(GLPeriodCell *)cell didWantToDeleteTheLatestCycle:(GLCycleData *)cycleData;
@end

@interface GLPeriodCell : GLSwipeToDeleteCell
@property (nonatomic, weak) id<GLPeriodCellDelegate> delegate;
@property (nonatomic, strong) GLCycleData *cycleData;
@property (nonatomic) BOOL allowDeletion;
@end
