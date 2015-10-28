//
//  TabbarController.m
//  emma
//
//  Created by Eric Xu on 10/11/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <GLCommunity/ForumTabNavController.h>
#import "AppDelegate.h"
#import "DropdownMessageController.h"
#import "EmmaNavigationController.h"
#import "Errors.h"
#import "Events.h"
#import "FulfillmentManager.h"
#import "Logging.h"
#import "StatusBarOverlay.h"
#import "TabbarController.h"
#import "User.h"
#import "AnimationSequence.h"
#import "GeniusMainViewController.h"
#import "BadgeView.h"
#import "UIView+Helpers.h"
#import <GLNavigationController.h>
#import <GLDialogViewController.h>
#import "AskLocationDialog.h"
#import "GLLocationManager.h"
#import <GLCommunity/ForumEvents.h>
#import "AlertContainerViewController.h"
#import "MeViewController.h"
#import "HomeViewController.h"
#import "MedicalRecordsDataManager.h"
#import "DebugViewController.h"
#import <GLCommunity/ForumProfileViewController.h>

#define TABBAR_ITEM_TAG_HOME 0
// #define TABBAR_ITEM_TAG_PLOG 1
#define TABBAR_ITEM_TAG_GENIUS 1
#define TABBAR_ITEM_TAG_ALERT 2
#define TABBAR_ITEM_TAG_ME 3
#define TABBAR_ITEM_TAG_COMM 4

#define POPUP_COMM_TAG @"popup_comm"
#define POPUP_PROMO_TAG @"popup_promo"
#define POPUP_GG_TUTORIAL_TAG @"popup_gg_tutorial"

#define DEFAULTS_GENIUS_UNREAD_VIEW_LAST_SHOWN @"defaults_genius_unread_view_last_shown"
#define DEFAULTS_GENIUS_UNREAD_VIEWS @"defaults_genius_unread_views"

@interface TabbarController () <UITabBarControllerDelegate, UIActionSheetDelegate> {
    // int mePageIndex;

    UIViewController *homeTabViewController;
    GeniusMainViewController *geniusTabViewController; // instead of periodTabViewController
    // UIViewController *periodTabViewController;
    UIViewController *commTabViewController;
    UIViewController *alertTabViewController;
    UIViewController *meTabViewController;
    
    NSInteger geniusBadgeCount;   // genius icon number
}

@property (nonatomic) NSArray * tabNames;

@property (nonatomic) BOOL underIconAnimation;  // genius related animation
@property (nonatomic) BOOL underDisplayAnimation;  // show/hide tabbar animation

@property (nonatomic) UIView * tabbarShadow;

@property (nonatomic) BOOL hasPopup;
@property (strong, nonatomic) NSTimer *popupViewTimer;
@property (strong, nonatomic) UIView * tipsPopupView;
@property (nonatomic) NSString * currentPopupView;
@property (nonatomic,strong) NSMutableDictionary *redDotViews;

@property (nonatomic, strong) GLLocationManager *locationManager;
@end

@implementation TabbarController

+ (TabbarController *)getInstance:(UIViewController *)viewController {
    return (TabbarController *)viewController.tabBarController;
}

- (NSDictionary *)popupMapper {
    return @{
        POPUP_COMM_TAG:@{
        @"text": @"Check out the Glow community!",
        @"position": TABBAR_NAME_COMM},
        POPUP_PROMO_TAG:@{
        @"text": @"Congrats! You’ve been selected to join our exclusive promo!",
        @"position": TABBAR_NAME_GENIUS},
        POPUP_GG_TUTORIAL_TAG:@{
        @"text": @"Check out Glow Genius!",
        @"position": TABBAR_NAME_GENIUS},
    };
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    geniusBadgeCount = 0;
    
    self.underIconAnimation = NO;
    self.underDisplayAnimation = NO;
    self.hidden = NO;
    self.hasPopup = NO;
    self.redDotViews = [NSMutableDictionary dictionary];
    
    [self reloadTabbarsForced:NO];
    
    // DEBUG for fund pages
    if (FUND_DEBUG_SWITCH) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fundDebugActionSheet)];
        tap.numberOfTapsRequired = 3;
        [self.view addGestureRecognizer:tap];
    }
    
    if (DEBUG_PANEL_SWITCH) {
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showDebugPanel)];
        gesture.numberOfTapsRequired = 2;
        [self.view addGestureRecognizer:gesture];
    }
    
    UIImage *shadowImage = [UIImage imageNamed:@"period-cal-shadow"];
    self.tabbarShadow = [[UIImageView alloc] initWithImage:shadowImage];
    self.tabbarShadow.width = SCREEN_WIDTH;
    if (IS_IPHONE_6_PLUS) {
        self.tabbarShadow.top -= 5.5;
    }
    else {
        self.tabbarShadow.top -= 7;
    }
    [self.tabBar addSubview:self.tabbarShadow];
    
    [self subscribeEvents];
}

