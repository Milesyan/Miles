//
//  FertilityTestViewController.m
//  emma
//
//  Created by Peng Gu on 7/9/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "FertilityTestViewController.h"
#import "FertilityTestDataController.h"
#import "StatusBarOverlay.h"
#import <GLQuestionKit/GLQuestionKit.h>
#import <GLQuestionKit/GLDateQuestionCell.h>
#import "User.h"
#import "NetworkLoadingView.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "StatusBarOverlay.h"
#import "Tooltip.h"

@interface FertilityTestViewController ()<GLQuestionCellDelegate>
@property (nonatomic, strong) NSArray *infoQuestions;
@property (nonatomic, strong) NSArray *testsQuestions;
@property (nonatomic, strong) NSArray *partnerTestsQuestions;
@property (nonatomic, strong) NSMutableArray *mainQuestions;
@property (strong, nonatomic) IBOutlet UIView *saveButtonContainer;
@property (nonatomic) BOOL pulled;
@end


@implementation FertilityTestViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.hidesBottomBarWhenPushed = YES;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = UIColorFromRGB(0xFBFAF7);
    
    self.saveButtonContainer.width = SCREEN_WIDTH;
    self.saveButtonContainer.top = SCREEN_HEIGHT;

    [self.tableView registerNib:[UINib nibWithNibName:@"GLQuestionCell" bundle:nil] forCellReuseIdentifier:GLQuestionCellIdentifier];
    
    [Logging log:PAGE_IMP_ME_FERTILITY_TESTING];
    
    self.infoQuestions = @[
        self.clinic,
        self.doctor,
        self.nurse
    ];
    
    self.testsQuestions = @[
        self.cycleDayThreeBloodWork,
        self.otherBloodTests,
        self.vaginalUltrasound,
        self.hysterosalpingogram,
        self.geneticScreening,
        self.salineSonogram,
        self.ovarianReserveTesting,
        self.mammogram,
        self.papsmear
    ];
    
    self.partnerTestsQuestions = @[
        self.semenAnalysis,
        self.infectiousDiseaseBloodTest,
        self.partnerGeneticScreening
    ];
    
    self.mainQuestions = [NSMutableArray array];
    
    [self.mainQuestions addObjectsFromArray:self.infoQuestions];
    [self.mainQuestions addObjectsFromArray:self.testsQuestions];
    [self.mainQuestions addObjectsFromArray:self.partnerTestsQuestions];

//    for (GLQuestion *question in self.testsQuestions) {
//        question.highlightTerms = @[question.title];
//    }
}

- (void)viewDidAppear:(BOOL)animated
{
    
    [super viewDidAppear:animated];
    
    [NetworkLoadingView showWithoutAutoClose];
    [[User currentUser] pullFertilityTests:^(BOOL success, NSArray *data) {
        self.pulled = YES;
        [NetworkLoadingView hide];
        if (success) {
            [self reloadWithData:data];
        } else {
            [UIAlertView bk_showAlertViewWithTitle:@"Sorry, we're unable to fetch your fertility treatment tests result due to a poor connection." message:nil cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
    }];
    
    [self subscribe:EVENT_GLQUESTION_TERM_CLICK selector:@selector(termClicked:)];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self hideSaveButton];
    [self unsubscribeAll];
}

- (void)termClicked:(Event *)event
{
    NSString *term = (NSString *)event.data;
    [Tooltip tip:term];
}

- (void)reloadWithData:(NSArray *)data
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSDictionary *test in data) {
        dict[test[@"test_key"]] = test[@"test_val"];
    }
    [self enumerateAllQuestions:^(GLQuestion *question) {
        [self setQuestion:question answerTo:dict[question.key]];
    }];
    [self.tableView reloadData];
}

- (void)pushToServer
{
    NSMutableArray *data = [NSMutableArray array];
    [self enumerateAllQuestions:^(GLQuestion *question) {
        if (question.answer) {
            [data addObject:[self dictWithQuestion:question]];
        }
    }];
    [NetworkLoadingView showWithoutAutoClose];
    [[User currentUser] pushFertilityTests:data completion:^(BOOL success) {
        [NetworkLoadingView hide];
        if (success) {
            [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
            [self hideSaveButton];
        } else {
            [UIAlertView bk_showAlertViewWithTitle:@"Failed to update data" message:nil cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            }];
        }
    }];
}

