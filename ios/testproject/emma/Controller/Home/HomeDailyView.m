//
//  DaySummaryView.m
//  emma
//
//  Created by ltebean on 14-12-18.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "HomeDailyView.h"

#import <CoreGraphics/CoreGraphics.h>
#import "HomeViewController.h"
#import "CKCalendarView.h"
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
#import "AlertContainerViewController.h"
#import "DailyArticleCell.h"
#import "DailyArticle.h"
#import "PartnerLoggingCell.h"
#import "RatingCell.h"
#import "RubyRecommendationCell.h"
#import "CustomizationCell.h"
#import "HomeCardCustomizationManager.h"
#import "UserStatusDataManager.h"
#import "DailyTodo.h"
#import "DailyTodoCell.h"
#import <GLPeriodEditor/GLDateUtils.h>

#define RATING_CELL_IDENTIFIER @"RatingItem"
#define ARTICLE_CELL_IDENTIFIER @"ArticleItem"
#define PARTNER_LOGGING_CELL_IDENTIFIER @"PartnerItem"
#define DAILY_TODO_CELL_IDENTIFIER @"DailyTodoItem"
#define POLL_CELL_IDENTIFIER @"PollItem"
#define RUBY_RECOMMENDATION_CELL_IDENTIFIER @"RubyItem"
#define CUSTOMIZATION_CELL_IDENTIFIER @"CustomizationItem"
#define CELL_ID_NOTES_ENTRANCE @"CELL_ID_NOTES_ENTRANCE"

#define NOTE_NEW_CELL_IDENTIFIER @"NoteNewItem"
#define TAG_NOTE_TEXTVIEW 1000

#define TAB_BUTTON_SIZE 22
#define TOOLBAR_HEIGHT 45
#define NAV_HEIGHT 44
#define GGSNAPSHOT_ALPHA 0.1
#define GGSNAPSHOT_SCALE 0.85
#define GGSNAPSHOT_CENTER_OFFSET 25

#define TRIANGLE_VIEW_HEIGHT 13
#define TRIANGLE_VIEW_ORIGINAL_TOP 13

static int kObservingContentSizeChangesContext;

@interface HomeDailyView ()<UIScrollViewDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, StartLoggingCellDelegate, FertilityTreatmentCellDelegate, PartnerLoggingCellDelegate, RatingCellDelegate, CustomizationCellDelegate, NotesCellDelegate, RubyRecommendationCellDelegate> {
    DateRelationOfToday dateRelation;
}

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet StartLoggingCell *startLoggingCell;
@property (strong, nonatomic) PartnerLoggingCell *partnerLoggingCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *futureDaysCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *tomorrowCell;
@property (nonatomic, weak) IBOutlet UIView *futureDayCellContainerView;
@property (nonatomic, weak) IBOutlet UIView *tomorrowCellContainerView;

@property (strong, nonatomic) IBOutlet FertilityTreatmentCell *fertilityTreatmentCell;
@property (nonatomic, strong) UIView *triangleView;
@property (nonatomic, strong) UIImageView *triangleImageView;

@property (nonatomic) BOOL selectedDateIsToday;

// In tutorial or days after tomorrow, the table is disabled
@property (nonatomic) BOOL tableEnabled;
@property (nonatomic) BOOL hasUpdatedTodo;
@property (readonly) User *user;
@property (nonatomic, strong) DailyArticle *dailyArticle;
@property (nonatomic, strong) NSArray *dailyTodos;

@property (nonatomic, strong) NSArray *orderOfCards;
@end


