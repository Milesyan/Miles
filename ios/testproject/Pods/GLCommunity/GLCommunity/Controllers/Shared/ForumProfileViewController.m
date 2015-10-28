//
//  ForumProfileViewController.m
//  emma
//
//  Created by Allen Hsu on 1/2/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLNameFormatter.h>
#import <GLFoundation/UIImage+Utils.h>
#import <GLFoundation/GLWebViewController.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import "MWPhotoBrowser.h"
#import "UINavigationBar+Awesome.h"

#import "ForumProfileHeaderView.h"
#import "ForumProfileViewController.h"
#import "ForumProfileDataController.h"
#import "ForumTopicDetailViewController.h"
#import "ForumCommentViewController.h"
#import "ForumEditProfileViewController.h"
#import "ForumSocialUsersViewController.h"
#import "ForumProfileGroupsViewController.h"
#import "ForumGroupsViewController.h"
#import "ForumTopicCell.h"
#import "ForumProfileReplyCell.h"
#import "Forum.h"

#define LOADING_CELL_IDENTIFIER    @"LoadingCell"
#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define kDefaultBackgroundOverlayAlpha 0.15

@interface ForumProfileViewController () <UITableViewDataSource, UITableViewDelegate, ForumTopicCellDelegate, ForumProfileReplyCellDelegate, UIGestureRecognizerDelegate, ForumProfileHeaderViewDelegate>

@property (weak, nonatomic) IBOutlet ForumProfileHeaderView *profileHeaderView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) UIView *loadingView;
@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIImageView *navigationBarShadowView;
@property (strong, nonatomic) UILabel *navigationBarTitleView;

@property (strong, nonatomic) ForumProfileDataController *dataController;
@property (strong, nonatomic) ForumUser *user;
@property (assign, nonatomic) BOOL isUserSelf;
@property (assign, nonatomic) BOOL shouldHidePosts;
@property (assign, nonatomic) BOOL isFetchingData;
@property (assign, nonatomic) BOOL hideStatusBar;

@property (assign, nonatomic) BOOL isPresented;

@end


@implementation ForumProfileViewController

- (instancetype)initWithUserID:(uint64_t)userid placeholderUser:(ForumUser *)user
{
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeTop;
        
        _user = user;
        _dataController = [[ForumProfileDataController alloc] initWithUserID:userid];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumTopicCell" bundle:nil]
         forCellReuseIdentifier:TOPIC_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumProfileReplyCell" bundle:nil]
         forCellReuseIdentifier:PROFILE_REPLY_CELL_IDENTIFIER];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableHeaderView = self.profileHeaderView;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.profileHeaderView.delegate = self;
    
    self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 120)];
    self.messageLabel.font = [GLTheme defaultFont:18];
    self.messageLabel.textColor = [UIColor lightGrayColor];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc]
                                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicatorView.center = CGPointMake(SCREEN_WIDTH/2, 60);
    [indicatorView startAnimating];
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 120)];
    [self.loadingView addSubview:indicatorView];
    
    [self subscribeEvents];
    [self setupNavigationBarStyle];
    
    if (self.user) {
        [self updateProfileHeaderView];
    }
    
    [self loadInitialData];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.clipsToBounds = YES;
    [self.navigationController.navigationBar lt_setBackgroundColor:[UIColor clearColor]];
    
    self.isPresented = self.isBeingPresented;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Forum log:PAGE_IMP_FORUM_PROFILE];
//    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self resetNavigationBar];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


- (void)resetNavigationBar
{
    self.navigationBarShadowView.hidden = NO;
    self.navigationController.navigationBar.clipsToBounds = NO;
    [self.navigationController.navigationBar lt_reset];
}


- (void)dealloc
{
    [self unsubscribeAll];
}


