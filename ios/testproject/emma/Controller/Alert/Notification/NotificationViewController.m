//
//  NotificationViewController.m
//  emma
//
//  Created by Ryan Ye on 3/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "BadgeView.h"
#import "DropdownMessageController.h"
#import "Logging.h"
#import "Notification.h"
#import "NotificationBodyCell.h"
#import "NotificationViewController.h"
#import "Reminder.h"
#import "ReminderDetailViewController.h"
#import "User.h"
#import "GeniusMainViewController.h"
#import "TabbarController.h"
#import "HomeViewController.h"
#import "AlertContainerViewController.h"
#import "WalgreensManager.h"
#import "WalgreensScannerViewController.h"

@interface NotificationViewController ()

@property (nonatomic, strong)NSFetchRequest *fetchRequest;
@property (nonatomic, strong)NSMutableArray *visibleNotifications;

@end

@implementation NotificationViewController

+ (id)getInstance {
    return [[NotificationViewController alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.model = [User currentUser];

    [self.tableView registerNib:[UINib nibWithNibName:@"NotificationBodyCell" bundle:nil] forCellReuseIdentifier:@"NotificationBodyCell"];
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 44, 0);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [CrashReport leaveBreadcrumb:@"NotificationViewController"];
    [self setUnreadCount];
    
    [self subscribe:EVENT_NOTIFICATION_HIDDEN selector:@selector(hideNotification:)];
    [self subscribe:EVENT_NOTIFICATION_UPDATED selector:@selector(notificationsUpdated:)];
    [self subscribe:EVENT_UNREAD_NOTIFICATIONS_CLEARED selector:@selector(notificationsUpdated:)];
    
    [self subscribe:EVENT_GO_SET_BBT_REMINDER selector:@selector(goSetBBTReminder:)];
    [self subscribe:EVENT_FULFILLMENT_PURCHASE_SUCCESSFUL selector:
            @selector(showFulfillmentSuccessfulMessage:)];
    [self subscribe:EVENT_NOTIF_GO_GLOW_FIRST selector:@selector(goGlowFirst:)];
    [self subscribe:EVENT_NOTIF_GO_REMINDER selector:@selector(goReminder:)];
    [self subscribe:EVENT_NOTIF_GO_PROMO selector:@selector(goPromo:)];
    [self subscribe:EVENT_NOTIF_GO_PERIOD selector:@selector(goPeriod:)];
    [self subscribe:EVENT_NOTIF_REFILL_BY_SCAN selector:@selector(refillByScan:)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadData];
    
    /*
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:APP_OPEN_WITH_OPTION];
    [defaults synchronize];
    */
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unsubscribeAll];
    [self.model clearUnreadNotifications];
    // we do not need reload data, becuase we will reload date in "clearUnreadNotification"
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)goSetBBTReminder:(Event *)event {
    ReminderDetailViewController *dest = nil;
    dest = (ReminderDetailViewController *)[[UIStoryboard storyboardWithName:@"reminder" bundle:nil] instantiateViewControllerWithIdentifier:@"detail"];
    dest.model = [Reminder getReminderByType:REMINDER_TYPE_SYS_BBT];
    
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:dest];
    
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)showFulfillmentSuccessfulMessage:(Event *)event {
    [[DropdownMessageController sharedInstance] postMessage:
            @"Success! Confirmation email sent!" duration:3.0f
            position:40.0f inView:self.view];
}

- (void)goGlowFirst:(Event *)event {
    [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(_goGlowFirst) userInfo:nil repeats:NO];
}

- (void)_goGlowFirst {
    TabbarController * tab = (TabbarController *)self.tabBarController;
    [tab selectFundPage];
}

- (void)goReminder:(Event *)event {
    AlertContainerViewController *mainController = (AlertContainerViewController *)self.parentViewController;
    [mainController selectRemindersTabWithAnimation:YES];
}

- (void)goPromo:(Event *)event {
    TabbarController * tab = (TabbarController *)self.tabBarController;
    [tab selectGeniusPage];
    UINavigationController * nav = (UINavigationController *)tab.selectedViewController;
    GeniusMainViewController *geniusViewController = (GeniusMainViewController *)[nav.viewControllers objectAtIndex:0];
    [geniusViewController goReferral];
}

- (void)goPeriod:(Event *)event {
    TabbarController * tab = (TabbarController *)self.tabBarController;
    [tab selectHomePage];
    
    UINavigationController * nav = (UINavigationController *)[tab.viewControllers objectAtIndex:0];
    HomeViewController * homeController = (HomeViewController * )([nav.viewControllers objectAtIndex:0]);
    [homeController gotoPeriodPage];
}

- (void)notificationsUpdated:(Event *)evt {
    [self reloadData];
    [self setUnreadCount];
}

- (void)hideNotification:(Event *)evt {
    Notification *notif = (Notification *)evt.obj;
    NSInteger index = [self.visibleNotifications indexOfObject:notif];
    if (index != NSNotFound) {
        [notif hide];
        [self.visibleNotifications removeObject:
         notif];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)setUnreadCount {
    NSUInteger count = self.model.unreadNotificationCount;
    [[self navigationController] tabBarItem].badgeValue = count == 0 ? nil : [@(count) stringValue];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.visibleNotifications count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationBodyCell *cell = (NotificationBodyCell *)[self.tableView dequeueReusableCellWithIdentifier:@"NotificationBodyCell"];
    Notification *notif = [self.visibleNotifications objectAtIndex:indexPath.row];

    cell.controller = self;
    cell.model = notif;
    if (indexPath.row == 0) {
        [cell hideDividerLine];
    } else {
        [cell showDividerLine];
    }
    return cell;
}

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [NotificationBodyCell rowHeight:[self.visibleNotifications objectAtIndex:indexPath.row]];
}

# pragma mark - Visible Notification
- (NSFetchRequest *)fetchRequest {
    if (!_fetchRequest) {
        _fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
        _fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@ and (hidden == NO || hidden == nil)", self.model.id];
        NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"timeCreated" ascending:NO];
        _fetchRequest.sortDescriptors = @[sortDesc];
    }
    return _fetchRequest;
}

- (void)reloadData {
    self.visibleNotifications = nil;
    [self.tableView reloadData];
}

- (NSArray *)visibleNotifications {
    if (!_visibleNotifications) {
        _visibleNotifications = [[self.model.managedObjectContext executeFetchRequest:self.fetchRequest error:nil] mutableCopy];
    }
    return _visibleNotifications;
}

#pragma mark - Walgreens
- (void)refillByScan:(Event *)event {
    NSDictionary * actionContext = (NSDictionary *)event.data;
    NSString * source = [actionContext objectForKey:@"source"];
    if ([source isEqualToString:@"walgreens"]) {
        [Logging log:BTN_CLK_NOTIFY_WALGREENS_REFILL];
        WalgreensScannerViewController *controller = (WalgreensScannerViewController *)[UIStoryboard walgreensScanner];
        [self presentViewController:controller animated:YES completion:nil];
    }
}
@end
