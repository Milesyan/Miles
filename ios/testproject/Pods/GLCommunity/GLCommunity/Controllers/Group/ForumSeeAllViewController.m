//
//  ForumSeeAllViewController.m
//  emma
//
//  Created by Xin Zhao on 7/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import <GLFoundation/GLNetworkLoadingView.h>
#import <GLFoundation/GLLog.h>
#import "Forum.h"
#import "ForumSeeAllViewController.h"
#import "ForumGroupCell.h"
#import "ForumTopicsViewController.h"

@interface ForumSeeAllViewController () <ForumGroupCellDelegate>

@property (assign, nonatomic) BOOL fetching;
@property (assign, nonatomic) BOOL noMore;
@property (strong, nonatomic) NSArray *allGroups;

@end

@implementation ForumSeeAllViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshData:)
                  forControlEvents:UIControlEventValueChanged];
    
    // navigation appearence
    self.navigationItem.title = self.category.name;
    
    // table cell register
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumGroupCell"
                                               bundle:nil] forCellReuseIdentifier:CELL_ID_GROUP_ROW];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //first fetching
    [self refreshData:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([Forum sharedInstance].groupPageDataUpdated) {
        [self.tableView reloadData];
    }
    [Forum log:PAGE_IMP_FORUM_ALL_GROUPS eventData:@{@"new_category_id": @(self.category.identifier)}];
    
    [self subscribe:EVENT_FORUM_GROUP_SUBSCRIPTION_UPDATED selector:
     @selector(inplaceRefresh:)];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self unsubscribeAll];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavigationBarAppearance
{
    if (self.category.backgroundColor) {
        [self.navigationController.navigationBar setBarTintColor:[UIColor colorFromWebHexValue:self.category.backgroundColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        UIColor * cc = [UIColor whiteColor];
        NSDictionary * dict = [NSDictionary dictionaryWithObject:cc forKey:NSForegroundColorAttributeName];
        self.navigationController.navigationBar.titleTextAttributes = dict;
    }
}


- (void)resetNavigationBarAppearance
{
    if (self.category.backgroundColor) {
        [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
        [self.navigationController.navigationBar setTintColor:UIColorFromRGB(0x6c6dd3)];
        
        NSDictionary * dict = [NSDictionary dictionaryWithObject:UIColorFromRGB(0x5b5b5b)
                                                          forKey:NSForegroundColorAttributeName];
        self.navigationController.navigationBar.titleTextAttributes = dict;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (0 == section) {
        return self.allGroups.count;
    } else {
        return (self.noMore || 0 == self.allGroups.count) ? 0 : 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:
(NSIndexPath *)indexPath
{
    if (0 == indexPath.section) {
        return CELL_H_GROUP;
    }
    return 118;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.section) {
        ForumGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:
                                CELL_ID_GROUP_ROW forIndexPath:indexPath];
        
        if (indexPath.row < self.allGroups.count) {
            cell.delegate = self;
            [cell setGroup:self.allGroups[indexPath.row]];
            if ([Forum isSubscribedGroup:self.allGroups[indexPath.row]]) {
                [cell setCellAccessory:ForumGroupCellAccessoryTypeJoined];
            }
            else {
                [cell setCellAccessory:ForumGroupCellAccessoryTypeJoinable];
            }
        }
        
        return cell;
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadingCell"];
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.font = [GLTheme defaultFont:18.0];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        for (UIView *view in cell.contentView.subviews) {
            [view removeFromSuperview];
        }
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicatorView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, 22.0);
        indicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [indicatorView startAnimating];
        indicatorView.hidden = NO;
        [cell.contentView addSubview:indicatorView];
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:
(NSIndexPath *)indexPath
{
    if (indexPath.row < self.allGroups.count) {
        ForumGroup *group = [self.allGroups objectAtIndex:indexPath.row];
        [self presentViewForGroup:group];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = indexPath.row % 2 == 1
    ? FORUMCELL_BG_ODD : FORUMCELL_BG_EVEN;
}

- (void) inplaceRefresh:(Event *)evt
{
    [self.tableView reloadData];
}

# pragma mark - data fetching
- (IBAction)refreshData:(id)sender {
    if (self.fetching) {
        [self.refreshControl endRefreshing];
        return;
    }
    GLLog(@"Refreshing data...");
    self.fetching = YES;
    if (![self.refreshControl isRefreshing]) {
        [self.refreshControl beginRefreshing];
        [self.tableView setContentOffset:CGPointMake(0.0, - self.tableView.contentInset.top) animated:YES];
    }
    uint64_t cid = self.category.identifier;
    
    @weakify(self)
    [Forum fetchGroupsInCategory:cid offset:0 callback:^(NSDictionary *result, NSError *error){
        @strongify(self)
        [self.refreshControl endRefreshing];
        if (cid != self.category.identifier) {
            GLLog(@"Type does not consistent");
            return;
        }
        BOOL failed = YES;
        if (!error && [result[@"rc"] intValue] == RC_SUCCESS) {
            failed = NO;
            NSArray *fetched = (NSArray*)result[@"groups"];
            unsigned int pageSize = [[result objectForKey:@"page_size"]
                                     unsignedIntValue];
            self.noMore = pageSize > fetched.count;
            NSMutableArray *groups = [NSMutableArray array];
            if ([fetched isKindOfClass:[NSArray class]]) {
                for (NSDictionary *dict in fetched) {
                    ForumGroup *group = [[ForumGroup alloc] initWithDictionary:dict];
                    if (group) {
                        [groups addObject:group];
                    }
                }
            }
            self.allGroups = [NSArray arrayWithArray:groups];
            [self.tableView reloadData];
        }
        self.fetching = NO;
    }];
}

- (void)loadMore:(id)sender {
    if (self.fetching || self.allGroups.count == 0 || self.noMore) {
        return;
    }
    GLLog(@"Loading more...");
    self.fetching = YES;
    
    uint64_t cid = self.category.identifier;
    @weakify(self)
    [Forum fetchGroupsInCategory:cid offset:(int)self.allGroups.count callback:^(NSDictionary *result, NSError *error){
        @strongify(self)
        [self.refreshControl endRefreshing];
        if (cid != self.category.identifier) {
            GLLog(@"Type does not consistent");
            return;
        }
        BOOL failed = YES;
        if (!error && [result[@"rc"] intValue] == RC_SUCCESS) {
            failed = NO;
            NSArray *fetched = [result objectForKey:@"groups"];
            unsigned int pageSize = [[result objectForKey:@"page_size"]
                                     unsignedIntValue];
            self.noMore = pageSize > fetched.count;
            NSMutableArray *groupsAfterAdding = [self.allGroups mutableCopy];
            if ([fetched isKindOfClass:[NSArray class]]) {
                for (NSDictionary *dict in fetched) {
                    ForumGroup *group = [[ForumGroup alloc] initWithDictionary:dict];
                    NSPredicate *existingDetect = [NSPredicate predicateWithFormat:
                                                   @"identifier == %llu", group.identifier];
                    NSArray *existing = [self.allGroups filteredArrayUsingPredicate:
                                         existingDetect];
                    if (existing.count == 0) {
                        [groupsAfterAdding addObject:group];
                    }
                }
            }
            self.allGroups = (NSArray*)groupsAfterAdding;
            [self.tableView reloadData];
        }
        self.fetching = NO;
    }];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView) {
        CGFloat y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom;
        if (y > scrollView.contentSize.height - scrollView.bounds.size.height / 3.0) {
            [self loadMore:nil];
        }
    }
}

# pragma mark - ForumGroupCell delegate
- (void)clickJoinButton:(ForumGroupCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) return;
    ForumGroup *group = indexPath.row >= self.allGroups.count
    ? nil : self.allGroups[indexPath.row];
    if (!group || group.identifier == 0) return;
    [Forum log:BTN_CLK_FORUM_GROUP_JOIN eventData:@{@"group_id": @(group.identifier)}];
    
    [UIView transitionWithView:cell.joinButton duration:0.2f
                       options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                           [cell setCellAccessory:ForumGroupCellAccessoryTypeJoined];
                       } completion:^(BOOL finished) {
                           @weakify(self)
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
                                       [self refreshData:nil];
                                   }];
                       }];
}

# pragma mark - push topics(group) view
- (void)presentViewForGroup:(ForumGroup *)group {
    ForumCategory *cat = [Forum categoryFromGroup:group];
    ForumTopicsViewController *vc = [ForumTopicsViewController viewController];
    vc.showGroupInfo = YES;
    vc.category = cat;
//    vc.type = ForumCategoryTypeNormal;
    vc.group = group;
    // vc.isFullViewController = YES;
    //vc.isPresentModally = YES;
    if ([vc isKindOfClass:[ForumTopicsViewController class]]) {
//        GLNavigationController *nav = [[GLNavigationController alloc] initWithRootViewController:vc];
//        nav.navigationBar.translucent = NO;
        [self.navigationController pushViewController:vc animated:YES from:self];
    }
}


@end
