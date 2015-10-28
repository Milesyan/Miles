//
//  MultiSelectionTableViewDataSource.m
//  emma
//
//  Created by Peng Gu on 10/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "MultiSelectionTableViewDataSource.h"


@interface MultiSelectionTableViewDataSource () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableIndexSet *mutableSelectedRows;

@end


@implementation MultiSelectionTableViewDataSource

- (instancetype)initWithOptions:(NSArray *)options
                   selectedRows:(NSIndexSet *)selectedRows
                      tableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
        self.options = options ? options : [NSArray array];
        self.selectedRows = selectedRows ? selectedRows : [NSIndexSet indexSet];
        self.tableView = tableView;
        
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MultiSelectionTableViewCellReuse"];
    }
    return self;
}


- (NSIndexSet *)selectedRows
{
    return self.mutableSelectedRows;
}


- (void)setSelectedRows:(NSIndexSet *)selectedRows
{
    self.mutableSelectedRows = [selectedRows mutableCopy];
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.options.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MultiSelectionTableViewCellReuse"
                                                            forIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [Utils semiBoldFont:17];
    cell.textLabel.text = self.options[indexPath.row];
    
    if ([self.selectedRows containsIndex:indexPath.row]) {
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL shouldSelect = YES;
    if ([self.delegate respondsToSelector:@selector(MultiSelectionTableViewDataSource:shouldSelectRowAtIndex:)]) {
        shouldSelect = [self.delegate MultiSelectionTableViewDataSource:self
                                                 shouldSelectRowAtIndex:indexPath.row];
    }
    
    if (shouldSelect) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.mutableSelectedRows addIndex:indexPath.row];
        
        if ([self.delegate respondsToSelector:@selector(MultiSelectionTableViewDataSource:didSelectRowAtIndex:)]) {
            [self.delegate MultiSelectionTableViewDataSource:self didSelectRowAtIndex:indexPath.row];
        }
    }
}


- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    [self.mutableSelectedRows removeIndex:indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(MultiSelectionTableViewDataSource:didDeselectRowAtIndex:)]) {
        [self.delegate MultiSelectionTableViewDataSource:self didDeselectRowAtIndex:indexPath.row];
    }
}


- (void)deselectRowsInIndexSet:(NSIndexSet *)indexSet
{
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        [self.mutableSelectedRows removeIndex:indexPath.row];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }];
}



@end
