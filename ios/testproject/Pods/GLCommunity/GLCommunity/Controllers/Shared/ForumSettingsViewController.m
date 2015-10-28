//
//  ForumSettingsViewController.m
//  GLCommunity
//
//  Created by Allen Hsu on 2/12/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import "ForumSettingsViewController.h"
#import "ForumProfileViewController.h"
#import "ForumGroupsViewController.h"

#import "Forum.h"
#import "ForumUser.h"

@interface ForumSettingsViewController ()

@property (copy, nonatomic) NSArray *availableRanges;
@property (strong, nonatomic) NSMutableArray *selectedRows;
@property (weak, nonatomic) IBOutlet UITableViewCell *ageFilterCell;

@end

@implementation ForumSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.availableRanges = [Forum availableAgeRanges];
    self.selectedRows = [[Forum selectedAgeRangeIndexes] mutableCopy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateContent];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Forum log:PAGE_IMP_FORUM_SETTINGS];
}

- (void)updateContent
{
    self.ageFilterCell.detailTextLabel.text = [Forum selectedAgeRangeDescription];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)save:(id)sender {
    if (!self.isBeingDismissed) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 && indexPath.row == 3) {
        //My profile
        if (![Forum isLoggedIn]) {
            [Forum actionRequiresLogin];
            return;
        }
        ForumUser *forumUser = [Forum currentForumUser];
        ForumProfileViewController *vc = [[ForumProfileViewController alloc] initWithUserID:forumUser.identifier
                                                                            placeholderUser:forumUser];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"myGroups"]) {
        [Forum log:BTN_CLK_FORUM_SETTINGS_MY_GROUPS];
        UINavigationController *nav = segue.destinationViewController;
        if ([nav isKindOfClass:[UINavigationController class]]) {
            ForumGroupsViewController *vc = [[nav viewControllers] firstObject];
            if ([vc isKindOfClass:[ForumGroupsViewController class]]) {
                vc.isMyGroups = YES;
            }
        }
    } else if ([segue.identifier isEqualToString:@"addGroups"]) {
        [Forum log:BTN_CLK_FORUM_SETTINGS_ADD_GROUPS];
    } else if ([segue.identifier isEqualToString:@"ageFilter"]) {
        [Forum log:BTN_CLK_FORUM_SETTINGS_AGE_FILTER];
    }
}

@end
