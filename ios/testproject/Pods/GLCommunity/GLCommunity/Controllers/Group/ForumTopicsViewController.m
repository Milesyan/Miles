//
//  ForumTopicsViewController.m
//  emma
//
//  Created by Allen Hsu on 11/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import <GLFoundation/GLNetworkLoadingView.h>
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>

#import "ForumTopicsViewController.h"
#import "ForumAddTopicViewController.h"
#import "ForumTopicDetailViewController.h"
#import "ForumTopicCell.h"
#import "ForumPromotionCell.h"
#import "ForumGroupCell.h"
#import "ForumProfileViewController.h"
#import "ForumGroupRoomViewController.h"
#import "ForumAddTopicViewController.h"
#import "ForumAddPollViewController.h"
#import "ForumAddPhotoViewController.h"
#import "ForumAddURLViewController.h"
#import "GLWebViewController.h"
#import "ForumPromotionFeed.h"

#define SEGUE_ID_ADD_TOPIC      @"addTopic"
#define SEGUE_ID_TOPIC_DETAIL   @"topicDetail"
#define TOPIC_CELL_IDENTIFIER   @"ForumTopicCell"
#define PROMOTION_CELL_IDENTIFIER   @"ForumPromotionCell"

#define LOADING_CELL_IDENTIFIER    @"LoadingCell"

typedef NS_ENUM(NSInteger, ForumTypeSegmentIndex) {
    ForumTypeSegmentBookmarked = 0,
    ForumTypeSegmentCreated = 1,
    ForumTypeSegmentParticipated = 2,
};

@interface ForumTopicsViewController () <ForumTopicCellDelegate, UIGestureRecognizerDelegate, ForumGroupCellDelegate, ForumPromotionCellDelegate>

@property (strong, nonatomic) NSMutableArray *topics;
@property (strong, nonatomic) NSMutableArray *visibleTopics;
@property (strong, nonatomic) NSMutableArray *bookmarkedCache;
@property (strong, nonatomic) NSMutableArray *createdCache;
@property (strong, nonatomic) NSMutableArray *participatedCache;
@property (strong, nonatomic) NSMutableDictionary *groups;
@property (assign, nonatomic) BOOL fetching;
@property (assign, nonatomic) BOOL noMore;
@property (assign, nonatomic) BOOL noMoreBookmarked;
@property (assign, nonatomic) BOOL noMoreCreated;
@property (assign, nonatomic) BOOL noMoreParticipated;
@property (strong, nonatomic) IBOutlet UIView *networkErrorView;
@property (strong, nonatomic) IBOutlet UIView *bookmarkEmptyView;
@property (strong, nonatomic) IBOutlet UIView *noTopicsView;
@property (weak, nonatomic) IBOutlet UIButton *btTryAgain;
@property (strong, nonatomic) IBOutlet UIView *typeView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *typeSeg;
@property (weak, nonatomic) IBOutlet UIButton *inviteWhenNoTopicsButton;


@property (nonatomic, strong) NSMutableArray *observed;

@end

@implementation ForumTopicsViewController

@synthesize topics=_topics;

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"topicList"];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSMutableArray *)topics
{
    if (!_topics) {
        _topics = [NSMutableArray array];
    }
    return _topics;
}

- (void)setTopics:(NSMutableArray *)topics
{
    if (_topics != topics) {
        _topics = topics;
        [self regenerateVisibleTopics];
        [self.tableView reloadData];
    }
}

- (NSMutableArray *)visibleTopics
{
    if (!_visibleTopics) {
        _visibleTopics = [NSMutableArray array];
    }
    return _visibleTopics;
}

- (NSMutableDictionary *)groups
{
    if (!_groups) {
        _groups = [NSMutableDictionary dictionary];
    }
    return _groups;
}

- (NSInteger)indexInTopicsForIndexPath:(NSIndexPath *)indexPath
{
    return !self.showGroupInfo ? indexPath.row : indexPath.row - 1;
}

- (uint64_t)groupId
{
    return self.group.identifier;
}

