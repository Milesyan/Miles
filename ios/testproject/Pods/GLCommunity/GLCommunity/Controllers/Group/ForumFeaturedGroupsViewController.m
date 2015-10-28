//
//  ForumFeaturedGroupsViewController.m
//  emma
//
//  Created by Jirong Wang on 8/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLNetworkLoadingView.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import "ForumFeaturedGroupsViewController.h"
#import "ForumGroupCell.h"
#import "ForumTableHeader.h"
#import "Forum.h"
#import "ForumTopicsViewController.h"

#define SECTION_GROUP_INTRO 0
#define SECTION_RECOMMENDED 1

#define CELL_GROUP_INTRO @"groupIntroCell"
@interface ForumFeaturedGroupsViewController () <ForumGroupCellDelegate,
ForumTableHeaderDelegate>

@property (nonatomic) NSMutableArray *categoriesAndGroupsPreview;
@property (assign, nonatomic) BOOL fetching;
@property (strong, nonatomic) NSMutableArray *recommended;
@property (assign, nonatomic) BOOL firstRefresh;

@end

@implementation ForumFeaturedGroupsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.firstRefresh = YES;
}

- (void)setup {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshDataFromServer) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumGroupCell" bundle:nil] forCellReuseIdentifier:CELL_ID_GROUP_ROW];
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumTableHeader" bundle:nil] forHeaderFooterViewReuseIdentifier: CELL_ID_FORUM_TABLE_HEADER];
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumGroupIntroCell" bundle:nil] forCellReuseIdentifier:CELL_GROUP_INTRO];

    self.categoriesAndGroupsPreview = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.firstRefresh) {
        [self refreshDataFromServerWithSpinner:YES];
    } else {
        [self refreshDataFromServerWithSpinner:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Forum log:PAGE_IMP_FORUM_GROUP_FEATURED];
    
    [self subscribe:EVENT_FORUM_GROUP_LOCAL_SUBSCRIPTION_UPDATED selector:@selector(inplaceRefresh:)];
    [self subscribe:EVENT_FORUM_GROUP_SUBSCRIPTION_UPDATED selector:@selector(inplaceRefresh:)];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self unsubscribeAll];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    // 0 for intro cell
    // 1 for recommended
    return self.categoriesAndGroupsPreview.count + 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == SECTION_GROUP_INTRO) {
        return 0;
    } else if (section == SECTION_RECOMMENDED) {
        return self.recommended.count > 0 ? CELL_H_FORUM_TABLE_HEADER : 0;
    } else {
        if ([self tableView:self.tableView numberOfRowsInSection:section] == 0) {
            return 0;
        }
        return CELL_H_FORUM_TABLE_HEADER;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ForumTableHeader *header = [tableView
                                dequeueReusableHeaderFooterViewWithIdentifier:
                                CELL_ID_FORUM_TABLE_HEADER];
    if (section == SECTION_GROUP_INTRO) {
        return nil;
    } else if (section == SECTION_RECOMMENDED) {
        if (self.recommended.count > 0) {
            [header setupWithBgColor:UIColorFromRGB(0xeeeffa) titleMeta:@{@"title":@"RECOMMENDED", @"color":UIColorFromRGB(0x5a62d2)} rightClickableMeta:nil];
        } else {
            return nil;
        }
    } else {
        header.delegate = self;
        NSDictionary *category = self.categoriesAndGroupsPreview[section-2][@"category"];
        long hexValue = [category[@"category_color"] longValue];
        UIColor *titleColor = UIColorFromRGB(hexValue);
        
        [header setupWithBgColor:[titleColor brighterAndUnsaturatedColor]
                       titleMeta:@{@"title":category[@"name"], @"color":titleColor}
              rightClickableMeta:
         @{@"text":@"See All", @"color": GLOW_COLOR_PURPLE}];
    }
    header.tag = section;
    return header;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == SECTION_GROUP_INTRO) {
        return 0;
    } else if (section == SECTION_RECOMMENDED) {
        return self.recommended.count;
    } else {
        if (section-2 < self.categoriesAndGroupsPreview.count) {
            NSUInteger rows = ((NSArray*)self.categoriesAndGroupsPreview[section-2]
                        [@"groups_preview"]).count;
            return rows;
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_GROUP_INTRO) {
        return 95;
    } else {
        return CELL_H_GROUP;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_GROUP_INTRO) {
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CELL_GROUP_INTRO forIndexPath:indexPath];
        return cell;
    } else {
        ForumGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:
                                CELL_ID_GROUP_ROW forIndexPath:indexPath];
        ForumGroup * group = [self groupFromIndexPath:indexPath];
        if (group) {
            cell.delegate = self;
            [cell setGroup:group];
            if (indexPath.section == SECTION_RECOMMENDED) {
                [cell setCellAccessory:ForumGroupCellAccessoryTypeJoinable];
            } else {
                if ([Forum isSubscribedGroup:group]) {
                    [cell setCellAccessory:ForumGroupCellAccessoryTypeJoined];
                } else {
                    [cell setCellAccessory:ForumGroupCellAccessoryTypeJoinable];
                }
            }
        }
        cell.shouldIndentWhileEditing = NO;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_GROUP_INTRO) {
        return;
    }
    cell.backgroundColor = indexPath.row % 2 == 1 ? FORUMCELL_BG_ODD : FORUMCELL_BG_EVEN;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ForumGroup *group = [self groupFromIndexPath:indexPath];
    if (group) {
        [self presentTopicsViewForGroup:group];
        // [self presentViewForGroup:group];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


# pragma mark - helper
- (ForumGroup *)groupFromIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_GROUP_INTRO) {
        return nil;
    } else if (indexPath.section == SECTION_RECOMMENDED) {
        if (indexPath.row < self.recommended.count) {
            return self.recommended[indexPath.row];
        }
    } else if (indexPath.section-2 < self.categoriesAndGroupsPreview.count) {
        NSArray * groups = self.categoriesAndGroupsPreview[indexPath.section-2][@"groups_preview"];
        if (indexPath.row < groups.count) {
            NSDictionary *dict = [groups objectAtIndex:indexPath.row];
            return [[ForumGroup alloc] initWithDictionary:dict];
        }
    }
    return nil;
}

