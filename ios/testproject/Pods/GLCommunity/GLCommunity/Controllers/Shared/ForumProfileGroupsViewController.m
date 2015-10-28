//
//  ForumProfileGroupsViewController.m
//  Pods
//
//  Created by Eric Xu on 5/28/15.
//
//
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import <GLFoundation/GLNetworkLoadingView.h>

#import "ForumProfileGroupsViewController.h"
#import "ForumGroupRoomViewController.h"
#import "ForumTopicsViewController.h"
#import "ForumGroupCell.h"
#import "ForumTableHeader.h"
#import "Forum.h"


@interface ForumProfileGroupsViewController () <ForumGroupCellDelegate, ForumTableHeaderDelegate>

@property (nonatomic, strong) ForumUser *user;
@property (nonatomic, strong) ForumUser *currentUser;
@end

@implementation ForumProfileGroupsViewController

- (instancetype)initWithUser:(ForumUser *)user
{
    self = [super init];
    if (self) {
        _user = user;
        _currentUser = [Forum currentForumUser];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
}

- (void)setup
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshGroup) forControlEvents:UIControlEventValueChanged];
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumGroupCell" bundle:nil] forCellReuseIdentifier:CELL_ID_GROUP_ROW];
    [self.tableView registerNib:[UINib nibWithNibName: @"ForumTableHeader" bundle:nil] forHeaderFooterViewReuseIdentifier:CELL_ID_FORUM_TABLE_HEADER];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.separatorColor = UIColorFromRGB(0xeceff1);
    
    self.navigationItem.title = @"Groups";
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.subscribed) {
        [self refreshGroup];
    }
    [self reloadPage];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Forum log:PAGE_IMP_FORUM_PROFILE_GROUPS];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.subscribed.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_H_GROUP;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ForumGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_ID_GROUP_ROW forIndexPath:indexPath];
    NSArray *groups = self.subscribed;
    
    if (indexPath.row < groups.count) {
        cell.delegate = self;
        ForumGroup *group = groups[indexPath.row];
        [cell setGroup:group];
        if ([self.user isMyself] || [self.currentUser isSubscribingGroup:group.identifier]) {
            [cell setCellAccessory:ForumGroupCellAccessoryTypeJoined];
        }
        else {
            [cell setCellAccessory:ForumGroupCellAccessoryTypeJoinable];
        }
    }
    if (self.tableView.isEditing && !cell.isEditing) {
        cell.overlay.hidden = NO;
    } else {
        cell.overlay.hidden = YES;
    }
    
    cell.shouldIndentWhileEditing = NO;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ForumGroup *group = self.subscribed[indexPath.row];
    ForumCategory *cat = [Forum categoryFromGroup:group];
   
    ForumTopicsViewController * controller = [ForumTopicsViewController viewController];
    controller.showGroupInfo = ![[Forum currentForumUser] isSubscribingGroup:group.identifier];
    controller.category = cat;
    controller.group = group;
    
    [self.navigationController pushViewController:controller animated:YES from:self];
}


#pragma mark - reload

- (void)reloadPage
{
    [self.tableView reloadData];
}

- (void)refreshGroup {
    [self.refreshControl beginRefreshing];
    @weakify(self)
    [Forum fetchGroupsSubscribedByUser:self.user.identifier callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        if (!error) {
            NSMutableArray *groups = [@[] mutableCopy];
            NSArray *array = result[@"result"];
            if ([array isKindOfClass:[NSArray class]]) {
                for (NSDictionary *dict in array) {
                    ForumGroup *group = [[ForumGroup alloc] initWithDictionary:dict];
                    if (group) {
                        [groups addObject:group];
                    }
                }
            }

            self.subscribed = [NSArray arrayWithArray:groups];
            [self reloadPage];
        }
        [self.refreshControl endRefreshing];
    }];
}

# pragma mark - ForumGroupCell delegate
- (void)clickJoinButton:(ForumGroupCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ForumGroup *group = indexPath.row >= self.subscribed.count? nil: self.subscribed[indexPath.row];
    
    if (!group || group.identifier == 0) {
        return;
    }
    [Forum log:BTN_CLK_FORUM_GROUP_JOIN eventData:@{@"group_id": @(group.identifier)}];
    
    @weakify(self)
    [[Forum currentForumUser] joinGroup:group
                             completion:^(BOOL success, NSError *error)
     {
         @strongify(self)
         [GLNetworkLoadingView hide];
         NSString *msg = @"Joined!";
         if (!success) {
             msg = @"Failed to join. Please try again later.";
         }
         else {
            [cell setCellAccessory:ForumGroupCellAccessoryTypeJoined];
         }
         [[GLDropdownMessageController sharedInstance] postMessage:msg duration:3 position:84 inView:[GLUtils keyWindow]];
         [self reloadPage];
     }];
}

#pragma mark - Table view click
- (void)clickSectionHeaderRight:(ForumTableHeader *)header
{
}

@end