- (void)showDebugPanel
{
    DebugViewController *vc = [DebugViewController instance];
    vc.tabbarVC = self;
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
    [[AppDelegate topMostController] presentViewController:navVC animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.viewControllerToPresentAfterMain) {
        [self presentViewController:appDelegate.viewControllerToPresentAfterMain animated:YES completion:nil];
        appDelegate.viewControllerToPresentAfterMain = nil;
    }
    [self updateAlertItemCount];
    [self updateGeniusItemCount];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // [self unsubscribeAll];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateCommunityNewRedDot
{    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kDidClickCommunityTab]) {
        if (self.selectedViewController.tabBarItem.tag == TABBAR_ITEM_TAG_COMM) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDidClickCommunityTab];
            return;
        }
        [self showRedDotViewOnTab:TABBAR_NAME_COMM];
    }
    else {
        [self hideRedDotViewOnTab:TABBAR_NAME_COMM];
    }
}

- (void)showRedDotViewOnTab:(NSString *)tabName
{
    [self hideRedDotViewOnTab:tabName];
    CGFloat itemWidth = self.tabBar.frame.size.width / self.tabNames.count;
    CGFloat x = ([self getIndexByTabName:tabName] + 0.5) * itemWidth + 9;
    CGRect rect = CGRectMake(x, 2, 8, 8);
    UIView *redDotView = [[UIView alloc] initWithFrame:rect];
    self.redDotViews[tabName] = redDotView;
    redDotView.backgroundColor = [UIColor redColor];
    redDotView.layer.cornerRadius = redDotView.height / 2;
    [self.tabBar addSubview:redDotView];
}

- (void)hideRedDotViewOnTab:(NSString *)tabName
{
    UIView *redDotView = self.redDotViews[tabName];
    if (redDotView) {
        [redDotView removeFromSuperview];
        [self.redDotViews removeObjectForKey:tabName];
    }
}

- (void)reloadTabbarsForced:(BOOL)forced {

    self.delegate = self;
    [self.tabBar setTintColor:UIColorFromRGB(0x6C6DD3)];
    
    if (!homeTabViewController || forced) {
        homeTabViewController = [[UIStoryboard storyboardWithName:@"home" bundle:nil] instantiateViewControllerWithIdentifier:@"home"];
    }
    
    if (!geniusTabViewController || forced) {
        geniusTabViewController = [[UIStoryboard storyboardWithName:@"genius" bundle:nil] instantiateViewControllerWithIdentifier:@"mainView"];
    }
    
    if (!commTabViewController || forced) {
        commTabViewController = [ForumTabNavController viewController];
    }
    
    if (!alertTabViewController || forced) {
        alertTabViewController = [UIStoryboard alert];
    }
    
    if (!meTabViewController || forced) {
        meTabViewController = [UIStoryboard me];
        meTabViewController.title = @"Me";
    }
    
    NSDictionary * tabControllers = @{
         TABBAR_NAME_HOME:   @{
                 @"viewController" : homeTabViewController,
                 @"title" : @"Home",
                 @"image" : @"bottom-nav-home",
                 @"tag"   : @(TABBAR_ITEM_TAG_HOME)
                },
         TABBAR_NAME_GENIUS: @{
                 @"viewController" : geniusTabViewController,
                 @"title" : @"Genius",
                 @"image" : @"bottom-nav-genius",
                 @"tag"   : @(TABBAR_ITEM_TAG_GENIUS)
                 },
         TABBAR_NAME_COMM: @{
                 @"viewController" : commTabViewController,
                 @"title" : @"Community",
                 @"image" : @"bottom-nav-community",
                 @"tag"   : @(TABBAR_ITEM_TAG_COMM)
                 },
         TABBAR_NAME_ALERT: @{
                 @"viewController" : alertTabViewController,
                 @"title" : @"Alert",
                 @"image" : @"bottom-nav-alert",
                 @"tag"   : @(TABBAR_ITEM_TAG_ALERT)
                 },
         TABBAR_NAME_ME: @{
                 @"viewController" : meTabViewController,
                 @"title" : @"Me",
                 @"image" : @"bottom-nav-me",
                 @"tag"   : @(TABBAR_ITEM_TAG_ME)
                 },
         };
    
    NSMutableArray * controllers = [[NSMutableArray alloc] init];
    self.tabNames = @[TABBAR_NAME_HOME,
                     TABBAR_NAME_COMM,
                     TABBAR_NAME_GENIUS,
                     TABBAR_NAME_ALERT,
                     TABBAR_NAME_ME];
    
    
    for (NSString * name in self.tabNames) {
        NSDictionary * dict = [tabControllers objectForKey:name];
        UIViewController * viewController = [dict objectForKey:@"viewController"];
        UIImage *img = [Utils image:[UIImage imageNamed:[dict objectForKey:@"image"]] withColor:UIColorFromRGB(0x999999)];
        
        UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:[dict objectForKey:@"title"]
                                                                 image:img
                                                                   tag:[[dict objectForKey:@"tag"] intValue]];
        tabBarItem.titlePositionAdjustment = UIOffsetMake(0.0, -3.0);
        viewController.tabBarItem = tabBarItem;

        if ([name isEqualToString:TABBAR_NAME_COMM]) {
            GLNavigationController *navController = [[GLNavigationController alloc] initWithRootViewController:viewController];
            [controllers addObject:navController];
        } else if ([name isEqualToString:TABBAR_NAME_ALERT]) {
            [controllers addObject:alertTabViewController];
        } else {
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
            [controllers addObject:navController];
        }
    }
    self.viewControllers = [NSArray arrayWithArray:controllers];
  
    // DEBUG for fund pages
    if (FUND_DEBUG_SWITCH) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fundDebugActionSheet)];
        tap.numberOfTapsRequired = 3;
        [self.view addGestureRecognizer:tap];
    }
    
    [self repositionPopupView];
}

