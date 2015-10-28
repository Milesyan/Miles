//
//  ForumTabBarController.m
//  GLCommunity
//
//  Created by Allen Hsu on 11/3/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLNavigationController.h>
#import <GLFoundation/UIImage+Utils.h>
#import <GLFoundation/GLDialogViewController.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import <GLFoundation/GLWebViewController.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <Masonry/Masonry.h>

#import "ForumTabNavController.h"
#import "Forum.h"
#import "ForumTabButton.h"
#import "ForumGroupRoomViewController.h"
#import "ForumGroupsViewController.h"
#import "ForumSearchViewController.h"
#import "ForumTopicDetailViewController.h"
#import "WelcomeToCommunityDialogViewController.h"
#import "ForumMyGroupPopupViewController.h"
#import "ForumProfileViewController.h"
#import "ForumIntroduceFollowViewController.h"
#import "ForumQuizViewController.h"

#define USER_DEFAULTS_KEY_FORUM_RULES_OPENED            @"forum_rules_opened"
#define USER_DEFAULTS_KEY_FORUM_TUTS_MAIN_FINISHED      @"forum_tuts_main_finished"
#define USER_DEFAULTS_KEY_FORUM_TUTS_GROUPS_FINISHED    @"forum_tuts_groups_finished"

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define TOP_MARGIN_ABOVE_NAVBAR 5.0

#define LOCAL_GROUPS_NUM 5

@interface ForumTabNavController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navigationView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *stripeShadow;
@property (weak, nonatomic) IBOutlet UIScrollView *contentScrollView;
@property (weak, nonatomic) IBOutlet UIView *referenceView;
@property (weak, nonatomic) IBOutlet UIView *contentSizeView;
@property (weak, nonatomic) IBOutlet UIButton *btSearch;
@property (weak, nonatomic) IBOutlet UIButton *btConfig;
@property (weak, nonatomic) IBOutlet UIButton *btProfile;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIView *stripeView;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIView *ruleDot;

@property (weak, nonatomic) IBOutlet UIScrollView *tabScrollView;
@property (weak, nonatomic) IBOutlet UIView *tabContentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topMargin;

@property (strong, nonatomic) NSArray *tabButtons;
@property (assign, nonatomic) NSInteger currentPage;
@property (assign, nonatomic) NSInteger pageBeforeDragging;
@property (assign, nonatomic) CGFloat beginOffsetX;
@property (strong, nonatomic) IBOutlet UIView *tutsViewGroups;
@property (strong, nonatomic) IBOutlet UIView *tutsViewMain;

@property (assign, nonatomic) BOOL groupsTutsAnimating;
@property (assign, nonatomic) BOOL mainTutsAnimating;
@property (assign, nonatomic) BOOL pauseAnimation;

@property (weak, nonatomic) IBOutlet UIView *tutsGroupsDot;
@property (weak, nonatomic) IBOutlet UIView *tutsGroupsTooltip;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tutsTooltipTop;

@property (weak, nonatomic) IBOutlet UIView *tutsMainDot;

@property (weak, nonatomic) IBOutlet UIView *step1Instruction;
@property (weak, nonatomic) IBOutlet UIView *step2Instruction;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIView *swipeArea;

@property (strong, nonatomic) ForumGroupsViewController *groupsViewController;
@property (strong, nonatomic) ForumTopicDetailViewController *rulesViewController;
@property (strong, nonatomic) NSMutableDictionary *vcCache;
@property (strong, nonatomic) NSMutableArray *visibleViewControllers;
@property (strong, nonatomic) NSArray *groups;

@property (weak, nonatomic) WelcomeToCommunityDialogViewController *welcomeViewController;
@property (weak, nonatomic) UIGestureRecognizer *mainSwipeGesture;
@property (weak, nonatomic) UIGestureRecognizer *tabSwipeGesture;

// Search
@property (nonatomic) ForumSearchViewController * searchViewController;
@property (nonatomic) BOOL searchPoped;

// Status Bar
@property (assign, nonatomic) BOOL hideStatusBar;
@property (assign, nonatomic) BOOL viewAppeared;

@property (nonatomic, strong) NSNumber *welcomeTopicID;

@property (assign, nonatomic) BOOL step1Finished;
@property (assign, nonatomic) BOOL inTutorial;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tutsMainDotX;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tutsMainDotY;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *swipeAreaTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *swipeAreaBottom;

@end

@implementation ForumTabNavController

+ (instancetype)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"ForumTabNavController"];
}

- (NSMutableDictionary *)vcCache
{
    if (!_vcCache) {
        _vcCache = [NSMutableDictionary dictionary];
    }
    return _vcCache;
}

