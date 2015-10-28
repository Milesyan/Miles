//
//  ForumHotViewController.m
//  emma
//
//  Created by Jirong Wang on 8/18/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLCameraViewController.h>
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/UIImage+Resize.h>
#import <GLFoundation/UIImage+Utils.h>
#import <GLFoundation/GLDialogViewController.h>
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit.h>

#import "ForumHotViewController.h"
#import "ForumSearchViewController.h"
#import "Forum.h"
#import "ForumTopicCell.h"
#import "ForumTopicDetailViewController.h"
#import "ForumProfileViewController.h"
#import "ForumTopicsViewController.h"
#import "ForumAddTopicViewController.h"
#import "ForumAddPollViewController.h"
#import "ForumAddPhotoViewController.h"
#import "ForumGroupRoomViewController.h"
#import "WelcomeToCommunityDialogViewController.h"
#import "CMPopTipView+Glow.h"

#define SEGMENT_HOT 0
#define SEGMENT_NEW 1

#define LOADING_CELL_IDENTIFIER    @"LoadingCell"

@interface ForumHotViewController () <UITableViewDelegate, UITableViewDataSource, ForumTopicCellDelegate, UIImagePickerControllerDelegate, CMPopTipViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *createBarView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *titleSegment;
@property (nonatomic) ForumSearchViewController * searchViewController;
@property (nonatomic) BOOL searchPoped;

@property (strong, nonatomic) NSMutableArray *topics;
@property (strong, nonatomic) NSMutableArray *cacheHot;
@property (strong, nonatomic) NSMutableArray *cacheNew;
@property (strong, nonatomic) NSMutableDictionary *groups;
@property (assign, nonatomic) BOOL fetching;
@property (assign, nonatomic) BOOL noMore;
//@property (assign, nonatomic) BOOL noMoreHot;
//@property (assign, nonatomic) BOOL noMoreNew;

@property (weak, nonatomic) IBOutlet UIButton *btnPoll;
@property (weak, nonatomic) IBOutlet UIButton *btnTopic;
@property (weak, nonatomic) IBOutlet UIButton *btnPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnSearch;
@property (weak, nonatomic) IBOutlet UIButton *btnBookmark;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnGroups;
@property (strong, nonatomic) UIView *redDotView;
@property (strong, nonatomic) UIView *redNewView;
@property (strong, nonatomic) CMPopTipView *popTipView;

@property (readonly) UITableView *tableView;
@property (readonly) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UITableViewController *tableViewController;
@property (weak, nonatomic) IBOutlet UIView *tableViewContainer;

@property (strong, nonatomic) IBOutlet UIView *networkErrorView;
@property (strong, nonatomic) IBOutlet UIView *bookmarkEmptyView;
@property (strong, nonatomic) IBOutlet UIView *noTopicsView;
@property (weak, nonatomic) IBOutlet UIButton *btTryAgain;

@property (nonatomic) BOOL backFromTopicsPage;

@property (nonatomic) NSNumber * createdTopicId;
@property (nonatomic, strong) NSNumber *welcomeTopicID;

- (IBAction)searchClicked:(id)sender;
- (IBAction)groupClicked:(id)sender;

@end

@implementation ForumHotViewController

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"hot"];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self unsubscribeAll];
}

- (NSMutableDictionary *)groups
{
    if (!_groups) {
        _groups = [NSMutableDictionary dictionary];
    }
    return _groups;
}

- (UITableView *)tableView
{
    return self.tableViewController.tableView;
}

- (UIRefreshControl *)refreshControl
{
    return self.tableViewController.refreshControl;
}