- (void)_setTypeSeg
{
    self.typeSeg.hidden = NO;
    switch (self.group.type) {
        case ForumGroupCreated:
            [self.typeSeg setSelectedSegmentIndex:1];
            break;
        case ForumGroupParticipated:
            [self.typeSeg setSelectedSegmentIndex:2];
            break;
        case ForumGroupBookmarked:
            [self.typeSeg setSelectedSegmentIndex:0];
            break;
        default:
            self.typeSeg.hidden = YES;
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.observed = [@[] mutableCopy];
 
    // title text
    if (self.group.type == ForumGroupNormal) {
        self.title = self.group.name;
        self.navigationItem.title = self.group.name;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventValueChanged];
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumGroupCell"
                                               bundle:nil] forCellReuseIdentifier:CELL_ID_GROUP_ROW];
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumTopicCell" bundle:nil] forCellReuseIdentifier:TOPIC_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumPromotionCell" bundle:nil] forCellReuseIdentifier:PROMOTION_CELL_IDENTIFIER];
    
    self.typeSeg.tintColor = [UIColor colorFromWebHexValue:self.category.backgroundColor];
    
    self.tableView.tableHeaderView = nil;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.typeView.backgroundColor = [UIColor whiteColor];// UIColorFromRGB(0xfbfaf7);
    
    [[NSBundle mainBundle] loadNibNamed:@"NetworkError" owner:self options:nil];
    [[NSBundle mainBundle] loadNibNamed:@"BookmarkEmpty" owner:self options:nil];
    [[NSBundle mainBundle] loadNibNamed:@"NoTopicsView" owner:self options:nil];
    
    self.networkErrorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.bookmarkEmptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.noTopicsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    self.inviteWhenNoTopicsButton.layer.cornerRadius =
    self.inviteWhenNoTopicsButton.frame.size.height / 2;
    self.inviteWhenNoTopicsButton.clipsToBounds = YES;
    
    NSDictionary *underlineAttribute = @{
                                         NSUnderlineStyleAttributeName: @1,
                                         NSFontAttributeName: [GLTheme defaultFont: 18],
                                         NSForegroundColorAttributeName: GLOW_COLOR_PURPLE,
                                         };
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:[self.btTryAgain titleForState:UIControlStateNormal] ?: @"Try again" attributes:underlineAttribute];
    [self.btTryAgain setAttributedTitle:attrString forState:UIControlStateNormal];
    
//    UIImage *backImg = [UIImage imageNamed:@"gl-community-back"];
//    UIImage *backImgPressed = [UIImage imageNamed:@"gl-community-back-press"];
    
    UIImage *closeImg = [UIImage imageNamed:@"gl-community-topnav-close"];
    UIImage *closeImgPressed = [UIImage imageNamed:@"gl-community-topnav-close-press"];
    
    SEL leftButtonAction = nil;
    UIImage *leftImg = nil;
    UIImage *leftImgPressed = nil;
    
    if (!(self.navigationController.viewControllers.count > 1)) {
        leftImg = closeImg;
        leftImgPressed = closeImgPressed;
        leftButtonAction = @selector(dismissSelf:);
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:leftImg
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:leftButtonAction];
    }
    
    @weakify(self)
    [self subscribe:EVENT_FORUM_ADD_TOPIC_SUCCESS handler:^(Event *event) {
        @strongify(self)
        NSDictionary * data = (NSDictionary *)event.data;
        ForumCategory * category = (ForumCategory *)[data objectForKey:@"category"];
        if ([category isKindOfClass:[ForumCategory class]] && category.identifier == self.category.identifier) {
            [self refreshData:nil];
        }
    }];
    [self subscribe:EVENT_FORUM_DID_HIDE_TOPIC handler:^(Event *event) {
        @strongify(self)
        [self.tableView reloadData];
    }];
    [self subscribe:EVENT_FORUM_AGE_FILTER_UPDATED handler:^(Event *event) {
        @strongify(self)
        [self regenerateVisibleTopics];
        [self.tableView reloadData];
    }];
    [self subscribe:EVENT_FORUM_DID_HIDE_TOPIC handler:^(Event *event) {
        @strongify(self)
        [self regenerateVisibleTopics];
        [self.tableView reloadData];
    }];
    [self subscribe:EVENT_FORUM_TOPIC_UPDATED handler:^(Event *event) {
        @strongify(self)
        [self refreshData:nil];
    }];
    
    [self subscribeOnce:EVENT_PROMOTION_FEED_UPDATED handler:^(Event *event) {
        @strongify(self)
        
        [self regenerateVisibleTopics];
        [self.tableView reloadData];
    }];
    [self subscribe:EVENT_PROMOTION_HEIGHT_UPDATED handler:^(Event *event) {
        @strongify(self)
        GLLog(@"promotion height updated");
        [self.tableView reloadData];
    }];
    [self refreshData:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.group.isBookmark) {
        [self _setTypeSeg];
        [self reloadBookmarkedTopics];
    }
//    [self setupNavigationBarAppearance];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [self resetNavigationBarAppearance];
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


- (void)updateGroupInfo:(ForumGroup *)group
{
    if (group) {
        self.group = group;
        self.category = [Forum categoryFromGroup:group];
        if (group.name) {
            self.title = group.name;
            self.navigationItem.title = group.name;
        }
    }
}

- (IBAction)goBack:(id)sender
{
    if ([self.navigationController.viewControllers lastObject] == self) {
        [self.navigationController popViewControllerAnimated:YES from:self];
    }
}

