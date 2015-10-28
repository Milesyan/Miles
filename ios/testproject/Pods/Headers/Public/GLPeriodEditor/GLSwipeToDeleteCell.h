//
//  GLSwipeToDeleteCell.h
//  GLPeriodEditor
//
//  Created by ltebean on 15/7/6.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
#define CHANGE_POINT 180;

typedef NS_ENUM(NSInteger, CellState) {
    CELL_STATE_NORMAL,
    CELL_STATE_RIGHT_VIEW_SHOWN,
};

@interface GLSwipeToDeleteCell : UITableViewCell
@property (nonatomic) CellState state;
@property (nonatomic) BOOL scrollEnabled;
- (void)didWantToDelete;
- (void)showDeleteButton;
- (void)hideDeleteButton;
@end
