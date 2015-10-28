//
//  ForumUserListViewController.m
//  Pods
//
//  Created by Peng Gu on 5/28/15.
//
//

#import <GLFoundation/GLFoundation.h>
#import "ForumSocialUsersViewController.h"
#import "ForumProfileViewController.h"
#import "ForumUserListCell.h"
#import <BlocksKit/NSArray+BlocksKit.h>
#import "Forum.h"

@interface ForumSocialUsersViewController ()

@property (nonatomic, strong) ForumUser *user;
@property (nonatomic, assign) SocialRelationType socialRelationType;
@property (nonatomic, strong) NSArray *users;

@property (nonatomic, assign) BOOL isFetchingData;

@end


@implementation ForumSocialUsersViewController

- (instancetype)initWithUser:(ForumUser *)user socialRelation:(SocialRelationType)relation
{
    ForumSocialUsersViewController * vc = [[Forum storyboard] instantiateViewControllerWithIdentifier:@"ForumFollowing"];
    vc.user = user;
    vc.socialRelationType = relation;
    return vc;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = 82;
    
    if (self.socialRelationType == SocialRelationTypeFollowers) {
        self.navigationItem.title = @"Followers";
    }
    else if (self.socialRelationType == SocialRelationTypeFollowings) {
        self.navigationItem.title = @"Following";
    }
    
    if (self.showCloseButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(dismiss)];
    }
    
    [self loadSocialInfo];
}


- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.socialRelationType == SocialRelationTypeFollowers) {
        [Forum log:PAGE_IMP_FORUM_PROFILE_FOLLOWERS];
    } else if (self.socialRelationType == SocialRelationTypeFollowings) {
        [Forum log:PAGE_IMP_FORUM_PROFILE_FOLLOWINGS];
    }
}


- (void)loadSocialInfo
{
    self.isFetchingData = YES;
    if (self.socialRelationType == SocialRelationTypeFollowers) {
        [Forum fetchFollowersForUser:self.user.identifier withOffset:0 callback:^(NSDictionary *result, NSError *error) {
            self.isFetchingData = NO;
            [self handleFetchResult:result error:error];
        }];
    }
    else if (self.socialRelationType == SocialRelationTypeFollowings) {
        [Forum fetchFollowingsForUser:self.user.identifier withOffset:0 callback:^(NSDictionary *result, NSError *error) {
            self.isFetchingData = NO;
            [self handleFetchResult:result error:error];
        }];
    }
}


- (void)handleFetchResult:(NSDictionary *)result error:(NSError *)error
{
    if (!error && result) {
        NSArray *users = result[@"users"];
        self.users = [users bk_map:^id(id obj) {
            return [[ForumUser alloc] initWithDictionary:obj];
        }];
        [self.tableView reloadData];
        
        if (self.users.count == 0) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 120)];
            label.font = [GLTheme defaultFont:16];
            label.textColor = [UIColor lightGrayColor];
            label.textAlignment = NSTextAlignmentCenter;
            
            NSString *type = self.socialRelationType == SocialRelationTypeFollowers ? @"followers" : @"following";
            BOOL isSelf = self.user.identifier == [Forum currentForumUser].identifier;
            NSString *format = isSelf ? @"You have no %@ yet." : @"No %@ yet.";
            label.text = [NSString stringWithFormat:format, type];
            
            self.tableView.tableFooterView = label;
        }
    }
}


#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.users.count;
    }
    
    return self.isFetchingData ? 1 : 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        ForumUserListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserListCell" forIndexPath:indexPath];
        ForumUser *user = self.users[indexPath.row];
        
        [cell configureWithUser:user];
        return cell;
    }
    else if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:@"LoadingCell"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        for (UIView *view in cell.contentView.subviews) {
            [view removeFromSuperview];
        }
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [indicatorView startAnimating];
        indicatorView.hidden = NO;
        indicatorView.center = CGPointMake(SCREEN_WIDTH/2, 105/2);
        
        [cell.contentView addSubview:indicatorView];
        return cell;
    }
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    ForumUser *user = self.users[indexPath.row];
    ForumProfileViewController *vc = [[ForumProfileViewController alloc] initWithUserID:user.identifier
                                                                        placeholderUser:user];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - Navigation


@end






