//
//  MedListViewController.m
//  emma
//
//  Created by Peng Gu on 1/7/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "MedListViewController.h"
#import "MedManager.h"
#import "MedicineViewController.h"
#import "MedListCell.h"
#import "UserMedicalLog.h"
#import "UserDailyData.h"
#import "UserStatusDataManager.h"
#import <GLQuestionKit/GLQuestionCell.h>
#import <GLQuestionKit/GLQuestionEvent.h>
#import <GLQuestionKit/GLYesOrNoQuestion.h>

@interface MedListViewController () <MedListCellDelegate, MedicineViewControllerDelegate, GLQuestionCellDelegate>

@property (nonatomic, copy) NSString *medBeingUpdated;
@property (nonatomic) BOOL isTreatment;
@property (nonatomic, strong) NSArray *defaultMedsQuestions;
@property (nonatomic, strong) NSArray *userAddedMedsQuestions;
@end


@implementation MedListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 66, 0);
    self.tableView.rowHeight = 66;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerNib:[UINib nibWithNibName:@"GLQuestionCell" bundle:nil] forCellReuseIdentifier:GLQuestionCellIdentifier];
}

- (void)setDate:(NSString *)date
{
    _date = [date copy];
    UserStatus *userStatus = [[UserStatusDataManager sharedInstance] statusOnDate:self.date forUser:[User userOwnsPeriodInfo]];
    self.isTreatment = [userStatus inTreatment];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)reloadData
{
    self.defaultMedsQuestions = [self questionWithMeds:self.medManager.defaultFertilityMeds titleColor:[UIColor blackColor]];
    self.userAddedMedsQuestions = [self questionWithMeds:self.medManager.userAddedMeds titleColor:GLOW_COLOR_PURPLE];
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSArray *)medsQuestionsInSection:(NSUInteger)section
{
    if (self.isTreatment) {
        return section == 0 ? self.defaultMedsQuestions :self.userAddedMedsQuestions;
    }
    else {
        return self.userAddedMedsQuestions;
    }
}

- (NSArray *)questionWithMeds:(NSArray *)meds titleColor:(UIColor *)color
{
    NSMutableArray *questions = [NSMutableArray array];
    for (NSString *med in meds) {
        GLYesOrNoQuestion *question = [GLYesOrNoQuestion new];
        question.title = med;
        question.key = med;
        NSInteger answer = [self.medManager.medLogs[med] integerValue];
        if (answer == kMedicalLogCheckValue) {
            question.answer = ANSWER_YES;
        } else if (answer == kMedicalLogCrossValue) {
            question.answer = ANSWER_NO;
        } else {
            question.answer = nil;
        }
        question.titleFont = [Utils defaultFont:16];
        question.titleColor = color;
        [questions addObject:question];
    }
    return questions;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.isTreatment ? 2 : 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger number = [[self medsQuestionsInSection:section] count];
    
    // Plus one "Add a new med / supplement" cell
    if (!self.isTreatment || section == 1) {
        number += 1;
    }
    return number;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (!self.isTreatment) {
        return nil;
    }
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.width, 22)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, tableView.width, 22)];
    label.font = [Utils defaultFont:13];
    label.text = section == 0 ? @"MEDICATION FOR FERTILITY TREATMENT" : @"OTHER MEDICATIONS";
    header.backgroundColor = [UIColor colorWithRed:234/255.0 green:234/255.0 blue:234/255.0 alpha:1.0];
    [header addSubview:label];
    return header;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return self.isTreatment ? 22 : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 68;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *questions = [self medsQuestionsInSection:indexPath.section];
    
    if (indexPath.row == questions.count) {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"NewMedCellReuseIdentifier"
                                                                     forIndexPath:indexPath];
        cell.backgroundColor = UIColorFromRGB(0xFBFAF7);
        return cell;
    }
    
    GLQuestionCell *cell = [tableView dequeueReusableCellWithIdentifier:GLQuestionCellIdentifier];
    cell.question = questions[indexPath.row];
    cell.outerTableView = self.tableView;
    cell.delegate = self;
    cell.userInteractionEnabled = YES;
    cell.backgroundColor = UIColorFromRGB(0xFBFAF7);
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // do not allow editing default meds in first section
    if (!self.isTreatment || indexPath.section == tableView.numberOfSections - 1) {
        NSArray *questions = [self medsQuestionsInSection:indexPath.section];
        self.medBeingUpdated = indexPath.row < questions.count ? [questions[indexPath.row] key] : nil;
        [self performSegueWithIdentifier:@"NewMedSegueIdentifier" sender:self];
    }
}

#pragma mark - GLQuestionCell delegate

- (void)questionCell:(GLQuestionCell *)cell didUpdateAnswerToQuestion:(GLQuestion *)question
{
    NSInteger value;
    if ([question.answer isEqualToString:ANSWER_YES]) {
        value = kMedicalLogCheckValue;
    } else if ([question.answer isEqualToString:ANSWER_NO]) {
        value = kMedicalLogCrossValue;
    } else {
        value = kMedicalLogNoneValue;
    }
    [self.medManager updateMedLog:question.key withValue:value];
}



#pragma mark - Cell delegate
- (void)medListCell:(MedListCell *)cell didUpdateValue:(NSInteger)value
{
    NSString *medName = cell.titleLabel.text;
    [self.medManager updateMedLog:medName withValue:value];
    NSLog(@"updated meds: %@", self.medManager.updatedMedLogs);
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"NewMedSegueIdentifier"]) {
        MedicineViewController *viewController = (MedicineViewController *)segue.destinationViewController;
        viewController.delegate = self;
        
        if (self.medBeingUpdated) {
            Medicine *med = [MedManager userMedWithName:self.medBeingUpdated];
            [viewController setModel:med];
            viewController.isEditingMedication = YES;
        }
        else {
            viewController.isEditingMedication = NO;
        }
    }
}


- (IBAction)backButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Medicine View Controller delegate

- (void)onConfirmDeleteMed:(NSString *)medName
{
    [self.medManager medDeleted:medName];
    [self reloadData];
}


- (void)medicineViewControllerDidAddNewMedicationWithName:(NSString *)medName
{
    [self.medManager medAdded:medName];
    [self reloadData];
}


- (void)medicineViewControllerDidUpdateMedicationWithName:(NSString *)medName
{
    [self.medManager med:self.medBeingUpdated updatedWithNewName:medName];
    [self reloadData];
}

@end