- (BOOL)enableGlowFirst {
    return ([User currentUser] && [User currentUser].currentPurpose != AppPurposesAvoidPregnant);
}

- (NSInteger)getIndexByTabName:(NSString *)name {
    return [self.tabNames indexOfObject:name];
}

- (void)subscribeEvents {
    /*
     * We don't need -
     *  - [self subscribeOnce:EVENT_HOME_VIEW_APPEAR selector:@selector(onHomeViewAppeared:)];
     */
    /*
     * Pending -
     //[self subscribe:EVENT_PARTNER_INVITED selector:@selector(onPartnerInvited:)];
     //[self subscribe:EVENT_PARTNER_REMOVED selector:@selector(onPartnerRemoved:)];
     //[self subscribe:EVENT_PROFILE_IMAGE_UPDATE selector:@selector(onProfileImageUpdated:)];
     //[self subscribe:EVENT_ACTIVITY_UPDATED selector:@selector(onActivityUpdated:)];
     */
    [self subscribe:EVENT_DATA_SUMMARY_SENT handler:^(Event *event) {
        [[StatusBarOverlay sharedInstance] postMessage:@"Sent!" duration:2];
    }];
    [self subscribe:EVENT_FUND_RENEW_PAGE selector:@selector(onFundRenewPage:)];
    
    [self subscribe:EVENT_DAILY_LOG_PREGNANT selector:@selector(onDailyLogPregnant:)];
    [self subscribe:EVENT_GO_CONNECTING_3RD_PARTY selector:@selector(onGoConnecting3rdPartyHealthApp:)];
    [self subscribe:EVENT_USER_CLK_PREGNANT selector:@selector(onDailyLogPregnant:)];
    [self subscribe:EVENT_PURPOSE_CHANGED selector:@selector(onPurposeChanged:)];
    [self subscribe:EVENT_SWITCH_FROM_PREGNANT selector:
            @selector(onSwitchFromPregnant)];
    
    __weak TabbarController *wself = self;
    [self subscribe:EVENT_HIDE_COMMUNITY_POPUP handler:^(Event *event) {
        [wself hideCommunityPopup];
    }];
    
    [self subscribe:EVENT_SHOW_COMMUNITY_POPUP handler:^(Event *event) {
        if ([event.data isKindOfClass:[NSNumber class]]) {
            NSNumber *delay = (NSNumber *)event.data;
            [wself showCommunityPopupDelay:[delay doubleValue]];
        } else {
            [wself showCommunityPopup];
        }
    }];

    [self subscribe:EVENT_SHOW_GG_TUTORIAL_POPUP handler:^(Event *event) {
        NSNumber *delay = (NSNumber *)event.data;
        [wself showGeniusTutorialPopupDelay:[delay doubleValue]];
    }];
    
    // The number of Genius should be updated by
    // EVENT_INSIGHT_UPDATED
    //       - called in user push callback
    //       - called in user sync
    // EVENT_NOTIFICATION_UPDATED
    //       - called in user sync
    // EVENT_UNREAD_NOTIFICATIONS_CLEARED
    //       - called when notification page closed
    // EVENT_UNREAD_INSIGHTS_CLEARED
    //       - called when insight page closed

    
    [self subscribe:EVENT_NOTIFICATION_UPDATED selector:@selector(updateAlertItemCount)];
    [self subscribe:EVENT_UNREAD_NOTIFICATIONS_CLEARED selector:@selector(updateAlertItemCount)];    
    [self subscribe:EVENT_FORUM_NEED_UPDATE_RED_DOT selector:@selector(updateCommunityNewRedDot)];
    
    // genius page unread views
    @weakify(self)
    [self subscribe:EVENT_CHART_NEEDS_UPDATE_TEMP handler:^(Event *event) {
        @strongify(self)
        [self geniusNeedShowUnreadView:@(TAG_GENIUS_CHILD_BBT_CHART)];
    }];
    [self subscribe:EVENT_CHART_NEEDS_UPDATE_WEIGHT handler:^(Event *event) {
        @strongify(self)
        [self geniusNeedShowUnreadView:@(TAG_GENIUS_CHILD_WEIGHT_CHART)];
    }];
    [self subscribe:EVENT_CHART_NEEDS_UPDATE_CALORIE handler:^(Event *event) {
        @strongify(self)
        [self geniusNeedShowUnreadView:@(TAG_GENIUS_CHILD_CALORIES_CHART)];
    }];
    [self subscribe:EVENT_CHART_NEEDS_UPDATE_NUTRITION handler:^(Event *event) {
        @strongify(self)
        [self geniusNeedShowUnreadView:@(TAG_GENIUS_CHILD_NUTRITION_CHART)];
    }];
    [self subscribe:EVENT_GENIUS_UNREAD_VIEW_HAS_BEEN_SHOWN selector:@selector(geniusUnreadViewHasBeenShown:)];
    
    // no need to update tabbar badge when insights get updated
    //    [self subscribe:EVENT_INSIGHT_UPDATED handler:^(Event *event) {
    //        [self geniusNeedShowUnreadView:@(TAG_GENIUS_CHILD_INSIGHT)];
    //        [self updateGeniusItemCount];
    //    }];
    //    [self subscribe:EVENT_UNREAD_INSIGHTS_CLEARED selector:@selector(updateGeniusItemCount)];

    [self subscribe:EVENT_NOTIF_GO_DAILY_LOG handler:^(Event *event) {
        @strongify(self)
        
        [self selectHomePage];
        
        UINavigationController * nav = (UINavigationController *)[self.viewControllers objectAtIndex:0];
        HomeViewController * homeController = (HomeViewController * )([nav.viewControllers objectAtIndex:0]);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [homeController gotoDailyLogPage];
        });
    }];
}

