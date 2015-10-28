//
//  SettingViewController.m
//  emma
//
//  Created by Eric Xu on 1/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//
#import <CoreGraphics/CoreGraphics.h>
#import "HomeViewController.h"
#import "TinyCalendarView.h"
#import "User.h"
#import "UIImage+Resize.h"
#import "DailyLogViewController.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "UIView+Emma.h"
#import "TutorialViewController.h"
#import "InvitePartnerDialog.h"
#import "Logging.h"
#import "DropdownMessageController.h"
#import "AskRateDialog.h"
#import "StartLoggingCell.h"
#import "StatusBarOverlay.h"
#import "Insight.h"
#import "BackToTodayButton.h"
#import "AnimationSequence.h"
#import "ShareDialogViewController.h"
#import "ShareController.h"
#import "Sendmail.h"
#import "Tooltip.h"
#import "NotesManager.h"
#import "NotesEntranceCell.h"
#import "NotesTableViewController.h"
#import "ImagePicker.h"
#import "WebViewController.h"
#import "ForumTutorialViewController.h"
#import "TabbarController.h"
#import "ForumTopic.h"
#import "ForumTopicDetailViewController.h"
#import "Nutrition.h"
#import "ForumAddReplyViewController.h"
#import "PeriodNavButton.h"
#import "PollItemCell.h"
#import "UserDailyPoll.h"
#import "AppDelegate.h"
#import "GLSSOService.h"
#import "StartupViewController.h"
#import "ForumHotViewController.h"
#import "CalendarCell.h"
#import "MedicalLogViewController.h"
#import "UserMedicalLog.h"
#import "FertilityTreatmentCell.h"
#import "HealthProfileData.h"
#import "HealthKitManager.h"
#import "UserDailyData+HealthKit.h"
#import "GLHealthAwarenessViewController.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "GLDynamicContentScrollView.h"
#import "GLInfiniteScrollView.h"
#import "HomeDailyView.h"
#import "DailyArticle.h"
#import "User+HomePageDailyContent.h"
#import "PeriodEditorViewController.h"
#import "HomeCardCustomizationManager.h"
#import <GLPeriodEditor/GLPeriodEditorViewController.h>
#import <GLCommunity/ForumProfileViewController.h>
#import <GLCommunity/ForumSocialUsersViewController.h>
#import "WatchDataController.h"
#import "StatusHistory.h"
#import "DailyTodo.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>

#define TAB_BUTTON_SIZE 22
#define TOOLBAR_HEIGHT 45
#define NAV_HEIGHT 44
#define GGSNAPSHOT_ALPHA 0.1
#define GGSNAPSHOT_SCALE 0.85
#define GGSNAPSHOT_CENTER_OFFSET 25
#define PULL_THRESHOLD -80

typedef enum GLHomeViewMode {
    TinyCalendarMode,
    FullCalendarMode,
} GLHomeViewMode;

@interface HomeViewController () < UIGestureRecognizerDelegate, ImagePickerDelegate,GLInfiniteScrollViewDelegate,GLInfiniteScrollViewDataSource,GLDynamicContentScrollViewDelegate,HomeDailyViewDelegate> {
    DateRelationOfToday dateRelation;
    CGPoint ggHomeSnapshotOriginCenter;
    UIViewController * periodViewController;
}

@property (weak, nonatomic) IBOutlet GLInfiniteScrollView *infiniteScrollView;
@property (nonatomic, strong) IBOutlet CalendarCell *calendarCell;
@property (nonatomic, weak) IBOutlet UIView *blurringCoverView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *blurringCoverViewBottomConstraint;

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic) BOOL selectedDateIsToday;

@property (nonatomic, strong) TutorialViewController *tutorialViewController;
@property (nonatomic, strong) UITapGestureRecognizer *navTapRecon;

// In tutorial or days after tomorrow, the homeDailyView is disabled
@property (nonatomic) BOOL verticalScrollDisabled;

@property (readonly) User *user;
@property (nonatomic) BOOL needPopupShare;

- (IBAction)clickPeriodButton;

@property (nonatomic) GLHomeViewMode mode;
@property (nonatomic) BOOL loaded;
@property (nonatomic,strong) NSDate *dateAtIndexZero;
@end

@implementation HomeViewController

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        self = [super initWithNibName:@"HomeViewController" bundle:nil];
        [self internalInitializeTitleView];
    }
    return self;
}

# pragma mark - life cycle related