- (IBAction)dismissSelf:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)typeDidChange:(id)sender {
    if (self.typeSeg.selectedSegmentIndex == 0) {
        [Forum log:BTN_CLK_FORUM_SEG_BOOKMARKED];
        self.group = [ForumGroup bookmarkedGroup];
        //        self.type = ForumCategoryTypeBookmarked;
    } else if (self.typeSeg.selectedSegmentIndex == 1) {
        [Forum log:BTN_CLK_FORUM_SEG_CREATED];
        self.group = [ForumGroup createdGroup];
        //        self.type = ForumCategoryTypeCreated;
    } else {
        [Forum log:BTN_CLK_FORUM_SEG_PARTICIPATED];
        self.group = [ForumGroup participatedGroup];
        //        self.type = ForumCategoryTypeParticipated;
    }
    [self reloadBookmarkedTopics];
}

- (void)regenerateVisibleTopics
{
    NSMutableArray *visibleTopics = [NSMutableArray array];
    NSArray *topics = [self.topics copy];
    for (ForumTopic *topic in topics) {
        if ([topic isHidden]) {
            continue;
        }
        if (self.group.type == ForumGroupHot && topic.shouldHideLowRatingContent) {
            continue;
        }
        [visibleTopics addObject:topic];
    }
  
    if (self.group.type == ForumGroupHot) {
        if ([Forum sharedInstance].delegate && [[Forum sharedInstance].delegate respondsToSelector:@selector(promotionFeed)]) {
            ForumPromotionFeed *feed = [[[Forum sharedInstance] delegate] promotionFeed];
            
            if (feed && visibleTopics.count > 0) {
                NSInteger idx = 0;
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSArray *days = [defaults arrayForKey:@"promotion_days"];
                if (!days) {
                    days = @[];
                }
                
                NSMutableArray *ma = [days mutableCopy];
                NSString *today = [self YMDofDate:[NSDate date]];
                if (![ma containsObject:today]) {
                    [ma addObject:today];
                    
                    [defaults setValue:[NSArray arrayWithArray:ma] forKey:@"promotion_days"];
                    [defaults synchronize];
                }
                
                idx = [days count];
                
                if (idx < 1) {
                    idx = 1;
                }
                if (idx > 10) {
                    idx = 10;
                }
                
                [visibleTopics insertObject:feed
                                    atIndex:(visibleTopics.count > idx)? idx: (visibleTopics.count -1)];
            }
        }
    }
    
    self.visibleTopics = visibleTopics;
}

- (NSString *)YMDofDate:(NSDate *)date {
    NSCalendar *cal = [GLUtils calendar];
    cal.locale = [NSLocale currentLocale];

    NSDateComponents *components = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    NSInteger year = [components year];
    NSInteger month = [components month];
    NSInteger day = [components day];
    NSString *dateLabel = [NSString stringWithFormat:@"%04ld/%02ld/%02ld", (long)year, (long)month, (long)day];
    
    return dateLabel;

}

