//
//  FundDemoViewController.m
//  emma
//
//  Created by Jirong Wang on 11/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundDemoViewController.h"
#import "Logging.h"
#import "User.h"
#import "FundHomeViewController.h"
#import "FundOngoingSectionHeader.h"
#import "FundOngoingGrantCell.h"
#import "FundOngoingActivityCell.h"
#import "FundOngoingButtonCell.h"
#import "Activity.h"
#import "ActivityLevel.h"
#import "PillGradientButton.h"
#import "TabbarController.h"
#import "GlowFirst.h"
#import "NetworkLoadingView.h"
#import "StatusBarOverlay.h"
#import "Errors.h"
#import <GLFoundation/NSString+Markdown.h>

#define FUND_DEMO_STATUS_CELL_IDENTIFIER @"statusCell"
#define FUND_DEMO_GRANT_CELL_IDENTIFIER @"grantCell"
#define FUND_DEMO_ACTIVITY_CELL_IDENTIFIER @"activityCell"
#define FUND_DEMO_QUIT_CELL_IDENTIFIER @"buttonCell"

#pragma mark - FundDemoStatusCell
@interface FundDemoStatusCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *fontAttributedText;
@property (nonatomic, strong) IBOutlet UILabel *demoDaysLeftLabel;
- (void)setDaysLeft:(NSInteger)days;
// we need this func for scroll the table, like FundOngoingBaseCell
- (void)cellDidScrolled:(NSValue *)vOffset;
@end

@implementation FundDemoStatusCell
- (void)setDaysLeft:(NSInteger)days {
    self.demoDaysLeftLabel.text = [NSString stringWithFormat:@"You have %ld demo %@ left.", (long)days, days == 1? @"day" : @"days"];
    
    // add font for the text
    self.fontAttributedText.attributedText = [NSString addFont:[Utils defaultFont:17.0] toAttributed:self.fontAttributedText.attributedText];
}
- (void)cellDidScrolled:(NSValue *)vOffset {
    return;
}

@end

#pragma mark - FundDemoViewController
@interface FundDemoViewController () <UIActionSheetDelegate> {
    IBOutlet UIView *bgView;
}

@property (nonatomic) NSArray * activityHistory;

- (IBAction)applyButtonPressed:(id)sender;

@end