- (void)viewDidLoad
{
    [super viewDidLoad];
    [HomeCardCustomizationManager sharedInstance];
    
    self.selectedDate = [NSDate date];
    
    self.edgesForExtendedLayout = UIRectEdgeBottom;
    
    
    GLLog(@"debug: viewDidLoad");
    self.infiniteScrollView.dataSource = self;
    self.infiniteScrollView.delegate = self;
    self.infiniteScrollView.pagingEnabled = YES;
    
    self.navTapRecon = [[UITapGestureRecognizer alloc]
                        initWithTarget:self action:@selector(navigationBarTap:)];
    self.navTapRecon.numberOfTapsRequired = 1;
    self.navTapRecon.delaysTouchesBegan = YES;
    [self.navigationController.navigationBar addGestureRecognizer:self.navTapRecon];
    
    [self updateTitle:self.selectedDate];
    
    @weakify(self);
    [self subscribe:CALENDAR_EVENT_DATE_CHANGED selector:@selector(calendarDateChanged:)];
    [self subscribe:CALENDAR_EVENT_MONTH_CHANGING selector:@selector(calendarMonthChanged:)];
    [self subscribe:EVENT_PREDICTION_UPDATE selector:@selector(predictionUpdated:)];
    
    [self subscribe:EVENT_USER_SYNC_COMPLETED selector:@selector(updateBySyncComplete:)];
    [self subscribe:EVENT_USER_STATUS_HISTORY_CHANGED selector:@selector(userStatusHistoryChanged)];

    [self subscribe:EVENT_USERDAILYDATAORTODO_PULLED_FROM_SERVER selector:@selector(dailyDataOrTodoPulledFromServer:)];
    [self subscribe:EVENT_USERDAILYDATA_PULLED_FROM_HEALTH_KIT handler:^(Event *event) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDate *date = (NSDate *)event.data;
            HomeDailyView *homeDailyView = [self homeDailyViewByDate:date];
            [homeDailyView reloadTableView];
            [homeDailyView reloadLogSummary];
        });
    }];
    [self subscribe:EVENT_USER_LOGGED_OUT selector:@selector(onLogout:)];
    
    [self subscribe:EVENT_GO_TO_LOG_REQUESTED handler:^(Event *event) {
        @strongify(self);
        [self performSegueWithIdentifier:@"startLogging" sender:self];
    }];
    
    //Removed subscription of EVENT_PURPOSE_CHANGED, Tabbarcontroller will call this method.
    //    [self subscribe:EVENT_PURPOSE_CHANGED selector:@selector(onPurposeChange:)];
    [self subscribe:EVENT_USER_REMOVED_FROM_SERVER selector:@selector(forceUserLogout:)];
    [self subscribe:EVENT_TOKEN_EXPIRED selector:@selector(forceUserLogoutBecauseOfToken:)];
    [self subscribe:EVENT_USER_MFP_UPDATED selector:@selector(mfpUpdated)];
    [self subscribe:EVENT_PARTNER_INVITED selector:@selector(onPartnerUpdated:)];
    [self subscribe:EVENT_PARTNER_REMOVED selector:@selector(onPartnerUpdated:)];
    [self subscribe:EVENT_HOME_GO_TO_TOPIC selector:@selector(goToForumTopic:)];
    [self subscribe:EVENT_FORUM_ADD_REPLY_SUCCESS selector:@selector(onForumReplyAdded:)];
    
    [self subscribe:EVENT_DAILY_POLL_LOADED selector:@selector(onDailyPollLoaded:)];
    [self subscribe:EVENT_INSIGHT_UPDATED selector:@selector(insightsUpdated)];
    [self subscribe:EVENT_HOME_CARD_CUSTOMIZATION_UPDATED selector:@selector(homeCardCustomizationUpdated)];

    
    [self performPopups];
    
    [Reminder updateAllReminders];
    
    [self updateCalendarRange];
    
    BackToTodayButton *backButton = (BackToTodayButton *) self.navigationItem.leftBarButtonItem.customView;
    [backButton performSelector:@selector(internalInit)];
    
    PeriodNavButton *periodButton = (PeriodNavButton *) self.navigationItem.rightBarButtonItem.customView;
    [periodButton performSelector:@selector(internalInit)];
    
    [[GLSSOService sharedInstance] updateService];
    
    // calendar view
    CGRect viewFrame = self.calendarCell.frame;
    viewFrame.size.width = SCREEN_WIDTH;
    self.calendarCell.frame = viewFrame;
    
    // gradient cover view
    CAGradientLayer *gradient = [CAGradientLayer layer];
    CGRect frame = self.blurringCoverView.bounds;
    frame.size.width = SCREEN_WIDTH;
    gradient.frame = frame;
    
    UIColor *color = UIColorFromRGB(0xF7F7FD);
    gradient.colors = @[(id)[[color colorWithAlphaComponent:0] CGColor], (id)color.CGColor];
    [self.blurringCoverView.layer insertSublayer:gradient atIndex:0];
    
    UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePanGestureInCalendarCell:)];
    [self.calendarCell addGestureRecognizer:panGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0xf7f7f7);
    self.navigationController.navigationBar.translucent = YES;
    
    self.navTapRecon.enabled = YES;
    
    [self.calendarCell layoutTinyCalendar];
    [self.calendarCell startTinyCalendarCenterButtonTipsRotation];
    [self.calendarCell.tinyCalendar updateButtonsForPrediction];
    [self.calendarCell.calendar updateCheckmarks];
    [self.calendarCell.calendar updateDateColors];
    
    if (!self.loaded) {
        self.calendarCell.selectedDate = self.selectedDate;
        [self.calendarCell setupViews];
        
        self.dateAtIndexZero = [NSDate date];
        
        self.infiniteScrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
        [self.infiniteScrollView reloadData];
        [[self currentHomeDailyView] showTriangleViewWithAnimation:NO];
        
        [self.view addSubview:self.calendarCell];
        [self.view bringSubviewToFront:self.blurringCoverView];
        [self.view bringSubviewToFront:self.infiniteScrollView];
        self.loaded = YES;
    }
    
    if (self.user.canEditPeriod) {
        [self setPeriodEditButtonEnabled:YES];
    } else {
        [self setPeriodEditButtonEnabled:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self publish:EVENT_HOME_VIEW_APPEAR];
    // log
    [CrashReport leaveBreadcrumb:@"HomeViewController"];
    [Logging log:PAGE_IMP_HOME];
    self.user.autoSave = YES;

    //if(YES){
    if (!self.tutorialViewController && !self.user.tutorialCompleted && !EMMA_DISABLE_TUTORIAL) {
        [self beginTutorial];
    } else {
        NSNumber * appOpenOption = (NSNumber *)[Utils getDefaultsForKey:APP_OPEN_WITH_OPTION];
        if (appOpenOption) {
            AppOpenData * openData = [[AppOpenData alloc] init];
            openData.openType = appOpenOption;
            NSDictionary * extData = [Utils getDefaultsForKey:APP_OPEN_EXT_DATA];
            if (extData) {
                openData.data1 = [extData objectForKey:@"data_1"];
                openData.data2 = [extData objectForKey:@"data_2"];
                openData.url   = [extData objectForKey:@"url"];
            }
            [Utils setDefaultsForKey:APP_OPEN_WITH_OPTION withValue:nil];
            [Utils setDefaultsForKey:APP_OPEN_EXT_DATA withValue:nil];
            
            [self checkJumpPage:openData];
        }
    }
    
    [self subscribe:EVENT_APP_RECEIVE_NOTIFICATION selector:@selector(viewAppearByReceiveNotification:)];
    
    [self refreshHomeDailyViewWithDate:self.selectedDate];
    // pull daily todo info
    [self pullDailyContent];

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.navTapRecon.enabled = NO;
    [self unsubscribe:EVENT_APP_RECEIVE_NOTIFICATION];
    [self unsubscribe:EVENT_APP_IDLE];
    [self.calendarCell stopTinyCalendarCenterButtonTipsRotation];
}

#pragma mark - pull daily content

- (void)pullDailyContent
{
    [self pullDailyContentForceSendCall:NO forceRegenerate:NO];
}

- (void)pullDailyContentForceSendCall:(BOOL)forceSendCall forceRegenerate:(BOOL)forceRegenerate
{
    if ([self.selectedDate isFutureDay]) {
        return;
    }
    [self.user fetchDailyContentOnDate:self.selectedDate forceSendCall:forceSendCall forceRenegerate:forceRegenerate completionHandler:^(BOOL success, NSDate *date) {
        // in case user has logged out
        if (!self.user) {
            return;
        }
        if (success) {
            HomeDailyView *homeDailyView = [self homeDailyViewByDate:date];
            [homeDailyView reloadDailyArticle];
            [homeDailyView reloadDailyTodo];
            [homeDailyView reloadTableView];
        }
    }];
}