- (void)reloadBookmarkedTopics {
    BOOL hasCache = NO;
    Forum *forum = [Forum sharedInstance];
    NSString *title;
    
    switch (self.group.type) {
        case ForumGroupBookmarked:
            if (forum.bookmarkedUpdated) {
                forum.bookmarkedUpdated = NO;
            } else if (self.bookmarkedCache) {
                self.topics = self.bookmarkedCache;
                self.noMore = self.noMoreBookmarked;
                hasCache = YES;
            }
            title = @"Bookmarked";
            break;
        case ForumGroupCreated:
            if (forum.createdUpdated) {
                forum.createdUpdated = NO;
            } else if (self.createdCache) {
                self.topics = self.createdCache;
                self.noMore = self.noMoreCreated;
                hasCache = YES;
            }
            title = @"Created";
            break;
        case ForumGroupParticipated:
            if (forum.participatedUpdated) {
                forum.participatedUpdated = NO;
            } else if (self.participatedCache) {
                self.topics = self.participatedCache;
                self.noMore = self.noMoreParticipated;
                hasCache = YES;
            }
            title = @"Participated";
            break;
        default:
            break;
    }
    if (self.parentViewController) {
        self.parentViewController.navigationItem.title = title;
    } else {
        self.navigationItem.title = title;
    }
    
    if (hasCache) {
        if (self.topics.count == 0) {
            self.tableView.tableFooterView = self.bookmarkEmptyView;
        } else {
            self.tableView.tableFooterView = [[UIView alloc] init];
        }
        [self.tableView reloadData];
        [self.tableView setContentOffset:CGPointMake(0.0, - self.tableView.contentInset.top) animated:NO];
    } else {
        self.topics = nil;
        self.noMore = NO;
        [self refreshData:nil];
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

- (IBAction)refreshData:(id)sender {
    [self refreshDataFromServer];
}

- (void)refreshDataFromServer {
    if (self.fetching) {
        [self.refreshControl endRefreshing];
        [self publish:EVENT_FORUM_TOPICS_STOP_LOAD];
        return;
    }
    
    GLLog(@"Refreshing data...");
    self.fetching = YES;
    
    [self publish:EVENT_FORUM_TOPICS_START_LOAD];
    if (![self.refreshControl isRefreshing]) {
        [self.refreshControl beginRefreshing];
        [self.tableView setContentOffset:CGPointMake(0.0, - self.tableView.contentInset.top) animated:YES];
    }
    
    //    ForumCategoryType targetType = self.type;
    ForumGroupType gtype = self.group.type;
    uint64_t gid = self.groupId;
    
    @weakify(self)
    void (^cb)(NSDictionary *result, NSError *error) = ^void(NSDictionary *result, NSError *error) {
        @strongify(self)
        [self publish:EVENT_FORUM_HIDE_TOP_NAVBAR];
        if (gid != self.groupId) {
            GLLog(@"Type does not consistent");
            [[self refreshControl] endRefreshing];
            [self publish:EVENT_FORUM_TOPICS_STOP_LOAD];
            self.fetching = NO;
            return;
        }
        BOOL failed = YES;
        BOOL hasResult = NO;
        if (!error) {
            if ([result isKindOfClass:[NSDictionary class]]) {
                if (result[@"group"]) {
                    ForumGroup *group = [[ForumGroup alloc] initWithDictionary:result[@"group"]];
                    [self updateGroupInfo:group];
                }
                NSArray *groupsArray = result[@"groups"];
                [self appendGroupsFromArray:groupsArray];
                
                NSArray *topicsArray = result[@"topics"];
                if ([topicsArray isKindOfClass:[NSArray class]]) {
                    failed = NO;
                    hasResult = YES;
                    unsigned int pageSize = [[result objectForKey:@"page_size"] unsignedIntValue];
                    self.noMore = pageSize > topicsArray.count;
                    
                    [self.topics removeAllObjects];
                    [self.visibleTopics removeAllObjects];
                    
                    for (NSDictionary *dict in topicsArray) {
                        ForumTopic *topic = [[ForumTopic alloc] initWithDictionary:dict];
                        [self.topics addObject:topic];
                        
                        if ([topic isHidden]) {
                            continue;
                        }
                        if (self.group.type == ForumGroupHot && topic.shouldHideLowRatingContent) {
                            continue;
                        }
                        [self.visibleTopics addObject:topic];
                    }
                    
                    [self regenerateVisibleTopics];
                    if (gtype == self.group.type) {
                        [self cacheDataIfNeeded];
                    }
                    [self.tableView reloadData];
                }
            }
        }
        if (self.topics.count == 0) {
            if (failed) {
                self.tableView.tableFooterView = self.networkErrorView;
            } else if (self.group.type == ForumGroupBookmarked
                       || self.group.type == ForumGroupCreated
                       || self.group.type == ForumGroupParticipated) {
                self.tableView.tableFooterView = self.bookmarkEmptyView;
            } else if (self.group.type == ForumGroupNormal) {
                self.tableView.tableFooterView = self.noTopicsView;
            } else {
                self.tableView.tableFooterView = [[UIView alloc] init];
            }
            //            [self.tableView layoutIfNeeded];
        } else {
            self.tableView.tableFooterView = [[UIView alloc] init];
        }
        if (!hasResult) {
            self.noMore = YES;
            [self.tableView reloadData];
        }
        [[self refreshControl] endRefreshing];
        [self publish:EVENT_FORUM_TOPICS_STOP_LOAD];
        self.fetching = NO;
    };
    
    [[Forum currentForumUser] fetchSocialInfoWithCompletion:nil];
    
    if (self.group.type == ForumGroupHot) {
        [Forum fetchHotTopicsOffset:0 callback:cb];
    } else if (self.group.type == ForumGroupNew) {
        [Forum fetchNewTopicsOffset:0 callback:cb];
    } else {
        [Forum fetchTopicsInGroup:gid withOffset:0 orType:gtype withLastReply:0 callback:cb];
    }
}

- (void)loadMore:(id)sender {
    if (self.fetching || self.topics.count == 0 || self.noMore) {
        return;
    }
    GLLog(@"Loading more...");
    self.fetching = YES;
    [self publish:EVENT_FORUM_TOPICS_START_LOAD];
    ForumTopic *lastTopic = [self.topics lastObject];
    //    ForumCategoryType targetType = self.type;
    ForumGroupType gtype = self.group.type;
    unsigned int lastTime = lastTopic.lastReplyTime;
    uint64_t gid = self.groupId;
    
    @weakify(self)
    void (^cb)(NSDictionary *result, NSError *error) = ^void(NSDictionary *result, NSError *error) {
        @strongify(self)
        if (gtype != self.group.type || gid != self.groupId) {
            GLLog(@"Type does not consistent");
            [[self refreshControl] endRefreshing];
            [self publish:EVENT_FORUM_TOPICS_STOP_LOAD];
            self.fetching = NO;
            return;
        }
        [self.refreshControl endRefreshing];
        BOOL hasResult = NO;
        if (!error) {
            if ([result isKindOfClass:[NSDictionary class]]) {
                NSArray *groupsArray = result[@"groups"];
                [self appendGroupsFromArray:groupsArray];
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
                            if ([topic isHidden]) {
                                continue;
                            }
                            if (self.group.type == ForumGroupHot && topic.shouldHideLowRatingContent) {
                                continue;
                            }
                            [self.visibleTopics addObject:topic];
                        }
                    }
                    if (gtype == self.group.type) {
                        [self cacheDataIfNeeded];
                    }
                    [self.tableView reloadData];
                }
            }
        }
        if (!hasResult) {
//            self.noMore = YES;
            [self.tableView reloadData];
        }
        [self publish:EVENT_FORUM_TOPICS_STOP_LOAD];
        self.fetching = NO;
    };
    
    [Forum log:BTN_CLK_FORUM_LOAD_MORE eventData:@{@"tab_name": self.group.name, @"start_index": @(self.topics.count)}];
    
    if (self.group.type == ForumGroupHot) {
        [Forum fetchHotTopicsOffset:(int)self.topics.count callback:cb];
    } else if (self.group.type == ForumGroupNew) {
        [Forum fetchNewTopicsOffset:(int)self.topics.count callback:cb];
    } else {
        [Forum fetchTopicsInGroup:gid withOffset:(int)self.topics.count orType:gtype withLastReply:lastTime callback:cb];
    }
}