- (NSMutableArray *)visibleViewControllers
{
    if (!_visibleViewControllers) {
        _visibleViewControllers = [NSMutableArray array];
    }
    return _visibleViewControllers;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.tabBarController.tabBar.hidden = self.searchViewController.isInSearchMode;
    [self setupToolbar];
    [self reloadGroups];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self hideMainTuts];
    if ([self.navigationController topViewController] != self) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [self hideNavigationBarAnimated:YES];
    self.viewAppeared = YES;
    
    [self showWelcomeOrTutsIfNeeded];
    [self showForumIntroduceFollowIfNeeded];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.viewAppeared = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *title = [self.skipButton titleForState:UIControlStateNormal];
    NSDictionary *attr = @{
                           NSFontAttributeName: [GLTheme defaultFont:15.0],
                           NSForegroundColorAttributeName: [UIColor whiteColor],
                           NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                           NSUnderlineColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.5],
                           };
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:title attributes:attr];
    [self.skipButton setAttributedTitle:attrString forState:UIControlStateNormal];
    
    for (UIGestureRecognizer *gesture in self.contentScrollView.gestureRecognizers) {
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
            self.mainSwipeGesture = gesture;
        }
    }
    
    for (UIGestureRecognizer *gesture in self.tabScrollView.gestureRecognizers) {
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
            self.tabSwipeGesture = gesture;
        }
    }
    
    self.ruleDot.layer.cornerRadius = self.ruleDot.width / 2.0;
    self.ruleDot.hidden = [[self class] rulesOpened];
    
    self.tutsGroupsDot.layer.cornerRadius = self.tutsGroupsDot.width / 2.0;
    self.tutsMainDot.layer.cornerRadius = self.tutsMainDot.width / 2.0;
    
    self.tutsMainDot.top = (self.contentView.height - self.tutsMainDot.height) / 2.0;
    
    self.btSearch.layer.cornerRadius = self.btSearch.height / 2;
    UIImage *searchImg = [UIImage imageNamed:@"gl-community-search"];
    [self.btSearch setImage:[searchImg imageWithTintColor:UIColorFromRGB(0xA2A3A4)] forState:UIControlStateNormal];
    
    [self configureProfileImageView];
    
    if (!self.searchViewController) {
        self.searchViewController = [[ForumSearchViewController alloc] init];
        [self addChildViewController:self.searchViewController];
        [self.view addSubview:self.searchViewController.view];
        
        [self.searchViewController.view mas_updateConstraints:^(MASConstraintMaker *maker){
            maker.edges.equalTo(self.view);
        }];
    }
    
    // Stripe Shadow
    self.stripeShadow.layer.shadowColor = [UIColor blackColor].CGColor;
    self.stripeShadow.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.stripeShadow.layer.shadowOpacity = 0.25;
    self.stripeShadow.layer.shadowRadius = 1.0;
    
    self.contentSizeView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.contentSizeView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.contentSizeView.layer.shadowOpacity = 0.25;
    self.contentSizeView.layer.shadowRadius = 1.0;
    
    self.step1Instruction.layer.cornerRadius = 10.0;
    self.step2Instruction.layer.cornerRadius = 10.0;
    
    self.currentPage = -1;
    // Do any additional setup after loading the view.
    [self reloadGroups];
    [self loadPage:0];
    
    @weakify(self)
    [self subscribe:EVENT_FORUM_SEARCH_CANCEL selector:@selector(searchCancel)];
    [self subscribe:EVENT_FORUM_GROUP_SUBSCRIPTION_UPDATED handler:^(Event *event) {
        @strongify(self)
        [self reloadGroups];
    }];
    [self subscribe:EVENT_FORUM_GROUP_LOCAL_SUBSCRIPTION_UPDATED handler:^(Event *event) {
        @strongify(self)
        [self reloadGroups];
    }];
    [self subscribe:EVENT_FORUM_HIDE_TOP_NAVBAR handler:^(Event *event) {
        @strongify(self)
        [self hideNavigationBar];
    }];
    [self subscribe:EVENT_FORUM_GOTO_GROUP_TAB handler:^(Event *event) {
        @strongify(self)
        ForumGroup *group = (ForumGroup *)event.data;
        if ([group isKindOfClass:[ForumGroup class]]) {
            [self gotoGroup:group];
        }
    }];
    [self subscribe:EVENT_DOUBLE_TAP_COMMUNITY_TAB handler:^(Event *event) {
        @strongify(self)
        if (self.navigationController.topViewController == self) {
            ForumGroup *group = [self.groups firstObject];
            if (group) {
                [self gotoGroup:group];
                ForumGroupRoomViewController *vc = [self viewControllerForGroup:group];
                [vc refresh];
            }
        }
    }];
    [self subscribe:EVENT_FORUM_GOTO_MY_GROUP handler:^(Event *event) {
        @strongify(self)
        [self gotoGroupsPage];
    }];
    
    [self subscribe:EVENT_FORUM_GOTO_RULES_GROUP handler:^(Event *event) {
        @strongify(self)
        [self gotoGroup:[ForumGroup rulesGroup]];
    }];
    
    [self subscribe:EVENT_FORUM_ADD_TOPIC_SUCCESS handler:^(Event *event) {
        @strongify(self)
        NSDictionary *data = (NSDictionary *)event.data;
        ForumTopic *topic = data[@"topic"];
        ForumCategory *category = data[@"category"];
        if (topic) {
            ForumTopicDetailViewController *detailViewController = [ForumTopicDetailViewController viewController];
            detailViewController.source = IOS_TOPIC_VIEW_FROM_FORUM;
            detailViewController.topic = topic;
            detailViewController.category = category;
            [self.navigationController pushViewController:detailViewController animated:YES from:self];
        }
    }];
    
    
    [self subscribe:EVENT_FORUM_CLICK_URL_TOPIC_CARD handler:^(Event *event) {
        @strongify(self)
        GLWebViewController *controller = [GLWebViewController viewController];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
        [self presentViewController:nav animated:YES completion:nil];
        NSString *url = (NSString *)event.data;
        if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
            url = [@"http://" stringByAppendingString:url];
        }
        [controller openUrl:url];
        
    }];
    
    [self subscribe:EVENT_FORUM_TAKE_QUIZ selector:@selector(didClickQuiz:)];
 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self showTutsIfNeeded];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupToolbar {
    if ([Forum isLoggedIn]) {
        self.btConfig.hidden = NO;
        self.btProfile.hidden = NO;
        self.profileImageView.hidden = NO;
    } else {
        self.btConfig.hidden = YES;
        self.btProfile.hidden = YES;
        self.profileImageView.hidden = YES;
    }
}