# pragma mark - gesture handler
- (void)handlePanGestureInCalendarCell:(UIPanGestureRecognizer *)gesture
{
    // handle pull down in calendar cell
    if  (self.verticalScrollDisabled){
        return;
    }
    CGFloat translationY = [gesture translationInView:self.view].y;
    
    if (translationY <=0 ) {
        return;
    }
    
    GLDynamicContentScrollView* currentScrollView = [self currentHomeDailyScrollView];
    CGPoint contentOffset = [currentScrollView contentOffset];
    
    if (contentOffset.y > 0) {
        return;
    }
    
    if (self.calendarCell.isSwitchingCalendar) {
        gesture.enabled = NO;
        gesture.enabled = YES;
        return;
    }
    
    // pull down scroll view simultaneously
    contentOffset.y = -translationY/2;
    [currentScrollView setContentOffset:contentOffset animated:NO];
    
    // if not pull down enough distance, animate calendar cell back
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [currentScrollView setContentOffset:CGPointZero animated:YES];
        if (contentOffset.y > PULL_THRESHOLD) {
            [self.calendarCell.tinyCalendar finishPulling];
        }
    }
}


#pragma mark - LTInfiniteScrollViewDataSource

- (int)totalViewCount
{
    return 999;
}

- (int)visibleViewCount
{
    return 1;
}

- (UIView *)viewAtIndex:(int)index reusingView:(UIView *)reusingView;
{
    GLDynamicContentScrollView *scrollView;
    if (!reusingView) {
        scrollView = [[GLDynamicContentScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, CGRectGetHeight(self.view.bounds))];
        scrollView.delegate = self;
        
        HomeDailyView *homeDailyView = [[HomeDailyView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0)];
        homeDailyView.delegate = self;
        homeDailyView.homeViewController = self;
        homeDailyView.parentScrollView = scrollView;
        scrollView.contentView = homeDailyView;
    } else {
        scrollView = (GLDynamicContentScrollView *)reusingView;
    }
    [scrollView setContentViewTop:[self currentCalendarHeight] animated:NO];
    HomeDailyView *homeDailyView = (HomeDailyView *)scrollView.contentView;
    homeDailyView.selectedDate = [Utils dateByAddingDays:index toDate:self.dateAtIndexZero];
    return scrollView;
}

- (BOOL)scrollView:(GLInfiniteScrollView *)scrollView shouldHandleEventWithBeginPoint:(CGPoint)point;
{
    // if the tap begin in top area, let calender cell handle the gesture;
    GLDynamicContentScrollView* view = [self currentHomeDailyScrollView];
    CGPoint contentOffSet = view.scrollView.contentOffset;
    if (point.y < ([self currentCalendarHeight] - contentOffSet.y)) {
        return NO;
    }
    return YES;
}

#pragma mark - LTInfiniteScrollViewDelegate

- (void)updateView:(UIView *)view withDistanceToCenter:(CGFloat)distance scrollDirection:(ScrollDirection)direction
{
    CGFloat percent = distance / CGRectGetWidth(self.view.bounds);
    // out of screen
    if (fabs(percent)==1) {
        // scroll back
        GLDynamicContentScrollView* scrollView = (GLDynamicContentScrollView*)view;
        [scrollView setContentOffset:CGPointZero animated:NO];
        
        // set triangel view back
        HomeDailyView* homeDailyView = (HomeDailyView*) scrollView.contentView;
        [homeDailyView updateTriangleViewTranslationY:0];
        [homeDailyView hideTriangleViewWithAnimation:NO];
    }
}

- (void)scrollViewDidBeginScroll:(GLInfiniteScrollView *)scrollView
{
    if (self.mode == TinyCalendarMode) {
        [[self currentHomeDailyView] hideTriangleViewWithAnimation:YES];
    }
    [self updateCalendarAlphaTo:1 animated:YES];
}

- (void)scrollViewDidEndScroll:(GLInfiniteScrollView *)scrollView
{
    HomeDailyView *homeDailyView = [self currentHomeDailyView];
    NSDate *currentDate = homeDailyView.selectedDate;
    self.selectedDate = currentDate;
    [self.calendarCell moveToDate:currentDate animated:YES];
    [self updateTitle:currentDate];
    
    if (self.mode == TinyCalendarMode) {
        [homeDailyView showTriangleViewWithAnimation:YES];
    }
    // update calendar background alpha
    GLDynamicContentScrollView *currentDailyScrollView = [self currentHomeDailyScrollView];
    CGFloat progress = 1 - fabs(currentDailyScrollView.contentOffset.y)/[self currentCalendarHeight];
    [self updateCalendarAlphaTo:progress animated:YES];
    
    // pull todo
    [self pullDailyContent];
}


#pragma mark - LTDynamicContentScrollViewDelegate

- (void)scrollView:(GLDynamicContentScrollView*)scrollView internalScrollViewDidScroll:(UIScrollView *)internalScrollView
{
    if ([self.calendarCell isSwitchingCalendar]) {
        return;
    }
    
    CGFloat offsetY = internalScrollView.contentOffset.y;
    
    HomeDailyView *homeDailyView = [self currentHomeDailyView];
    
    // prevent scrolling up when homeDailyView's height is small
    CGFloat height = [self heightThatFitsForHomeDailyView:homeDailyView];
    if (offsetY > 0 && height == [self minHeightForhomeDailyView]) {
        [internalScrollView setContentOffset:CGPointZero animated:NO];
        return;
    }
    
    // update tutorial view when scrolling
    if (offsetY <= 0 && self.tutorialViewController) {
        [self.tutorialViewController pullDownWithDistance:fabs(offsetY) maxValue:abs(PULL_THRESHOLD)];
    }
    
    if (offsetY <= 0) {
        // when scroll down, pull down calendarCell together
        [self.calendarCell pullDownWithDistance:fabs(offsetY) maxValue:abs(PULL_THRESHOLD)];
        [self.tutorialViewController hideAllGestures];
    } else {
        // when scroll up, make calendar view transparent
        CGFloat progress = 1 - fabs(offsetY) / [self currentCalendarHeight];
        [self updateCalendarAlphaTo:progress animated:NO];
    }
    
    // update triangle position
    if (self.mode == TinyCalendarMode) {
        [homeDailyView updateTriangleViewTranslationY:offsetY];
    }
    
    // check calendar switch
    if (offsetY < PULL_THRESHOLD) {
        if (self.mode == FullCalendarMode) {
            [self switchToTinyCalendarMode];
        } else {
            [self switchToFullCalendarMode];
        }
    }
}

- (void)scrollView:(GLDynamicContentScrollView *)scrollView internalScrollViewDidEndDragging:(UIScrollView *)internalScrollView
{
    // if not pull with enough distance, animate calendar cell back
    CGFloat offsetY = internalScrollView.contentOffset.y;
    
    if (offsetY > PULL_THRESHOLD) {
        [self.calendarCell.tinyCalendar finishPulling];
    }
}