- (NSMutableArray *)topics
{
    if (!_topics) {
        _topics = [NSMutableArray array];
    }
    return _topics;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSArray *btns = @[self.btnPoll, self.btnTopic, self.btnPhoto];
    for (UIButton *btn in btns) {
        UIImage *icon = [btn imageForState:UIControlStateNormal];
        icon = [icon imageWithTintColor:btn.tintColor];
        [btn setImage:icon forState:UIControlStateNormal];
    }
    
    self.tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    
    self.tableViewController.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableViewController.refreshControl addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventValueChanged];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumTopicCell" bundle:nil] forCellReuseIdentifier:TOPIC_CELL_IDENTIFIER];
    
    [self.tableViewController willMoveToParentViewController:self];
    [self addChildViewController:self.tableViewController];
    [self.tableViewContainer addSubview:self.tableView];
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *maker)
    {
        maker.edges.equalTo(self.tableViewContainer).priorityHigh();
    }];
    [self.tableViewController didMoveToParentViewController:self];
    
    [[NSBundle mainBundle] loadNibNamed:@"NetworkError" owner:self options:nil];
    [[NSBundle mainBundle] loadNibNamed:@"BookmarkEmpty" owner:self options:nil];
    
    NSDictionary *underlineAttribute = @{
                                         NSUnderlineStyleAttributeName: @1,
                                         NSFontAttributeName: [GLTheme defaultFont: 18],
                                         NSForegroundColorAttributeName: GLOW_COLOR_PURPLE,
                                         };
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:[self.btTryAgain titleForState:UIControlStateNormal] ?: @"Try again"  attributes:underlineAttribute];
    [self.btTryAgain setAttributedTitle:attrString forState:UIControlStateNormal];
    if (!self.searchViewController) {
        self.searchViewController = [[ForumSearchViewController alloc] init];
        [self addChildViewController:self.searchViewController];
        [self.view addSubview:self.searchViewController.view];
        
        [self.searchViewController.view mas_updateConstraints:^(MASConstraintMaker *maker){
            maker.edges.equalTo(self.view);
        }];
    }
    
    UIImage *searchIcon = [[UIImage imageNamed:@"gl-community-search"] imageWithTintColor:GLOW_COLOR_PURPLE];
    UIImage *bookmarkIcon = [[UIImage imageNamed:@"gl-community-bookmark"] imageWithTintColor:GLOW_COLOR_PURPLE];
    [self.btnSearch setImage:searchIcon forState:UIControlStateNormal];
    [self.btnBookmark setImage:bookmarkIcon forState:UIControlStateNormal];
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = -6.0;
    self.navigationItem.leftBarButtonItems = @[spacer, self.navigationItem.leftBarButtonItem];
    
    [self subscribe:EVENT_FORUM_SEARCH_CANCEL selector:@selector(searchCancel)];
    [self subscribe:EVENT_FORUM_ADD_TOPIC_SUCCESS selector:@selector(forumTopicAdded:)];
    @weakify(self)
    [self subscribe:EVENT_DID_CLICK_COMMUNITY_TAB handler:^(Event *event) {
        @strongify(self)
        if (self.navigationController.topViewController == self) {
            [self.titleSegment setSelectedSegmentIndex:SEGMENT_HOT];
            [self refreshDataFromServer];
        }
    }];
    
    self.titleSegment.selectedSegmentIndex = SEGMENT_HOT;
    
    self.backFromTopicsPage = NO;
    [self refreshDataFromServer];
    
    self.navigationItem.title = NSLocalizedString(@"Topics", nil);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self showTutorialIfNecessary];
    [Forum log:PAGE_IMP_FORUM_HOT_TOPICS];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [self.redNewView removeFromSuperview];
    [self.popTipView removeFromSuperview];
    self.redNewView = nil;
    self.popTipView = nil;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.backFromTopicsPage) {
        self.backFromTopicsPage = NO;
    } else {
    }
    [self.navigationController setNavigationBarHidden:self.searchViewController.isInSearchMode animated:YES];
    self.tabBarController.tabBar.hidden = self.searchViewController.isInSearchMode;
}