@implementation HomeDailyView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [[NSBundle mainBundle] loadNibNamed:@"HomeDailyView" owner:self options:nil];
        self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.containerView.frame = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
        [self addSubview: self.containerView];
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.tableView.contentInset =  UIEdgeInsetsMake(0, 0, 66, 0);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.scrollEnabled = NO;

    [self.tableView registerNib:[UINib nibWithNibName:@"DailyArticleCell" bundle:nil] forCellReuseIdentifier:ARTICLE_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"PartnerLoggingCell" bundle:nil] forCellReuseIdentifier:PARTNER_LOGGING_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"DailyTodoCell" bundle:nil] forCellReuseIdentifier:DAILY_TODO_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"PollItemCell" bundle:nil] forCellReuseIdentifier:POLL_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"NotesEntranceCell" bundle:nil] forCellReuseIdentifier:CELL_ID_NOTES_ENTRANCE];
    [self.tableView registerNib:[UINib nibWithNibName:@"RatingCell" bundle:nil] forCellReuseIdentifier:RATING_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"CustomizationCell" bundle:nil] forCellReuseIdentifier:CUSTOMIZATION_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"RubyRecommendationCell" bundle:nil] forCellReuseIdentifier:RUBY_RECOMMENDATION_CELL_IDENTIFIER];
    
    self.partnerLoggingCell = [self.tableView dequeueReusableCellWithIdentifier:PARTNER_LOGGING_CELL_IDENTIFIER];
    
    self.tableEnabled = YES;
    
    self.startLoggingCell.delegate = self;
    self.fertilityTreatmentCell.delegate = self;

    [self.futureDayCellContainerView addDefaultBorder];
    [self.tomorrowCellContainerView addDefaultBorder];
    
    [self.fertilityTreatmentCell setHighlighted:NO animated:NO];
    if (!IOS8_OR_ABOVE) {
        [self.startLoggingCell setupWeekLogColors];
    }
    [self.startLoggingCell setHighlighted:NO animated:NO];
    
    // triangle view
    self.triangleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 26, TRIANGLE_VIEW_HEIGHT)];
    self.triangleImageView.image = [UIImage imageNamed:@"home-card-arrow-white"];
    self.triangleView = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2-13, TRIANGLE_VIEW_ORIGINAL_TOP, 26, TRIANGLE_VIEW_HEIGHT)];
    self.triangleView.clipsToBounds = YES;
    [self.triangleView addSubview:self.triangleImageView];
    self.triangleView.hidden = YES;
    self.triangleView.height = 0;
    [self.containerView addSubview:self.triangleView];
    
    [self startObservingContentSizeChangesInTableView];
}

- (void)setSelectedDate:(NSDate *)date
{
    NSLog(@"set selected date: %@", date);
    [UserDailyData pullFromHealthKitForDate:date];
    
    _selectedDate = date;
    
    NSDate *today = [[NSDate date] truncatedSelf];
    NSInteger timeInterval = [self.selectedDate timeIntervalSinceDate:today];
    if (timeInterval < -86400) {
        dateRelation = dateRelationVeryPast;
    } else if (timeInterval < 0 && timeInterval >= -86400) {
        dateRelation = dateRelationYesterday;
    } else if (timeInterval < 86400 && timeInterval >= 0) {
        dateRelation = dateRelationToday;
    } else if (timeInterval >= 86400 && timeInterval < 2 * 86400) {
        dateRelation = dateRelationTomorrowLocked;
    }else {
        dateRelation = dateRelationVeryFuture;
    }
    
    if (dateRelation > dateRelationToday) {
        self.triangleView.hidden = YES;
    } else {
        self.triangleView.hidden = NO;
    }
    
    [self updateDailyTopic];
    [self reloadLogSummary];
    [self reloadPartnerLogSummary];
    [self updateDailyArticleData];
    [self updateDailyTodosData];
    [self updateTodoLeft];
    [self reloadTableView];
}

# pragma mark - getter

- (StartLoggingCell *)startLoggingCell
{
    return _startLoggingCell;
}

- (User *)user {
    return [User currentUser];
}

- (CGFloat)contentHeight
{
    return self.tableView.contentSize.height + 5;
}

# pragma mark - triangle view related

- (void)showTriangleViewWithAnimation:(BOOL)animated;
{
    if (dateRelation > dateRelationToday) {
        return;
    }
    
    if (self.triangleView.transform.ty!=0) {
        self.triangleView.hidden = NO;
        return;
    }
    if (!animated) {
        self.triangleView.top = TRIANGLE_VIEW_ORIGINAL_TOP - TRIANGLE_VIEW_HEIGHT;
        self.triangleView.height = TRIANGLE_VIEW_HEIGHT;
        self.triangleView.hidden = NO;
    } else {
        self.triangleView.height = 0;
        self.triangleView.hidden = NO;
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self.triangleView.top = TRIANGLE_VIEW_ORIGINAL_TOP - TRIANGLE_VIEW_HEIGHT;
            self.triangleView.height = TRIANGLE_VIEW_HEIGHT;

        } completion:^(BOOL finished) {

        }];
    }
}

