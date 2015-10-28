//
//  MedicalLogViewController.m
//  emma
//
//  Created by Peng Gu on 10/16/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "MedicalLogViewController.h"
#import "StatusBarOverlay.h"
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <GLFoundation/GLGeneralPicker.h>

#import "MedicalLogDataController.h"
#import "MedicalLogNewMedCell.h"

#import "MedManager.h"
#import "MedListViewController.h"
#import "MedicineViewController.h"
#import "HealthProfileData.h"
#import "User.h"
#import "UserStatusDataManager.h"

#import <GLQuestionKit/GLQuestionCell.h>
#import <GLQuestionKit/GLYesOrNoQuestion.h>
#import <GLQuestionKit/GLPickerQuestion.h>
#import <GLQuestionKit/GLNumberQuestion.h>
#import <GLQuestionKit/GLDateQuestion.h>
#import <GLQuestionKit/GLQuestionEvent.h>

@interface MedicalLogViewController () <MedicineViewControllerDelegate, UIActionSheetDelegate, MedManagerDelegate, GLQuestionCellDelegate>

@property (nonatomic, weak) IBOutlet UIView *saveButtonContainer;
@property (nonatomic, strong) MedicalLogDataController *dataController;
@property (nonatomic, strong) NSArray *questions;
@property (nonatomic, strong) MedManager *medManager;
@property (nonatomic, strong) UserStatus *userStatus;

@end

@implementation MedicalLogViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.saveButtonContainer.width = SCREEN_WIDTH;

    [self.tableView registerNib:[UINib nibWithNibName:@"MedicalLogNewMedCell" bundle:nil] forCellReuseIdentifier:kMedItemAddMedication];
    [self.tableView registerNib:[UINib nibWithNibName:@"GLQuestionCell" bundle:nil] forCellReuseIdentifier:GLQuestionCellIdentifier];

    
    NSString *dateString = [Utils dailyDataDateLabel:self.selectedDate];
    self.dataController = [[MedicalLogDataController alloc] initWithDate:dateString];
    self.medManager = [[MedManager alloc] initWithDate:dateString];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.tableFooterView = [UIView new];
    self.userStatus = [[UserStatusDataManager sharedInstance] statusOnDate:[self.selectedDate toDateLabel] forUser:[User userOwnsPeriodInfo]];
    
    self.questions = self.dataController.questions;
}


- (void)viewWillAppear:(BOOL)animated
{
    // disable tableview auto-scrolling on iphone 4/4s 
    if (!IS_IPHONE_4) {
        [super viewWillAppear:animated];
    }
    self.title = [self.selectedDate toReadableDate];
    [self.tableView reloadData];
    [self updateSaveButton];
    [self subscribe:EVENT_GLQUESTION_BUTTON_CLICK selector:@selector(handleButtonClick:)];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_HOME_MEDICALLOG eventData:@{@"daily_time" : @((int64_t)[self.selectedDate timeIntervalSince1970])}];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unsubscribeAll];
    [self hideSaveButton];
}

- (void)handleButtonClick:(Event *)event
{
    if (!event) {
        return;
    }
    NSDictionary *eventData = (NSDictionary *)event.data;
    NSString *questionKey = eventData[@"key"];
    NSString *type = eventData[@"type"];
    NSString *value = eventData[@"value"];
    NSDictionary *data = @{
                           @"medical_log_name": questionKey,
                           @"click_type": type,
                           @"select_value": value ?: @"",
                           @"daily_time": @([self.selectedDate timeIntervalSince1970]),
                           @"additional_info": @""};
    [Logging log:BTN_CLK_MEDICAL_LOG_ITEM eventData:data];
}

#pragma mark - save button
- (void)updateSaveButton
{
    if (self.dataController.hasChanges || self.medManager.hasUpdatesForMedLogs) {
        [self showSaveButton];
    }
    else {
        [self hideSaveButton];
    }
}


- (void)showSaveButton
{
    if (self.saveButtonContainer.top == SCREEN_HEIGHT - self.saveButtonContainer.height) {
        return;
    }
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (![window.subviews containsObject:self.saveButtonContainer]) {
        [window addSubview:self.saveButtonContainer];
        [window bringSubviewToFront:self.saveButtonContainer];
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        self.saveButtonContainer.top = SCREEN_HEIGHT - self.saveButtonContainer.height;
    }];
}