- (void)scrollView:(GLDynamicContentScrollView *)scrollView internalScrollViewDidEndDecelerating:(UIScrollView *)internalScrollView
{
    CGFloat offsetY = internalScrollView.contentOffset.y;
    // update calendar view alpha
    CGFloat progress = 1 - fabs(offsetY) / [self currentCalendarHeight];
    progress = progress < 0 ? 0 : MIN(1, progress);
    [self updateCalendarAlphaTo:progress animated:YES];
}

# pragma mark - HomeDailyViewDelegate

- (void)homeDailyView:(HomeDailyView *)homeDailyView needsUpdateHeightTo:(CGFloat)height
{
    GLDynamicContentScrollView *scrollView = homeDailyView.parentScrollView;
    [scrollView setContentViewHeight:[self heightThatFitsForHomeDailyView:homeDailyView]];
}

- (void)homeDailyView:(HomeDailyView*)homeDailyView needsPerformSegueWithIdentifier:(NSString *)identifier
{
    [self performSegueWithIdentifier:identifier sender:nil];
}


#pragma mark - mode switch

- (void)switchToFullCalendarMode
{
    [self setMode:FullCalendarMode];
    CGRect frame = self.calendarCell.frame;
    frame.size.width = CGRectGetWidth(self.view.bounds);
    frame.size.height = CALENDAR_HEIGHT;
    self.calendarCell.frame = frame;
    [self.calendarCell switchToFullCalendarView:YES];
    [[self currentHomeDailyView] hideTriangleViewWithAnimation:YES];
    [self updateCalendarAlphaTo:1 animated:YES];
}

- (void)switchToTinyCalendarMode
{
    [self setMode:TinyCalendarMode];
    CGRect frame = self.calendarCell.frame;
    frame.size.width = CGRectGetWidth(self.view.bounds);
    frame.size.height = TINY_CAL_HEIGHT;
    self.calendarCell.frame = frame;
    [self.calendarCell switchToTinyCalendarView:YES];
    [[self currentHomeDailyView] showTriangleViewWithAnimation:NO];
    [self updateCalendarAlphaTo:1 animated:YES];
}

- (void)setMode:(GLHomeViewMode)mode
{
    UIView *currentScrollView = [self currentHomeDailyScrollView];
    _mode = mode;
    NSArray *allViews = [self.infiniteScrollView allViews];
    
    // just animate current view
    for (GLDynamicContentScrollView *view in allViews) {
        BOOL animated = NO;
        if (currentScrollView == view) {
            animated = YES;
        }
        [view setContentViewTop:[self currentCalendarHeight] animated:animated];
    }
}

# pragma mark - UI related helper
- (void)updateCalendarAlphaTo:(CGFloat)alpha animated:(BOOL)animated;
{
    if (alpha > 1) {
        alpha = 1;
    }
    if (alpha < 0) {
        alpha = 0;
    }
    [self.calendarCell updateAlphaTo:alpha animated:animated];
    if (alpha == 0) {
        self.blurringCoverView.hidden = YES;
    } else {
        self.blurringCoverView.hidden = NO;
    }
}

// always use this method to scroll to certain date
- (void)scrollToDate:(NSDate *)date
{
    NSDate *currentDate = [self currentHomeDailyView].selectedDate;
    
    if ([Utils date:date isSameDayAsDate:currentDate]) {
        return;
    }
    
    self.selectedDate = date;
    
    NSInteger days = [self daysBetweenDate:currentDate andDate:date];
    
    // if delta days > 1, make daily scroll view reload the data
    if (labs(days) > 1) {
        self.dateAtIndexZero = date;
        [self.infiniteScrollView reloadData];
        [self updateCalendarAlphaTo:1 animated:NO];
        [self.calendarCell moveToDate:date animated:YES];
        [self pullDailyContent];
    } else {
        NSInteger deltaDays = [self daysBetweenDate:self.dateAtIndexZero andDate:date];
        [self.infiniteScrollView scrollToIndex:(int)deltaDays animated:NO];
        [self.calendarCell moveToDate:date animated:YES];
    }
    if (self.mode == TinyCalendarMode) {
        [[self currentHomeDailyView]showTriangleViewWithAnimation:NO];
    }
    [self updateTitle:self.selectedDate];
}

- (void)refreshAllHomeDailyView
{
    NSArray* dailyScrollViews = [self.infiniteScrollView allViews];
    for (GLDynamicContentScrollView *scrollView in dailyScrollViews) {
        HomeDailyView *homeDailyView = (HomeDailyView *)scrollView.contentView;
        NSDate *selectedDate = homeDailyView.selectedDate;
        homeDailyView.selectedDate = selectedDate;
    }
}

- (void)refreshHomeDailyViewWithDate:(NSDate *)date
{
    HomeDailyView *homeDailyView = [self homeDailyViewByDate:date];
    homeDailyView.selectedDate = homeDailyView.selectedDate;
}

- (void)updateCalendarRange {
    NSDate *earliest = [UserDailyData getEarliestDateForUser:[User userOwnsPeriodInfo]];
    if (earliest) {
        [self.calendarCell.calendar updateBeginDate:earliest];
        [self.calendarCell.tinyCalendar updateBeginDate:earliest];
        [Utils setDefaultsForKey:USER_DEFAULTS_MIN_PRED_DATE withValue:earliest];
    }
}

- (void)updateTitle:(NSDate *)date {
    UILabel *dateLabel = (UILabel*)self.navigationItem.titleView.subviews[0];
    dateLabel.text = [date toReadableDate];
    UILabel *cdLabel = (UILabel*)self.navigationItem.titleView.subviews[1];

    NSInteger cdIndex = [self cycleDays];
    cdLabel.text = cdIndex < 0 ? @"N/A" : [NSString stringWithFormat:@"Cycle Day %ld", (long)cdIndex];

    self.navigationItem.leftBarButtonItem.customView.hidden = self.selectedDateIsToday;
}

- (void)internalInitializeTitleView {
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 172, 30)];
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 172, 18)];
    dateLabel.textAlignment = NSTextAlignmentCenter;
    dateLabel.font = [UIFont fontWithName:GLOW_FONT_MEDIUM size:18];
    dateLabel.textColor = [UIColor blackColor];
    dateLabel.backgroundColor = [UIColor clearColor];
    [titleView addSubview:dateLabel];
    UILabel *cdLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 18, 172, 12)];
    cdLabel.textAlignment = NSTextAlignmentCenter;
    cdLabel.font = [UIFont fontWithName:GLOW_FONT_LIGHT size:12];
    cdLabel.textColor = [UIColor blackColor];
    cdLabel.backgroundColor = [UIColor clearColor];
    [titleView addSubview:cdLabel];
    [self.navigationItem setTitleView:titleView];
}

