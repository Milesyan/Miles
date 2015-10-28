//
//  ForumAgeFilterViewController.m
//  GLCommunity
//
//  Created by Allen Hsu on 2/11/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import "ForumAgeFilterViewController.h"
#import "Forum.h"

@interface ForumAgeFilterViewController ()

@property (copy, nonatomic) NSArray *availableRanges;
@property (strong, nonatomic) NSMutableArray *selectedRows;

@end

@implementation ForumAgeFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.hidesBottomBarWhenPushed = YES;
    self.availableRanges = [Forum availableAgeRanges];
    self.selectedRows = [[Forum selectedAgeRangeIndexes] mutableCopy];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Forum log:PAGE_IMP_FORUM_AGE_FILTER];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.availableRanges.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"optionCell"];
    NSString *text = @"";
    if (indexPath.row < self.availableRanges.count) {
        NSValue *v = self.availableRanges[indexPath.row];
        NSRange r = [v rangeValue];
        text = [Forum descriptionOfAgeRange:r];
    }
    cell.textLabel.text = text;
    if ([self.selectedRows containsObject:@(indexPath.row)]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *rowObj = @(indexPath.row);
    if ([self.selectedRows containsObject:rowObj]) {
        if (self.selectedRows.count > 1) {
            [self.selectedRows removeObject:rowObj];
        }
    } else {
        [self.selectedRows addObject:rowObj];
    }
    [self.tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Age Filter";
    }
    return nil;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return @"A checkmark indicates that you will only see topics created by that selected age group. All other topics will be filtered out.";
    }
    return nil;
}

//
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//    NSString *title = [self tableView:tableView titleForFooterInSection:section];
//    if (title) {
//        CGFloat height = [self tableView:tableView heightForFooterInSection:section];
//        CGFloat width = tableView.width;
//        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];
//        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, width - 30.0, height - 10.0)];
//        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//        label.textColor = UIColorFromRGB(0x6cba2d);
//        label.font = [GLTheme defaultFont:15.0];
//        label.text = title;
//        label.numberOfLines = 0;
//        [label sizeToFit];
//        [view addSubview:label];
//        return view;
//    }
//    return nil;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return 80.0;
//}

- (IBAction)save:(id)sender {
    NSMutableArray *rows = [self.selectedRows mutableCopy];
    long selectedIndexes = 0;
    for (NSNumber *n in rows) {
        if ([n intValue] >= self.availableRanges.count) {
            [rows removeObject:n];
        } else {
            selectedIndexes |= 1 << [n intValue];
        }
    }
    [Forum log:BTN_CLK_FORUM_AGE_FILTER_SAVE eventData:@{@"selected_indexes": @(selectedIndexes)}];
    [Forum setSelectedAgeRangeIndexes:rows];
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (!self.isBeingDismissed) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end