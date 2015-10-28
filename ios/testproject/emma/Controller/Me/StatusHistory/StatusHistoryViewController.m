//
//  StatusHistoryViewController.m
//  emma
//
//  Created by ltebean on 15/6/17.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "StatusHistoryViewController.h"
#import "StatusHistoryCell.h"
#import "StatusHistory.h"
#import <GLPeriodEditor/GLDateUtils.h>
#import <GLFoundation/GLTheme.h>
#import "UserStatus.h"
#import "GLPillGradientButton.h"
#import "AddStatusHistoryView.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "UserStatusDataManager.h"
#import "StatusBarOverlay.h"
#import "NetworkLoadingView.h"
#import "DropdownMessageController.h"
#import "StatusBarOverlay.h"

static const CGFloat SECTION_HEADER_HEIGHT = 24;
static const CGFloat CURRENT_STATUS_VIEW_HEIGHT = 65;

@interface StatusHistoryViewController ()<UITableViewDataSource, UITableViewDelegate, StatusHistoryCellDelegate, AddStatusHistoryViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTop;
@property (weak, nonatomic) IBOutlet GLPillGradientButton *addCycleButton;
@property (weak, nonatomic) IBOutlet UILabel *currentStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentStatusDatesLabel;
@property (nonatomic, strong) NSMutableDictionary *sections;
@property (nonatomic, strong) NSArray *sortedYears;
@property (nonatomic, strong) NSArray *treatmentStatusHistory;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *currentStatusViewHeight;

@property (weak, nonatomic) IBOutlet AddStatusHistoryView *addTreatmentCycleView;
@property (nonatomic) BOOL addTreatmentCycleViewIsVisible;
@property (nonatomic, strong) UserStatusDataManager *dataManager;
@property (nonatomic) BOOL hasCurrentStatus;
@property (nonatomic) BOOL isAnimating;
@property (nonatomic) BOOL pulled;
@end

@implementation StatusHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.dataManager = [UserStatusDataManager sharedInstance];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.addCycleButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    self.addTreatmentCycleView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self subscribe:EVENT_USER_SYNC_COMPLETED selector:@selector(reloadData)];
    [self reloadData];
    if ([User currentUser].isSecondary) {
        self.addCycleButton.enabled = NO;
    } else {
        self.addCycleButton.enabled = YES;
    }
    [Logging log:PAGE_IMP_ME_FERTILITY_TREATMENT_STATUS_HISTORY];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unsubscribeAll];
}

- (void)reloadData
{
    User *user = [User userOwnsPeriodInfo];
    self.treatmentStatusHistory = [self.dataManager statusHistoryForUser:user];
    self.sections = [NSMutableDictionary dictionary];
    
    UserStatus *currentStatus;
    NSDate *today = [NSDate date];
    
    for (int i = 0; i < self.treatmentStatusHistory.count; i++) {
        UserStatus *history = self.treatmentStatusHistory[i];
        if ([history containsDate:today]) {
            currentStatus = history;
        }
        NSDateComponents *date = [[GLDateUtils calendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:history.startDate];
        NSMutableArray *dataList = self.sections[@(date.year)];
        if (!dataList) {
            dataList = [NSMutableArray array];
            self.sections[@(date.year)] = dataList;
        }
        [dataList addObject:history];
    }
    self.sortedYears = [self.sections.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj2 compare:obj1];
    }];
    [self.tableView reloadData];
    
    if (currentStatus) {
        self.currentStatusLabel.text = [currentStatus shortDescription];
        self.currentStatusDatesLabel.text = [currentStatus datesDescription];
        self.hasCurrentStatus = YES;
        self.currentStatusViewHeight.constant = CURRENT_STATUS_VIEW_HEIGHT;
    } else {
        self.currentStatusLabel.text = @"-";
        self.currentStatusDatesLabel.text = @"";
        self.hasCurrentStatus = NO;
        self.currentStatusViewHeight.constant = 0;
    }
    self.tableViewTop.constant = [self topForTableViewExpanded:self.addTreatmentCycleViewIsVisible];
    [self.addTreatmentCycleView layoutIfNeeded];
    
    if (self.treatmentStatusHistory.count == 0 && !self.pulled) {
        [NetworkLoadingView showWithoutAutoClose];
        [[User currentUser] pullStatusHistory:^(BOOL success) {
            self.pulled = YES;
            [NetworkLoadingView hide];
            if (success) {
                [self reloadData];
            } else {
                [UIAlertView bk_showAlertViewWithTitle:@"Sorry, we're unable to fetch your fertility treatment history due to a poor connection." message:nil cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            }
        }];
        return;
    }
}