- (void)setPeriodEditButtonEnabled:(BOOL)enabled
{
    if (enabled) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.rightBarButtonItem.customView.hidden = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.customView.hidden = YES;
    }
}

# pragma mark - getters

- (User *)user {
    return [User currentUser];
}

- (HomeDailyView *)currentHomeDailyView
{
    return (HomeDailyView *)[self currentHomeDailyScrollView].contentView;
}

- (GLDynamicContentScrollView *)currentHomeDailyScrollView
{
    return (GLDynamicContentScrollView *) [self.infiniteScrollView viewAtIndex:self.infiniteScrollView.currentIndex];
}

- (CGFloat)heightThatFitsForHomeDailyView:(HomeDailyView *)homeDailyView
{
    CGFloat minHeight = [self minHeightForhomeDailyView];;
    CGFloat height = [homeDailyView contentHeight] + self.tabBarController.tabBar.size.height;
    return MAX(minHeight,height);
}

- (CGFloat)minHeightForhomeDailyView
{
    return CGRectGetHeight(self.view.bounds) - [self currentCalendarHeight] + abs(PULL_THRESHOLD) - (self.tabBarController.tabBar.size.height);
}

- (CGFloat)currentCalendarHeight
{
    return self.mode == TinyCalendarMode? TINY_CAL_HEIGHT : CALENDAR_HEIGHT;
}

- (GLDynamicContentScrollView *)homeDailyScrollViewByDate:(NSDate *)date
{
    NSArray *dailyScrollViews = [self.infiniteScrollView allViews];
    for (GLDynamicContentScrollView *scrollView in dailyScrollViews) {
        HomeDailyView *homeDailyView = (HomeDailyView *)scrollView.contentView;
        NSDate *selectedDate = homeDailyView.selectedDate;
        if ([Utils date:selectedDate isSameDayAsDate:date]) {
            return scrollView;
        }
    }
    return nil;
}

- (HomeDailyView *)homeDailyViewByDate:(NSDate *)date
{
    GLDynamicContentScrollView *scrollView = [self homeDailyScrollViewByDate:date];
    if (scrollView) {
        return (HomeDailyView *)scrollView.contentView;
    }
    return nil;
}

- (NSInteger)cycleDays {
    User *user = [User userOwnsPeriodInfo];
    if (!user || !user.prediction) {
        return -1;
    }
    NSString *selectedDateLabel = [Utils dailyDataDateLabel:self.selectedDate];
    NSInteger pbIndex = [[Utils findFirstPbIndexBefore:selectedDateLabel inPrediction:user.prediction] integerValue];
    if (9999 == pbIndex || pbIndex < 0) {
        return -1;
    }
    return [Utils daysBeforeDateLabel:selectedDateLabel sinceDateLabel:user.prediction[pbIndex][@"pb"]] + 1;
}

# pragma mark - event handler

- (void)calendarDateChanged:(Event *)event
{
    NSDate *date = (NSDate *)event.data;
    if (!date) {
        return;
    }
    if ([Utils date:date isSameDayAsDate:self.selectedDate]) {
        return;
    }
    if ([[event obj] isKindOfClass:[TinyCalendarView class]]) {
        [self.calendarCell.calendar moveCalendarToDate:date animated:NO];
    }
    else {
        [self.calendarCell.tinyCalendar moveToDate:date animated:NO];
    }
    [self scrollToDate:date];
}

- (void)mfpUpdated {
    [self.calendarCell.tinyCalendar updateButtonsForPrediction];
}

- (void)calendarMonthChanged:(Event *)event {
    NSDate *date = (NSDate *)event.data;
    [self updateTitle:date];
}

- (void)predictionUpdated:(Event *)event {
    GLLog(@"get PREDICTION_UPDATE event");
    if (event.data) {
        [self.calendarCell.calendar updateForPredictionChangeInMonth:(NSDate *)event.data];
    } else {
        [self.calendarCell.calendar updateForPredictionChange];
    }
    [self.calendarCell.tinyCalendar updateButtonsForPrediction];
    // update reminders
    [Reminder updatePredictionReminders];
    GLLog(@"get PREDICTION_UPDATE event done");
    [self updateTitle:self.selectedDate];
    [self updateCalendarRange];
    
    [[self currentHomeDailyView] reloadLogSummary];
    
    [[WatchDataController sharedInstance] passWatchData];
}



- (void)dailyDataOrTodoPulledFromServer:(Event *)event {
    [self.calendarCell.calendar updateCheckmarks];
}

- (void)onPartnerUpdated:(Event *)event {
    GLLog(@"Partner updated");
    [self refreshAllHomeDailyView];
}

- (void)onLogout:(Event *)event {
    [self unsubscribeAll];
    periodViewController = nil;
}

- (void)onPurposeChange:(Event *)event {
    [self refreshAllHomeDailyView];
    
    [self.calendarCell.tinyCalendar updateButtonsForPrediction];
    [self.calendarCell.calendar updateForPredictionChange];
    [self.calendarCell backgroundImageChanged:nil];
    
    self.navTapRecon = [[UITapGestureRecognizer alloc]
                        initWithTarget:self action:@selector(navigationBarTap:)];
    self.navTapRecon.numberOfTapsRequired = 1;
    self.navTapRecon.delaysTouchesBegan = YES;
    [self.navigationController.navigationBar addGestureRecognizer:self.navTapRecon];
    
}

- (void)forceUserLogout:(Event *)event {
    [self.user logout];
    [self unsubscribeAll];
    periodViewController = nil;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry!"
                                                        message:@"Your account does not exist."
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
    [alertView show];
    
    UIViewController *root = [self.infiniteScrollView window].rootViewController;
    [root dismissViewControllerAnimated:YES completion:nil];
}

- (void)forceUserLogoutBecauseOfToken:(Event *)event {
    [[User currentUser] logout];
    [self unsubscribeAll];
    periodViewController = nil;
    
    UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:NSLocalizedString(@"Sorry", nil) message:NSLocalizedString(@"You haven't open this app for too long. Please login again.", nil)];
    [alertView bk_addButtonWithTitle:NSLocalizedString(@"OK", nil) handler:^()
     {
         UIViewController *root = [self.infiniteScrollView window].rootViewController;
         [root dismissViewControllerAnimated:YES completion:nil];
     }];
    
    [alertView show];
}


- (void)updateBySyncComplete:(Event *) event {
    [self refreshAllHomeDailyView];
    [self.calendarCell.tinyCalendar updateButtonsForPrediction];
    [self.calendarCell.calendar updateDateColors];
    if (self.needPopupShare) {
        self.needPopupShare = NO;
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_showShareDialog) userInfo:nil repeats:NO];
    }
}