- (void)subscribeEvents
{
    @weakify(self)
    [self subscribe:EVENT_PROFILE_IMAGE_UPDATE handler:^(Event *event) {
        @strongify(self)
        [self.tableView reloadData];
    }];
    [self subscribe:EVENT_PROFILE_MODIFIED handler:^(Event *event) {
        @strongify(self)
        [self updateProfileHeaderView];
        
        // may switched on hide_posts
        [self.tableView reloadData];
        [self updateTableFooterView];
    }];
    [self subscribe:kForumEditProfileViewControllerDidUpdateProfileInfo handler:^(Event *event) {
        @strongify(self)
        [self updateProfileHeaderView];
        
        // may switched on hide_posts
        [self.tableView reloadData];
        [self updateTableFooterView];
    }];
    
    [self subscribe:EVENT_FORUM_TOPIC_BOOKMARKED handler:^(Event *event) {
        @strongify(self)
        ForumTopic *topic = (ForumTopic *)event.data;
        if (topic.bookmarked) {
            [self.dataController addTopicToBookmarkedTopics:topic];
        }
        else {
            [self.dataController removeTopicFromBookmarkedTopics:topic];
        }
        
        if (self.dataController.activityType == ForumUserActivityTypeBookmarked) {
            [self.tableView reloadData];
            [self updateTableFooterView];
        }
    }];
}


- (void)setupNavigationBarStyle
{
    UINavigationBar *bar = self.navigationController.navigationBar;
    self.navigationBarShadowView = [self findNavigationBarShadowImageView:bar];
    self.navigationBarShadowView.hidden = YES;
    
    CGFloat barHeight = self.navigationController.navigationBar.height;
    UIView *titleContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 180, barHeight)];
    self.navigationBarTitleView = [[UILabel alloc] initWithFrame:CGRectMake(0, barHeight, 180, 18)];
    self.navigationBarTitleView.textAlignment = NSTextAlignmentCenter;
    self.navigationBarTitleView.font = [GLTheme boldFont:18];
    self.navigationBarTitleView.textColor = UIColorFromRGB(0xfbfaf7);
    [titleContainerView addSubview:self.navigationBarTitleView];
    self.navigationItem.titleView = titleContainerView;
    
    // back button
    UIImage *backImage = [UIImage imageNamed:@"gl-community-back"];
    backImage = [backImage imageWithTintColor:UIColorFromRGB(0xfbfaf7)];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 39)];
    [button setImage:backImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}