- (void)onPurposeChanged:(Event *)event {
    // remove all red dot views
    [[self.redDotViews allValues]makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.redDotViews removeAllObjects];
    
    [self reloadTabbarsForced:NO];
    self.selectedIndex = [self getIndexByTabName:TABBAR_NAME_ME];

    if ([homeTabViewController respondsToSelector:@selector(onPurposeChange:)]) {
        [homeTabViewController performSelector:@selector(onPurposeChange:) withObject:nil];
    }
}

- (void)onSwitchFromPregnant {
    self.selectedIndex = self.periodLogIndex;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New period"
            message:@"Add new round of your period. Leave empty if it does not "
                "come yet."
            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)onDailyLogPregnant:(Event *)event {
    [self goPregnantPage];
}
- (void)goPregnantPage {
    [self selectPageIndex:[self getIndexByTabName:TABBAR_NAME_ME]];
    UINavigationController *nav = (UINavigationController *)self.selectedViewController;
    if ([nav.viewControllers[0] respondsToSelector:@selector(onPregnant:)]) {
        [nav.viewControllers[0] performSelector:@selector(onPregnant:) withObject:nil afterDelay:1];
    }
}

- (void)onGoConnecting3rdPartyHealthApp:(Event *)event {
    
    [UIView transitionWithView:self.view duration:0.5f
        options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        
        [self setSelectedIndex:[self getIndexByTabName:TABBAR_NAME_ME]];
    } completion: ^(BOOL finished){
        [self publish:EVENT_SHOW_ME_CONNECTION_SECTION];
    }];
}

