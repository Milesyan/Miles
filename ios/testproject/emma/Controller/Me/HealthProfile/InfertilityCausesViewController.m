//
//  InfertilityCausesViewControllerTableViewController.m
//  emma
//
//  Created by Peng Gu on 10/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "InfertilityCausesViewController.h"
#import "HealthProfileData.h"
#import "User.h"
#import "StatusBarOverlay.h"
#import "MultiSelectionTableViewDataSource.h"

@interface InfertilityCausesViewController () <MultiSelectionTableViewDataSourceDelegate>

@property (nonatomic, strong) MultiSelectionTableViewDataSource *dataSource;

@end


@implementation InfertilityCausesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    int64_t value = [User currentUser].settings.infertilityDiagnosis;
    NSIndexSet *selectedRows = [HealthProfileData indexSetForInfertilityCausesValue:value];
    NSArray *options = [HealthProfileData infertilityCausesOptions];
    
    self.dataSource = [[MultiSelectionTableViewDataSource alloc] initWithOptions:options
                                                                    selectedRows:selectedRows
                                                                       tableView:self.tableView];
    self.dataSource.delegate = self;

}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    User *user = [User currentUser];
    int64_t oldValue = user.settings.infertilityDiagnosis;
    int64_t newValue = [HealthProfileData valueForInfertilityCausesInIndexSet:self.dataSource.selectedRows];
    if (oldValue != newValue) {
        [user.settings update:@"infertilityDiagnosis" intValue:newValue];
        [user save];
        [user pushToServer];
        [self publish:EVENT_USER_SETTINGS_UPDATED];
        [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_HEALTH_DIAGNOSED_CAUSES];
}


- (void)MultiSelectionTableViewDataSource:(MultiSelectionTableViewDataSource *)dataSource didSelectRowAtIndex:(NSUInteger)index
{
    NSDictionary *data = @{@"click_type": CLICK_TYPE_SELECT,
                           @"diagnosed_cause_name": self.dataSource.options[index]};
    [Logging log:BTN_CLK_HEALTH_DIAGNOSED_CAUSES eventData:data];
}


- (void)MultiSelectionTableViewDataSource:(MultiSelectionTableViewDataSource *)dataSource didDeselectRowAtIndex:(NSUInteger)index
{
    NSDictionary *data = @{@"click_type": CLICK_TYPE_UNSELECT,
                           @"diagnosed_cause_name": self.dataSource.options[index]};
    [Logging log:BTN_CLK_HEALTH_DIAGNOSED_CAUSES eventData:data];
}


@end
