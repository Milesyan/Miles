//
//  HealthConditionsViewController.m
//  emma
//
//  Created by Peng Gu on 10/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "HealthConditionsViewController.h"
#import "HealthProfileData.h"
#import "User.h"
#import "StatusBarOverlay.h"
#import "MultiSelectionTableViewDataSource.h"

@interface HealthConditionsViewController () <MultiSelectionTableViewDataSourceDelegate>

@property (nonatomic, strong) MultiSelectionTableViewDataSource *dataSource;

@end

@implementation HealthConditionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    int64_t value = [User currentUser].settings.diagnosedConditions;
    NSIndexSet *selectedRows = [HealthProfileData indexSetForDiagnosedConditionsValue:value];
    NSArray *options = [HealthProfileData diagnosedConditionOptions];
    
    self.dataSource = [[MultiSelectionTableViewDataSource alloc] initWithOptions:options
                                                                    selectedRows:selectedRows
                                                                       tableView:self.tableView];
    self.dataSource.delegate = self;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    User *user = [User currentUser];
    int64_t oldValue = user.settings.diagnosedConditions;
    int64_t newValue = [HealthProfileData valueForDiagnosedConditionsInIndexSet:self.dataSource.selectedRows];
    if (oldValue != newValue) {
        [user.settings update:@"diagnosedConditions" intValue:newValue];
        [user save];
        [user pushToServer];
        [self publish:EVENT_USER_SETTINGS_UPDATED];
        [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_HEALTH_CONDITIONS];
}


- (BOOL)MultiSelectionTableViewDataSource:(MultiSelectionTableViewDataSource *)dataSource
                   shouldSelectRowAtIndex:(NSUInteger)index
{
    // if None is selected, disable selection for other items
//    return ![self.dataSource.selectedRows containsIndex:0];
    return YES;
}


- (void)MultiSelectionTableViewDataSource:(MultiSelectionTableViewDataSource *)dataSource didSelectRowAtIndex:(NSUInteger)index
{
    if (index == 0) {
        // select None and deselect all others
        NSIndexSet *indexSet = [self.dataSource.selectedRows indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
            return idx > 0;
        }];
        
        [self.dataSource deselectRowsInIndexSet:indexSet];
    }
    else if ([self.dataSource.selectedRows containsIndex:0]) {
        // deselect none
        [self.dataSource deselectRowsInIndexSet:[NSIndexSet indexSetWithIndex:0]];
    }
    
    NSDictionary *data = @{@"click_type": CLICK_TYPE_SELECT,
                           @"health_condition_name": self.dataSource.options[index]};
    [Logging log:BTN_CLK_HEALTH_CONDITIONS eventData:data];
}


- (void)MultiSelectionTableViewDataSource:(MultiSelectionTableViewDataSource *)dataSource didDeselectRowAtIndex:(NSUInteger)index
{
    NSDictionary *data = @{@"click_type": CLICK_TYPE_UNSELECT,
                           @"health_condition_name": self.dataSource.options[index]};
    [Logging log:BTN_CLK_HEALTH_CONDITIONS eventData:data];
}


@end