- (void)configureProfileImageView
{
    ForumUser *user = [Forum currentForumUser];
    UIImage *defaultProfileImage = [UIImage imageNamed:@"gl-community-profile-empty"];
    
    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.layer.cornerRadius = self.profileImageView.height / 2;
    
    @weakify(self)
    [self subscribe:EVENT_PROFILE_IMAGE_UPDATE handler:^(Event *event) {
        @strongify(self)
        if ([event.data isKindOfClass:[UIImage class]]) {
            self.profileImageView.image = (UIImage *)event.data;
        }
    }];
    
    if (user.cachedProfileImage) {
        self.profileImageView.image = user.cachedProfileImage;
    }
    else if (user.profileImage.length > 0) {
        [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:user.profileImage]
                                 placeholderImage:defaultProfileImage
                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
         {
             if (image) {
                 user.cachedProfileImage = image;
             }
         }];
    }
    else {
        self.profileImageView.image = defaultProfileImage;
    }
}


- (void)reloadGroups {
    ForumGroup *prevGroup = nil;
    if (self.currentPage >= 0 && self.currentPage < self.groups.count) {
        prevGroup = self.groups[self.currentPage];
    }
    NSArray *subscribedGroups = [[Forum reorderGroups:[Forum sharedInstance].subscribedGroups] mutableCopy];
    NSMutableArray *groups = [NSMutableArray arrayWithArray:@[[ForumGroup topGroup], [ForumGroup feedGroup]]];
    for (ForumGroup *group in subscribedGroups) {
        ForumCategory *category = [Forum categoryFromGroup:group];
        if (category && category.backgroundColor.length > 0) {
            group.color = [UIColor colorFromWebHexValue:category.backgroundColor];
        }
        [groups addObject:group];
    }
    if ([Forum isLoggedIn]) {
//        [groups addObject:[ForumGroup bookmarkedGroup]];
        [groups addObject:[ForumGroup rulesGroup]];
        [groups addObject:[ForumGroup groupsGroup]];
    } else {
        [groups addObject:[ForumGroup rulesGroup]];
    }
    self.groups = [NSArray arrayWithArray:groups];
    [self setupTabs];
    
    NSInteger newPage = 0;
    if (prevGroup && [self.groups containsObject:prevGroup]) {
        newPage = [self.groups indexOfObject:prevGroup];
    }
    BOOL needForceReload = self.currentPage == newPage;
    [self selectTabAtIndex:self.currentPage];
    [self.contentScrollView setContentOffset:CGPointMake(self.contentScrollView.width * newPage, 0.0) animated:NO];
    if (needForceReload) {
        [self loadPage:newPage force:YES];
    }
    [self showTutsIfNeeded];
}

- (void)setupTabs
{
    NSArray *groups = self.groups;
    NSMutableArray *btsToKeep = [NSMutableArray array];
    NSMutableArray *btsToRemove = [NSMutableArray array];
    for (ForumTabButton *bt in self.tabButtons) {
        if ([groups containsObject:bt.group]) {
            [btsToKeep addObject:bt];
        } else {
            [bt removeFromSuperview];
            [btsToRemove addObject:bt];
        }
    }
    
    CGFloat x = 0;
    NSMutableArray *buttons = [NSMutableArray array];
    
    for (int i = 0; i < self.groups.count; ++i) {
        ForumGroup *group = self.groups[i];
        
        // Tab button
        ForumTabButton *bt = nil;
        
        for (ForumTabButton *testButton in btsToKeep) {
            if ([testButton.group isEqual:group]) {
                bt = testButton;
                [btsToKeep removeObject:bt];
                break;
            }
        }
        if (!bt) {
            if (btsToRemove.count > 0) {
                bt = [btsToRemove firstObject];
                [btsToRemove removeObject:bt];
            } else {
                bt = [[ForumTabButton alloc] initWithFrame:CGRectMake(x, self.tabScrollView.height, 60.0, 42.0)];
                bt.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
                UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnTab:)];
                [bt addGestureRecognizer:press];
            }
        }
        
        bt.group = group;
        if (group.type == ForumGroupGroups) {
            bt.titleLabel.text = TAB_PLUS_SYMBOL;
        } else {
            bt.titleLabel.text = group.name;
        }
        [bt setTintColor:group.color];
        [bt sizeToFit];
        x += bt.width;
        [bt addTarget:self action:@selector(didSelectTab:) forControlEvents:UIControlEventTouchUpInside];
        [self.tabContentView addSubview:bt];
        [buttons addObject:bt];
    }
    
    self.tabButtons = [NSArray arrayWithArray:buttons];
    
    [UIView animateWithDuration:0.25 animations:^{
        CGFloat x = 0.0;
        for (ForumTabButton *bt in self.tabButtons) {
            bt.origin = CGPointMake(x, 0.0);
            x += bt.width;
        }
    }];
    
    self.tabWidth.constant = x;
    [self.contentSizeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.referenceView.mas_width).multipliedBy(self.groups.count);
    }];
    [self.view layoutIfNeeded];
    
    self.stripeShadow.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.stripeShadow.bounds].CGPath;
    self.contentSizeView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.contentSizeView.bounds].CGPath;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#define SNAP_THRESHOLD  59.0
- (void)snapContentView
{
    CGFloat margin = self.contentView.top;
    if (margin < SNAP_THRESHOLD) {
        [self hideNavigationBarAnimated:YES];
    } else if (margin >= SNAP_THRESHOLD) {
        [self showNavigationBarAnimated:YES];
    }
}

- (void)hideNavigationBar
{
    [self hideNavigationBarAnimated:YES];
}