- (UIViewController *)fundViewController
{
    UIViewController *dest = nil;
    User *u = [User currentUser];
    
    switch (u.ovationStatus) {
        case OVATION_STATUS_UNDER_REVIEW:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"appliedFund"];
            break;
        case OVATION_STATUS_PASS_REVIEW:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"acceptedFund"];
            break;
        case OVATION_STATUS_FAIL_REVIEW:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"rejectedFund"];
            break;
        case OVATION_STATUS_UNDER_FUND:
        case OVATION_STATUS_UNDER_FUND_DELAY:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"ongoing"];
            break;
        case OVATION_STATUS_EXIT_FUND:
        case OVATION_STATUS_PREGNANT:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"ongoing"];
            break;
        case OVATION_STATUS_GET_FUND:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"fundClaimPre"];
            break;
        case OVATION_STATUS_DEMO:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"demo"];
            break;
        default:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"home"];
            break;
    }

    return dest;
}

- (void)rePerformFundSegue {
    if (![self enableGlowFirst])
        return;
    
    [self selectFundPage];
}

- (void)onFundRenewPage:(Event *)evt {
    NSDictionary *resp = (NSDictionary *)evt.data;
    NSInteger rc = [[resp objectForKey:@"rc"] integerValue];
    if (rc==RC_SUCCESS) {
        [self rePerformFundSegue];
    } else {
        if (FUND_DEBUG_SWITCH) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                                message:@"Can not go to that page!"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
}

#pragma mark - property shortcut
- (int)periodLogIndex {
    return 1;
}

#pragma mark - fund debug action sheet
- (void)fundDebugActionSheet {
    if (!FUND_DEBUG_SWITCH) {
        return;
    }
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Choose fund page"
                                  delegate:self
                                  cancelButtonTitle:@"Current Page"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"Landing page", @"Rejected review", @"Pass review", @"Under fund", @"Pregnant", @"Kicked out", @"Fund end", nil];
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 9) {
        return;
    }
    [[GlowFirst sharedInstance] adminSetFundPage:buttonIndex];
}

#pragma mark - UITabBarControllerDelegate
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    GLLog(@"tab selected:%d", viewController.tabBarItem.tag);
    switch (viewController.tabBarItem.tag) {
        case TABBAR_ITEM_TAG_HOME:
            [Logging log:BTN_CLK_TAB_HOME];
            break;
        case TABBAR_ITEM_TAG_GENIUS: {
            // hide tab bar in Glow Genius
            [Logging log:BTN_CLK_TAB_GENIUS];
            [self hidePromoPopup];
            [self hideGeniusTutorialPopup];
            NSMutableOrderedSet *geniusUnreadViews = [self geniusUnreadViews];
            // show when there's only one unread view
            if (geniusUnreadViews.count == 1) {
                geniusTabViewController.unreadViewTag = geniusUnreadViews[0];
            }
            break;
        }
        case TABBAR_ITEM_TAG_COMM: {
            [Logging log:BTN_CLK_TAB_FORUM];
            [self hideCommunityPopup];
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDidClickCommunityTab];
            [self updateCommunityNewRedDot];
        
            // ask location dialog
            NSInteger seenTimes = [[Utils getDefaultsForKey:USER_DEFAULTS_KEY_FORUM_SEEN_TIMES] integerValue];
            if (seenTimes > 0) {
                // 0 not asked,  1 yes,  2 no
                NSInteger asked = [[Utils getDefaultsForKey:USER_DEFAULTS_KEY_ASK_LOCATION] integerValue];
                if (!asked) {
                    AskLocationDialog *dialog = [[AskLocationDialog alloc] init];
                    [dialog present];
                } else if (asked == 1) {
                    // sync again
                    if (!self.locationManager) {
                        self.locationManager = [[GLLocationManager alloc] init];
                    }
                    [self.locationManager startUpdatingLocation:nil failCallback:nil];
                }
            } else {
                [Utils setDefaultsForKey:USER_DEFAULTS_KEY_FORUM_SEEN_TIMES withValue:@(1)];
            }
            break;
        }
        case TABBAR_ITEM_TAG_ALERT:
            [Logging log:BTN_CLK_TAB_ALERT];
            break;
        case TABBAR_ITEM_TAG_ME:
//            [[MedicalRecordsDataManager sharedInstance] fetchSummaryData];
            [Logging log:BTN_CLK_TAB_ME];
            break;
        default:
            break;
    }
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if (self.underDisplayAnimation) return NO;
    if (self.selectedViewController == viewController) {
        if (viewController.tabBarItem.tag == TABBAR_ITEM_TAG_COMM) {
            [self publish:EVENT_FORUM_GOTO_FIRST_ROOM];
        }
    }
    if ((self.selectedViewController == viewController) && (viewController.tabBarItem.tag == TABBAR_ITEM_TAG_COMM)) {
        [self publish:EVENT_DOUBLE_TAP_COMMUNITY_TAB];
    }
    return YES;
}


- (void)selectFundPage {
    [self selectMePage];
    MeViewController *vc = (MeViewController *)meTabViewController;
    [vc goToGlowFirstPage];
}

- (void)selectForumPage {
    [self selectPageIndex:[self getIndexByTabName:TABBAR_NAME_COMM]];
}

- (void)selectGeniusPage {
    [self selectPageIndex:[self getIndexByTabName:TABBAR_NAME_GENIUS]];
}

- (void)selectHomePage {
    [self selectPageIndex:[self getIndexByTabName:TABBAR_NAME_HOME]];
}

- (void)selectMePage
{
    [self selectPageIndex:[self getIndexByTabName:TABBAR_NAME_ME]];
}

- (void)selectAlertPage
{
    [self selectPageIndex:[self getIndexByTabName:TABBAR_NAME_ALERT]];
}

- (void)goToFertitliyTreatmentPage:(id)sender
{
    [self selectPageIndex:[self getIndexByTabName:TABBAR_NAME_ME]];
    [meTabViewController performSegueWithIdentifier:@"fertilityTreatmentIdentifier" sender:sender];
}



#pragma mark - Genius related functions

- (void)updateGeniusItemCount
{
    // only show red dot when there's one chart has an update
    if ([self geniusUnreadViews].count == 1) {
        geniusTabViewController.tabBarItem.badgeValue = nil;
        [self showRedDotViewOnTab:TABBAR_NAME_GENIUS];
    } else {
        geniusTabViewController.tabBarItem.badgeValue = nil;
        [self hideRedDotViewOnTab:TABBAR_NAME_GENIUS];
    }
}

- (void)geniusNeedShowUnreadView:(NSNumber *)viewTag
{
    // show unread view one time per day
    NSDate* lastSeen = [Utils getDefaultsForKey:DEFAULTS_GENIUS_UNREAD_VIEW_LAST_SHOWN];
    if (lastSeen && [Utils date:lastSeen isSameDayAsDate:[NSDate date]]) {
        return;
    }
    NSMutableOrderedSet *geniusUnreadViews = [self geniusUnreadViews];
    [geniusUnreadViews addObject:viewTag];
    [Utils setDefaultsForKey:DEFAULTS_GENIUS_UNREAD_VIEWS withValue:[geniusUnreadViews array]];
    [self updateGeniusItemCount];
}

- (NSMutableOrderedSet *)geniusUnreadViews
{
    NSArray *unreadViewsArray = [Utils getDefaultsForKey:DEFAULTS_GENIUS_UNREAD_VIEWS];
    NSMutableOrderedSet *geniusUnreadViews = [[NSMutableOrderedSet alloc]initWithArray:unreadViewsArray?:@[]];
    return geniusUnreadViews;
}

- (void)geniusUnreadViewHasBeenShown:(Event *)event
{
    [Utils setDefaultsForKey:DEFAULTS_GENIUS_UNREAD_VIEWS withValue:nil];
    [self hideRedDotViewOnTab:TABBAR_NAME_GENIUS];
    geniusTabViewController.tabBarItem.badgeValue = nil;
    [Utils setDefaultsForKey:DEFAULTS_GENIUS_UNREAD_VIEW_LAST_SHOWN withValue:[NSDate date]];
}

#pragma mark - Show / Hide tabbar animation
- (void)hideWithAnimation:(BOOL)animation {
    if (self.hidden) return;
    if (self.underDisplayAnimation) return;

    UIView * tranView = nil;
    for (UIView * v in self.view.subviews) {
        if(![v isKindOfClass:[UITabBar class]]) {
            tranView = v;
            break;
        }
    }
    CGRect rect = self.tabBar.frame;
    if (animation) {
        self.underDisplayAnimation = YES;
        [UIView animateWithDuration:0.3 animations:^{
            [self.tabBar setFrame:CGRectMake(rect.origin.x, rect.origin.y + rect.size.height, rect.size.width, rect.size.height)];
            if (self.hasPopup) {
                self.tipsPopupView.alpha = 0;
            }
        } completion:^(BOOL finished) {
            self.hidden = YES;
            self.underDisplayAnimation = NO;
            self.tabbarShadow.hidden = YES;
        }];
    } else {
        [self.tabBar setFrame:CGRectMake(rect.origin.x, rect.origin.y + rect.size.height, rect.size.width, rect.size.height)];
        if (self.hasPopup) {
            self.tipsPopupView.alpha = 0;
        }
        self.hidden = YES;
        self.tabbarShadow.hidden = YES;
    }
}