- (void)hideTriangleViewWithAnimation:(BOOL)animated;
{
    if (self.triangleView.transform.ty != 0) {
        self.triangleView.hidden = YES;
        return;
    }
    if (!animated) {
        self.triangleView.top = TRIANGLE_VIEW_ORIGINAL_TOP;
        self.triangleView.hidden = YES;
        self.triangleView.height = 0;
    } else {
        self.triangleView.hidden = NO;
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self.triangleView.top = TRIANGLE_VIEW_ORIGINAL_TOP;
            self.triangleView.height = 0;
        } completion:^(BOOL finished) {
            self.triangleView.height = 0;
            self.triangleView.hidden = YES;
        }];
    }
}

- (void)updateTriangleViewTranslationY:(CGFloat)translationY
{
    CGFloat ty;
    if (translationY < 0) {
        ty = 0;
    } else {
        ty = MIN(fabs(translationY), TRIANGLE_VIEW_HEIGHT);
    }
    self.triangleView.transform = CGAffineTransformMakeTranslation(0, ty);
    self.triangleView.height = TRIANGLE_VIEW_HEIGHT - ty;
}

# pragma mark - tableView related

- (void)tableViewCellNeedsUpdateHeight:(UITableViewCell *)cell
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.orderOfCards.count;
}

- (BOOL)hasSectionPartnerDailyLog {
    BOOL needsDisplay = [[HomeCardCustomizationManager sharedInstance] needsDisplayCard:CARD_PARTNER_SUMMARY];
    return needsDisplay && ((dateRelation <= dateRelationTomorrowUnlocked) && self.user.partner && self.user.partner.status == USER_STATUS_NORMAL);
}

- (BOOL)hasSectionImportantTasks {
    BOOL needsDisplay = [[HomeCardCustomizationManager sharedInstance] needsDisplayCard:CARD_IMPORTANT_TASK];
    return needsDisplay && ((dateRelation <= dateRelationTomorrowUnlocked) && (self.dailyTodos && self.dailyTodos.count > 0));
}

- (BOOL)hasSectionHealthTips {
    BOOL needsDisplay = [[HomeCardCustomizationManager sharedInstance] needsDisplayCard:CARD_HEALTH_TIPS];
    return needsDisplay && (dateRelation <= dateRelationTomorrowUnlocked) && self.dailyArticle && self.dailyArticle.articleId != 0;
}

static BOOL ratingCardAlreadyShown;
- (BOOL)hasSectionRatingCard {
    BOOL needsShow = [RatingCell needsShow];
    if (needsShow && !ratingCardAlreadyShown) {
        [Logging log:PAGE_IMP_RATING_CARD];
    }
    ratingCardAlreadyShown = YES;
    return needsShow;
}


static BOOL rubyCardAlreadyShown;
- (BOOL)hasSectionRubyRecommendation
{
    BOOL needsShow = [RubyRecommendationCell needsShow] && ![self hasSectionRatingCard];
    if (needsShow && !rubyCardAlreadyShown) {
        [Logging log:PAGE_IMP_HOME_RUBY_RECOMMENDATION_CARD];
    }
    rubyCardAlreadyShown = YES;
    return needsShow;
}

- (BOOL)hasSectionHealthPoll {
    BOOL needsDisplay = [[HomeCardCustomizationManager sharedInstance] needsDisplayCard:CARD_DAILY_POLL];
    if (!needsDisplay) {
        return NO;
    }
    if (dateRelation > dateRelationToday) return NO;
    NSString * dateStr = [Utils dailyDataDateLabel:self.selectedDate];
    ForumTopic * t = [[UserDailyPoll sharedInstance] getTopicByDateStr:dateStr];
    if (t)
        return YES;
    else
        return NO;
}