- (void)cacheDataIfNeeded
{
    switch (self.group.type) {
        case ForumGroupBookmarked:
            self.bookmarkedCache = [self.topics mutableCopy];
            self.noMoreBookmarked = self.noMore;
            break;
        case ForumGroupCreated:
            self.createdCache = [self.topics mutableCopy];
            self.noMoreCreated = self.noMore;
            break;
        case ForumGroupParticipated:
            self.participatedCache = [self.topics mutableCopy];
            self.noMoreParticipated = self.noMore;
            break;
        default:
            break;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    Forum *forum = [Forum sharedInstance];
    switch (self.group.type) {
        case ForumGroupNormal:
            break;
        case ForumGroupParticipated:
            if (forum.participatedUpdated) {
                forum.participatedUpdated = NO;
                [self refreshData:nil];
            }
            break;
        case ForumGroupBookmarked:
            if (forum.bookmarkedUpdated) {
                forum.bookmarkedUpdated = NO;
                [self refreshData:nil];
            }
            break;
        case ForumGroupCreated:
            if (forum.createdUpdated) {
                forum.createdUpdated = NO;
                [self refreshData:nil];
            }
            break;
        default:
            break;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.category.backgroundColor.length > 0) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldShowTypeSeg
{
    switch (self.group.type) {
        case ForumGroupBookmarked:
        case ForumGroupCreated:
        case ForumGroupParticipated:
            return YES;
            break;
        default:
            break;
    }
    return NO;
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        if ([self shouldShowTypeSeg]) {
            return self.typeView;
        } else {
            return nil;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return [self shouldShowTypeSeg] ? 44.0 : 0;
    }
    return 0.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        if (!self.showGroupInfo) {
            return self.visibleTopics.count;
        }
        return self.visibleTopics.count + 1;
    } else {
        return (self.noMore || self.topics.count == 0) ? 0 : 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        BOOL hasGroupInfo = self.showGroupInfo;
        if (0 == indexPath.row && hasGroupInfo) {
            ForumGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:
                                    CELL_ID_GROUP_ROW forIndexPath:indexPath];
            cell.delegate = self;
            [cell setGroup:self.group];
            if ([Forum isSubscribedGroup:self.group]) {
                [cell setCellAccessory:ForumGroupCellAccessoryTypeJoined];
            }
            else {
                [cell setCellAccessory:ForumGroupCellAccessoryTypeJoinable];
            }
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return cell;
        }
        
        NSInteger indexInTopics = [self indexInTopicsForIndexPath:indexPath];
       
        if (indexInTopics < self.visibleTopics.count) {
            NSObject *item = [self.visibleTopics objectAtIndex:indexInTopics];
            
            if ([item isKindOfClass:[ForumTopic class]]) {
                ForumTopicCell *cell = [tableView dequeueReusableCellWithIdentifier:TOPIC_CELL_IDENTIFIER forIndexPath:indexPath];
                cell.delegate = self;
                
                ForumTopic *topic = (ForumTopic *)item;
                BOOL showGroup = NO;
                if (self.group.type == ForumGroupHot || self.group.type == ForumGroupNew) {
                    showGroup = [self showsGroupForTopicAtIndex:indexInTopics];
                    if (showGroup) {
                        ForumGroup *group = self.groups[@(topic.groupId)];
                        if (!group) {
                            showGroup = NO;
                        }
                        cell.group = group;
                    }
                }
                [cell configureWithTopic:topic isProfile:NO showGroup:showGroup showPinned:topic.isPinned];
                
                return cell;

            } else if ([item isKindOfClass:[ForumPromotionFeed class]]) {
                ForumPromotionCell *cell = [tableView dequeueReusableCellWithIdentifier:PROMOTION_CELL_IDENTIFIER forIndexPath:indexPath];
                cell.delegate = self;
                
                ForumPromotionFeed *feed = (ForumPromotionFeed *)item;
                [cell setFeed:feed];
                
                if (![self.observed containsObject:cell.contentWebView.scrollView]) {
                    [cell.contentWebView.scrollView addObserver:self forKeyPath:@"contentSize" options:0 context:nil];
                    [self.observed addObject:cell.contentWebView.scrollView];
                }
 
                return cell;
            }
        }
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

    NSInteger indexInTopics = [self indexInTopicsForIndexPath:indexPath];
    
    if (indexInTopics < self.visibleTopics.count) {
        ForumTopic *topic = [self.visibleTopics objectAtIndex:indexInTopics];
        if ([topic isKindOfClass:[ForumTopic class]]) {
            if (self.group.type == ForumGroupHot || self.group.type == ForumGroupNew) {
                
                @try {
                    [Forum log:FORUM_TOPIC_DISPLAYED eventData:@{
                                                                 @"topic_id": @(topic.identifier),
                                                                 @"group_desc": self.group.type == ForumGroupHot? @"hot": @"new",
                                                                 @"index": [NSString stringWithFormat:@"%@", @(indexInTopics)],
                                                                 @"is_subscribed_group": @([[Forum currentForumUser] isSubscribingGroup:topic.groupId]),
                                                                 @"is_following_author": @([[Forum currentForumUser] isFollowingUser:topic.author.identifier]),
                                                                 }];
                }
                @catch (NSException *exception) {
                    
                }
                @finally {
                }
            }
        } else if ([topic isKindOfClass:[ForumPromotionFeed class]]) {
            ForumPromotionFeed *feed = (ForumPromotionFeed *)[self.visibleTopics objectAtIndex:indexInTopics];
            [Forum log:PAGE_IMP_HOT_CARD_MONETIZATION
               eventData:@{
                           @"test_id": @(feed.identifier),
                           }];
 
        }
        

        
    }
 
}

/*
 - (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
 {
 return TOPIC_CELL_HEIGHT_FULL;
 }
 */

- (BOOL)showsGroupForTopicAtIndex:(NSInteger)index
{
    if (index >= self.visibleTopics.count) {
        return NO;
    }
    ForumTopic *topic = self.visibleTopics[index];
    if ([topic isKindOfClass:[ForumTopic class]]) {
        ForumTopic *prevTopic = nil;
        BOOL showsGroup = NO;
        if (index > 0) {
            prevTopic = self.visibleTopics[index - 1];
            if (![prevTopic isKindOfClass:[ForumTopic class]]) {
                prevTopic = nil;
            }
        }
        if (!prevTopic || prevTopic.groupId != topic.groupId) {
            ForumGroup *group = self.groups[@(topic.groupId)];
            if (group) {
                showsGroup = YES;
            }
        }
        return showsGroup;
    }
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (self.showGroupInfo && 0 == indexPath.row) {
            return CELL_H_GROUP;
        }
        
        long index = [self indexInTopicsForIndexPath:
                      indexPath];
        
        if (index >= self.visibleTopics.count) {
            return 0;
        }
        
        NSObject *item = self.visibleTopics[index];
        
        if ([item isKindOfClass:[ForumTopic class]]) {
            if (self.group.type == ForumGroupHot || self.group.type == ForumGroupNew) {
                ForumTopic *topic = self.visibleTopics[index];
                BOOL showsGroup = [self showsGroupForTopicAtIndex:index];
                return [ForumTopicCell cellHeightForTopic:topic showsGroup:showsGroup showsPinned:topic.isPinned];
            }
            ForumTopic *topic = self.visibleTopics[index];
            return [ForumTopicCell cellHeightForTopic:topic showsGroup:NO showsPinned:topic.isPinned];
        } else if ([item isKindOfClass:[ForumPromotionFeed class]]) {
            ForumPromotionFeed *f = self.visibleTopics[index];
            if ([[[Forum sharedInstance] delegate] respondsToSelector:@selector(heightForPromotionFeed:withInWidth:)]) {
                return [[[Forum sharedInstance] delegate] heightForPromotionFeed:f withInWidth:SCREEN_WIDTH - 16] + 50;
            }
            return 0;
        }
        
    }
    return TOPIC_CELL_HEIGHT_FULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        NSInteger indexInTopics = [self indexInTopicsForIndexPath:indexPath];
        if (indexInTopics >= self.visibleTopics.count) {
            return;
        }
        
        NSObject *item = [self.visibleTopics objectAtIndex:indexInTopics];
        
        if ([item isKindOfClass:[ForumTopic class]]) {
            ForumTopic *topic = [self.visibleTopics objectAtIndex:indexInTopics];
            if ([topic shouldHideLowRatingContent]) {
                return;
            }
            
            ForumTopicDetailViewController *detailViewController = [ForumTopicDetailViewController viewController];
            detailViewController.source = IOS_TOPIC_VIEW_FROM_FORUM;
            detailViewController.topic = topic;
            //        if (self.group.type == ForumGroupNormal) {
            //            detailViewController.category = [Forum categoryFromGroup:self.group];
            //        }
            //        if (self.group.type == ForumGroupBookmarked) {
            //            detailViewController.source = IOS_TOPIC_VIEW_FROM_BOOKMARK;
            //        }
            
            NSDictionary *eventData = @{@"topic_id": @(topic.identifier),
                                        @"group_id": @(topic.groupId),
                                        @"row_index": @(indexPath.row),
                                        @"tab_name": self.group.name};
            [Forum log:BTN_CLK_FORUM_SELECT_TOPIC eventData:eventData];
            
            // should not add from:self, because this is a child view controller
            [self.navigationController pushViewController:detailViewController animated:YES from:self];
        }
        else if ([item isKindOfClass:[ForumPromotionFeed class]]) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self cellGotClicked:[self.tableView cellForRowAtIndexPath:indexPath]];
            
            ForumPromotionFeed *feed = [self.visibleTopics objectAtIndex:indexInTopics];
            if ([feed isKindOfClass:[ForumPromotionFeed class]]) {
                [Forum log:BTN_CLK_MONETIZATION_CARD_HOT
                 eventData:@{
                             @"test_id":@(feed.identifier),
                             @"button_index": @(0),
                             }];
            }
        }
        
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
    if (self.navigationController.viewControllers.count > 1 || ![[Forum currentForumUser] isSubscribingGroup:group.identifier]) {
        ForumCategory *cat = [Forum categoryFromGroup:group];
        
        ForumTopicsViewController *vc = [ForumTopicsViewController viewController];
        vc.showGroupInfo = YES;
        vc.category = cat;
        vc.group = group;

        [self.navigationController pushViewController:vc animated:YES from:self];
    } else {
        [self publish:EVENT_FORUM_GOTO_GROUP_TAB data:group];
    }
}