- (void)showWithAnimation:(BOOL)animation {
    if (!self.hidden) return;
    if (self.underDisplayAnimation) return;
    
    UIView * tranView = nil;
    for (UIView * v in self.view.subviews) {
        if(![v isKindOfClass:[UITabBar class]]) {
            tranView = v;
            break;
        }
    }
    CGRect rect = self.tabBar.frame;
    if (animation) {
        self.underDisplayAnimation = YES;
        [UIView animateWithDuration:0.3 animations:^{
            [self.tabBar setFrame:CGRectMake(rect.origin.x, rect.origin.y - rect.size.height, rect.size.width, rect.size.height)];
            if (self.hasPopup) {
                self.tipsPopupView.alpha = 1;
            }
        } completion:^(BOOL finished) {
            self.hidden = NO;
            self.underDisplayAnimation = NO;
            self.tabbarShadow.hidden = NO;
        }];
    } else {
        [self.tabBar setFrame:CGRectMake(rect.origin.x, rect.origin.y - rect.size.height, rect.size.width, rect.size.height)];
        if (self.hasPopup) {
            self.tipsPopupView.alpha = 1;
        }
        self.hidden = NO;
        self.tabbarShadow.hidden = NO;
    }
}

- (void)selectPageIndex:(NSUInteger)index {
    // REMIND! please use this function instead of "setSelectedIndex"
    [self setSelectedIndex:index];
    [self showWithAnimation:NO];
}

- (void)updateAlertItemCount {
    User *u = [User currentUser];
    NSInteger count = u.unreadNotificationCount;
    alertTabViewController.tabBarItem.badgeValue = count == 0 ? nil : [@(count)stringValue];
}

#pragma mark - popup UI

- (UIView *)tipsPopupView {
    if (!_tipsPopupView) {
        _tipsPopupView = [[UIView alloc] init];
        UIView * tipsContainer = [[UIView alloc] init];
        tipsContainer.tag = 1;
        tipsContainer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.694];
        tipsContainer.layer.cornerRadius = 5;
        tipsContainer.frame = CGRectMake(0, 0, 130, 50);
        
        UILabel * tipsLabel = [[UILabel alloc] init];
        tipsLabel.text = @"Tips";
        tipsLabel.textColor = [UIColor whiteColor];
        tipsLabel.frame = CGRectMake(10, 8, 110, 30);
        tipsLabel.font = [Utils defaultFont:14];
        tipsLabel.lineBreakMode = NSLineBreakByWordWrapping;
        tipsLabel.numberOfLines = 0;
        tipsLabel.textAlignment = NSTextAlignmentCenter;
        tipsLabel.backgroundColor = [UIColor clearColor];
        
        [tipsContainer addSubview:tipsLabel];
        
        UIImageView * imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial-checkout-popup"]];
        imgView.tag = 2;
        imgView.frame = CGRectMake(58, -0.5, 14, 5.5);
        
        [_tipsPopupView addSubview:tipsContainer];
        [_tipsPopupView addSubview:imgView];
        _tipsPopupView.frame = CGRectMake(0, 0, 130, 30);
    }
    return _tipsPopupView;
}

- (void)resetTipsPopupText {
    NSString * text = [[[self popupMapper] objectForKey:self.currentPopupView] objectForKey:@"text"];
    UIView * tipsContainer = [self.tipsPopupView viewWithTag:1];
    UILabel * label = (UILabel *)[[tipsContainer subviews] objectAtIndex:0];
    UIImageView * arrowView = (UIImageView *)[self.tipsPopupView viewWithTag:2];
    
    // set text label, only if it is changed.
    if ([label.text isEqualToString:text]) {
        return;
    }
    label.text = text;
    // default width = 110
    [label sizeToFit];
    label.frame = setRectWidth(label.frame, 110);
    CGFloat h = label.frame.size.height;
    // set tipsContainer
    tipsContainer.frame = CGRectMake(0, 0, 130, h + 16);
    // set arrow position
    arrowView.frame = setRectY(arrowView.frame, h+16);
    // set tips popup view itself
    self.tipsPopupView.frame = CGRectMake(0, 0, 130, h+16+5.5);
}