- (void)goBack:(id)sender
{
    if (self.navigationController.viewControllers.count > 1) {
        if (self.navigationController.topViewController == self) {
            [self.navigationController popViewControllerAnimated:YES from:self];
        }
    } else {
        if (!self.isBeingDismissed) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}


- (UIImageView *)findNavigationBarShadowImageView:(UIView *)view
{
    if ([view isKindOfClass:UIImageView.class] && view.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findNavigationBarShadowImageView:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}


- (BOOL)shouldHidePosts
{
    return ![self.user isMyself] && self.user && self.user.hidePosts;
}


- (void)updateProfileHeaderView
{
    self.navigationBarTitleView.text = self.user.firstName;
    [self.profileHeaderView configureWithUser:self.user];
    self.tableView.tableHeaderView = self.profileHeaderView;
    
    if (self.profileHeaderView.segmentsControl.indexChangeBlock) {
        return;
    }
    
    @weakify(self)
    self.profileHeaderView.segmentsControl.indexChangeBlock = ^(NSInteger index) {
        @strongify(self)
        
        if (self.shouldHidePosts) {
            return;
        }
        
        ForumUserActivityType type;
        if ([self.user isMyself]) {
            if (index == 0) {
                type = ForumUserActivityTypeParticipated;
            }
            else if (index == 1) {
                type = ForumUserActivityTypeCreated;
            }
            else {
                type = ForumUserActivityTypeBookmarked;
            }
        }
        else {
            if (index == 0) {
                type = ForumUserActivityTypePopularFeed;
            }
            else {
                type = ForumUserActivityTypeFeed;
            }
        }
        
        [self loadDataWithType:type];
        
        [Forum log:BTN_CLK_FORUM_PROFILE_SELECT_SEGMENT eventData:@{@"segment": self.dataController.activityTypeDescription}];
    };
}


- (void)updateTableFooterView
{
    if (self.shouldHidePosts) {
        self.messageLabel.text = @"Content has been hidden.";
        self.tableView.tableFooterView = self.messageLabel;
        self.tableView.scrollEnabled = NO;
        return;
    }
    
    self.tableView.scrollEnabled = YES;
    
    if (self.isFetchingData) {
        self.tableView.tableFooterView = self.loadingView;
        return;
    }

    NSInteger count = self.dataController.activeItems.count;
    if (count == 0) {
        self.messageLabel.text = @"No content available.";
        self.tableView.tableFooterView = self.messageLabel;
        return;
    }
    
    self.tableView.tableFooterView = [[UIView alloc] init];
}


#pragma mark - update data

- (void)loadInitialData
{
    self.isFetchingData = YES;
    [self updateTableFooterView];
    @weakify(self)
    [self.dataController fetchInitialDataWithCompletion:^(BOOL success, NSError *error) {
        @strongify(self)
        self.isFetchingData = NO;
        self.user = self.dataController.user;
        [self.tableView reloadData];
        [self updateTableFooterView];
        [self updateProfileHeaderView];
    }];
}


- (void)loadDataWithType:(ForumUserActivityType)dataType
{
    // set data type and reload data
    self.dataController.activityType = dataType;
    [self.tableView reloadData];
    
    // we already has items for this data type
    if (self.dataController.activeItems.count > 0) {
        [self updateTableFooterView];
        return;
    }
    
    // no items and has loaded data before
    if (self.shouldHidePosts || self.dataController.hasLoadedItems) {
        [self updateTableFooterView];
        return;
    }
    
    // First time loading data
    self.isFetchingData = YES;
    [self updateTableFooterView];
    
    @weakify(self)
    [self.dataController fetchData:dataType completion:^(BOOL success, NSError *error) {
        @strongify(self)
        self.isFetchingData = NO;
        [self.tableView reloadData];
        [self updateTableFooterView];
    }];
}


- (void)loadMore
{
    if (self.isFetchingData || self.dataController.hasNoMoreItems) {
        return;
    }
    
    self.isFetchingData = YES;
    [self updateTableFooterView];
    @weakify(self)
    [self.dataController fetchMoreDataWithCompletion:^(BOOL success, NSError *error) {
        @strongify(self)
        self.isFetchingData = NO;
        [self.tableView reloadData];
        [self updateTableFooterView];
    }];
}


#pragma mark - tableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.shouldHidePosts ? 0 : self.dataController.activeItems.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = self.dataController.activeItems[indexPath.row];
    if (self.dataController.activityType != ForumUserActivityTypeBookmarked &&
        self.dataController.activityType != ForumUserActivityTypeParticipated) {
        [item setAuthor:self.user];
    }

    if ([item isKindOfClass:[ForumTopic class]]) {
        ForumTopicCell *cell = [tableView dequeueReusableCellWithIdentifier:TOPIC_CELL_IDENTIFIER
                                                               forIndexPath:indexPath];
        cell.delegate = self;
        cell.isParticipatedTopic = self.dataController.activityType == ForumUserActivityTypeParticipated;
        [cell configureWithTopic:item isProfile:YES showGroup:NO showPinned:NO];
        return cell;
    }
    
    ForumProfileReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:PROFILE_REPLY_CELL_IDENTIFIER
                                                                  forIndexPath:indexPath];
    cell.delegate = self;
    [cell configureWithReply:(ForumReply *)item];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = self.dataController.activeItems[indexPath.row];
    if ([item isKindOfClass:[ForumTopic class]]) {
        return [ForumTopicCell cellHeightForTopic:item];
    }
    return [ForumProfileReplyCell cellHeightFor:item];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
   
    id item = [self.dataController.activeItems objectAtIndex:indexPath.row];
    BOOL isTopic = [item isKindOfClass:[ForumTopic class]];
    ForumTopic *topic = isTopic ? item : [(ForumReply *)item topic];
    
    ForumTopicDetailViewController *detailViewController = [ForumTopicDetailViewController viewController];
    detailViewController.source = IOS_TOPIC_VIEW_FROM_PROFILE;
    detailViewController.topic = topic;
    
    if (!isTopic) {
        detailViewController.replyId = [(ForumReply *)item identifier];
    }
    
    [self.navigationController pushViewController:detailViewController animated:YES from:self];
    
    [self logSelectionForItem:item atIndexPath:indexPath];
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self.dataController.activeItems objectAtIndex:indexPath.row];
    BOOL isTopic = [item isKindOfClass:[ForumTopic class]];
    
    return isTopic ? indexPath : nil;
}


