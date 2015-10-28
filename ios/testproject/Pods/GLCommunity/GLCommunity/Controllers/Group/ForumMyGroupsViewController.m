//
//  ForumMyGroupsViewController.m
//  emma
//
//  Created by Jirong Wang on 8/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLNetworkLoadingView.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import "ForumMyGroupsViewController.h"
#import "ForumGroupCell.h"
#import "ForumTableHeader.h"
#import "Forum.h"
#import "ForumTopicsViewController.h"
#import "ForumGroupRoomViewController.h"

#define SECTION_BOOKMAKR  0
#define SECTION_SUBSCRIBE 1

@interface ForumMyGroupsViewController () <ForumGroupCellDelegate, ForumTableHeaderDelegate>

@property (strong, nonatomic) NSMutableArray *subscribed;
@property (assign, nonatomic) BOOL dirty;

@end

@implementation ForumMyGroupsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)setup {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshGroup) forControlEvents:UIControlEventValueChanged];
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumGroupCell" bundle:nil] forCellReuseIdentifier:CELL_ID_GROUP_ROW];
    [self.tableView registerNib:[UINib nibWithNibName: @"ForumTableHeader" bundle:nil] forHeaderFooterViewReuseIdentifier:CELL_ID_FORUM_TABLE_HEADER];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorInset = UIEdgeInsetsZero;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([Forum sharedInstance].cidToCategories.count == 0 ||
        [Forum sharedInstance].subscribedGroups.count == 0) {
        [self refreshGroup];
    } else {
        [self reloadPage];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Forum log:PAGE_IMP_FORUM_GROUP_MY_GROUP];
   // self.pushInteractor = [[GLPushableInteractor alloc]
   //                        initWithParentViewController:self];
    [self subscribe:EVENT_FORUM_GROUP_SUBSCRIPTION_UPDATED selector:@selector(reloadPage)];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.dirty = NO;
    [Forum saveOrderWith:self.subscribed];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    if (section == SECTION_BOOKMAKR) {
//        return 0;
//    }
//    return CELL_H_FORUM_TABLE_HEADER;
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    if (section == SECTION_BOOKMAKR) {
//        return nil;
//    }
//    ForumTableHeader *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:CELL_ID_FORUM_TABLE_HEADER];
//    if (section == SECTION_BOOKMAKR) {
//        [header setupWithBgColor:[UIColor colorWithWhite:0.5f alpha:0.95f] titleMeta:@{@"title":@"BOOKMARKS", @"color":[UIColor whiteColor]} rightClickableMeta: nil];
//    } else {
//        [header setupWithBgColor:[UIColor whiteColor] titleMeta:@{
//            @"title":@"MY GROUPS",
//            @"color":[UIColor blackColor]
//        } rightClickableMeta:@{
//            @"text":self.tableView.isEditing ? @"Save" : @"Leave/Reorder",
//            @"color":GLOW_COLOR_PURPLE
//        }];
//        header.delegate = self;
//    }
//    header.tag = section;
//    return header;
//}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SECTION_BOOKMAKR) {
//        return 3;
        return 0;
    } else {
        return self.subscribed.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_BOOKMAKR) {
        return 50;
    } else {
        return CELL_H_GROUP;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ForumGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_ID_GROUP_ROW forIndexPath:indexPath];
    NSArray *groups = nil;
    if (indexPath.section == SECTION_BOOKMAKR) {
        groups = [ForumGroup aggregatedGroups];
    } else if (indexPath.section == SECTION_SUBSCRIBE) {
        groups = self.subscribed;
    } else {
        return nil;
    }
    
    if (indexPath.row < groups.count) {
        cell.delegate = self;
        ForumGroup *group = groups[indexPath.row];
        [cell setGroup:group];
        if (indexPath.section == SECTION_BOOKMAKR) {
            [cell setCellAccessory:ForumGroupCellAccessoryTypeThin];
        } else if (indexPath.section == SECTION_SUBSCRIBE) {
            [cell setCellAccessory:ForumGroupCellAccessoryTypeMyGroup];
        }
        //    [cell setCellAccessory:ForumGroupCellAccessoryTypeJoinable];
    }
    if (self.tableView.isEditing && !cell.isEditing) {
        cell.overlay.hidden = NO;
    } else {
        cell.overlay.hidden = YES;
    }
    
    cell.shouldIndentWhileEditing = NO;
    return cell;
}