- (CGFloat)topForTableViewExpanded:(BOOL)expanded
{
    if ([User currentUser].isSecondary) {
        return self.hasCurrentStatus ? CURRENT_STATUS_VIEW_HEIGHT : 0;
    } else {
        CGFloat height = expanded ? 185 : 135;
        if (!self.hasCurrentStatus) {
            height -= CURRENT_STATUS_VIEW_HEIGHT;
        }
        return height;
    }
}

# pragma mark - table view related

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSNumber *year = self.sortedYears[section];
    return [self.sections[year] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StatusHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    NSArray *dataList = self.sections[self.sortedYears[indexPath.section]];
    UserStatus* data = dataList[indexPath.row];
    cell.data = data;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SECTION_HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, SECTION_HEADER_HEIGHT)];
    header.backgroundColor = [UIColor whiteColor];
    
    UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 1)];
    border.backgroundColor = UIColorFromRGB(0xf1f1f1);
    [header addSubview:border];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, SECTION_HEADER_HEIGHT)];
    label.left = 15;
    label.font = [GLTheme defaultFont:14];
    NSNumber *year = self.sortedYears[section] ;
    label.text = [NSString stringWithFormat:@"%@", [year stringValue]];
    label.textColor = UIColorFromRGB(0x666666);
    [header addSubview:label];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

# pragma mark - AddStatusHistoryView delegate
- (void)addStatusHistoryViewDidCancel:(AddStatusHistoryView *)view
{
    [self hideAddTreatmentCycleView];
}

- (void)addStatusHistoryView:(AddStatusHistoryView *)view didWantToAddStatusHistory:(UserStatus *)status
{
    User *user = [User currentUser];
    BOOL willOverlape = NO;
    for (UserStatus *statusHistory in self.treatmentStatusHistory) {
        // found conflicts
        if ([status containsDate:statusHistory.startDate] || [status containsDate:statusHistory.endDate]) {
            willOverlape = YES;
            break;
        }
        if ([statusHistory containsDate:status.startDate] || [statusHistory containsDate:status.endDate]) {
            willOverlape = YES;
            break;
        }
    }
    if (willOverlape) {
        [UIAlertView bk_showAlertViewWithTitle:@"The selected treatment dates conflict with another cycle. Do you want to replace your logs for those days?" message:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Yes"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [self createTreatmentStatus:status forUser:user];
            }
        }];
        return;
    }
    [self createTreatmentStatus:status forUser:user];
}

# pragma mark - StatusHistoryCell delegate

- (void)statusHistoryCell:(StatusHistoryCell *)cell didUpdateStatus:(UserStatus *)originalStatus to:(UserStatus *)status
{
    User *user = [User currentUser];
    BOOL willOverlape = NO;
    for (UserStatus *statusHistory in self.treatmentStatusHistory) {
        // found self
        if ([statusHistory isEqual:originalStatus]) {
            continue;
        }
        // found conflicts
        if ([status containsDate:statusHistory.startDate] || [status containsDate:statusHistory.endDate]) {
            willOverlape = YES;
            break;
        }
        if ([statusHistory containsDate:status.startDate] || [statusHistory containsDate:status.endDate]) {
            willOverlape = YES;
            break;
        }
    }
    if (willOverlape) {
        [UIAlertView bk_showAlertViewWithTitle:@"The selected dates conflict with another cycle. Do you want to replace your logs for those days?" message:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Yes"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [self updateTreatmentStatus:originalStatus to:status forUser:user];
            }
        }];
        return;
    }
    [self updateTreatmentStatus:originalStatus to:status forUser:user];
}