- (void)cell:(ForumTopicCell *)cell hideTopic:(ForumTopic *)topic
{
    @weakify(self)
    UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"Would you like to hide this topic?"];
    [alert bk_addButtonWithTitle:@"Yes, hide it." handler:^{
        @strongify(self)
        [Forum hideTopic:topic.identifier];
        [self publish:EVENT_FORUM_DID_HIDE_TOPIC data:@(topic.identifier)];
    }];
    [alert bk_setCancelButtonWithTitle:@"No" handler:nil];
    [alert show];
}

- (void)cell:(ForumTopicCell *)cell reportTopic:(ForumTopic *)topic
{
    [Forum reportTopic:topic.identifier];
}

- (void)cell:(ForumTopicCell *)cell presentUrlPage:(NSString *)url
{
    GLWebViewController *controller = [GLWebViewController viewController];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:^{
        [controller openUrl:url];
    }];
}

- (void)cell:(ForumTopicCell *)cell showLowRatingContent:(ForumTopic *)topic
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)cell:(ForumTopicCell *)cell showRules:(ForumTopic *)topic
{
    [self publish:EVENT_FORUM_GOTO_RULES_GROUP];
}

- (void)cell:(ForumTopicCell *)cell editTopic:(ForumTopic *)topic {
    GLLog(@"edit topic: %@", topic);
    if (!topic) {
        return;
    }
   
    UIViewController *vc  = nil;
    if (topic.isURLTopic) {
        vc =  [ForumAddURLViewController viewController];
        ((ForumAddURLViewController *)vc).topic = topic;
    } else if (topic.isPhotoTopic) {
        vc = [ForumAddPhotoViewController viewController];
        ((ForumAddPhotoViewController *)vc).topic = topic;
    } else if (topic.isPoll) {
        vc = [ForumAddPollViewController viewController];
        ((ForumAddPollViewController *)vc).topic = topic;
    } else {
        vc = [ForumAddTopicViewController viewController];
        ((ForumAddTopicViewController *)vc).topic = topic;
    }

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.navigationBar.translucent = NO;
    [self presentViewController:nav animated:YES completion:nil];
 
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.scrollDelegate scrollViewDidScroll:scrollView];
    }
    if (scrollView == self.tableView) {
        CGFloat y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom;
        if (y > scrollView.contentSize.height - scrollView.bounds.size.height / 3.0) {
            [self loadMore:nil];
        }
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

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SEGUE_ID_TOPIC_DETAIL]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath.row < self.visibleTopics.count) {
            ForumTopic *topic = [self.visibleTopics objectAtIndex:indexPath.row];
            ForumTopicDetailViewController *detailViewController = [segue destinationViewController];
            detailViewController.source = IOS_TOPIC_VIEW_FROM_FORUM;
            detailViewController.topic = topic;
            detailViewController.category = self.category;
        }
    }
}