- (void)hideSaveButton
{
    if (self.saveButtonContainer.top == SCREEN_HEIGHT) {
        return;
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        self.saveButtonContainer.top = SCREEN_HEIGHT;
    } completion:^(BOOL finished) {
    }];
}


- (IBAction)saveButtonPressed:(id)sender
{
    [Logging log:BTN_CLK_HOME_MEDICALLOG_SAVE];
    [self saveData];
}


- (void)saveData
{
    [self.dataController saveAllToModel];
    [self.medManager saveUpdatedMedLogs];
    [[User currentUser] save];
    [[User currentUser] pushToServer];
    
    [self publish:EVENT_MEDICAL_LOG_SAVED data:self.selectedDate];
    [self publish:EVENT_DAILY_LOG_EXIT];
    [self showStatusBar];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)exitWithoutChanges
{
    [Logging log:BTN_CLK_HOME_MEDICALLOG_BACK eventData:@{@"save": @NO}];
    [self publish:EVENT_DAILY_LOG_EXIT];
    [self.navigationController popViewControllerAnimated:YES];
    NSLog(@"exit medical log vc");
}


- (void)showStatusBar
{
    [[StatusBarOverlay sharedInstance] postMessage:@"Magic and science at work..."
                                           options:StatusBarShowSpinner | StatusBarShowProgressBar
                                          duration:5.0];
    [[StatusBarOverlay sharedInstance] setProgress:0.0 animated:NO];
    [[StatusBarOverlay sharedInstance] setProgress:0.7 animated:YES duration:0.5];
    
    [Utils performInMainQueueAfter:0.5 callback:^{
        [[StatusBarOverlay sharedInstance] setProgress:0.8 animated:YES duration:1.25];
    }];
    
    [Utils performInMainQueueAfter:2.0 callback:^{
        [[StatusBarOverlay sharedInstance] postMessage:@"Prediction updated!"
                                               options:StatusBarShowProgressBar
                                              duration:1.5];
        [[StatusBarOverlay sharedInstance] setProgress:1.0 animated:YES duration:0.25];
    }];
}


- (IBAction)backButtonPressed:(id)sender
{
    if (self.dataController.hasChanges) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Do you want to save your changes?"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:@"No, please discard"
                                                        otherButtonTitles:@"Yes, save my changes", nil];
        [actionSheet showInView:self.view];
    }
    else {
        [self exitWithoutChanges];
    }
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        
    }
    else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self exitWithoutChanges];
    }
    else {
        [Logging log:BTN_CLK_HOME_MEDICALLOG_BACK eventData:@{@"save": @YES}];
        [self saveData];
    }
}


#pragma mark - GLQuestionCell delegate

- (void)questionCell:(GLQuestionCell *)cell didUpdateAnswerToQuestion:(GLQuestion *)question
{
    [self updateSaveButton];
    NSLog(@"key:%@ val:%@", question.key, question.answer);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.questions.count;
    } else {
        return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0) {
        GLQuestionCell *cell = [tableView dequeueReusableCellWithIdentifier:GLQuestionCellIdentifier];
        cell.question = self.questions[indexPath.row];
        cell.outerTableView = self.tableView;
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    } else {
        GLQuestionCell *cell = [tableView dequeueReusableCellWithIdentifier:kMedItemAddMedication];
        NSInteger num = self.medManager.numberOfLogs;
        MedicalLogNewMedCell *medCell = (MedicalLogNewMedCell *)cell;
        NSString *text = num > 0 ? [NSString stringWithFormat:@"%ld logged", (long)num] : nil;
        medCell.numberOfLoggedLabel.text = text;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = UIColorFromRGB(0xFBFAF7);
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.width, 22)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, tableView.width, 22)];
    label.font = [Utils defaultFont:13];
    label.text = section == 0 ? [self.userStatus fullDescription] : @"Medication";
    header.backgroundColor = [UIColor colorWithRed:234/255.0 green:234/255.0 blue:234/255.0 alpha:1.0];
    [header addSubview:label];
    return header;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 22 ;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [GLQuestionCell heightForMainQuestion:self.questions[indexPath.row]];
    } else {
        return 70;
    }
}

 
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        [self performSegueWithIdentifier:@"MedListSegueIdentifier" sender:nil];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"MedListSegueIdentifier"]) {
        MedListViewController *vc = (MedListViewController *)segue.destinationViewController;
        vc.medManager = self.medManager;
        vc.date = self.medManager.date;
    }
}

@end