- (void)statusHistoryCell:(StatusHistoryCell *)cell didWantToDeleteStatus:(UserStatus *)status
{
    if (self.isAnimating) {
        return;
    }
    if (self.treatmentStatusHistory.count == 1) {
        [cell hideDeleteButton];
        [UIAlertView bk_showAlertViewWithTitle:@"Cannot delete the only treatment cycle" message:nil cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        }];
        return;
    }
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) {
        return;
    }
    // update model
    NSDateComponents *date = [[GLDateUtils calendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:status.startDate];
    NSMutableArray *statusHistory = self.sections[@(date.year)];
    [statusHistory removeObjectAtIndex:indexPath.row];
    
    self.isAnimating = YES;
    [CATransaction begin];
    [CATransaction setCompletionBlock: ^{
        self.isAnimating = NO;
        User *user = [User currentUser];
        [self deleteTreatmentStatus:status forUser:user];
    }];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    [CATransaction commit];
   
}

# pragma mark - data update logic

- (void)updateTreatmentStatus:(UserStatus *)originalStatus to:(UserStatus *)status forUser:(User *)user
{
    user.dirty = YES;
    [self.dataManager updateStatusHistory:originalStatus to:status forUser:user];
    [self reloadData];
    [user pushToServer];
    [self logAction:BTN_CLK_FTHISTORY_SAVE status:status];
    [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
}

- (void)deleteTreatmentStatus:(UserStatus *)status forUser:(User *)user
{
    user.dirty = YES;
    [self.dataManager deleteStatusHistory:status forUser:user];
    [self reloadData];
    [user pushToServer];
    [self logAction:BTN_CLK_FTHISTORY_DELETE status:status];
    [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
}


- (void)createTreatmentStatus:(UserStatus *)status forUser:(User *)user
{
    user.dirty = YES;
    [self.dataManager createStatusHistory:status forUser:user];
    [self reloadData];
    [self hideAddTreatmentCycleView];
    [user pushToServer];
    [self logAction:BTN_CLK_FTHISTORY_ADD status:status];
    [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
}


- (void)logAction:(NSString *)name status:(UserStatus *)status
{
    [Logging log:name eventData:@{@"status":@(status.status), @"treatment_type":@(status.treatmentType), @"start_date": [status.startDate toDateLabel], @"end_date": [status.endDate toDateLabel]}];
}

# pragma mark - add new cycle view

- (IBAction)addTreatmentCycleButtonPressed:(id)sender
{
    [self showAddTreatmentCycleView];
}

- (void)showAddTreatmentCycleView
{
    if (self.addTreatmentCycleViewIsVisible) {
        return;
    }
    self.addTreatmentCycleViewIsVisible = YES;
    [self.addTreatmentCycleView setupToInitialLook];
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:5 options:0 animations:^{
        self.tableViewTop.constant = [self topForTableViewExpanded:YES];
        [self.tableView setNeedsUpdateConstraints];
        [self.tableView layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideAddTreatmentCycleView
{
    if (!self.addTreatmentCycleViewIsVisible) {
        return;
    }
    self.addTreatmentCycleViewIsVisible = NO;
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:5 options:0 animations:^{
        self.tableViewTop.constant = [self topForTableViewExpanded:NO];
        [self.tableView setNeedsUpdateConstraints];
        [self.tableView layoutIfNeeded];
    } completion:^(BOOL finished) {
        
        
    }];
}
@end