- (void)setQuestion:(GLQuestion *)question answerTo:(id)answer
{
    if (!answer) {
        question.answer = nil;
        return;
    }
    if ([question isKindOfClass:[GLDateQuestion class]]) {
        question.answer = [NSString stringWithFormat:@"%.f", [[Utils dateWithDateLabel:answer] timeIntervalSince1970]];
    }
    else if ([question isKindOfClass:[GLPickerQuestion class]]) {
        question.answer = [(NSNumber *)answer stringValue];
    }
    else if ([question isKindOfClass:[GLNumberQuestion class]]) {
        question.answer = [(NSNumber *)answer stringValue];
    }
    else {
        question.answer = answer;
    }
}

- (NSDictionary *)dictWithQuestion:(GLQuestion *)question
{
    id val;
    NSString *answer = question.answer;
    if ([question isKindOfClass:[GLDateQuestion class]]) {
        val = answer ? [[NSDate dateWithTimeIntervalSince1970:[answer integerValue]] toDateLabel] : @"";
    }
    else if ([question isKindOfClass:[GLPickerQuestion class]]) {
        val = answer ? @([answer integerValue]) : @(0);
    }
    else if ([question isKindOfClass:[GLNumberQuestion class]]) {
        val = answer ? @([answer floatValue]) : @(0);
    }
    else {
        val = answer;
    }
    return @{@"test_key": question.key, @"test_val": val};
}

- (void)enumerateAllQuestions:(void(^)(GLQuestion *))block
{
    for (GLQuestion *question in self.mainQuestions) {
        block(question);
        [question enumerateSubQuestions:^(GLQuestion *subQuestion) {
            block(subQuestion);
        }];
    }
}

#pragma mark - question definition

- (GLQuestion *)clinic
{
    GLPickerQuestion *question = [GLPickerQuestion new];
    question.key = @"fertility_clinic";
    question.title = @"Who are you seeing?";
    question.optionTitles = @[
        @"No one",
        @"Primary care/other doctor",
        @"OB/GYN",
        @"Boston IVF",
        @"Shady Grove Fertility",
        @"RMA of New York",
        @"other fertility clinic"
    ];
    question.optionValues = @[@"1", @"2", @"3", @"4", @"5", @"6", @"100"];
    question.pickerTitle = @"Who are you seeing?";
    return question;
}

- (GLQuestion *)doctor
{
    GLTextInputQuestion *question = [GLTextInputQuestion new];
    question.key = @"doctor_name";
    question.title = @"Doctor";
    question.placeholderText = @"Enter doctor's name";
    return question;
}

- (GLQuestion *)nurse
{
    GLTextInputQuestion *question = [GLTextInputQuestion new];
    question.key = @"nurse_name";
    question.title = @"Nurse";
    question.placeholderText = @"Enter nurse's name";
    return question;
}

- (GLQuestion *)cycleDayThreeBloodWork
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"cycle_day_three_blood_work";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Cycle day 3 blood work";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;
    
    GLNumberQuestion *e2 = [GLNumberQuestion new];
    e2.key = @"cycle_day_three_blood_work_e2";
    e2.padType = DECIMAL_PAD;
    e2.title = @"E2 (Estrogen)";
    e2.unitList = @[[GLUnit unitWithName:@"pg/mL" weight:1]];
    
    GLNumberQuestion *fsh = [GLNumberQuestion new];
    fsh.key = @"cycle_day_three_blood_work_fsh";
    fsh.padType = DECIMAL_PAD;
    fsh.title = @"FSH (Follicle Stimulating Hormone)";
    fsh.unitList = @[[GLUnit unitWithName:@"mIU/mL" weight:1]];

    GLNumberQuestion *lh = [GLNumberQuestion new];
    lh.key = @"cycle_day_three_blood_work_lh";
    lh.padType = DECIMAL_PAD;
    lh.title = @"LH (Leutinizing Hormone)";
    lh.unitList = @[[GLUnit unitWithName:@"mIU/mL" weight:1]];

    
    GLNumberQuestion *prl = [GLNumberQuestion new];
    prl.key = @"cycle_day_three_blood_work_prl";
    prl.padType = DECIMAL_PAD;
    prl.title = @"PRL (Prolactin)";
    prl.unitList = @[[GLUnit unitWithName:@"ng/mL" weight:1]];

    GLNumberQuestion *tsh = [GLNumberQuestion new];
    tsh.key = @"cycle_day_three_blood_work_tsh";
    tsh.padType = DECIMAL_PAD;
    tsh.title = @"TSH (Thyroid Stimulating Hormone)";
    tsh.unitList = @[[GLUnit unitWithName:@"uIU/mL" weight:1]];

    question.subQuestions = @[@[e2, fsh, lh, prl, tsh]];
    return question;
}