- (void)showTutorialIfNecessary
{
    WelcomeToCommunityDialogViewController *vc = [WelcomeToCommunityDialogViewController presentDialogOnlyTheFirstTime];
    if (vc) {
        @weakify(self)
        [Forum fetchWelcomeTopicIdWithCallback:^(NSDictionary *result, NSError *error) {
            @strongify(self)
            if (!error) {
                self.welcomeTopicID = [result objectForKey:@"topic_id"];
            }
            else {
                GLLog(@"peng debug %@", error);
            }
        }];
        
        vc.getStartedAction = ^() {
            @strongify(self)
            if (self.welcomeTopicID) {
                ForumTopic *topic = [[ForumTopic alloc] init];
                topic.identifier = [self.welcomeTopicID unsignedLongLongValue];
                topic.isWelcomeTopic = YES;
                
                ForumTopicDetailViewController *topicViewController = [ForumTopicDetailViewController viewController];
                topicViewController.topic = topic;
                
                [self.navigationController pushViewController:topicViewController animated:YES from:self];
            }
        };
    }
    
    @weakify(self)
    [self subscribe:EVENT_DIALOG_DISMISSED handler:^(Event *event) {
        @strongify(self)
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDidClickGroupsButton]) {
            return;
        }
        
        if (!self.redNewView) {
            self.redNewView = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 32, 2, 28, 14)];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 20, 14)];
            label.backgroundColor = [UIColor clearColor];
            label.text = @"NEW";
            label.textColor = [UIColor whiteColor];
            label.font = [GLTheme semiBoldFont:8];
            [self.redNewView addSubview:label];
            
            self.redNewView.backgroundColor = [UIColor redColor];
            self.redNewView.layer.cornerRadius = self.redNewView.height / 2;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.navigationController.topViewController == self) {
                    [self.navigationController.navigationBar addSubview:self.redNewView];
                }
            });
        }
        
        if (!self.popTipView) {
            self.popTipView = [[CMPopTipView alloc] initWithMessage:@"New groups for you here!"];
            self.popTipView.delegate = self;
            [self.popTipView customize];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.popTipView presentPointingAtBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
            });
        }
        
//        if (![[GLUtils getDefaultsForKey:DEFAULTS_GG_TUTORED] boolValue]) {
//            [self publish:EVENT_SHOW_GG_TUTORIAL_POPUP data:@(15.0)];
//        }
    }];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kDidClickNewSectionInCommunity]) {
        if (!self.redDotView && self.titleSegment.selectedSegmentIndex != 1) {
            self.redDotView = [[UIView alloc] initWithFrame:CGRectMake(54, 5, 8, 8)];
            self.redDotView.backgroundColor = [UIColor redColor];
            self.redDotView.layer.cornerRadius = self.redDotView.height / 2;
            [self.titleSegment.subviews[0] addSubview:self.redDotView];
        }
    }
}


- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    if (sender == self.btnGroups && ![defs boolForKey:kDidClickGroupsButton]) {
        [defs setBool:YES forKey:kDidClickGroupsButton];
        [defs synchronize];
        
        [self.popTipView removeFromSuperview];
        [self.redNewView removeFromSuperview];
        
        self.popTipView = nil;
        self.redNewView = nil;
    }
}


- (void)appendGroupsFromArray:(NSArray *)newGroups {
    if ([newGroups isKindOfClass:[NSArray class]]) {
        for (NSDictionary *dict in newGroups) {
            ForumGroup *group = [[ForumGroup alloc] initWithDictionary:dict];
            if (group) {
                self.groups[@(group.identifier)] = group;
            }
        }
    }
}

- (void)refreshData:(id)sender {
    // selector handler
    [self refreshDataFromServer];
}