# pragma mark - ForumGroupCell delegate
- (void)clickJoinButton:(ForumGroupCell *)cell
{
    if (!self.group || self.group.identifier == 0) {
        return;
    }
    [Forum log:BTN_CLK_FORUM_GROUP_JOIN eventData:@{@"group_id": @(self.group.identifier)}];
    
    [UIView transitionWithView:cell.joinButton duration:0.2f
                       options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                           [cell setCellAccessory:ForumGroupCellAccessoryTypeJoined];
                       } completion:^(BOOL finished) {
                           @weakify(self)
                           [GLNetworkLoadingView showWithDelay:6];
                           [Forum joinGroup:self.group.identifier
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
# pragma mark - ForumPromotionDelegate

- (void)cellDidDismissed:(ForumPromotionCell *)cell {
    NSLog(@"dismiss");
    [Forum log:BTN_CLK_MONETIZATION_CARD_HOT
     eventData:@{
                 @"test_id":@(cell.feed.identifier),
                 @"button_index": @(1),
                 }];
 
    if ([[[Forum sharedInstance] delegate] respondsToSelector:@selector(userDidmissedPromotionFeed:)]) {
       
        UIActionSheet *as = [UIActionSheet bk_actionSheetWithTitle:@"Do you want to remove this item?"];
        [as bk_setDestructiveButtonWithTitle:@"I'm not interested" handler:^{
            [[[Forum sharedInstance] delegate] userDidmissedPromotionFeed:cell.feed];
            [self regenerateVisibleTopics];
            [self.tableView reloadData];

            [Forum log:BTN_CLK_MONETIZATION_CARD_HOT
             eventData:@{
                         @"test_id":@(cell.feed.identifier),
                         @"button_index": @(2),
                         }];

        }];
        [as bk_addButtonWithTitle:@"I already own this item" handler:^{
            [[[Forum sharedInstance] delegate] userDidmissedPromotionFeed:cell.feed];
            [self regenerateVisibleTopics];
            [self.tableView reloadData];
            [Forum log:BTN_CLK_MONETIZATION_CARD_HOT
             eventData:@{
                         @"test_id":@(cell.feed.identifier),
                         @"button_index": @(3),
                         }];
 
        }];

        [as bk_setCancelButtonWithTitle:@"Cancel" handler:^{
            [Forum log:BTN_CLK_MONETIZATION_CARD_HOT
             eventData:@{
                         @"test_id":@(cell.feed.identifier),
                         @"button_index": @(4),
                         }];

        }];
        [as showInView:self.view];
        
    }
    
}

- (void)cellGotClicked:(ForumPromotionCell *)cell {
    NSLog(@"cliked");
    
    if ([[Forum sharedInstance].delegate respondsToSelector:@selector(userClickedPromotionFeed:fromViewController:)]) {
        [[Forum sharedInstance].delegate userClickedPromotionFeed:cell.feed fromViewController:self];
    }
}

# pragma mark - share view

- (IBAction)inviteWhenNoTopicsButtonClicked:(id)sender {
    [Forum shareGroupWithObject:self.group];
}

# pragma mark - class method
+ (ForumTopicsViewController *)pushableControllerBy:(ForumGroup *)group {
    ForumCategory *cat = [Forum categoryFromGroup:group];
    ForumTopicsViewController *vc = [ForumTopicsViewController viewController];
    vc.showGroupInfo = YES;
    vc.category = cat;
    //    vc.type = cat.type;
    vc.group = group;
    //vc.isPresentModally = YES;
    return vc;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[UIScrollView class]]) {
        [self.tableView reloadData];
    }
}

- (void)dealloc {
    for (NSObject *observed in self.observed) {
        [observed removeObserver:self forKeyPath:@"contentSize"];
    }

}

@end