- (GLQuestion *)otherBloodTests
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"other_blood_tests";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Other blood tests";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;
    
    GLNumberQuestion *amh = [GLNumberQuestion new];
    amh.key = @"other_blood_tests_amh";
    amh.padType = DECIMAL_PAD;
    amh.title = @"AMH (Antimullarian Hormone)";
    
    GLPickerQuestion *disease = [GLPickerQuestion new];
    disease.key = @"other_blood_tests_infectious_disease";
    disease.title = @"Infectious Disease";
    disease.pickerTitle = @"Result";
    disease.optionTitles = @[@"Normal", @"Abnormal"];
    disease.optionValues = @[@"1", @"2"];
    
    question.subQuestions = @[@[amh, disease]];
    return question;
}

- (GLQuestion *)vaginalUltrasound
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"vaginal_ultrasound";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Vaginal ultrasound";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;
    
    GLNumberQuestion *count = [GLNumberQuestion new];
    count.key = @"vaginal_ultrasound_antral_follicle_count";
    count.title = @"Antral follicle count";
    
    GLNumberQuestion *lining = [GLNumberQuestion new];
    lining.key = @"vaginal_ultrasound_lining";
    lining.padType = DECIMAL_PAD;
    lining.title = @"Lining";
    lining.unitList = @[[GLUnit unitWithName:@"mm" weight:1]];

    question.subQuestions = @[@[count, lining]];
    return question;
}

- (GLQuestion *)hysterosalpingogram
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"hysterosalpingogram";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Hysterosalpingogram";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;
    
    GLPickerQuestion *result = [GLPickerQuestion new];
    result.key = @"hysterosalpingogram_result";

    result.title = @"Result";
    result.pickerTitle = @"Result";
    result.optionTitles = @[@"Normal", @"Abnormal"];
    result.optionValues = @[@"1", @"2"];
    
    question.subQuestions = @[@[result]];
    return question;
}

- (GLQuestion *)geneticScreening
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"genetic_screening";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Genetic testing";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;
    
    GLPickerQuestion *result = [GLPickerQuestion new];
    result.key = @"genetic_screening_result";
    result.title = @"Result";
    result.pickerTitle = @"Result";
    result.optionTitles = @[@"Normal", @"Abnormal"];
    result.optionValues = @[@"1", @"2"];
    
    question.subQuestions = @[@[result]];
    return question;
}

- (GLQuestion *)salineSonogram
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"saline_sonogram";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Saline sonohysterogram";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;
    
    GLPickerQuestion *result = [GLPickerQuestion new];
    result.key = @"saline_sonogram_result";
    result.title = @"Result";
    result.pickerTitle = @"Result";
    result.optionTitles = @[@"Normal", @"Abnormal"];
    result.optionValues = @[@"1", @"2"];
    
    question.subQuestions = @[@[result]];
    return question;
}

- (GLQuestion *)ovarianReserveTesting
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"ovarian_reserve_testing";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Ovarian reserve testing";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;    
    
    GLPickerQuestion *result = [GLPickerQuestion new];
    result.key = @"ovarian_reserve_testing_result";
    result.title = @"Result";
    result.pickerTitle = @"Result";
    result.optionTitles = @[@"Good (11 and above)", @"Fair (6-10)", @"Reduced (1-5)"];
    result.optionValues = @[@"1", @"2", @"3"];
    
    question.subQuestions = @[@[result]];
    return question;
}

- (GLQuestion *)papsmear
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"papsmear";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Pap smear";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;
    
    GLPickerQuestion *result = [GLPickerQuestion new];
    result.key = @"papsmear_result";
    result.title = @"Result";
    result.pickerTitle = @"Result";
    result.optionTitles = @[@"Normal", @"Abnormal"];
    result.optionValues = @[@"1", @"2"];
    
    question.subQuestions = @[@[result]];
    return question;
}

- (GLQuestion *)mammogram
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"mammogram";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Mammogram (Age > 40)";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;    
    
    GLPickerQuestion *result = [GLPickerQuestion new];
    result.key = @"mammogram_result";
    result.title = @"Result";
    result.pickerTitle = @"Result";
    result.optionTitles = @[@"Normal", @"Abnormal"];
    result.optionValues = @[@"1", @"2"];
    
    question.subQuestions = @[@[result]];
    return question;
}