- (BOOL)hasSectionMedicalLog
{
    if ([self.user isSingle] && [self.user isMale]) {
        return NO;
    }
    if (!(dateRelation <= dateRelationTomorrowUnlocked)) {
        return NO;
    }
    
    UserStatus *userStatus = [[UserStatusDataManager sharedInstance] statusOnDate:[self.selectedDate toDateLabel] forUser:[User userOwnsPeriodInfo]];
    
    if (userStatus.status != STATUS_TREATMENT) {
        return NO;
    }
    if (userStatus.treatmentType != TREATMENT_TYPE_INTERVAL) {
        return YES;
    }
    
    // for treatment interval, we only display treatment end UI on today, mom's side
    if (!self.selectedDateIsToday || [self.user isSecondary]) {
        return NO;
    }
    UserStatus *lastTreatment = [[UserStatusDataManager sharedInstance] lastTreatmentStatusForUser:[User userOwnsPeriodInfo]];
    if (lastTreatment && [GLDateUtils daysBetween:lastTreatment.endDate and:self.selectedDate] > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)hasSectionNotes
{
    BOOL needsDisplay = [[HomeCardCustomizationManager sharedInstance] needsDisplayCard:CARD_NOTES];
    return needsDisplay && (dateRelation <= dateRelationTomorrowUnlocked);
}


- (ForumTopic *)currentHealthPollTopic {
    NSString * dateStr = [Utils dailyDataDateLabel:self.selectedDate];
    return [[UserDailyPoll sharedInstance] getTopicByDateStr:dateStr];
}


- (void)reloadTableView
{
    self.orderOfCards = [[HomeCardCustomizationManager sharedInstance] orderOfCards];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *card = self.orderOfCards[section];
    
    if ([card isEqualToString:CARD_MEDICAL_LOG]) {
        return (dateRelation <= dateRelationToday) ? ([self hasSectionMedicalLog] ? 1 : 0) : 0;
    }
    else if ([card isEqualToString:CARD_DAILY_LOG]) {
        return (dateRelation == dateRelationTomorrowUnlocked) ? 0 : 1;
    }
    else if ([card isEqualToString:CARD_PARTNER_SUMMARY]) {
        return (dateRelation <= dateRelationToday) ? ([self hasSectionPartnerDailyLog] ? 1 : 0) : 0;
    }
    else if ([card isEqualToString:CARD_IMPORTANT_TASK]) {
        return (dateRelation <= dateRelationTomorrowUnlocked) ? ([self hasSectionImportantTasks] ? 1 : 0) : 0;
    }
    else if ([card isEqualToString:CARD_DAILY_POLL]) {
        return (dateRelation <= dateRelationToday) ? ([self hasSectionHealthPoll] ? 1 : 0) : 0;
    }
    else if ([card isEqualToString:CARD_RATING]) {
        return (dateRelation == dateRelationToday) ? ([self hasSectionRatingCard] ? 1 : 0) : 0;
    }
    else if ([card isEqualToString:CARD_RUBY_RECOMMENDATION]) {
        return (dateRelation == dateRelationToday) ? ([self hasSectionRubyRecommendation] ? 1 : 0) : 0;
    }
    else if ([card isEqualToString:CARD_HEALTH_TIPS]) {
        return (dateRelation <= dateRelationToday) ? ([self hasSectionHealthTips] ? 1 : 0) : 0;
    }
    else if ([card isEqualToString:CARD_NOTES]) {
        return (dateRelation <= dateRelationToday) ? ([self hasSectionNotes] ? 1 : 0) : 0;
    }
    else if ([card isEqualToString:CARD_CUSTOMIZATION]) {
        return (dateRelation <= dateRelationToday) ? 1 : 0;
    }
    else {
        return 0;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSString *card = self.orderOfCards[indexPath.section];

    if ([card isEqualToString:CARD_MEDICAL_LOG]) {
        [self.fertilityTreatmentCell configureWithDate:self.selectedDate dateRelation:dateRelation];
        return self.fertilityTreatmentCell.heightThatFits + 4;
    }
    else if ([card isEqualToString:CARD_DAILY_LOG]) {
        if (dateRelation <= dateRelationToday) {
            return self.startLoggingCell.heightThatFits;
        }
        else if ((dateRelation>= dateRelationTomorrowUnlocked) && (indexPath.row == 0)) {
            return 144;
        }
        return 0;
        
    }
    else if ([card isEqualToString:CARD_PARTNER_SUMMARY]) {
        return self.partnerLoggingCell.heightThatFits;
    }
    else if ([card isEqualToString:CARD_IMPORTANT_TASK]) {
        return [DailyTodoCell heightForTodos:self.dailyTodos];
    }
    else if ([card isEqualToString:CARD_DAILY_POLL]) {
        return [PollItemCell getCellHeightByTopic:[self currentHealthPollTopic]];
    }
    else if ([card isEqualToString:CARD_RATING]) {
        if (IS_IPHONE_6) {
            return 254;
        } else if (IS_IPHONE_6_PLUS) {
            return 274;
        } else {
            return 244;
        }
    }
    else if ([card isEqualToString:CARD_RUBY_RECOMMENDATION]) {
        return [RubyRecommendationCell height];
    }
    else if ([card isEqualToString:CARD_HEALTH_TIPS]) {
        return [DailyArticleCell heightThatFitsForArticle:self.dailyArticle];
    }
    else if ([card isEqualToString:CARD_NOTES]) {
        return 60;
    }
    else if ([card isEqualToString:CARD_CUSTOMIZATION]) {
        return 60;
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSString *card = self.orderOfCards[indexPath.section];
    
    if ([card isEqualToString:CARD_MEDICAL_LOG]) {
        self.fertilityTreatmentCell.userInteractionEnabled = self.tableEnabled;
        return self.fertilityTreatmentCell;
    }
    else if ([card isEqualToString:CARD_DAILY_LOG]) {
        if (dateRelation <= dateRelationToday) {
            self.startLoggingCell.userInteractionEnabled = self.tableEnabled;
            return self.startLoggingCell;
        }
        else if (dateRelation == dateRelationTomorrowLocked) {
            return self.futureDaysCell;
        }
        else if (dateRelation == dateRelationVeryFuture) {
            return self.futureDaysCell;
        }
    }
    else if ([card isEqualToString:CARD_PARTNER_SUMMARY]) {
        self.partnerLoggingCell.delegate = self;
        return self.partnerLoggingCell;
    }
    else if ([card isEqualToString:CARD_IMPORTANT_TASK]) {
        DailyTodoCell *cell = [tableView dequeueReusableCellWithIdentifier:DAILY_TODO_CELL_IDENTIFIER];
        cell.todos = self.dailyTodos;
        return cell;
    }
    else if ([card isEqualToString:CARD_DAILY_POLL]) {
        PollItemCell *cell = [tableView dequeueReusableCellWithIdentifier:POLL_CELL_IDENTIFIER];
        [cell setModel:[self currentHealthPollTopic]];
        cell.userInteractionEnabled = self.tableEnabled;
        return cell;

    }
    else if ([card isEqualToString:CARD_RATING]) {
        RatingCell *cell = [tableView dequeueReusableCellWithIdentifier:RATING_CELL_IDENTIFIER];
        cell.delegate = self;
        cell.viewController = self.homeViewController;
        return cell;
    }
    else if ([card isEqualToString:CARD_RUBY_RECOMMENDATION]) {
        RubyRecommendationCell *cell = [tableView dequeueReusableCellWithIdentifier:RUBY_RECOMMENDATION_CELL_IDENTIFIER];
        cell.delegate = self;
        return cell;
    }
    else if ([card isEqualToString:CARD_HEALTH_TIPS]) {
        DailyArticleCell *cell = [tableView dequeueReusableCellWithIdentifier:ARTICLE_CELL_IDENTIFIER];
        cell.article = self.dailyArticle;
        return cell;
    }
    else if ([card isEqualToString:CARD_NOTES]) {
        NotesEntranceCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_ID_NOTES_ENTRANCE];
        NSInteger notesCount = [NotesManager getNotesForDate:[self.selectedDate toDateLabel]].count;
        NSString *entranceMsg = notesCount == 0 ? nil : catstr([@(notesCount) stringValue], @" note", notesCount > 1 ? @"s" : @"", @" added!", nil);
        cell.delegate = self;
        [cell setNotesPreview:entranceMsg];
        return cell;
    }
    else if ([card isEqualToString:CARD_CUSTOMIZATION]) {
        CustomizationCell *cell = [tableView dequeueReusableCellWithIdentifier:CUSTOMIZATION_CELL_IDENTIFIER];
        cell.delegate = self;
        return cell;
    }
    else {
        return [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0)];
    }
    return [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0)];

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

- (void)tableViewCell:(UITableViewCell *)cell needsPerformSegue:(NSString *)segueIdentifier
{
    if ([segueIdentifier isEqualToString:@"appointments"]) {
        [Logging log:BTN_CLK_HOME_APPOINTMENT];

        TabbarController * tabbarController =(TabbarController *)self.homeViewController.tabBarController;
        [tabbarController selectAlertPage];
        
        UINavigationController * nav = (UINavigationController *) tabbarController.selectedViewController;
        AlertContainerViewController * alertController = (AlertContainerViewController * )([nav.viewControllers objectAtIndex:0]);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [alertController selectAppointmentsTabWithAnimation:YES];
        });
        
        return;
    }
    [self.delegate homeDailyView:self needsPerformSegueWithIdentifier:segueIdentifier];
}

