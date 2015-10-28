//
//  HealthProfileViewController.m
//  emma
//
//  Created by Peng Gu on 10/11/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "HealthProfileViewController.h"
#import "HealthProfileDataController.h"
#import "HealthProfileActionController.h"
#import "HealthProfileData.h"
#import "HealthProfileItem.h"
#import "User.h"
#import "StatusBarOverlay.h"
#import "DACircularProgressView.h"
#import "MedicalRecordsSummaryView.h"
#import "MedicalRecordsDataManager.h"
#import "MedicalRecordsDetailViewController.h"
#import <GLFoundation/NSString+Markdown.h>
#import "DropdownMessageController.h"
#import "Tooltip.h"
#import "UIViewController+ScrollingNavbar.h"


#define medicalRecordDataManager  [MedicalRecordsDataManager sharedInstance]

@interface HealthProfileViewController () <UIScrollViewDelegate, MedicalRecordsSummaryViewDelegate, HealthProfileActionControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *topInfoViewShadow;
@property (weak, nonatomic) IBOutlet UIView *topInfoView;
@property (weak, nonatomic) IBOutlet DACircularProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet MedicalRecordsSummaryView *medicalRecordsSummaryView;

@property (nonatomic, strong) HealthProfileDataController *dataController;
@property (nonatomic, strong) HealthProfileActionController *actionController;

@property (nonatomic) BOOL needsHideNavBar;
@end

@implementation HealthProfileViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.titleView.alpha = 0;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    
    self.needsHideNavBar = IOS8_OR_ABOVE ? YES : NO;

    if (self.needsHideNavBar) {
        [self followScrollView:self.tableView];
        [self setUseSuperview:NO];
        self.topInfoViewShadow.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI);
    } else {
        self.topInfoViewShadow.hidden = YES;
    }

    self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 44.0, 0.0);
    
    self.dataController = [[HealthProfileDataController alloc] init];
    self.actionController = [[HealthProfileActionController alloc] initWithTableView:self.tableView
                                                                      dataController:self.dataController];
    self.actionController.delegate = self;
    
    [self.progressView setRoundedCorners:YES];
    self.progressView.thicknessRatio = 0.2;
    
    self.medicalRecordsSummaryView.delegate = self;
    
    [self subscribe:EVENT_HUMAN_API_AUTH_FINISHED selector:@selector(humanAPIAuthFinished)];
    [self reloadMedicalRecordsSummaryView];
    
    [self setupTitleView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    BOOL needFetchMedicalRecord = !([medicalRecordDataManager connectStatus] == ConnectStatusNotConnected);
    if (needFetchMedicalRecord) {
        [self fetchMedicalRecordsSummaryData];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_HEALTH];
    [self refreshCompletionProgress];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    [self.medicalRecordsSummaryView stopAnimatingFetchingDataLabel];
    if (self.needsHideNavBar) {
        [self showNavBarAnimated:NO];
    }
}

- (void)setupTitleView
{
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor whiteColor];
    shadow.shadowOffset = CGSizeMake(0, 0);
    NSDictionary *attrs = @{
                            NSFontAttributeName: [Utils semiBoldFont:24],
                            NSForegroundColorAttributeName: UIColorFromRGB(0x5b5b5b),
                            NSShadowAttributeName: shadow
                            };
    UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.backgroundColor = [UIColor clearColor];
    titleView.attributedText = [[NSAttributedString alloc] initWithString:@"Health profile" attributes:attrs];
    titleView.centerX = SCREEN_WIDTH / 2;
    self.navigationItem.titleView = titleView;
}

- (void)refreshCompletionProgress
{
    CGFloat progress = [HealthProfileDataController completionRate];
    [self.progressView setProgress:progress animated:YES];
    
    NSUInteger rate = (NSUInteger)(progress * 100);
    self.progressLabel.text = [NSString stringWithFormat:@"%ld%%", (unsigned long)rate];
}


#pragma mark - event
- (void)humanAPIAuthFinished
{
    // show cover view after view appears
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.medicalRecordsSummaryView showFetchingDataCover];
    });
    // fetch data later
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [medicalRecordDataManager fetchSummaryDataWithCompletionHandler:^(BOOL success) {
            NSDictionary* data = [medicalRecordDataManager summaryData];
            if (data && data.count == 0) {
                [[DropdownMessageController sharedInstance] postMessage:@"No medical records data available" duration:2.5 inView:[GLUtils keyWindow]];
            }
            [self reloadMedicalRecordsSummaryView];
        }];
    });
}


- (void)fetchMedicalRecordsSummaryData
{
    [medicalRecordDataManager fetchSummaryDataWithCompletionHandler:^(BOOL success) {
        if (success) {
            [self reloadMedicalRecordsSummaryView];
        }
    }];
}

#pragma mark - MedicalRecordsSummaryView delegate
- (void)medicalRecordsSummaryView:(MedicalRecordsSummaryView *)summaryView didSelectType:(NSString *)type
{
    [self performSegueWithIdentifier:@"showMedicalRecordDetail" sender:type];
    [Logging log:BTN_CLK_HUMANAPI_VIEW_RECORDS eventData:@{@"data_type": type}];
}

- (void)medicalRecordsSummaryViewNeedsConnectHumanAPI:(MedicalRecordsSummaryView *)summaryView
{
    [self performSegueWithIdentifier:@"connectHumanAPI" sender:nil];
    [Logging log:BTN_CLK_HUMANAPI_CONNECT];
}

- (void)reloadMedicalRecordsSummaryView
{
    if ([medicalRecordDataManager connectStatus] == ConnectStatusConnected) {
        self.medicalRecordsSummaryView.summaryData = [medicalRecordDataManager summaryData];
    }
    else {
        self.medicalRecordsSummaryView.summaryData = nil;
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 22)];
    }
}

#pragma mark - medical records IBAction
- (IBAction)cancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES from:self];
}


#pragma mark - Table view data source and delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataController.numberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataController numberOfItemsInSection:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HealthProfileCellReuseIdentifier"
                                                            forIndexPath:indexPath];
    
    HealthProfileItem *item = [self.dataController itemAtIndexPath:indexPath];
    [item configureCell:cell];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    HealthProfileItem *item = [self.dataController itemAtIndexPath:indexPath];
    [self.actionController performActionForItem:item];
}


#pragma mark - Action Controller Delegate

- (void)actionControllerNeedsToPerformSegue:(NSString *)segueIdentifier
{
    [self performSegueWithIdentifier:segueIdentifier sender:nil from:self];
}


- (void)actionControllerDidSaveUpdate
{
    [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
    
    [self.tableView reloadData];
    [self refreshCompletionProgress];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.needsHideNavBar) {
        return;
    }
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY > 0) {
        self.topInfoView.transform = CGAffineTransformMakeTranslation(0, offsetY);
    } else {
        self.topInfoView.transform = CGAffineTransformIdentity;
    }
}


#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showMedicalRecordDetail"]) {
        MedicalRecordsDetailViewController *vc = segue.destinationViewController;
        vc.type = sender;
    }
}




@end






