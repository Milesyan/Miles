//
//  AlertContainerViewController.m
//  emma
//
//  Created by ltebean on 15-1-4.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "AlertContainerViewController.h"
#import "NotificationViewController.h"
#import "AlertViewTransition.h"
#import "User.h"
#import "HealthProfileData.h"
#import "RemindersViewController.h"
#import "TabbarController.h"
#import "UserStatusDataManager.h"

#define TAB_NAME_NOTIFICATIONS @"Notifications"
#define TAB_NAME_APPOINTMENTS @"Appointments"
#define TAB_NAME_REMINDERS @"Reminders"

@interface AlertContainerViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSArray *pages;
@end

@implementation AlertContainerViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self subscribe:EVENT_PURPOSE_CHANGED selector:@selector(onPurposeChanged:)];

    [self.view setGradientBackground:UIColorFromRGB(0xfcfeff) toColor:UIColorFromRGB(0xe8f7ff)];
    
//    self.animator = [AlertViewTransition new];;
    [self reloadTabs];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.segmentedControl.width = self.view.width - 20;
    [Logging log:PAGE_IMP_ALERT];
}

- (void)reloadTabs
{
    [self removeAllChildViewControllers];
    
    UIViewController *notificationVC = [NotificationViewController getInstance];
    
    RemindersViewController *reminderVC = [RemindersViewController getInstance];
    reminderVC.inAppointment = NO;
    
    if ([self hasAppointment]) {
        RemindersViewController *appointmentVC = [RemindersViewController getInstance];
        appointmentVC.inAppointment = YES;
        self.pages = @[@{@"title":TAB_NAME_NOTIFICATIONS,@"vc":notificationVC},
                       @{@"title":TAB_NAME_APPOINTMENTS,@"vc":appointmentVC},
                       @{@"title":TAB_NAME_REMINDERS,@"vc":reminderVC}];
    } else {
        self.pages = @[@{@"title":TAB_NAME_NOTIFICATIONS,@"vc":notificationVC},
                       @{@"title":TAB_NAME_REMINDERS,@"vc":reminderVC}];
    }
    
    while (self.segmentedControl.numberOfSegments > 0) {
        [self.segmentedControl removeSegmentAtIndex:0 animated:NO];
    }
    
    [self.pages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *page = (NSDictionary *)obj;
        [self.segmentedControl insertSegmentWithTitle:page[@"title"] atIndex:idx animated:NO];
        [self addChildViewController:page[@"vc"]];
    }];
    
    self.segmentedControl.selectedSegmentIndex = 0;
}


- (void)selectNotificationsTabWithAnimation:(BOOL)needsAnimation
{
    [self scrollToPageWithTitle:TAB_NAME_NOTIFICATIONS animated:needsAnimation];
}

- (void)selectAppointmentsTabWithAnimation:(BOOL)needsAnimation
{
    [self scrollToPageWithTitle:TAB_NAME_APPOINTMENTS animated:needsAnimation];
}

- (void)selectRemindersTabWithAnimation:(BOOL)needsAnimation
{
    [self scrollToPageWithTitle:TAB_NAME_REMINDERS animated:needsAnimation];
}

- (void)scrollToPageWithTitle:(NSString *)title animated:(BOOL)animated
{
    int index = [self indexOfPageByTitle:title];
    if (index >=0 ) {
        [self scrollToPage:index animated:animated];
        self.segmentedControl.selectedSegmentIndex = index;
    }
}

- (int)indexOfPageByTitle:(NSString *)title
{
    for (int i = 0; i < self.pages.count; i ++) {
        NSDictionary* page = self.pages[i];
        if ([page[@"title"] isEqualToString:title]) {
            return i;
        }
    }
    return -1;
}

- (void)didScrollToPage:(int)page
{
    [super didScrollToPage:page];
    NSDictionary* p = [self.pages objectAtIndex:page];
    if (p) {
        if ([p[@"title"] isEqualToString:TAB_NAME_NOTIFICATIONS]) {
            [Logging log:PAGE_IMP_ALERT_SCROLL_TO eventData:@{@"alert_page": ALERT_PAGE_NOTIFICATION}];
        } else if ([p[@"title"] isEqualToString:TAB_NAME_APPOINTMENTS]) {
            [Logging log:PAGE_IMP_ALERT_SCROLL_TO eventData:@{@"alert_page": ALERT_PAGE_APPOINTMENT}];
        } else {
            [Logging log:PAGE_IMP_ALERT_SCROLL_TO eventData:@{@"alert_page": ALERT_PAGE_REMINDER}];
        }
    }
    self.segmentedControl.selectedSegmentIndex = page;
}

- (IBAction)changeAlertType:(UISegmentedControl *)segmentedControl
{
    NSDictionary* page = self.pages[segmentedControl.selectedSegmentIndex];
    if (page) {
        if ([page[@"title"] isEqualToString:TAB_NAME_NOTIFICATIONS]) {
            [Logging log:BTN_CLK_ALERT_SEGMENT eventData:@{@"alert_page": ALERT_PAGE_NOTIFICATION}];
        } else if ([page[@"title"] isEqualToString:TAB_NAME_APPOINTMENTS]) {
            [Logging log:BTN_CLK_ALERT_SEGMENT eventData:@{@"alert_page": ALERT_PAGE_APPOINTMENT}];
        } else {
            [Logging log:BTN_CLK_ALERT_SEGMENT eventData:@{@"alert_page": ALERT_PAGE_REMINDER}];
        }
    }
    [self scrollToPage:(int)segmentedControl.selectedSegmentIndex animated:YES];
}

- (void)onPurposeChanged:(Event *)event
{
    [self reloadTabs];
}

- (BOOL)hasAppointment {
    User * user = [User currentUser];
    if (!user) {
        return NO;
    }
    if (user.currentPurpose == AppPurposesTTCWithTreatment) {
        return YES;
    } else {
        return NO;
    }
}


@end
