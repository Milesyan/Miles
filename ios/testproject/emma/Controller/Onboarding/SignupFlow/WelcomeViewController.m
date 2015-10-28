//
//  WelcomeViewController.m
//  emma
//
//  Created by Eric Xu on 2/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ChildrenNumberPicker.h"
#import "DaysPicker.h"
#import "DropdownMessageController.h"
#import "GradientLabel.h"
#import "InvitePartnerDialog.h" 
#import "LastPeriodPicker.h"
#import "Logging.h"
#import "PillButton.h"
#import "StatusBarOverlay.h"
#import "TTCStartTimePicker.h"
#import "Tooltip.h"
#import "UILinkLabel.h"
#import "UIStoryboard+Emma.h"
#import "User.h"
#import "UserDailyData.h"
#import "VariousPurposesDataProviderFactory.h"
#import "WelcomeViewController.h"
#import "StepsNavigationItem.h"
#import "TabbarController.h"
#import "UIView+Helpers.h"
#import "OnboardingDataProviderTreatment.h"

#define ONBOARD_DONE @"onBoardDone"

#define TAG_DONE 5
#define TAG_CELL_TITLE 1
#define TAG_CELL_BUTTON 2
#define TAG_CELL_ADDITIONAL_BUTTON 3
#define TAG_CELL_ASSISTANT_INFO 4
#define CELL_TITLE_WIDTH 188.0f
#define CELL_HEIGHT_WITH_ADDITIONAL_BUTTON 134.0f
#define BUTTONS_HEIGHT_WITH_ADDITIONAL 104.0f

@interface WelcomeViewController () <UIScrollViewDelegate,
        UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate> {
    BOOL doneMessageShown;
    __weak IBOutlet UITableView *questionTableView;
}

@property (nonatomic) int onboardingStatus;

- (IBAction)doneButtonPressed:(id)sender;
@end

@implementation WelcomeViewController
@synthesize data;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)_prepareData {
    if (![Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS]) {
        self.data = [NSMutableDictionary dictionary];
        [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:self.data];
    }
    else {
        self.data = (NSMutableDictionary *)[Utils getDefaultsForKey:
                DEFAULTS_ONBOARDING_ANSWERS];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self _prepareData];

    [self.navigationController.navigationBar setNeedsLayout];
    
    // using stepInOnboarding to detect the step 1 or step2
    NSDictionary *setting = [Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS];
    NSNumber *val = setting[SETTINGS_KEY_CURRENT_STATUS];
    self.onboardingStatus = [val intValue];
    
    [self _setDataProvider];
    
    questionTableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    questionTableView.backgroundColor = [self.variousPurposesDataProvider numberOfQuestions] % 2 == 0
            ? TABLECELL_INTERLACED_YELLOW
            : TABLECELL_INTERLACED_WHITE;
    if ([self.variousPurposesDataProvider navigationTitle]) {
        [((StepsNavigationItem*)self.navigationItem) setTitle:[self.variousPurposesDataProvider navigationTitle]];
    }
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 150)];
    questionTableView.tableFooterView = footer;
    
    // TODO, need change for log
    [self logPageImpression];
    
    StepsNavigationItem *navItem = (StepsNavigationItem *)self.navigationItem;
    if ([navItem isKindOfClass:[StepsNavigationItem class]]) {
        navItem.currentStep = self.stepInOnboarding;
        navItem.allSteps = [User currentUser] ? @(2) : @(3);
        [navItem redraw];
    }    
}

- (void)logPageImpression {
    int step = [self.stepInOnboarding intValue];
    switch (self.onboardingStatus) {
        case AppPurposesTTC:
            [Logging syncLog:(step == 1) ? PAGE_IMP_ONBOARDING_TTC_1 : PAGE_IMP_ONBOARDING_TTC_2 eventData:@{}];
            break;
        case AppPurposesTTCWithTreatment:
            [Logging syncLog:(step == 1) ? PAGE_IMP_ONBOARDING_TTC_TREATMENT_1 : PAGE_IMP_ONBOARDING_TTC_TREATMENT_2 eventData:@{}];
            break;
        default:
            [Logging syncLog:(step == 1) ? PAGE_IMP_ONBOARDING_NO_TTC_1 : PAGE_IMP_ONBOARDING_NO_TTC_2 eventData:@{}];
            break;
    }
}