- (void)hideNavigationBarAnimated:(BOOL)animated
{
    if (self.contentView.top != TOP_MARGIN_ABOVE_NAVBAR) {
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                self.navigationView.alpha = 0.0;
                self.backgroundView.alpha = 1.0;
                self.topMargin.constant = TOP_MARGIN_ABOVE_NAVBAR;
                [self.view layoutIfNeeded];
            }];
        } else {
            self.navigationView.alpha = 0.0;
            self.backgroundView.alpha = 1.0;
            self.topMargin.constant = TOP_MARGIN_ABOVE_NAVBAR;
            [self.view layoutIfNeeded];
        }
    }
    self.hideStatusBar = YES;
}

- (void)showNavigationBar
{
    [self showNavigationBarAnimated:YES];
}

- (void)showNavigationBarAnimated:(BOOL)animated
{
    if (self.contentView.top != 64.0) {
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                self.navigationView.alpha = 1.0;
                self.backgroundView.alpha = 0.0;
                self.topMargin.constant = 64.0;
                [self.view layoutIfNeeded];
            }];
        } else {
            self.navigationView.alpha = 1.0;
            self.backgroundView.alpha = 0.0;
            self.topMargin.constant = 64.0;
            [self.view layoutIfNeeded];
        }
    }
    self.hideStatusBar = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.contentScrollView) {
        NSInteger page = scrollView.contentOffset.x / scrollView.width + 0.5;
        page = MAX(page, 0);
//        page = MIN(page, [[[Forum sharedInstance] categories] count] - 1);
//        if (self.inTutorial && self.currentPage != page) {
//            [self finishStep1];
//        }
        [self loadPage:page];
    } else if ([scrollView isKindOfClass:[UITableView class]]) {
        if (self.inTutorial) {
            return;
        }
        if ([scrollView isDragging]) {
            CGFloat y = scrollView.contentOffset.y;
            if ((y > 0.0 && self.contentView.top > TOP_MARGIN_ABOVE_NAVBAR) || (y < 0.0 && self.contentView.top < 64.0)) {
                CGFloat topMargin = self.contentView.top - y;
                topMargin = MIN(64.0, topMargin);
                topMargin = MAX(TOP_MARGIN_ABOVE_NAVBAR, topMargin);
                CGFloat offsetY = y - (self.contentView.top - topMargin);
                self.navigationView.alpha = MAX(0.0, (topMargin - 20.0) / 44.0);
                self.backgroundView.alpha = 1.0 - self.navigationView.alpha;
                self.topMargin.constant = topMargin;
                [self.view layoutIfNeeded];
                scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, offsetY);
                self.hideStatusBar = (topMargin < 64.0);
            }
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.contentScrollView) {
        if (self.inTutorial && self.currentPage == self.groups.count - 1) {
            [self finishStep1];
        } else if (self.inTutorial && self.currentPage != self.pageBeforeDragging) {
            [self finishStep1];
        }
    } else if ([scrollView isKindOfClass:[UITableView class]]) {
        [self snapContentView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == self.contentScrollView) {
        self.pageBeforeDragging = self.currentPage;
    } else if (scrollView == self.tabScrollView) {
        self.beginOffsetX = scrollView.contentOffset.x;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (scrollView == self.tabScrollView) {
        if (![Forum isLoggedIn]) {
            return;
        }
        if (self.inTutorial && scrollView.contentOffset.x > self.beginOffsetX) {
            targetContentOffset->x = MAX(0.0, self.tabScrollView.contentSize.width - self.tabScrollView.width);
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView == self.tabScrollView) {
        if (self.inTutorial && scrollView.contentOffset.x > self.beginOffsetX) {
            [self finishMainTuts];
        }
    } else if (scrollView == self.contentScrollView) {
        if (self.inTutorial && self.currentPage == self.groups.count - 1) {
            [self finishStep1];
        } else if (self.inTutorial && self.currentPage != self.pageBeforeDragging) {
            [self finishStep1];
        }
    } else if ([scrollView isKindOfClass:[UITableView class]]) {
        if (!decelerate) {
            [self snapContentView];
        }
    }
}

- (void)selectTabAtIndex:(NSInteger)index
{
    [UIView animateWithDuration:0.25 animations:^{
        ForumTabButton *selectedButton = nil;
        if (index < self.tabButtons.count) {
            for (NSInteger i = 0; i < self.tabButtons.count; ++i) {
                ForumTabButton *bt = self.tabButtons[i];
                bt.selected = (i == index);
                if (i == index) {
                    selectedButton = bt;
                }
                if (i <= index) {
                    [self.tabContentView bringSubviewToFront:bt];
                } else {
                    [self.tabContentView sendSubviewToBack:bt];
                }
                [bt layoutIfNeeded];
            }
        }
        if (selectedButton) {
            CGFloat x = selectedButton.centerX - self.tabScrollView.width / 2.0;
            x = MIN(self.tabScrollView.contentSize.width - self.tabScrollView.width, x);
            x = MAX(0.0, x);
            [self.tabScrollView setContentOffset:CGPointMake(x, 0.0) animated:YES];
        }
        if (index < self.groups.count) {
            ForumGroup *group = self.groups[index];
            self.stripeView.backgroundColor = group.color;
            if (group.type == ForumGroupGroups) {
                [self finishGroupsTuts];
            }
        }
    }];
    [self hideNavigationBar];
}

- (IBAction)didSelectTab:(id)sender
{
    ForumTabButton *tab = sender;
    if ([tab isKindOfClass:[ForumTabButton class]]) {
        NSInteger index = [self.tabButtons indexOfObject:tab];
        if (index < self.groups.count) {
            ForumGroup *group = self.groups[index];
            if (group.type == ForumGroupNormal) {
                [Forum log:BTN_CLK_FORUM_NAVBAR_TAB eventData:@{@"group_id": @(group.identifier)}];
            } else if (group.type == ForumGroupHot) {
                [Forum log:BTN_CLK_FORUM_NAVBAR_TAB_HOT];
            } else if (group.type == ForumGroupNew) {
                [Forum log:BTN_CLK_FORUM_NAVBAR_TAB_NEW];
            } else if (group.type == ForumGroupGroups) {
                [Forum log:BTN_CLK_FORUM_NAVBAR_TAB_GROUPS];
            } else if (group.type == ForumGroupRules) {
                [Forum log:BTN_CLK_FORUM_NAVBAR_RULES];
            }
        }
        [self selectTabAtIndex:index];
        [self.contentScrollView setContentOffset:CGPointMake(self.contentScrollView.width * index, 0.0) animated:NO];
    }
}

- (void)loadPage:(NSInteger)page
{
    [self loadPage:page force:NO];
}

- (void)loadPage:(NSInteger)page force:(BOOL)force
{
    if (page == self.currentPage && !force) {
        return;
    }
    
    
    self.currentPage = page;
    
    if (page >= 0 && page < self.groups.count) {
        ForumGroup *group = self.groups[page];
        if (!force) {
            [Forum log:BTN_CLK_FORUM_SWIPE_LOAD_PAGE eventData:@{@"group_id": @(group.identifier), @"group_type": @(group.type)}];
        }
        self.titleLabel.text = group.name;
        self.descriptionLabel.text = group.desc;
        if ([[group.desc trim] length] > 0) {
            self.titleLabel.top = 5.0;
        } else {
            self.titleLabel.top = 11.0;
        }
    }
    // Remove off-screen VCs
    NSMutableArray *vcToRemove = [NSMutableArray array];
    for (UIViewController *vc in self.visibleViewControllers) {
        ForumGroup *group = nil;
        if ([vc isKindOfClass:[ForumGroupRoomViewController class]]) {
            group = [(ForumGroupRoomViewController *)vc group];
        } else if ([vc isKindOfClass:[ForumGroupsViewController class]]) {
            group = [ForumGroup groupsGroup];
        }
        if (group) {
            NSInteger vcPage = [self.groups indexOfObject:group];
            if (vcPage < page - 1 || vcPage > page + 1) {
                [vc.view removeFromSuperview];
                [vcToRemove addObject:vc];
            }
        } else {
            [vc.view removeFromSuperview];
            [vcToRemove addObject:vc];
        }
    }
    [self.visibleViewControllers removeObjectsInArray:vcToRemove];
    // Add on-screen VCs
    [self addControllerForPage:page];
    [self addControllerForPage:page - 1];
    [self addControllerForPage:page + 1];
    
    [self selectTabAtIndex:page];
}

- (void)addControllerForPage:(NSInteger)page
{
    if (page >= 0 && page < self.groups.count) {
        ForumGroup *group = self.groups[page];
        if (group.type == ForumGroupGroups) {
            if (!self.groupsViewController) {
                self.groupsViewController = [ForumGroupsViewController viewController];
                self.groupsViewController.scrollDelegate = self;
                [self.groupsViewController willMoveToParentViewController:self];
                [self addChildViewController:self.groupsViewController];
                [self.groupsViewController didMoveToParentViewController:self];
            }
            ForumGroupsViewController *vc = self.groupsViewController;
            [self.contentScrollView addSubview:vc.view];
            [vc.view mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.contentScrollView.mas_left).with.offset(SCREEN_WIDTH * page);
                make.top.equalTo(self.contentScrollView.mas_top);
                make.size.equalTo(self.referenceView);
            }];
            [self.visibleViewControllers addObject:vc];
        } else if (group.type == ForumGroupRules) {
            if (!self.rulesViewController) {
                ForumTopic *topic = [[ForumTopic alloc] init];
                topic.identifier = FORUM_RULES_TOPIC_ID;
                topic.title = @"Community rules";
                ForumTopicDetailViewController *topicViewController = [ForumTopicDetailViewController viewController];
                topicViewController.source = IOS_TOPIC_VIEW_FROM_COMMUNITY_RULES;
                topicViewController.topic = topic;
                topicViewController.hideComments = YES;
                topicViewController.scrollDelegate = self;
                self.rulesViewController = topicViewController;
                [self.rulesViewController willMoveToParentViewController:self];
                [self addChildViewController:self.rulesViewController];
                [self.rulesViewController didMoveToParentViewController:self];
            }
            ForumTopicDetailViewController *vc = self.rulesViewController;
            [self.contentScrollView addSubview:vc.view];
            [vc.view mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.contentScrollView.mas_left).with.offset(SCREEN_WIDTH * page);
                make.top.equalTo(self.contentScrollView.mas_top);
                make.size.equalTo(self.referenceView);
            }];
            [self.visibleViewControllers addObject:vc];
        } else {
            ForumGroupRoomViewController *vc = [self viewControllerForGroup:group];
            [self.contentScrollView addSubview:vc.view];
            [vc.view mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.contentScrollView.mas_left).with.offset(SCREEN_WIDTH * page);
                make.top.equalTo(self.contentScrollView.mas_top);
                make.size.equalTo(self.referenceView);
            }];
            [self.visibleViewControllers addObject:vc];
        }
    }
}