- (void)refreshDataFromServer {
    // separated from "refreshData", since we don't want to let one function
    // perform 2 actors - selector handler and server caller.
    // This function only works as "server caller"
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
   
    NSInteger currentIndex = self.titleSegment.selectedSegmentIndex;
    @weakify(self)
    void (^cb)(NSDictionary *result, NSError *error) = ^void(NSDictionary *result, NSError *error) {
        @strongify(self)
        if (self.titleSegment.selectedSegmentIndex != currentIndex) {
            self.fetching = NO;
            return;
        }
        BOOL failed = YES;
        BOOL hasResult = NO;
        if (!error) {
            if ([result isKindOfClass:[NSDictionary class]]) {
                NSArray *groupsArray = result[@"groups"];
                [self appendGroupsFromArray:groupsArray];
                NSArray *topicsArray = result[@"topics"];
                if ([topicsArray isKindOfClass:[NSArray class]]) {
                    failed = NO;
                    hasResult = YES;
                    unsigned int pageSize = [[result objectForKey:@"page_size"] unsignedIntValue];
                    self.noMore = pageSize > topicsArray.count;
                    [self.topics removeAllObjects];
                    for (NSDictionary *dict in topicsArray) {
                        ForumTopic *topic = [[ForumTopic alloc] initWithDictionary:dict];
                        [self.topics addObject:topic];
                    }
                    [self cacheDataIfNeeded];
                    [self.tableView reloadData];
                }
            }
        }
        if (self.topics.count == 0) {
            if (failed) {
                self.tableView.tableFooterView = self.networkErrorView;
            } else {
                self.tableView.tableFooterView = self.noTopicsView;
            }
        } else {
            self.tableView.tableFooterView = nil;
        }
        if (!hasResult) {
            self.noMore = YES;
            [self.tableView reloadData];
        }
        [[self refreshControl] endRefreshing];
        
        self.fetching = NO;
    };
    switch (self.titleSegment.selectedSegmentIndex) {
        case SEGMENT_HOT:
            [Forum fetchHotTopicsOffset:0 callback:cb];
            break;
        case SEGMENT_NEW:
            [Forum fetchNewTopicsOffset:0 callback:cb];
            break;
        default:
            break;
    }
}

- (void)loadMore {
    if (self.fetching || self.topics.count == 0 || self.noMore) {
        return;
    }
    GLLog(@"Loading more...");
    self.fetching = YES;
    
    NSInteger currentIndex = self.titleSegment.selectedSegmentIndex;
    @weakify(self)
    void (^cb)(NSDictionary *result, NSError *error) = ^void(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self.refreshControl endRefreshing];
        if (self.titleSegment.selectedSegmentIndex != currentIndex) {
            self.fetching = NO;
            return;
        }
        BOOL hasResult = NO;
        if (!error) {
            if ([result isKindOfClass:[NSDictionary class]]) {
                NSArray *topicsArray = [result objectForKey:@"topics"];
                if ([topicsArray isKindOfClass:[NSArray class]]) {
                    hasResult = YES;
                    unsigned int pageSize = [[result objectForKey:@"page_size"] unsignedIntValue];
                    self.noMore = pageSize > topicsArray.count;
                    BOOL foundNewTopic = NO;
                    for (NSDictionary *dict in topicsArray) {
                        ForumTopic *topic = [[ForumTopic alloc] initWithDictionary:dict];
                        BOOL exists = NO;
                        
                        // Test if the topic is already in the array
                        if (self.topics.count > 0 && !foundNewTopic) {
                            NSInteger index = self.topics.count - 1;
                            ForumTopic *testTopic = [self.topics objectAtIndex:index];
                            while (!exists && index >= 0) {
                                if (topic.identifier == testTopic.identifier) {
                                    exists = YES;
                                }
                                index--;
                                if (index >= 0) {
                                    testTopic = [self.topics objectAtIndex:index];
                                }
                            }
                        }
                        
                        if (!exists) {
                            foundNewTopic = YES;
                            [self.topics addObject:topic];
                        }
                    }
                    [self cacheDataIfNeeded];
                    [self.tableView reloadData];
                }
            }
        }
        if (!hasResult) {
            self.noMore = YES;
            [self.tableView reloadData];
        }
        self.fetching = NO;
    };
    
    switch (self.titleSegment.selectedSegmentIndex) {
        case SEGMENT_HOT:
            [Forum fetchHotTopicsOffset:(int)self.topics.count callback:cb];
            break;
        case SEGMENT_NEW:
            [Forum fetchNewTopicsOffset:(int)self.topics.count callback:cb];
            break;
        default:
            break;
    }
}


- (IBAction)searchClicked:(id)sender {
    [Forum log:BTN_CLK_FORUM_HOME_SEARCH];
    
    [self.searchViewController toggleSearchBar];
    self.searchPoped = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self.popTipView removeFromSuperview];
    self.popTipView = nil;
}

- (IBAction)bookmarkClicked:(id)sender {
    [Forum log:BTN_CLK_FORUM_HOME_BOOKMARK];
    [self gotoBookmarkGroup];
}