@implementation FundDemoViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.tableView.backgroundView = bgView;
    [self.tableView registerNib:[UINib nibWithNibName:@"FundOngoingGrantCell" bundle:nil] forCellReuseIdentifier:FUND_DEMO_GRANT_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"FundOngoingActivityCell" bundle:nil] forCellReuseIdentifier:FUND_DEMO_ACTIVITY_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"FundOngoingButtonCell" bundle:nil] forCellReuseIdentifier:FUND_DEMO_QUIT_CELL_IDENTIFIER];
    
    self.tableView.backgroundView = bgView;
    
    [self.tableView setContentInset:UIEdgeInsetsMake(-50, 0, 0, 0)];
    
    // navigation bar buttons
    NSInteger curStatus = [User currentUser].ovationStatus;
    if ((curStatus != OVATION_STATUS_NONE) && (curStatus != OVATION_STATUS_DEMO)) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = @"Applied";
    } else {
        self.navigationItem.rightBarButtonItem.title = @"Exit & Apply";
    }
    
    /*
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 160, 30)];
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, 30)];
    NSDictionary *attr = @{NSFontAttributeName: [Utils lightFont:22]};
    NSDictionary *underlineAttribute = @{
        NSFontAttributeName : [Utils boldFont: 22]
    //    NSUnderlineStyleAttributeName: @1
    };
    NSMutableAttributedString * titleString = [[NSMutableAttributedString alloc] initWithString:@"Glow First Demo"attributes:attr];
    [titleString setAttributes:underlineAttribute range:NSMakeRange(11, 4)];
    label.attributedText = titleString;
    label.textColor = UIColorFromRGB(0x5b5b5b);
    label.textAlignment = NSTextAlignmentCenter;
    [view addSubview:label];
    view.backgroundColor = [UIColor clearColor];
    label.backgroundColor = [UIColor clearColor];
     
    self.navigationItem.title = @"";
    self.navigationItem.titleView = view;
    */
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self subscribe:EVENT_ACTIVITY_GF_DEMO_UPDATED selector:@selector(activityHistoryUpdated:)];
    // This is for clicking the quit demo button, because the button is in cell
    // cell publish this event, and we handle it
    [self subscribe:EVENT_FUND_QUIT_DEMO_PRESSED selector:@selector(quitGlowFirstPressed:)];
    // This is callback of "quit" server call
    [self subscribe:EVENT_FUND_QUIT_DEMO selector:@selector(onQuitDemo:)];
    
    NSDate * quitDate = [[GlowFirst sharedInstance] localFundQuitDemoDate];
    if (!quitDate) {
        // This is callback of "get quit time" server call
        [self subscribe:EVENT_FUND_GET_QUIT_DEMO_TIME selector:@selector(onGetQuitTime:)];
        [[GlowFirst sharedInstance] getQuitDemoDate];
    } else {
        [self updateDemoLeftDays:quitDate];
    }
    // get Activity history for demo
    [Activity calDemoActivityHistory:[User currentUser]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView.visibleCells makeObjectsPerformSelector:@selector(cellDidScrolled:) withObject:[NSValue valueWithCGPoint:self.tableView.contentOffset]];
    // logging
    [CrashReport leaveBreadcrumb:@"FundDemoViewController"];
    [Logging log:PAGE_IMP_FUND_DEMO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self unsubscribeAll];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)activityHistoryUpdated:(Event *)event {
    self.activityHistory = [NSArray arrayWithArray:(NSArray *)event.data];
    [self.tableView reloadData];
}

- (NSInteger)activityHistoryCount {
    return self.activityHistory ? self.activityHistory.count : 0;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.tableView.visibleCells makeObjectsPerformSelector:@selector(cellDidScrolled:) withObject:[NSValue valueWithCGPoint:self.tableView.contentOffset]];
}

#pragma mark - Table view data source
- (BOOL)isQuitDemoSection:(NSInteger)section {
    if ([self activityHistoryCount] > 0)
        return section == 4;
    else
        return section == 3;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self activityHistoryCount] > 0 ? 5 : 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([self activityHistoryCount] > 0) {
        // 5 sections, 0, 1, 2, 4 is 1, 3 is not
        return section == 3 ? [self activityHistoryCount] : 1;
    } else {
        return 1;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSArray *headerText = [self activityHistoryCount] > 0 ?
    @[@"",
      @"Potential grant on 10th month",
      @"Current engagement level",
      @"Previous engagement level",
      @"Click below to exit demo"] :
    @[@"",
      @"Potential grant on 10th month",
      @"Current engagement level",
      @"Click below to exit demo"];
    NSArray *headerTextWidth = [self activityHistoryCount] > 0 ? @[@0, @215, @200, @205, @185] : @[@0, @215, @200, @185];
    
    if(section == 0) {
        // give an empty header with transform background, because we don't want to
        // other headers stay at top when scroll up
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 50)];
        view.backgroundColor = [UIColor clearColor];
        return view;
    } else {
        FundOngoingSectionHeader * header = [[[NSBundle mainBundle] loadNibNamed:@"FundOngoingSectionHeader" owner:nil options:nil] objectAtIndex:0];
        [header setHeaderText:[headerText objectAtIndex:section] width:[[headerTextWidth objectAtIndex:section] integerValue]];
        return header;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 100;
    } else if (indexPath.section == 1) {
        return 255;
    } else {
        return 160;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FUND_DEMO_STATUS_CELL_IDENTIFIER forIndexPath:indexPath];
        return cell;
    } else if ([self isQuitDemoSection:indexPath.section]) {
        FundOngoingButtonCell *bCell = (FundOngoingButtonCell *)[tableView dequeueReusableCellWithIdentifier:FUND_DEMO_QUIT_CELL_IDENTIFIER forIndexPath:indexPath];
        [bCell setIsPregnantButton:NO];
        return bCell;
    } else if (indexPath.section == 1)  {
        FundOngoingGrantCell *cell = (FundOngoingGrantCell *)[tableView dequeueReusableCellWithIdentifier:FUND_DEMO_GRANT_CELL_IDENTIFIER];
        cell.mainLabel.text = @"$1000";
        cell.secondaryLabel.text = [NSString stringWithFormat:@"This $ is just an example. Paid version will have\n a different amount."];
        return cell;
    } else {
        // history months
        FundOngoingActivityCell *cell = (FundOngoingActivityCell *)[tableView dequeueReusableCellWithIdentifier:FUND_DEMO_ACTIVITY_CELL_IDENTIFIER];
        
        ActivityLevel *activity = nil;
        if (indexPath.section == 2) {
            activity = [Activity getActivityForCurrentMonth:[User currentUser]];
        } else {
            activity = [self.activityHistory objectAtIndex:indexPath.row];
        }
        
        cell.active = activity.activeLevel != ACTIVITY_INACTIVE;
        cell.activityLabel.text = activity.activityDescription;
        cell.monthLabel.text = activity.monthLabel;
        cell.scoreLabel.text = [NSString stringWithFormat:@"%2.1f%%", activity.activeScore * 100];
        // This value is used for the size of background cycle, minus 1
        // The max size is 160% (score=100%), min size is 100% (score=15%)
        cell.activeLevel = ((activity.activeScore - 0.15) / 0.85) * 0.6;
        return cell;
    }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section > 0) && ![self isQuitDemoSection:indexPath.section]) {
        if ([cell respondsToSelector:@selector(willShow)]) {
            [cell performSelector:@selector(willShow)];
        }
    }
}