- (void)gotoPage:(NSInteger)page
{
    page = MIN(self.groups.count - 1, MAX(0, page));
    if (page == self.currentPage) {
        return;
    }
    [self.contentScrollView setContentOffset:CGPointMake(self.contentScrollView.width * page, 0.0) animated:NO];
}

- (void)gotoGroup:(ForumGroup *)group
{
    if ([group isKindOfClass:[ForumGroup class]]) {
        NSInteger index = [self.groups indexOfObject:group];
        if (index != NSNotFound) {
            [self gotoPage:index];
        } else {
            ForumCategory *cat = [Forum categoryFromGroup:group];
            ForumGroupRoomViewController *controller = [ForumGroupRoomViewController viewController];
            controller.category = cat;
            controller.group = group;
            [self.navigationController pushViewController:controller animated:YES from:self];
        }
    }
}

- (ForumGroupRoomViewController *)viewControllerForGroup:(ForumGroup *)group
{
    if (!group) {
        return nil;
    }
    NSString *key = [NSString stringWithFormat:@"%ld-%llu", (NSUInteger)group.type, group.identifier];
    UIViewController *controller = (self.vcCache)[key];
    if (!controller) {
        {
            ForumCategory *cat = [Forum categoryFromGroup:group];
            ForumGroupRoomViewController *vc = [ForumGroupRoomViewController viewController];
            vc.category = cat;
            vc.group = group;
            vc.scrollDelegate = self;
            controller = vc;
        }
        
        [controller willMoveToParentViewController:self];
        [self addChildViewController:controller];
        [controller didMoveToParentViewController:self];
        (self.vcCache)[key] = controller;
    }
    return (ForumGroupRoomViewController *)controller;
}