- (void)ratingCellNeedsDismiss:(RatingCell *)ratingCell
{
    [self reloadTableView];
}

- (void)rubyRecommendationCellNeedsDismiss:(RubyRecommendationCell *)cell
{
    [self reloadTableView];
}


# pragma mark - segue

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


#pragma mark - IBAction
- (IBAction)restartOrChangeTreatment:(id)sender
{
    if (sender == self.fertilityTreatmentCell.startCycleButton) {
        [Logging log:BTN_CLK_HOME_START_NEW_CYCLE];
    }
    else {
        [Logging log:BTN_CLK_HOME_CHANGE_STATUS_TREATMENT];
    }
    [[TabbarController getInstance:self.homeViewController] goToFertitliyTreatmentPage:sender];
}

- (IBAction)reportPregnancy:(id)sender
{
    [Logging log:BTN_CLK_HOME_REPORT_PREGNANCY];
    [[TabbarController getInstance:self.homeViewController] selectMePage];
}

- (void)custmozationCellDidClick:(CustomizationCell *)cell
{
    [self.delegate homeDailyView:self needsPerformSegueWithIdentifier:@"customize"];
}

#pragma mark - update data logic

- (void)updateDailyTopic {
    UserDailyPoll * dailyPoll = [UserDailyPoll sharedInstance];
    NSString * dateStr = [Utils dailyDataDateLabel:self.selectedDate];
    ForumTopic * topic = [dailyPoll getTopicByDateStr:dateStr];
    if (!topic) {
        // load from server if needed
        [dailyPoll loadTopicByDate:self.selectedDate];
    }
}