# pragma mark - view recommended groups
- (void)presentTopicsViewForGroup:(ForumGroup *)group {
    ForumCategory *cat = [Forum categoryFromGroup:group];
    ForumTopicsViewController *vc = [ForumTopicsViewController viewController];
    vc.showGroupInfo = YES;
    vc.category = cat;
//    vc.type = cat.type;
    vc.group = group;
    // vc.isFullViewController = YES;
    //vc.isPresentModally = YES;
    if ([vc isKindOfClass:[ForumTopicsViewController class]]) {
        [self.navigationController pushViewController:vc animated:YES from:self];
    }
}

- (void)inplaceRefresh:(Event *)evt
{
    [self.tableView reloadData];
}

- (void)refreshDataFromServer
{
    [self refreshDataFromServerWithSpinner:YES];
}

- (void)refreshDataFromServerWithSpinner:(BOOL)spinner
{
    if (self.fetching) {
        return;
    }
    self.fetching = YES;
    if (spinner && ![self.refreshControl isRefreshing]) {
        [self.refreshControl beginRefreshing];
        [self.tableView setContentOffset:CGPointMake(0.0, - self.tableView.contentInset.top) animated:YES];
    }

    [Forum fetchFindGroupsPageCallback:^(NSDictionary *result, NSError *error) {
        [self.refreshControl endRefreshing];
        self.fetching = NO;
        
        if (!error && result[@"categories_and_groups_preview"]) {
            self.categoriesAndGroupsPreview = [result[@"categories_and_groups_preview"] mutableCopy];
            self.recommended = [[Forum sharedInstance].recommendedGroups mutableCopy];
            [self.tableView reloadData];
        }
    }];
}

# pragma mark - ForumGroupCell delegate
- (void)clickJoinButton:(ForumGroupCell *)cell
{
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) return;
    ForumGroup *group = [self groupFromIndexPath:indexPath];
    if (!group || group.identifier == 0) return;
    
    [Forum log:BTN_CLK_FORUM_GROUP_JOIN eventData:@{@"group_id": @(group.identifier)}];
    
    BOOL isRecommended = indexPath.section == SECTION_RECOMMENDED;
    NSDictionary *eventData = @{@"group_id": @(group.identifier), @"is_recommended": @(isRecommended)};
    [Forum log:BTN_CLK_FORUM_FEATURED_GROUP_PAGE_JOIN eventData:eventData];
    
    @weakify(self)
    [UIView transitionWithView:cell.joinButton duration:0.2f
                       options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                           [cell setCellAccessory:ForumGroupCellAccessoryTypeJoined];
                       } completion:^(BOOL finished) {
                           [GLNetworkLoadingView showWithDelay:6];
                           [Forum joinGroup:group.identifier
                                   callback:^(NSDictionary *result, NSError *error) {
                                       @strongify(self)
                                       [GLNetworkLoadingView hide];
                                       NSString *msg = @"Joined!";
                                       if (error) {
                                           msg = @"Failed to join. Please try again later.";
                                       } else if ([result[@"rc"] intValue] != RC_SUCCESS) {
                                           if (result[@"msg"]) {
                                               msg = result[@"msg"];
                                           } else {
                                               msg = @"Failed to join. Please try again later.";
                                           }
                                       }
                                       [[GLDropdownMessageController sharedInstance] postMessage:msg duration:3 position:84 inView:[GLUtils keyWindow]];
                                       [self refreshDataFromServerWithSpinner:NO];
                                   }];
                       }];
}

# pragma mark - push SeeAll page
- (void)clickSectionHeaderRight:(ForumTableHeader *)header
{
    NSInteger section = header.tag;
    if (section == SECTION_GROUP_INTRO) {
        return;
    } else if (section == SECTION_RECOMMENDED) {
        return;
    } else if (section-2 >= self.categoriesAndGroupsPreview.count) {
        return;
    }
    NSDictionary *category = self.categoriesAndGroupsPreview[section-2][@"category"];
    [Forum log:BTN_CLK_FIND_GROUPS_SEE_ALL eventData:@{@"new_category_id":category[@"id"]}];
    [self.parentViewController performSegueWithIdentifier:@"findToSeeall" sender:category from:self];
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