- (void)logSelectionForItem:(id)item atIndexPath:(NSIndexPath *)indexPath
{
    BOOL isTopic = [item isKindOfClass:[ForumTopic class]];
    ForumTopic *topic = isTopic ? item : [(ForumReply *)item topic];
    
    ForumFeedType postType = isTopic ? ForumFeedTypeTopic : ForumFeedTypeComment;
    NSNumber *postID = isTopic ? @(topic.identifier) : @([(ForumReply *)item identifier]);
    NSString *segment = self.dataController.activityTypeDescription;
    
    NSDictionary *eventData = @{@"post_type": @(postType), @"post_id": postID,
                                @"row_index": @(indexPath.row), @"segment": segment};
    [Forum log:BTN_CLK_FORUM_PROFILE_SELECT_POST eventData:eventData];
}


#pragma mark - cell delegates
- (void)forumProfileReplyCellDidClickViewAllReplies:(ForumProfileReplyCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ForumReply *reply = [self.dataController.activeItems objectAtIndex:indexPath.row];
    
    ForumCommentViewController *commentView = [ForumCommentViewController viewController];
    commentView.reply = reply;
    commentView.topic = reply.topic;
    [self.navigationController pushViewController:commentView animated:YES from:self];
}


- (void)forumProfileReplyCellDidClickTopicCard:(ForumProfileReplyCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath) {
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
}


- (void)forumProfileReplyCell:(ForumProfileReplyCell *)cell needToPresentImageBrowser:(MWPhotoBrowser *)imageBrowser
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imageBrowser];
    [self presentViewController:nav animated:YES completion:nil];
}


- (void)forumProfileHeaderView:(ForumProfileHeaderView *)cell needToPresentImageBrowser:(MWPhotoBrowser *)imageBrowser
{
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imageBrowser];
    [self presentViewController:nav animated:YES completion:nil];
}


#pragma mark - scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.y;
    CGFloat navigationTop = self.navigationController.navigationBar.height;
    
    if (offset > kProfileUsenameTransitionPoint + 30) {
        navigationTop = 14;
    }
    else if (offset > kProfileUsenameTransitionPoint && offset <= kProfileUsenameTransitionPoint + 30) {
        navigationTop = 44 + kProfileUsenameTransitionPoint - offset;
    }
    else if (offset > 0) {
        CGFloat alpha = offset / (kProfileBackgroundImageHeight - kNavigationBarHeight);
        self.navigationBarShadowView.hidden = alpha >= 1;
    }
    else {
        
    }
    
    self.navigationBarTitleView.top = navigationTop;
    
    [self.profileHeaderView updateLayoutWithScrollingOffset:offset];
    
    CGFloat y = scrollView.contentOffset.y + scrollView.height;
    if (y > scrollView.contentSize.height - scrollView.height / 3.0) {
        [self loadMore];
    }
}


#pragma mark - actions
- (IBAction)showGroups:(id)sender
{
    [Forum log:BTN_CLK_FORUM_PROFILE_SHOW_GROUPS];

    if ([self.user isMyself]) {
        ForumGroupsViewController *vc = [ForumGroupsViewController viewController];
        vc.isMyGroups = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        ForumProfileGroupsViewController *vc = [[ForumProfileGroupsViewController alloc] initWithUser:self.user];
        [self.navigationController pushViewController:vc animated:YES from:self];
    }
}


- (IBAction)showFollowers:(id)sender
{
    [Forum log:BTN_CLK_FORUM_PROFILE_SHOW_FOLLOWERS];

    ForumSocialUsersViewController *vc = [[ForumSocialUsersViewController alloc] initWithUser:self.user
                                                                               socialRelation:SocialRelationTypeFollowers];
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)showFollowings:(id)sender
{
    [Forum log:BTN_CLK_FORUM_PROFILE_SHOW_FOLLOWINGS];

    ForumSocialUsersViewController *vc = [[ForumSocialUsersViewController alloc] initWithUser:self.user
                                                                               socialRelation:SocialRelationTypeFollowings];
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)editProfile:(id)sender
{
    [Forum log:BTN_CLK_FORUM_PROFILE_EDIT_PROFILE];
    ForumEditProfileViewController *vc = [[ForumEditProfileViewController alloc] initWithUser:self.user];
    [self.navigationController pushViewController:vc animated:YES from:self];
    
    [sender setSelected:NO];
}


- (void)cell:(ForumTopicCell *)cell presentUrlPage:(NSString *)url
{
    GLWebViewController *controller = [GLWebViewController viewController];
    [controller openUrl:url];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:nil];
}


@end