#pragma mark - Table view click
- (void)clickSectionHeaderRight:(ForumTableHeader *)header
{
    if (header.tag == SECTION_SUBSCRIBE) {
        if (!self.tableView.isEditing) {
            header.rightLabel.text = @"Save";
            [self enterEditing];
            [Forum log:BTN_CLK_MY_GROUPS_EDIT];
        }
        else {
            [Forum saveOrderWith:self.subscribed];
            header.rightLabel.text = @"Leave/Reorder";
            [self exitEditing];
            [Forum log:BTN_CLK_MY_GROUPS_SAVE];
            [Forum fetchGroupsPageCallback:^(NSDictionary *result, NSError *error) {
                [self reloadPage];
                [self.refreshControl endRefreshing];
            }];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_BOOKMAKR) {
        if (indexPath.row == 0) {
            [Forum log:BTN_CLK_MY_GROUPS_BOOKMARKED];
        } else if (indexPath.row == 1) {
            [Forum log:BTN_CLK_MY_GROUPS_CREATED];
        } else if (indexPath.row == 2) {
            [Forum log:BTN_CLK_MY_GROUPS_PARTICIPATED];
        }
        if (indexPath.row < 3) {
            // Deprecated
        }
    } else if (indexPath.section == SECTION_SUBSCRIBE) {
        if (indexPath.row < self.subscribed.count) {
            ForumGroup *group = self.subscribed[indexPath.row];
            [self presentGroupView:group];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

# pragma mark - edit rows
- (void)enterEditing
{
    [self.tableView setEditing:YES animated:YES];
    [self.tableView reloadData];
}

- (void)exitEditing
{
    [self.tableView setEditing:NO animated:YES];
    [self reloadPage];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == SECTION_SUBSCRIBE? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == SECTION_SUBSCRIBE);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == SECTION_SUBSCRIBE) ? tableView.isEditing : NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (UITableViewCellEditingStyleDelete == editingStyle) {
        ForumGroup *group = [self subscribedGroupFromIndexPath:indexPath];
        if (group) {
            [self.subscribed removeObject:group];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [[Forum currentForumUser] leaveGroup:group completion:^(BOOL success, NSError *error) {
                
            }];
            self.dirty = YES;
        }
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if (SECTION_SUBSCRIBE != fromIndexPath.section || SECTION_SUBSCRIBE != toIndexPath.section ||
        fromIndexPath.row >= self.subscribed.count ||
        toIndexPath.row >= self.subscribed.count) {
        return;
    }
    
    ForumGroup *movedGroup = self.subscribed[fromIndexPath.row];
    [self.subscribed removeObjectAtIndex:fromIndexPath.row];
    [self.subscribed insertObject:movedGroup atIndex:toIndexPath.row];
    self.dirty = YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if( SECTION_SUBSCRIBE != proposedDestinationIndexPath.section ) {
        return sourceIndexPath;
    } else {
        return proposedDestinationIndexPath;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (SECTION_SUBSCRIBE == indexPath.section) {
        return @"Leave";
    }
    return @"Delete";
}

# pragma mark - ForumGroupCell delegate
- (void)clickJoinButton:(ForumGroupCell *)cell {
    return;
}

#pragma mark - helper
- (ForumGroup *)subscribedGroupFromIndexPath:(NSIndexPath *)indexPath
{
    if (SECTION_SUBSCRIBE == indexPath.section) {
        return indexPath.row >= self.subscribed.count ? nil : self.subscribed[indexPath.row];
    }
    /*
    } else if (2 == indexPath.section) {
        return indexPath.row >= self.recommended.count ? nil
        : self.recommended[indexPath.row];
    }
     */
    return nil;
}


#pragma mark - reload

- (void)reloadPage
{
    self.subscribed = [[Forum reorderGroups:[Forum sharedInstance].subscribedGroups] mutableCopy];
    // self.recommended = [[Forum sharedInstance].recommendedGroups mutableCopy];
    [self.tableView reloadData];
}

- (void)refreshGroup {
    [self.refreshControl beginRefreshing];
    @weakify(self)
    [Forum fetchGroupsPageCallback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self publish:EVENT_FORUM_HIDE_TOP_NAVBAR];
        [self reloadPage];
        [self.refreshControl endRefreshing];
    }];
}

# pragma mark - goto group page
- (void)presentGroupView:(ForumGroup *)group {
    [self.parentViewController performSegueWithIdentifier:@"viewGroup" sender:group from:self.parentViewController];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.scrollDelegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.scrollDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.scrollDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

@end