- (void)_setDataProvider{
    self.variousPurposesDataProvider = [VariousPurposesDataProviderFactory
            generateOnboardingDataProviderAtStep:[self.stepInOnboarding integerValue]
            withReceiver:self
            storedAnser:self.data
            presenter:self];
    
    self.variousPurposesDataProvider.currentPurpose = self.onboardingStatus;
}

- (void)viewDidAppear:(BOOL)animated {

    [CrashReport leaveBreadcrumb:@"WelcomeViewController"];
    
    [self _checkDoneButtonStatusWithShowingMessage:NO];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"personInfo"] || [identifier isEqualToString:@"step1ToStep3"]) {
        User * u  = [User currentUser];
    
        if (u)
        {
            // NSDictionary *request = [Settings createPushRequestForNewUserWith:[Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS]];
//            GLLog(@"SAVED ONBOARDING DATA", request);
            [u updateOnboardingInfoWithCompletionHandler:^(NSError *e) {
                if (!e) {
                    if ([self.presentingViewController isKindOfClass:[TabbarController class]]) {
                        //Presenting from home
                        [self dismissViewControllerAnimated:YES completion:nil];
                        }
                    else {
                        [self presentViewController:[UIStoryboard main] animated:YES completion:nil];
                    }
                }
            }];
            return NO;
        }
    }
    return YES;
}

#pragma mark - done button
- (void)_checkDoneButtonStatusWithShowingMessage:(BOOL)showMsg {
    if ([self.variousPurposesDataProvider allAnswered]) {
        if (!doneMessageShown && showMsg) {
            [[DropdownMessageController sharedInstance] postMessage:@"Great Job! Click **Next** button to continue." duration:2.f inView:self.view];
            doneMessageShown = YES;
        }
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (IBAction)doneButtonPressed:(id)sender
{
    // avoid send duplicated request to server
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    if ([self shouldPerformSegueWithIdentifier:[self.variousPurposesDataProvider segueIdentifierToNextStep] sender:nil])
    {
        [self performSegueWithIdentifier:[self.variousPurposesDataProvider segueIdentifierToNextStep] sender:self from:self];
    }
}

#pragma mark - UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIndentifier = @"onboardingQuestionCell";
    BOOL hasAdditionalButton = [self.variousPurposesDataProvider hasAdditionalButtonForIndexPath:indexPath];
    if (hasAdditionalButton) {
        cellIndentifier = @"onboardingQuestionCellAdditionalButton";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifier];
        
    }
    
    UILinkLabel *title = (UILinkLabel*)[cell viewWithTag:TAG_CELL_TITLE];
    NSString *titleText = [self.variousPurposesDataProvider onboardingQuestionTitleForIndexPath:indexPath];
    CGSize size = [titleText boundingRectWithSize:CGSizeMake(CELL_TITLE_WIDTH, 10000.0f)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName: [Utils semiBoldFont:17]}
                                          context:nil].size;
    title.text = titleText;
    title.height = roundf(size.height);
    [Tooltip setCallbackForAllKeywordOnLabel:title];
    
    PillButton *button = (PillButton*)[cell viewWithTag:TAG_CELL_BUTTON];
    [button setLabelText:[self.variousPurposesDataProvider onboardingQuestionButtonTextForIndexPath:indexPath] bold:NO];
    button.assistant = cell;
    id answer = [self.variousPurposesDataProvider answerForIndexPath:indexPath];
    if (answer) {
        [button setSelected:YES];
    } else {
        button.selected = NO;
    }

    if (hasAdditionalButton) {
        PillButton *additionalButton = (PillButton*)[cell viewWithTag:TAG_CELL_ADDITIONAL_BUTTON];
        [additionalButton setLabelText:[self.variousPurposesDataProvider onboardingQuestionAdditionalButtonTextForIndexPath:indexPath] bold: NO];
        additionalButton.assistant = cell;
        additionalButton.hidden = NO;
        
        id additionalAnswer = [self.variousPurposesDataProvider additionalAnswerForIndexPath:indexPath];
        if (additionalAnswer) {
            [additionalButton setSelected:YES];
        } else {
            additionalButton.selected = NO;
        }
        
        UILabel *assistantInfo = (UILabel*)[cell viewWithTag:TAG_CELL_ASSISTANT_INFO];
        assistantInfo.text = [self.variousPurposesDataProvider assistantInfoForIndexPath:indexPath];
    }
    
    cell.hidden = NO;
    if ([self.variousPurposesDataProvider isKindOfClass:[OnboardingDataProviderTreatment class]]) {
        OnboardingDataProviderTreatment *provider = (OnboardingDataProviderTreatment *)self.variousPurposesDataProvider;
        if ([provider shouldHideQuestionAtIndexPath:indexPath]) {
            cell.hidden = YES;
        }
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.variousPurposesDataProvider isKindOfClass:[OnboardingDataProviderTreatment class]]) {
        OnboardingDataProviderTreatment *provider = (OnboardingDataProviderTreatment *)self.variousPurposesDataProvider;
        if ([provider shouldHideQuestionAtIndexPath:indexPath]) {
            return 0;
        }
    }
    
    BOOL hasAdditionalButton = [self.variousPurposesDataProvider hasAdditionalButtonForIndexPath:indexPath];
    NSString *titleText = [self.variousPurposesDataProvider onboardingQuestionTitleForIndexPath:indexPath];
    CGSize size = [titleText boundingRectWithSize:CGSizeMake(CELL_TITLE_WIDTH, 10000.0f)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName: [Utils semiBoldFont:17]} context:nil].size;
    CGFloat h = roundf(size.height) + 44;
    if (hasAdditionalButton) {
        h = MAX(h, CELL_HEIGHT_WITH_ADDITIONAL_BUTTON);
    }
    else {
        h = MAX(h, questionTableView.rowHeight);
    }
    return h;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.variousPurposesDataProvider numberOfQuestions];
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)path
{
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = TABLECELL_INTERLACED_YELLOW;
    }
    else {
        cell.backgroundColor = TABLECELL_INTERLACED_WHITE;
    }
}