- (GLQuestion *)semenAnalysis
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"partner_semen_analysis";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Semen analysis";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;
    
    GLNumberQuestion *volume = [GLNumberQuestion new];
    volume.key = @"partner_semen_analysis_volume";
    volume.padType = DECIMAL_PAD;
    volume.title = @"Volume";
    volume.unitList = @[[GLUnit unitWithName:@"cc" weight:1]];

    
    GLNumberQuestion *concentration = [GLNumberQuestion new];
    concentration.key = @"partner_semen_analysis_concentration";
    concentration.padType = DECIMAL_PAD;
    concentration.title = @"Concentration";
    concentration.unitList = @[[GLUnit unitWithName:@"million sperm/ml" weight:1]];

    GLNumberQuestion *motility = [GLNumberQuestion new];
    motility.key = @"partner_semen_analysis_motility";
    motility.padType = DECIMAL_PAD;
    motility.title = @"Motility";
    motility.unitList = @[[GLUnit unitWithName:@"%" weight:1]];

    GLPickerQuestion *morphology = [GLPickerQuestion new];
    morphology.key = @"partner_semen_analysis_morphology";
    morphology.title = @"Morphology";
    morphology.pickerTitle = @"Result";
    morphology.optionTitles = @[@"Normal", @"Abnormal"];
    morphology.optionValues = @[@"1", @"2"];
    
    question.subQuestions = @[@[volume, concentration, motility, morphology]];
    return question;
}

- (GLQuestion *)infectiousDiseaseBloodTest
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"partner_infectious_disease_blood_test";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Infectious disease blood test";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;
    
    GLPickerQuestion *result = [GLPickerQuestion new];
    result.key = @"partner_infectious_disease_blood_test_result";
    result.title = @"Result";
    result.pickerTitle = @"Result";
    result.optionTitles = @[@"Normal", @"Abnormal"];
    result.optionValues = @[@"1", @"2"];
    
    question.subQuestions = @[@[result]];
    return question;
}

- (GLQuestion *)partnerGeneticScreening
{
    GLDateQuestion *question = [GLDateQuestion new];
    question.key = @"partner_genetic_screening";
    question.showSubQuestionsWhenAnswered = YES;
    question.title = @"Genetic testing";
    question.pickerTitle = @"When";
    question.showInfoButton = YES;
    
    GLPickerQuestion *result = [GLPickerQuestion new];
    result.key = @"partner_genetic_screening_result";
    result.title = @"Result";
    result.pickerTitle = @"Result";
    result.optionTitles = @[@"Normal", @"Abnormal"];
    result.optionValues = @[@"1", @"2"];
    
    question.subQuestions = @[@[result]];
    return question;
}



#pragma mark - GLQuestionCell delegate

- (void)questionCell:(GLQuestionCell *)cell didUpdateAnswerToQuestion:(GLQuestion *)question
{
    __block BOOL modified = NO;
    [self enumerateAllQuestions:^(GLQuestion *question) {
        if (question.modified) {
            modified = YES;
        }
    }];
    if (modified) {
        [self showSaveButton];
    } else {
        [self hideSaveButton];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.infoQuestions.count;
    }
    else if (section == 1) {
        return self.testsQuestions.count;
    }
    else if (section == 2) {
        return self.partnerTestsQuestions.count;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    GLQuestionCell *cell = [tableView dequeueReusableCellWithIdentifier:GLQuestionCellIdentifier];
    cell.outerTableView = self.tableView;
    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 0) {
        cell.question = self.infoQuestions[indexPath.row];
    }
    else if (indexPath.section == 1) {
        cell.question = self.testsQuestions[indexPath.row];
    }
    else if (indexPath.section == 2) {
        cell.question = self.partnerTestsQuestions[indexPath.row];
    }
    return cell;
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
    if (section == 0) {
        return [self headerViewWithText:@"INFO"];
    }
    else if (section == 1) {
        return [self headerViewWithText:@"YOUR TESTS"];
    }
    else if (section == 2) {
        return [self headerViewWithText:@"YOUR PARTNER'S TESTS"];
    }
    return nil;
}

- (UIView *)headerViewWithText:(NSString *)text
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.width, 22)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.tableView.width, 22)];
    label.font = [Utils defaultFont:13];
    label.text = text;
    header.backgroundColor = [UIColor colorWithRed:234/255.0 green:234/255.0 blue:234/255.0 alpha:1.0];
    [header addSubview:label];
    return header;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 22;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [GLQuestionCell heightForMainQuestion:self.infoQuestions[indexPath.row]];
    }
    else if (indexPath.section == 1) {
        return [GLQuestionCell heightForMainQuestion:self.testsQuestions[indexPath.row]];
    }
    else if (indexPath.section == 2) {
        return [GLQuestionCell heightForMainQuestion:self.partnerTestsQuestions[indexPath.row]];
    }
    return 0;
}


- (void)showSaveButton
{
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
    [UIView animateWithDuration:0.2f animations:^{
        self.saveButtonContainer.top = SCREEN_HEIGHT;
    } completion:^(BOOL finished) {
        [self.saveButtonContainer removeFromSuperview];
    }];
}

- (IBAction)saveButtonPressed:(id)sender {
    [self pushToServer];
}


@end
