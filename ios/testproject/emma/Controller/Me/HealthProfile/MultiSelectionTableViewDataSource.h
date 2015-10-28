//
//  MultiSelectionTableViewDataSource.h
//  emma
//
//  Created by Peng Gu on 10/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>


@class MultiSelectionTableViewDataSource;

@protocol MultiSelectionTableViewDataSourceDelegate <NSObject>

- (BOOL)MultiSelectionTableViewDataSource:(MultiSelectionTableViewDataSource *)dataSource
                   shouldSelectRowAtIndex:(NSUInteger)index;

- (void)MultiSelectionTableViewDataSource:(MultiSelectionTableViewDataSource *)dataSource
                      didSelectRowAtIndex:(NSUInteger)index;

- (void)MultiSelectionTableViewDataSource:(MultiSelectionTableViewDataSource *)dataSource
                      didDeselectRowAtIndex:(NSUInteger)index;

@end

@interface MultiSelectionTableViewDataSource : NSObject

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSArray *options;
@property (nonatomic, strong) NSIndexSet *selectedRows;
@property (nonatomic, weak) id<MultiSelectionTableViewDataSourceDelegate> delegate;

- (instancetype)initWithOptions:(NSArray *)options selectedRows:(NSIndexSet *)selectedRows tableView:(UITableView *)tableView;
- (void)deselectRowsInIndexSet:(NSIndexSet *)indexSet;

@end