#pragma mark - OnboardingDataReceiver protocol
- (void)onDataUpdatedIndexPath:(NSIndexPath *)indexPath
{
    if ([self.stepInOnboarding intValue] == 1) {
        if ([self.variousPurposesDataProvider isKindOfClass:[OnboardingDataProviderTreatment class]]) {
            StepsNavigationItem *navItem = (StepsNavigationItem *)self.navigationItem;
            if ([navItem isKindOfClass:[StepsNavigationItem class]]) {
                NSUInteger steps = [User currentUser] ? 2 : 3;
                if (navItem.allSteps.integerValue != steps) {
                    navItem.allSteps = @(steps);
                    [navItem redraw];
                }
            }
        }
    }
    
    [questionTableView reloadData];
    [self _checkDoneButtonStatusWithShowingMessage:YES];
    [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:self.variousPurposesDataProvider.storedAnswer];
}

#pragma mark - IBAction for buttons
- (IBAction)answerButtonTouchUpInside:(id)sender {
    UITableViewCell *cell = (UITableViewCell*)((PillButton*)sender).assistant;
    NSIndexPath *indexPath = [questionTableView indexPathForCell:cell];
    if (((UIView*)sender).tag == TAG_CELL_ADDITIONAL_BUTTON) {
        [self.variousPurposesDataProvider showAdditionalChoiceSelectorForIndexPath:indexPath];
    }
    else {
        [self.variousPurposesDataProvider showChoiceSelectorForIndexPath:indexPath];
    }
}

- (IBAction)backButtonClicked:(id)sender {
    if ([self.stepInOnboarding intValue] == 1) {
        [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:nil];
        //[[User currentUser] logout];
    }
    [self.navigationController popViewControllerAnimated:YES from:self];
}

@end