- (void)repositionPopupView {
    if (!self.hasPopup) {
        return;
    }
    CGPoint center;
    if (self.currentPopupView) {
        NSInteger total = self.viewControllers.count;
        CGFloat itemWidth = self.tabBar.frame.size.width / total;
        NSInteger positionIndex = [self getIndexByTabName:[[[self popupMapper] objectForKey:self.currentPopupView] objectForKey:@"position"]];
        center = CGPointMake(itemWidth * (positionIndex + 0.5), 0.0);
    } else {
        center = CGPointMake(-200, 0.0);
    }
    if (!self.tipsPopupView.superview) {
        [self.tabBar addSubview:self.tipsPopupView];
    }
    [self.tabBar bringSubviewToFront:self.tipsPopupView];
    self.tipsPopupView.layer.anchorPoint = CGPointMake(0.5, 1.0);
    self.tipsPopupView.center = center;
}

- (BOOL)showPopupView:(NSString *)tipName {
    if (self.hasPopup) {
        return NO;
    }
    self.hasPopup = YES;
    self.currentPopupView = tipName;
    [self resetTipsPopupText];
    [self repositionPopupView];
    self.tipsPopupView.alpha = 0.0;
    self.tipsPopupView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    
    [AnimationSequence performAnimations:@[[AnimationBlock duration:0.25 animations:^{
        self.tipsPopupView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.tipsPopupView.alpha = 1.0;
    }], [AnimationBlock duration:0.05 animations:^{
        self.tipsPopupView.transform = CGAffineTransformIdentity;
    }]] completion:^(BOOL finished) {
    }];
    return YES;
}

- (void)hidePopupView {
    if (!self.hasPopup) {
        return;
    }
    if (self.popupViewTimer) {
        [self.popupViewTimer invalidate];
        self.popupViewTimer = nil;
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.tipsPopupView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        self.tipsPopupView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.tipsPopupView removeFromSuperview];
        self.tipsPopupView.transform = CGAffineTransformMakeScale(1, 1);
        self.hasPopup = NO;
        self.currentPopupView = nil;
    }];
}

- (void)showCommunityPopupDelay:(NSTimeInterval)delay
{
    if (self.popupViewTimer) {
        [self.popupViewTimer invalidate];
        self.popupViewTimer = nil;
    }
    if (delay > 0.0) {
        self.popupViewTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(showCommunityPopup) userInfo:nil repeats:NO];
    } else {
        [self showCommunityPopup];
    }
}
- (void)showCommunityPopup {
    if (geniusTabViewController) {
        GeniusMainViewController *geniusVc = (GeniusMainViewController*)geniusTabViewController;
        if ([geniusVc anyChildOpened]) {
            return;
        }
    }

    if ([self showPopupView:POPUP_COMM_TAG]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDidClickCheckoutCommunity];
    };
}
- (void)hideCommunityPopup {
    if ([self.currentPopupView isEqualToString:POPUP_COMM_TAG]) {
        [self hidePopupView];
    }
}

- (void)showPromoPopupDelay:(NSTimeInterval)delay
{
    if (self.popupViewTimer) {
        [self.popupViewTimer invalidate];
        self.popupViewTimer = nil;
    }
    if (delay > 0.0) {
        self.popupViewTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(showPromoPopup) userInfo:nil repeats:NO];
    } else {
        [self showPromoPopup];
    }
}
- (void)showPromoPopup {
    if ([self showPopupView:POPUP_PROMO_TAG]) {
        [Utils setDefaultsForKey:DEFAULTS_GG_TUTORED withValue:@YES];
    };
}
- (void)hidePromoPopup {
    if ([self.currentPopupView isEqualToString:POPUP_PROMO_TAG]) {
        [self hidePopupView];
    }
}

- (void)showGeniusTutorialPopupDelay:(NSTimeInterval)delay
{
    if (self.popupViewTimer) {
        [self.popupViewTimer invalidate];
        self.popupViewTimer = nil;
    }
    if (delay > 0.0) {
        self.popupViewTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(showGeniusTutorialPopup) userInfo:nil repeats:NO];
    }
    else {
        [self showGeniusTutorialPopup];
    }
}
- (void)showGeniusTutorialPopup {
    if ([self showPopupView:POPUP_GG_TUTORIAL_TAG]) {
        //[Utils setDefaultsForKey:DEFAULTS_GG_TUTORED withValue:@YES];
    };
}
- (void)hideGeniusTutorialPopup {
    if ([self.currentPopupView isEqualToString:POPUP_GG_TUTORIAL_TAG]) {
        [self hidePopupView];
    }
}

@end