- (void)goToForumTopic:(Event *)event {
    ForumTopic *topic = [[ForumTopic alloc] init];
    NSNumber * topicID = (NSNumber * )event.data;
    topic.identifier = [topicID unsignedLongLongValue];
    
    ForumTopicDetailViewController *topicViewController = [ForumTopicDetailViewController viewController];
    topicViewController.topic = topic;
    UINavigationController *topicNavController = [[UINavigationController alloc] initWithRootViewController:topicViewController];
    [self.navigationController presentViewController:topicNavController animated:YES completion:nil];
}

- (void)onForumReplyAdded:(Event *)event {
    ForumTopic *topic = (ForumTopic *)event.data;
    
    NSArray *todos = [DailyTodo todosByTopicId:topic.identifier forUser:[User currentUser]];
    if (todos && todos.count > 0) {
        for (DailyTodo *todo in todos) {
            todo.comments += 1;
        }
        [self refreshHomeDailyViewWithDate:self.selectedDate];
        return;
    }
    
    DailyArticle *article = [DailyArticle articleByTopicId:topic.identifier forUser:self.user];
    if (article) {
        article.comments +=1;
        [article save];
        [self refreshHomeDailyViewWithDate:self.selectedDate];
    }
}

- (void)onDailyPollLoaded:(Event *)event
{
    NSString * dateStr = (NSString *)event.data;
    NSDate * date = [Utils dateWithDateLabel:dateStr];
    [[self homeDailyViewByDate:date] reloadTableView];
}

- (void)insightsUpdated {
    HomeDailyView* homeDailyView = [self currentHomeDailyView];
    [[homeDailyView startLoggingCell] updateInsights:[self.selectedDate toDateLabel]];
    [homeDailyView reloadTableView];
    
    if ([TabbarController getInstance:self].selectedIndex != 0) {
        return;
    }
    if (self.presentedViewController) {
        return;
    }
    if (self.navigationController.visibleViewController != self) {
        return;
    }
    [[homeDailyView startLoggingCell] popupInsights];
}

- (void)viewAppearByReceiveNotification:(Event *)event {
    NSDictionary * dict = (NSDictionary *)event.data;
    GLLog(@"did received notification: %@", dict);
    
    AppOpenData * openData = [[AppOpenData alloc] init];
    openData.openType = [dict objectForKey:@"opType"];
    openData.data1    = [dict objectForKey:@"data_1"];
    openData.data2    = [dict objectForKey:@"data_2"];
    openData.url      = [dict objectForKey:@"url"];
    
    if (openData.openType) {
        [self checkJumpPage:openData];
    }
}

- (void)homeCardCustomizationUpdated
{
    NSArray* dailyScrollViews = [self.infiniteScrollView allViews];
    for (GLDynamicContentScrollView *scrollView in dailyScrollViews) {
        HomeDailyView *homeDailyView = (HomeDailyView *)scrollView.contentView;
        [homeDailyView reloadTableView];
    }

    GLDynamicContentScrollView *currentDailyScrollView = [self currentHomeDailyScrollView];
    CGFloat progress = 1 - fabs(currentDailyScrollView.contentOffset.y) / [self currentCalendarHeight];
    [self updateCalendarAlphaTo:progress animated:NO];
}

- (void)userStatusHistoryChanged
{
    NSArray* dailyScrollViews = [self.infiniteScrollView allViews];
    for (GLDynamicContentScrollView *scrollView in dailyScrollViews) {
        HomeDailyView *homeDailyView = (HomeDailyView *)scrollView.contentView;
        [homeDailyView reloadTableView];
    }
    [self refreshHomeDailyViewWithDate:self.selectedDate];

}

#pragma mark - tutorial

- (void)beginTutorial {
    // subscribe tutorial events
    [self switchToTinyCalendarMode];
    [self updateCalendarAlphaTo:1 animated:NO];
    
    self.verticalScrollDisabled = YES;
    self.infiniteScrollView.userInteractionEnabled = NO;

    self.calendarCell.backgroundButton.hidden = YES;
    
    @weakify(self)
    [self subscribeOnce:EVENT_TUTORIAL_ENTER_STEP1 handler:^(Event *evt) {
        @strongify(self)
        self.navigationItem.leftBarButtonItem.customView.hidden = YES;
        [self setPeriodEditButtonEnabled:NO];
        self.navTapRecon.enabled = NO;
        //[self reloadTableWithChangeEnable:NO];
        [self currentHomeDailyScrollView].scrollEnabled = NO;
     }];
    [self subscribeOnce:EVENT_TUTORIAL_ENTER_STEP2 handler:^(Event *evt) {
        @strongify(self)
        self.verticalScrollDisabled = NO;
    }];
    [self subscribeOnce:EVENT_TUTORIAL_ENTER_STEP3 handler:^(Event *evt) {
        @strongify(self)
        self.verticalScrollDisabled = NO;
    }];
    [self subscribeOnce:EVENT_HOME_GOTO_TODAY handler:^(Event *evt) {
        @strongify(self)
        [self gotoToday:YES];
    }];
    [self subscribeOnce:EVENT_TUTORIAL_START_LOGGING handler:^(Event *evt) {
        @strongify(self)
        self.infiniteScrollView.userInteractionEnabled = YES;
        self.infiniteScrollView.scrollEnabled = YES;
        self.verticalScrollDisabled = NO;

        if (self.user.settings.currentStatus == AppPurposesTTCWithTreatment) {
            [self performSegueWithIdentifier:@"MedicalLogSegueIdentifier" sender:self];
        }
        else {
            [self performSegueWithIdentifier:@"startLogging" sender:self from:self];
        }

    }];
    [self subscribeOnce:EVENT_TUTORIAL_COMPLETED handler:^(Event *evt) {
        @strongify(self)
        GLLog(@"tutorial completed");
        self.infiniteScrollView.userInteractionEnabled = YES;
        self.infiniteScrollView.scrollEnabled = YES;
        self.verticalScrollDisabled = NO;

        self.calendarCell.backgroundButton.hidden = NO;
        
        if (self.user.canEditPeriod) {
            [self setPeriodEditButtonEnabled:YES];
        }

        self.navTapRecon.enabled = YES;

        [[DropdownMessageController sharedInstance] postMessage:@"Check out interesting health tips below!"
                                                       duration:2.5
                                                       position:20
                                                         inView:self.view];
        [self publish:EVENT_SHOW_COMMUNITY_POPUP data:@(5.0)];
        [self.user completeTutorial];
        [self.tutorialViewController.view removeFromSuperview];
        self.tutorialViewController = nil;
        self.tabBarController.tabBar.userInteractionEnabled = YES;
        [self currentHomeDailyView].selectedDate = self.selectedDate;
        
        // first time pull todo info
        [self pullDailyContent];
        [self showSignupWarningDialogIfNecessary];
    }];
    
    // show tutorial interface.
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    UIView *navView = self.tabBarController.view;
    self.tutorialViewController = [[TutorialViewController alloc] init];
    [navView addSubview:self.tutorialViewController.view];
    self.tutorialViewController.view.frame = navView.bounds;
    [self.tutorialViewController start];
    [self publish:EVENT_HIDE_COMMUNITY_POPUP];
}