#pragma mark - IBAction
- (IBAction)applyButtonPressed:(id)sender {
    [Logging log:BTN_CLK_FUND_DEMO_APPLY];
    if (ENABLE_GF_ENTERPRISE)
        [self performSegueWithIdentifier:@"applyFromDemo" sender:self from:self];
    else
        [self performSegueWithIdentifier:@"personalFromDemo" sender:self from:self];
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [NetworkLoadingView show];
            [[GlowFirst sharedInstance] quitDemo];
            break;
        default:
            break;
    }
}

#pragma mark - Glow First quit demo post and callback
- (void)quitGlowFirstPressed:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Are you sure you want to exit Glow First Demo?"
                                  delegate:self
                                  cancelButtonTitle:@"No, thanks"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"Yes, please quit", nil];
    actionSheet.cancelButtonIndex = 1;
    [actionSheet showInView:self.view.window];
}

- (void)onQuitDemo:(Event *)event {
    [NetworkLoadingView hide];
    NSDictionary * response = (NSDictionary *)(event.data);
    
    NSInteger rc = [[response objectForKey:@"rc"] integerValue];
    if (rc == RC_NETWORK_ERROR) {
        StatusBarOverlay *sbar = [StatusBarOverlay sharedInstance];
        [sbar postMessage:@"Failed to quit Glow Demo." duration:4.0];
    } else if (rc == RC_SUCCESS) {
        [Logging log:BTN_CLK_FUND_DEMO_QUIT];
        [[TabbarController getInstance:self] rePerformFundSegue];
    } else {
        NSString *errMsg = [response objectForKey:@"msg"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:(errMsg ? errMsg : [Errors errorMessage:rc])
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - Glow First get quit demo time callback
- (void)onGetQuitTime:(Event *)event {
    NSDate * quitDate = [[GlowFirst sharedInstance] localFundQuitDemoDate];
    [self updateDemoLeftDays:quitDate];
}

- (void)updateDemoLeftDays:(NSDate *)quitDate {
    NSInteger days = [Utils daysBeforeDate:quitDate sinceDate:[NSDate date]];
    FundDemoStatusCell * cell = (FundDemoStatusCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [cell setDaysLeft:days];
}

@end
