//
//  StatusCell.h
//  emma
//
//  Created by ltebean on 15/6/17.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLPeriodEditor/GLSwipeToDeleteCell.h>
#import "UserStatus.h"

#define EVENT_HISTORY_CELL_DID_BEGIN_EDIT @"event_history_cell_did_begin_edit"

@class StatusHistoryCell;

@protocol StatusHistoryCellDelegate <NSObject>
- (void)statusHistoryCell:(StatusHistoryCell *)cell didUpdateStatus:(UserStatus *)originalStatus to:(UserStatus *)status;
- (void)statusHistoryCell:(StatusHistoryCell *)cell didWantToDeleteStatus:(UserStatus *)status;
@end

@interface StatusHistoryCell : GLSwipeToDeleteCell
@property (nonatomic, strong) UserStatus *data;
@property (nonatomic, weak) id<StatusHistoryCellDelegate>delegate;
@end