- (IBAction)groupClicked:(id)sender {
    [Forum log:BTN_CLK_FORUM_HOME_GO_GROUPS];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.searchPoped) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (void)searchCancel {
    self.searchPoped = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView) {
        CGFloat y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom;
        if (y > scrollView.contentSize.height - scrollView.bounds.size.height / 3.0) {
            [self loadMore];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.topics.count;
    } else if (section == 1) {
        return (self.topics.count == 0 || self.noMore) ? 0 : 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        ForumTopicCell *cell = [tableView dequeueReusableCellWithIdentifier:TOPIC_CELL_IDENTIFIER forIndexPath:indexPath];
        cell.delegate = self;
       
        if (indexPath.row < self.topics.count) {
            ForumTopic *topic = [self.topics objectAtIndex:indexPath.row];
            ForumTopic *prevTopic = nil;
            BOOL showsGroup = NO;
            if (indexPath.row > 0) {
                prevTopic = self.topics[indexPath.row - 1];
            }
            if (!prevTopic || prevTopic.groupId != topic.groupId) {
                ForumGroup *group = self.groups[@(topic.groupId)];
                if (group) {
                    showsGroup = YES;
                }
                cell.group = group;
            }
            [cell configureWithTopic:topic isProfile:NO showGroup:showsGroup showPinned:topic.isPinned];
        }
        return cell;
    }
    else if (indexPath.section == 1) {
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:LOADING_CELL_IDENTIFIER];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LOADING_CELL_IDENTIFIER];
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.font = [GLTheme defaultFont:18.0];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        for (UIView *view in cell.contentView.subviews) {
            [view removeFromSuperview];
        }
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [indicatorView startAnimating];
        indicatorView.hidden = NO;
        [cell.contentView addSubview:indicatorView];
        [indicatorView mas_updateConstraints:^(MASConstraintMaker *maker){
            maker.center.equalTo(cell.contentView);
        }];
        return cell;
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row < self.topics.count) {
        ForumTopic *topic = self.topics[indexPath.row];
        ForumTopic *prevTopic = nil;
        BOOL showsGroup = NO;
        if (indexPath.row > 0) {
            prevTopic = self.topics[indexPath.row - 1];
        }
        if (!prevTopic || prevTopic.groupId != topic.groupId) {
            ForumGroup *group = self.groups[@(topic.groupId)];
            if (group) {
                showsGroup = YES;
            }
        }
        return [ForumTopicCell cellHeightForTopic:topic showsGroup:showsGroup showsPinned:topic.isPinned];
    }
    return TOPIC_CELL_HEIGHT_FULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        NSInteger indexInTopics = indexPath.row;
        if (indexInTopics >= self.topics.count) {
            return;
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        ForumTopic *topic = [self.topics objectAtIndex:indexInTopics];
        ForumTopicDetailViewController *detailViewController = [ForumTopicDetailViewController viewController];
        detailViewController.topic = topic;
//        detailViewController.category = [Forum categoryFromGroup:self.group];
        // should not add from:self, because this is a child view controller
        [self.navigationController pushViewController:detailViewController animated:YES from:self];
    }
}

- (void)cell:(ForumTopicCell *)cell showProfileForUser:(ForumUser *)user
{
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    ForumProfileViewController *vc = [[ForumProfileViewController alloc] initWithUserID:user.identifier
                                                                        placeholderUser:user];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)cell:(ForumTopicCell *)cell gotoGroup:(ForumGroup *)group
{
    ForumCategory *cat = [Forum categoryFromGroup:group];
    ForumGroupRoomViewController *controller = [ForumGroupRoomViewController viewController];
    controller.category = cat;
    controller.group = group;
    self.backFromTopicsPage = YES;
    [self.navigationController pushViewController:controller animated:YES from:self];
}

- (void)cacheDataIfNeeded
{
    switch (self.titleSegment.selectedSegmentIndex) {
        case SEGMENT_HOT:
            self.cacheHot = [self.topics mutableCopy];
//            self.noMoreHot = self.noMore;
            break;
        case SEGMENT_NEW:
            self.cacheNew = [self.topics mutableCopy];
//            self.noMoreNew = self.noMore;
            break;
        default:
            break;
    }
}