# pragma mark - popups
- (void)showSignupWarningDialogIfNecessary
{
    NSString *warningType = [Utils getDefaultsForKey:USER_DEFAULTS_SIGN_UP_WARNING_TYPE_KEY];
    if ([warningType isEqualToString:SIGN_UP_WARNING_TYPE_MALE_INVITED_BY_MALE]) {
        [UIAlertView bk_showAlertViewWithTitle:@"Warning" message:@"Looks like both you and your partner signed up as males. Unfortunately, Glow does not yet support male-male partners, so we cannot connect your accounts." cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        }];

    }
    else if ([warningType isEqualToString:SIGN_UP_WARNING_TYPE_FEMALE_PARTNER]) {
        [UIAlertView bk_showAlertViewWithTitle:@"Warning" message:@"Welcome to Glow! Glow partners share a single period calendar. So if you want to see your own periods, and not your partner’s, please disconnect from your partner within your app settings." cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        }];
    }
    [Utils setDefaultsForKey:USER_DEFAULTS_SIGN_UP_WARNING_TYPE_KEY withValue:nil];
}

- (void)performPopups {
    // This func is called during HomePage load.
    // We have many popups / redirect pages on home page,
    // This func is used to ensure that we only handle one popup/redirect at once
    
    // NOTE: we could use if ([self askForxxx]) return, instead of popup
    //       but it is not readable.
    BOOL popup = NO;
    
    if (!self.user) {
        return;
    }
    if (!self.user.tutorialCompleted) {
        return;
    }
    
    // check if we should ask inviting partner
    if ([self askForInvitePartner]) {
        return;
    }
    
    // check if we should ask share success story
    popup = [self askShareSuccessStory];
    if (popup) return;
    
    // check if we should open share dialog
    self.needPopupShare = NO;
    popup = [self askForShare];
    if (popup) return;
    
}


- (BOOL)askForInvitePartner
{
    if (self.user.partner || [self.user isMale]) {
        return NO;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *firstLaunch = [defaults objectForKey:@"firstLaunch"];
    BOOL hasAsked = [defaults boolForKey:@"hasAskedForInvitePartnerOnAppLanuch"];
    BOOL createdThreeDaysBefore = [firstLaunch timeIntervalSinceNow] <= -86400 * DAYS_BEFORE_ASKING_FOR_INVITE;
    
    if (!hasAsked && createdThreeDaysBefore) {
        [InvitePartnerDialog openDialog];
        [defaults setBool:YES forKey:@"hasAskedForInvitePartnerOnAppLanuch"];
        [defaults synchronize];
        return YES;
    }
    return NO;
}

- (BOOL)askForShare {
    // Do not open ask_for_share dialog for partner
    if ([self.user isSecondary]) {
        return NO;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *firstLaunch = [defaults objectForKey:@"firstLaunch"];
    BOOL hasAsked = [defaults boolForKey:@"hasAskedForShare"];
    if (!hasAsked && ![ShareDialogViewController alreadyShared] && [firstLaunch timeIntervalSinceNow] <= -86400 * DAYS_BEFORE_ASKING_FOR_SHARE) {
        // We have a crash here
        // in share dailog, we will create the screen snapshot, but - we popup the share
        // dialog too early, that the home page may be changed by "user sync completed"
        // To fix, move the popup to the "sync complete"
        self.needPopupShare = YES;
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)askShareSuccessStory {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *laterClickTime = [defaults objectForKey:USER_DEFAULTS_LATER_SHARE_CLIKE_TIME];
    if ((laterClickTime) && ([laterClickTime timeIntervalSinceNow] <= -86400 * DAYS_BEFORE_ASKING_SHARE_STORY)) {
        // pop to share story
        [defaults removeObjectForKey:USER_DEFAULTS_LATER_SHARE_CLIKE_TIME];
        [defaults synchronize];
        
        // check current status first
        if ((self.user) && ([self.user currentPurpose] != AppPurposesAlreadyPregnant)) {
            return NO;
        } else {
            [[TabbarController getInstance:self] goPregnantPage];
            return YES;
        }
    } else {
        return NO;
    }
}

- (void)_showShareDialog {
    ShareDialogViewController *vc = [[ShareDialogViewController alloc] initFromNib];
    vc.shareType = ShareTypeAppShareSyncComplete;
    [vc present];
    [Utils setDefaultsForKey:@"hasAskedForShare" withValue:@YES];
}

# pragma mark - IBAction

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqual:@"startLogging"]) {
        DailyLogViewController *controller = (DailyLogViewController *)segue.destinationViewController;
        controller.selectedDate = self.selectedDate;
    }
    if ([segue.identifier isEqualToString:@"MedicalLogSegueIdentifier"]) {
        MedicalLogViewController *vc = (MedicalLogViewController *)segue.destinationViewController;
        vc.selectedDate = self.selectedDate;
    }
    
    UIViewController *dest = segue.destinationViewController;
    if ([dest isKindOfClass:[NotesTableViewController class]]) {
        ((NotesTableViewController*)dest).dateString = [self.selectedDate toDateLabel];
        return;
    }
}

- (IBAction)backToTodayClicked:(id)sender {
    // a new "back to today" button, added in v2.2.0
    [Logging log:BTN_CLK_HOME_BACK_TODAY];
    [self gotoToday:YES];
}

- (IBAction)clickPeriodButton {
    [Logging log:BTN_CLK_HOME_BAR_PERIOD];
    [self gotoPeriodPage];
}

- (void)gotoPeriodPage {
    
    if (self.presentedViewController) return;

    if (!periodViewController) {
        periodViewController = [GLPeriodEditorViewController instanceOfSubClass:@"PeriodEditorViewController"];
    }
    [self presentViewController:periodViewController animated:YES completion:^{
        self.periodEditButton.enabled = YES;
        self.periodEditButton.alpha = 1.f;
    }];
    
    self.periodEditButton.enabled = NO;
    self.periodEditButton.alpha = 0.5f;
}

- (void)gotoDailyLogPage
{
    [self gotoToday:NO];
    [self performSegueWithIdentifier:@"startLogging" sender:nil];
}

- (void)navigationBarTap: (id)sender {
    NSDate *today = [NSDate date];
    GLLog(@"sender: %@", sender);
    GLLog(@"Back to today! %@", today);
    // logging
    [Logging log:BTN_CLK_HOME_BAR_TODAY];
    
    UITapGestureRecognizer *tgr = (UITapGestureRecognizer *)sender;
    CGPoint location = [tgr locationInView:tgr.view];
    GLLog(@"tapped at: %f, %f", location.x, location.y);
    
    [self gotoToday:YES];
}

