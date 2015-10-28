//
//  PregnancyHistoryViewController.m
//  emma
//
//  Created by Peng Gu on 10/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "PregnancyHistoryViewController.h"
#import "User.h"
#import <GLFoundation/GLGeneralPicker.h>
#import "StatusBarOverlay.h"

@interface PregnancyHistoryViewController ()

@property (nonatomic, strong) NSArray *itemKeys;

@end

@implementation PregnancyHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.itemKeys = @[@"liveBirthNumber", @"miscarriageNumber", @"tubalPregnancyNumber",
                   @"abortionNumber", @"stillbirthNumber"];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_HEALTH_PREGNANCY_HISTORY];
}


- (void)save
{
    [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
    
    [[User currentUser] save];
    [[User currentUser] pushToServer];
    [self publish:EVENT_USER_SETTINGS_UPDATED];
    
    [self.tableView reloadData];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    Settings *setting = [User currentUser].settings;
    NSString *number = @"Choose";
    
    NSString *key = self.itemKeys[indexPath.row];
    NSInteger value = [[setting valueForKey:key] integerValue];
    if (value >= 0) {
        number = [NSString stringWithFormat:@"%ld", value];
    }
    
    cell.detailTextLabel.text = number;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = self.itemKeys[indexPath.row];
    [self presentPickerWithKey:key];
}


- (void)logButtonClickWithKey:(NSString *)key
                         value:(NSInteger)value
                additionalInfo:(NSString *)info
{
    NSString *name = @{
                        @"liveBirthNumber": HEALTH_PROFILE_ITEM_LIVEBIRTHNUMBER,
                        @"miscarriageNumber": HEALTH_PROFILE_ITEM_MISCARRIAGENUMBER,
                        @"tubalPregnancyNumber": HEALTH_PROFILE_ITEM_TUBALPREGNANCYNUMBER,
                        @"abortionNumber": HEALTH_PROFILE_ITEM_ABORTIONNUMBER,
                        @"stillbirthNumber": HEALTH_PROFILE_ITEM_STILLBIRTHNUMBER}[key];
    
    NSDictionary *data = @{
                           @"health_profile_name": name,
                           @"click_type": CLICK_TYPE_INPUT,
                           @"select_value": @(value),
                           @"additional_info": info ? info : @"" };
    [Logging log:BTN_CLK_HEALTH_PROFILE_ITEM eventData:data];
}


- (void)presentPickerWithKey:(NSString *)key
{
    NSInteger number = [[[User currentUser].settings valueForKey:key] integerValue] + 1;
    NSArray *rows = @[@"", @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10"];
    NSString *title = @{
                        @"liveBirthNumber": @"Live Birth",
                        @"miscarriageNumber": @"Miscarriage",
                        @"tubalPregnancyNumber": @"Tubal or Ectopic",
                        @"abortionNumber": @"Abortion",
                        @"stillbirthNumber": @"Stillbirth"}[key];
    
    [GLGeneralPicker presentCancelableSimplePickerWithTitle:title
                                                       rows:rows
                                                selectedRow:number
                                                  doneTitle:@"Done"
                                                 showCancel:YES
                                              withAnimation:YES
                                             doneCompletion:^(NSInteger row, NSInteger comp) {
        [self logButtonClickWithKey:key value:row-1 additionalInfo:@"done"];
        if (row != number) {
            [[User currentUser].settings update:key intValue:row - 1];
            [self save];
        }
    } cancelCompletion:^(NSInteger row, NSInteger comp) {
        [self logButtonClickWithKey:key value:row-1 additionalInfo:@"cancel"];
    }];
}


@end