- (IBAction)segmentClicked:(id)sender {
    switch (self.titleSegment.selectedSegmentIndex) {
        case SEGMENT_HOT:
            [Forum log:BTN_CLK_FORUM_HOME_TOP];
            break;
        case SEGMENT_NEW:
            [Forum log:BTN_CLK_FORUM_HOME_NEW];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDidClickNewSectionInCommunity];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self.redDotView removeFromSuperview];
            self.redDotView = nil;
            break;
        default:
            break;
    }
    [self reloadTopics];
}

- (void)reloadTopics {
    BOOL hasCache = NO;
    if (hasCache) {
        if (self.topics.count == 0) {
            self.tableView.tableFooterView = self.noTopicsView;
        } else {
            self.tableView.tableFooterView = nil;
        }
        [self.tableView reloadData];
        [self.tableView setContentOffset:CGPointMake(0.0, - self.tableView.contentInset.top) animated:NO];
    } else {
        self.topics = nil;
        self.noMore = NO;
        [self.tableView reloadData];
        [self refreshDataFromServer];
    }
}

- (IBAction)createTopicButtonClicked:(id)sender {
    [Forum log:BTN_CLK_FORUM_HOME_CREATE_TOPIC];
    [self presentAddTopicViewController];
}

- (IBAction)createPollButtonClicked:(id)sender {
    [Forum log:BTN_CLK_FORUM_HOME_CREATE_POLL];
    [self presentAddPollViewController];
}

- (IBAction)createPhotoButtonClicked:(id)sender {
    [Forum log:BTN_CLK_FORUM_HOME_CREATE_PHOTO];
    [self presentAddPhotoViewController];
}

- (void)presentAddTopicViewController {
    ForumAddTopicViewController *addTopicViewController = [ForumAddTopicViewController viewController];
    UINavigationController *addTopicNavController = [[UINavigationController alloc] initWithRootViewController:addTopicViewController];
    addTopicNavController.navigationBar.translucent = NO;
    [self presentViewController:addTopicNavController animated:YES completion:nil];
}

- (void)presentAddPollViewController {
    ForumAddPollViewController *controller = [ForumAddPollViewController viewController];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    nav.navigationBar.translucent = NO;
    [self presentViewController:nav animated:YES completion:nil];
}


- (void)presentAddPhotoViewController {
    GLCameraViewController *camera = [[GLCameraViewController alloc] initWithImagePickerDelegate:self];
    camera.allowsEditing = YES;
    [self presentViewController:camera animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = nil;
    if (picker.allowsEditing) {
        image = info[UIImagePickerControllerEditedImage];
    }
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
        image = [image thumbnailImage:640 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationMedium];
    }
    if (image) {
        ForumAddPhotoViewController *controller = [ForumAddPhotoViewController viewController];
        controller.image = image;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navController.navigationBar.translucent = NO;
        @weakify(self)
        [self dismissViewControllerAnimated:YES completion:^{
            @strongify(self)
            [self presentViewController:navController animated:YES completion:nil];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - share to topic

- (void)forumTopicAdded:(Event *)event {
    NSDictionary * data = (NSDictionary *)event.data;
    ForumTopic * topic = (ForumTopic *)[data objectForKey:@"topic"];
    ForumCategory * category = (ForumCategory *)[data objectForKey:@"category"];

    ForumTopicDetailViewController *detailViewController = [ForumTopicDetailViewController viewController];
    detailViewController.topic = topic;
    detailViewController.category = category;
    // should not add from:self, because this is a child view controller

    self.createdTopicId = @(topic.identifier);
    [Forum shareTopicWithObject:topic];
}


- (void)gotoBookmarkGroup
{
    ForumGroupRoomViewController *controller = [ForumGroupRoomViewController viewController];
    controller.category = [ForumCategory bookmarkCategory];
//    controller.bookmarkType = ForumCategoryTypeBookmarked;
    controller.group = [ForumGroup bookmarkedGroup];
    self.backFromTopicsPage = YES;
    [self.navigationController pushViewController:controller animated:YES from:self];
}

@end