- (void)gotoToday:(BOOL)animation {
    if (self.selectedDateIsToday)
        return;
    NSDate *today = [NSDate date];
    [self scrollToDate:today];
}

# pragma mark - IBAction - change background

- (IBAction)changeBackground:(id)sender {
    [Logging log:BTN_CLK_HOME_BACKGROUND];
    [[ImagePicker sharedInstance] showInController:self
                                         withTitle:@"Change background image"
                            destructiveButtonTitle:@"Restore default"
                                     allowsEditing:NO];
}

- (void)didPickedImage:(UIImage *)image {
    [self.user.settings updateBackgroundImage:image];
}

- (void)imagePickerDidClickDestructiveButton
{
    [self.user.settings restoreBackgroundImage];
}

# pragma mark - utils method
- (NSInteger)daysBetweenDate:(NSDate *)fromDateTime andDate:(NSDate *)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate interval:NULL forDate:toDateTime];
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit fromDate:fromDate toDate:toDate options:0];
    return [difference day];
}

- (BOOL)selectedDateIsToday {
    return [Utils date:self.selectedDate isSameDayAsDate:[NSDate date]];
}

# pragma mark - check jump page
- (void)checkJumpPage:(AppOpenData *)openData {
    NSInteger openOption = [openData.openType integerValue];
    switch (openOption) {
        case APP_OPEN_TYPE_LOG:
            // go to log page
            [Logging log:IOS_APP_OPEN_WITH_OPEN_TYPE eventData:@{@"app_open_type": APP_OPEN_TYPE_GO_DAILY_LOG}];
            [self gotoToday:NO];
            [self performSegueWithIdentifier:@"startLogging" sender:self from:self];
            break;
            
        case APP_OPEN_TYPE_GENIUS:
            // go to genius page
            [Logging log:IOS_APP_OPEN_WITH_OPEN_TYPE eventData:@{@"app_open_type": APP_OPEN_TYPE_GO_GENIUS}];
            [[TabbarController getInstance:self] selectGeniusPage];
            break;
            
        case APP_OPEN_TYPE_FUND:
            [Logging log:IOS_APP_OPEN_WITH_OPEN_TYPE eventData:@{@"app_open_type": APP_OPEN_TYPE_GO_GLOW_FIRST}];
            [[TabbarController getInstance:self] selectFundPage];
            break;
            
        case APP_OPEN_TYPE_PERIOD:
            [Logging log:IOS_APP_OPEN_WITH_OPEN_TYPE eventData:@{@"app_open_type": APP_OPEN_TYPE_GO_PERIOD}];
            [self gotoPeriodPage];
            break;
            
        case APP_OPEN_TYPE_LOG_BBT: {
            // got to log page, open base temperature
            [Logging log:IOS_APP_OPEN_WITH_OPEN_TYPE eventData:@{@"app_open_type": APP_OPEN_TYPE_GO_LOG_BBT}];
            // save data in to user default
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:@(APP_OPEN_TYPE_LOG_BBT) forKey:DAILY_PAGE_OPEN_OPTION];
            [defaults synchronize];
            // go to log page
            [self gotoToday:NO];
            [self performSegueWithIdentifier:@"startLogging" sender:self from:self];
            break;
        }
            
        case APP_OPEN_TYPE_URL:
            [Logging log:IOS_APP_OPEN_WITH_OPEN_TYPE eventData:@{@"app_open_type": APP_OPEN_TYPE_BY_URL}];
            if (openData.url) {
                WebViewController *controller = (WebViewController *)[UIStoryboard webView];
                [controller setHidesBottomBarWhenPushed:YES];
                [self.navigationController pushViewController:controller animated:YES from:self];
                [controller openUrl:openData.url];
            }
            break;
            
        case APP_OPEN_TYPE_FORUM_TOPIC: {
            [Logging log:IOS_APP_OPEN_WITH_OPEN_TYPE eventData:@{@"app_open_type": APP_OPEN_TYPE_GO_TOPIC}];
            uint64_t topicId = [openData.data1 longLongValue];
            ForumTopic *topic = [[ForumTopic alloc] init];
            topic.identifier = topicId;
            ForumTopicDetailViewController *topicViewController = [ForumTopicDetailViewController viewController];
            topicViewController.topic = topic;
            UINavigationController *topicNavController = [[UINavigationController alloc] initWithRootViewController:topicViewController];
            [self.tabBarController presentViewController:topicNavController animated:YES completion:nil];
            break;
        }
            
        case APP_OPEN_TYPE_FORUM_REPLY: {
            [Logging log:IOS_APP_OPEN_WITH_OPEN_TYPE eventData:@{@"app_open_type": APP_OPEN_TYPE_GO_TOPIC_COMMENT}];
            uint64_t topicId = [openData.data1 longLongValue];
            // feature usage
            // currently, we can not jump to a specified reply
            // uint64_t replyId = [openData.data2 longLongValue];
            
            ForumTopic *topic = [[ForumTopic alloc] init];
            topic.identifier = topicId;
            ForumTopicDetailViewController *topicViewController = [ForumTopicDetailViewController viewController];
            topicViewController.topic = topic;
            UINavigationController *topicNavController = [[UINavigationController alloc] initWithRootViewController:topicViewController];
            [self.tabBarController presentViewController:topicNavController animated:YES completion:nil];
            break;
        }
            
        case APP_OPEN_TYPE_ALERT: {
            [Logging log:IOS_APP_OPEN_WITH_OPEN_TYPE eventData:@{@"app_open_type": APP_OPEN_TYPE_GO_ALERT}];
            [[TabbarController getInstance:self] selectAlertPage];
            break;
        }
            
        case APP_OPEN_TYPE_FORUM_PROFILE: {
            uint64_t userId = openData.data1 ? openData.data1.unsignedLongLongValue : self.user.id.unsignedLongLongValue;
            id vc = nil;
            if (userId == [Forum currentForumUser].identifier) {
                vc = [[ForumSocialUsersViewController alloc] initWithUser:[Forum currentForumUser]
                                                           socialRelation:SocialRelationTypeFollowers];
                [vc setShowCloseButton:YES];
            }
            else {
                vc = [[ForumProfileViewController alloc] initWithUserID:userId placeholderUser:nil];
            }

            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
            [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
            
            [Logging log:IOS_APP_OPEN_WITH_OPEN_TYPE eventData:@{@"app_open_type": APP_OPEN_TYPE_GO_FORUM_PROFILE}];
            break;
        }
        
        default:
            break;
    }
}

@end