- (IBAction)didClickBookmark:(id)sender {
    [Forum log:BTN_CLK_FORUM_NAVBAR_BOOKMARK];
    [self gotoGroup:[ForumGroup bookmarkedGroup]];
}

- (IBAction)didClickSearch:(id)sender {
    [Forum log:BTN_CLK_FORUM_NAVBAR_SEARCH];

    [self.searchViewController toggleSearchBar];
    self.searchPoped = YES;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (IBAction)didClickRule:(id)sender {
    [[self class] setRulesOpened:YES];
    [Forum log:BTN_CLK_FORUM_NAVBAR_RULES];
    ForumTopic *topic = [[ForumTopic alloc] init];
    topic.identifier = FORUM_RULES_TOPIC_ID;
    topic.title = @"Community rules";
    ForumTopicDetailViewController *topicViewController = [ForumTopicDetailViewController viewController];
    topicViewController.source = IOS_TOPIC_VIEW_FROM_COMMUNITY_RULES;
    topicViewController.topic = topic;
    GLNavigationController *nav = [[GLNavigationController alloc] initWithRootViewController:topicViewController];
    [self presentViewController:nav animated:YES completion:nil];
    self.ruleDot.hidden = YES;
}

- (IBAction)didClickSettings:(id)sender {
    [Forum log:BTN_CLK_FORUM_NAVBAR_SETTINGS];
    [self gotoSettingsPage];
}

- (void)longPressOnTab:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [Forum log:BTN_CLK_FORUM_NAVBAR_TAB_LONG_PRESS];
        [self gotoGroupsPage];
    }
}

- (void)gotoSettingsPage
{
    [Forum log:BTN_CLK_FORUM_SETTINGS_AGE_FILTER];
    [self performSegueWithIdentifier:@"ShowAgeFilter" sender:nil from:self];
//    [self performSegueWithIdentifier:@"showSettings" sender:nil from:self];
}

- (void)gotoGroupsPage
{
    ForumGroupsViewController *vc = [ForumGroupsViewController viewController];
    vc.isMyGroups = YES;
    GLNavigationController *nav = [[GLNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (!self.viewAppeared) {
        return [[UIApplication sharedApplication] statusBarStyle];
    }
//    if (self.searchPoped) {
//        return UIStatusBarStyleLightContent;
//    } else {
        return UIStatusBarStyleDefault;
//    }
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

- (void)searchCancel {
    self.searchPoped = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Status Bar Related
- (void)setViewAppeared:(BOOL)viewAppeared
{
    if (_viewAppeared != viewAppeared) {
        _viewAppeared = viewAppeared;
        [UIView animateWithDuration:0.2 animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    }
}

- (BOOL)prefersStatusBarHidden
{
    if (!self.viewAppeared) {
        return [[UIApplication sharedApplication] isStatusBarHidden];
    }
    return self.hideStatusBar;
}

- (void)setHideStatusBar:(BOOL)hideStatusBar {
    if (_hideStatusBar != hideStatusBar) {
        _hideStatusBar = hideStatusBar;
        [UIView animateWithDuration:0.2 animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    }
}

+ (void)resetAllTuts
{
    [self setMainTutsFinished:NO];
    [self setGroupsTutsFinished:NO];
}

+ (BOOL)rulesOpened
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:USER_DEFAULTS_KEY_FORUM_RULES_OPENED];
}

+ (void)setRulesOpened:(BOOL)opened
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:opened forKey:USER_DEFAULTS_KEY_FORUM_RULES_OPENED];
    [ud synchronize];
}

+ (BOOL)mainTutsFinished
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:USER_DEFAULTS_KEY_FORUM_TUTS_MAIN_FINISHED];
}

+ (void)setMainTutsFinished:(BOOL)finished
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:finished forKey:USER_DEFAULTS_KEY_FORUM_TUTS_MAIN_FINISHED];
    [ud synchronize];
}

+ (BOOL)groupsTutsFinished
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:USER_DEFAULTS_KEY_FORUM_TUTS_GROUPS_FINISHED];
}

+ (void)setGroupsTutsFinished:(BOOL)finished
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:finished forKey:USER_DEFAULTS_KEY_FORUM_TUTS_GROUPS_FINISHED];
    [ud synchronize];
}

- (void)showMyGroupsPopupIfNeeded
{
    if ([Forum needsShowMyGruopsPopup]) {
        [self showMyGroupsPopup];
    }
}

- (void)showMyGroupsPopup
{
    [Forum setNeedsShowMyGroupsPopup:NO];
    [self showNavigationBar];
    ForumMyGroupPopupViewController *popup = [ForumMyGroupPopupViewController viewController];
    [popup present];
}