- (void)updateDailyArticleData
{
    if ([self.selectedDate isFutureDay]) {
        return;
    }
    self.dailyArticle = [DailyArticle articleAtDate:[self.selectedDate toDateLabel] forUser:[self user]];
}

- (void)updateDailyTodosData
{
    if ([self.selectedDate isFutureDay]) {
        return;
    }
    self.dailyTodos = [DailyTodo todosAtDate:[self.selectedDate toDateLabel] forUser:[self user]];
}


- (void)updateTodoLeft {
    
    NSInteger todoLeft = 0;
    
    for (DailyTodo *todo in self.dailyTodos) {
        if (!todo.checked) {
            todoLeft ++;
        }
    }
    if (![self hasDailyData]){
        todoLeft += 1;
    }
    if (todoLeft == 0 && self.selectedDateIsToday) {
        if (!self.user.settings.hasSeenShareDialog && ![ShareDialogViewController alreadyShared] && self.hasUpdatedTodo) {
            ShareDialogViewController *vc = [[ShareDialogViewController alloc] initFromNib];
            vc.shareType = ShareTypeAppShareDailyTodo;
            [vc present];
        }
    }
}

- (BOOL)hasDailyData {
    return [UserDailyData hasDataForDate:[Utils dailyDataDateLabel:self.selectedDate]
                                 forUser:self.user];
}


# pragma mark - public method to update data and reload correspoding section

- (void)reloadLogSummary
{
    self.startLoggingCell.currentDate = self.selectedDate;
}

- (void)reloadPartnerLogSummary
{
    self.partnerLoggingCell.date = self.selectedDate;
}

- (void)reloadDailyArticle
{
    [self updateDailyArticleData];
}

- (void)reloadDailyTodo
{
    [self updateDailyTodosData];
}

# pragma mark - table view content size kvo
- (void)startObservingContentSizeChangesInTableView
{
    [self.tableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&kObservingContentSizeChangesContext];
}

- (void)stopObservingContentSizeChangesInTableView
{
    [self.tableView removeObserver:self forKeyPath:@"contentSize" context:&kObservingContentSizeChangesContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &kObservingContentSizeChangesContext) {
        CGFloat old = [[change objectForKey:NSKeyValueChangeOldKey] CGSizeValue].height;
        CGFloat new = [[change objectForKey:NSKeyValueChangeNewKey] CGSizeValue].height;
        if (old != new) {
            [self.delegate homeDailyView:self needsUpdateHeightTo:[self contentHeight]];
        }
    }
}

# pragma mark - helper

- (BOOL)selectedDateIsToday {
    return [Utils date:self.selectedDate isSameDayAsDate:[NSDate date]];
}

# pragma mark - dealloc

- (void)dealloc {
    [self stopObservingContentSizeChangesInTableView];
}

@end