- (BOOL)showForumIntroduceFollowIfNeeded
{
    if (![Forum isLoggedIn]) {
        return YES;
    }
    @weakify(self)
    [Forum fetchGlowAccountID:^(NSDictionary *result, NSError *error) {
        if (!error) {
            uint64_t uid = [result unsignedLongLongForKey:@"glow_account_id"];
            if (uid > 0) {
                [ForumIntroduceFollowViewController presentIfTheFirstTimeWithCheckoutAction:^{
                    @strongify(self)
                    ForumProfileViewController *vc = [[ForumProfileViewController alloc] initWithUserID:uid
                                                                                        placeholderUser:nil];
                    [self.navigationController pushViewController:vc animated:YES];
                }];
            }
        }
    }];
    return YES;
}

- (void)showWelcomeOrTutsIfNeeded
{
    if (self.tabBarController.selectedViewController != self.navigationController) {
        return;
    }
    if (![Forum isLoggedIn]) {
        return;
    }
    @weakify(self)
    [self subscribe:EVENT_DIALOG_DISMISSED handler:^(Event *event) {
        @strongify(self)
        self.welcomeViewController = nil;
        [self showTutsIfNeeded];
    }];
    WelcomeToCommunityDialogViewController *vc = [WelcomeToCommunityDialogViewController presentDialogOnlyTheFirstTime];
    self.welcomeViewController = vc;
    if (!vc) {
        [self showMyGroupsPopupIfNeeded];
        [self showTutsIfNeeded];
    } else {
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
                topicViewController.source = IOS_TOPIC_VIEW_FROM_WELCOME;
                topicViewController.topic = topic;
                
                [self.navigationController pushViewController:topicViewController animated:YES from:self];
            } else {
                self.welcomeViewController = nil;
                [self showTutsIfNeeded];
            }
        };
    }
}

- (void)delayedShowTutsIfNeeded
{
    @weakify(self)
    [GLUtils performInMainQueueAfter:10.0 callback:^{
        @strongify(self)
        [self showTutsIfNeeded];
    }];
}

- (void)showTutsIfNeeded
{
    return;
//    if (self.welcomeViewController) {
//        return;
//    }
//    if (self.navigationController.topViewController != self) {
//        return;
//    }
//    if (self.tabBarController.selectedViewController != self.navigationController) {
//        return;
//    }
//    if (![[self class] mainTutsFinished]) {
//        [self hideGroupsTuts];
//        if (!self.step1Finished) {
//            [self setupStep1];
//            [self showMainTuts];
//        } else {
//            [self setupStep2];
//            [self showMainTuts];
//        }
//    } else if (![[self class] groupsTutsFinished]) {
//        [self hideMainTuts];
//        [self showGroupsTuts];
//    }
}

- (void)setupStep1
{
    if (self.groups.count <= LOCAL_GROUPS_NUM) {
        return;
    }
    [self hideNavigationBarAnimated:YES];
    self.swipeArea.gestureRecognizers = @[self.mainSwipeGesture];
    self.swipeAreaTop.constant = 42.0;
    self.swipeAreaBottom.constant = 0.0;
    [self.swipeArea setNeedsLayout];
    [self.swipeArea layoutIfNeeded];
//    self.tutsMainDot.alpha = 0.0;
    self.tutsMainDotY.constant = 0;
    [self.tutsViewMain setNeedsLayout];
    [self.tutsViewMain layoutIfNeeded];
    [UIView animateWithDuration:0.25 animations:^{
        self.tutsViewMain.alpha = 1.0;
        self.step1Instruction.alpha = 1.0;
        self.step2Instruction.alpha = 0.0;
        self.skipButton.alpha = 0.0;
    }];
}

- (void)setupStep2
{
    if (self.groups.count <= LOCAL_GROUPS_NUM) {
        return;
    }
    [self hideNavigationBarAnimated:YES];
    self.swipeArea.gestureRecognizers = @[self.tabSwipeGesture];
    self.swipeAreaTop.constant = 0.0;
    self.swipeAreaBottom.constant = self.tutsViewMain.height - 42.0;
    [self.swipeArea setNeedsLayout];
    [self.swipeArea layoutIfNeeded];
    self.pauseAnimation = YES;
    [self stopMainTutsAnimation];
    self.tutsMainDot.alpha = 0.0;
    self.tutsMainDotY.constant = self.tutsViewMain.height / 2.0 - 64.0;;
    [self.tutsViewMain setNeedsLayout];
    [self.tutsViewMain layoutIfNeeded];
    [UIView animateWithDuration:0.25 animations:^{
        self.tutsViewMain.alpha = 1.0;
        self.step1Instruction.alpha = 0.0;
        self.step2Instruction.alpha = 1.0;
        self.skipButton.alpha = 1.0;
    }];
    [GLUtils performInMainQueueAfter:1.0 callback:^{
        self.pauseAnimation = NO;
        [self beginMainTutsAnimation];
    }];
}

- (void)showMainTuts
{
    if (self.groups.count <= LOCAL_GROUPS_NUM) {
        return;
    }
    self.inTutorial = YES;
    [self.tabBarController.view addSubview:self.tutsViewMain];
    [self.tabBarController.view bringSubviewToFront:self.tutsViewMain];
//    [self.tutsViewMain mas_updateConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(self.tabBarController.view);
//    }];
    self.tutsViewMain.frame = self.tabBarController.view.bounds;
    self.tutsViewMain.backgroundColor = [UIColor clearColor];
    [self.tutsViewMain removeGradientBackground];
    [self.tutsViewMain setGradientBackground:[UIColor colorWithWhite:0.0 alpha:0.0] toColor:[UIColor colorWithWhite:0.0 alpha:1.0]];
    self.tutsViewMain.hidden = NO;
    if (!self.step1Finished) {
        [self beginMainTutsAnimation];
    }
}

- (void)stopMainTutsAnimation
{
    [self.tutsViewMain.layer removeAllAnimations];
    self.mainTutsAnimating = NO;
}

- (void)beginMainTutsAnimation
{
    if (!self.mainTutsAnimating && !self.pauseAnimation) {
        self.mainTutsAnimating = YES;
        self.tutsMainDot.alpha = 0.0;
        self.tutsMainDotX.constant = -80.0;
        [self.tutsMainDot setNeedsLayout];
        [self.tutsMainDot layoutIfNeeded];
        [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.tutsMainDot.alpha = 1.0;
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.8 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.tutsMainDotX.constant = 80.0;
                    [self.tutsMainDot setNeedsLayout];
                    [self.tutsMainDot layoutIfNeeded];
                } completion:^(BOOL finished) {
                    if (finished) {
                        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                            self.tutsMainDot.alpha = 0.0;
                        } completion:^(BOOL finished) {
                            self.mainTutsAnimating = NO;
                            if (finished && self.inTutorial) {
                                [self beginMainTutsAnimation];
                            } else {
                                [self hideMainTuts];
                            }
                        }];
                    } else {
                        self.mainTutsAnimating = NO;
                    }
                }];
            } else {
                self.mainTutsAnimating = NO;
            }
        }];
    }
}

- (void)hideMainTuts
{
    [UIView animateWithDuration:0.25 animations:^{
        self.tutsViewMain.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.tutsViewMain.hidden = YES;
        [self stopMainTutsAnimation];
    }];
}

- (void)finishStep1
{
    if (self.inTutorial) {
        [[GLDropdownMessageController sharedInstance] postMessage:@"Nice! Now browse more groups!" duration:2.0 inWindow:self.view.window];
    }
    self.step1Finished = YES;
    [self setupStep2];
    [self showMainTuts];
}

- (void)finishMainTuts
{
    [self.contentScrollView removeGestureRecognizer:self.mainSwipeGesture];
    [self.contentScrollView addGestureRecognizer:self.mainSwipeGesture];
    [self.tabScrollView removeGestureRecognizer:self.tabSwipeGesture];
    [self.tabScrollView addGestureRecognizer:self.tabSwipeGesture];
    
    [self hideMainTuts];
    [[self class] setMainTutsFinished:YES];
    if (![[self class] groupsTutsFinished]) {
        [self showGroupsTuts];
    }
    self.inTutorial = NO;
}

- (void)showGroupsTuts
{
    if (![Forum isLoggedIn] || self.groups.count <= LOCAL_GROUPS_NUM) {
        return;
    }
    if (![self.groups containsObject:[ForumGroup groupsGroup]]) {
        return;
    }
    if (self.tutsViewGroups.hidden) {
        self.tutsViewGroups.alpha = 0.0;
        self.tutsViewGroups.hidden = NO;
        [UIView animateWithDuration:0.25 delay:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.tutsViewGroups.alpha = 1.0;
        } completion:^(BOOL finished) {
            [self beginGroupsTutsAnimation];
        }];
    } else {
        [self beginGroupsTutsAnimation];
    }
}

- (void)beginGroupsTutsAnimation
{
    if (!self.groupsTutsAnimating) {
        self.groupsTutsAnimating = YES;
        self.tutsGroupsDot.alpha = 0.4;
        self.tutsTooltipTop.constant = 52.0;
        [self.tutsGroupsTooltip setNeedsLayout];
        [self.tutsGroupsTooltip layoutIfNeeded];
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat|UIViewAnimationCurveEaseOut animations:^{
            self.tutsGroupsDot.alpha = 0.7;
            self.tutsTooltipTop.constant = 47.0;
            [self.tutsGroupsTooltip setNeedsLayout];
            [self.tutsGroupsTooltip layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.groupsTutsAnimating = NO;
        }];
    }
}

- (void)hideGroupsTuts
{
    [UIView animateWithDuration:0.25 animations:^{
        self.tutsViewGroups.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.tutsViewGroups.hidden = YES;
    }];
}

- (void)finishGroupsTuts
{
    [self hideGroupsTuts];
    [[self class] setGroupsTutsFinished:YES];
}

- (IBAction)skipTutorial:(id)sender {
    if ([Forum isLoggedIn]) {
        [self.tabScrollView setContentOffset:CGPointMake(MAX(0.0, self.tabScrollView.contentSize.width - self.tabScrollView.width), 0.0) animated:YES];
    }
    [self finishMainTuts];
}


- (IBAction)showUserProfilePage:(id)sender
{
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    [Forum log:BTN_CLK_FORUM_NAV_PROFILE];
    ForumUser *user = [Forum currentForumUser];
    ForumProfileViewController *vc = [[ForumProfileViewController alloc] initWithUserID:user.identifier
                                                                        placeholderUser:user];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)didClickQuiz:(Event *)event {
    ForumTopic *topic = event.data;
    if ([topic isKindOfClass:[ForumTopic class]] && topic.isQuiz) {
        ForumQuizViewController *quizView = [ForumQuizViewController viewController];
        quizView.topicId = topic.identifier;
        [self presentViewController:quizView animated:YES completion:nil];
        if (self.searchPoped) {
            [Forum log:BTN_CLK_FORUM_TAKE_QUIZ_FROM_GROUP eventData:@{
                @"topic_id": @(topic.identifier),
                @"group_id": @(0),
                @"group_type": @"search_result",
            }];
        } else {
            ForumGroup *group = self.groups[self.currentPage];
            [Forum log:BTN_CLK_FORUM_TAKE_QUIZ_FROM_GROUP eventData:@{
                @"topic_id": @(topic.identifier),
                @"group_id": @(group.identifier),
                @"group_type": @(group.type),
            }];
        }
    }
}

@end
