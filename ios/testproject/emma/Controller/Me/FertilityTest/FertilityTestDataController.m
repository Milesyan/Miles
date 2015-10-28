//
//  FertilityTestDataController.m
//  emma
//
//  Created by Peng Gu on 7/9/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "FertilityTestDataController.h"
#import "FertilityTestItem.h"
#import "FertilityTest.h"
#import "FertilityTestInputCell.h"
#import "FertilityTestPickerCell.h"
#import "User.h"
#import "Tooltip.h"

#import <BlocksKit/NSDictionary+BlocksKit.h>
#import <BlocksKit/NSArray+BlocksKit.h>
#import <GLFoundation/GLGeneralPicker.h>
#import <GLFoundation/GLPickerViewController.h>


@interface FertilityTestDataController () <UITableViewDataSource, UITableViewDelegate, FertilityTestInputCellDelegate, FertilityTestPickerCellDelegate>

@property (nonatomic, strong) NSArray *infoItems;
@property (nonatomic, strong) NSArray *testItems;
@property (nonatomic, strong) NSArray *partnerItems;

@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic, assign) BOOL hasUpdates;

@end


@implementation FertilityTestDataController

- (instancetype)initWithTableView:(UITableView *)tableView onboarding:(BOOL)onboarding
{
    self = [super init];
    if (self) {
        _infoItems = [FertilityTestItem infoItems];
        _testItems = [FertilityTestItem testItems];
        _partnerItems = [FertilityTestItem partnerItems];
        
        _tableView = tableView;
        tableView.delegate = self;
        tableView.dataSource = self;
        
        _isOnboarding = onboarding;
        if (onboarding) {
            // get answers from onboarding defaults
            NSMutableDictionary *mutableAnswers = [NSMutableDictionary dictionary];
            NSDictionary *setting = [Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS];
            NSArray *keys = [_testItems bk_map:^id(id obj) {
                return [(FertilityTestItem *)obj testKey];
            }];
            for (NSString *each in setting) {
                if ([keys containsObject:each]) {
                    mutableAnswers[each] = setting[each];
                }
            }
            _answeredTests = mutableAnswers;
        }
    }
    return self;
}


- (FertilityTestItem *)fertilityTestItemAtIndexPath:(NSIndexPath *)indexpath
{
    if (self.isOnboarding) {
        return self.testItems[indexpath.row];
    }
    
    if (indexpath.section == 0) {
        return self.infoItems[indexpath.row];
    }
    else if (indexpath.section == 1) {
        return self.testItems[indexpath.row];
    }
    else {
        return self.partnerItems[indexpath.row];
    }
}


- (NSString *)testAnswerForItem:(FertilityTestItem *)item
{
    if (self.isOnboarding) {
        NSNumber *answer = self.answeredTests[item.testKey];
        if (!answer || answer.integerValue == 0) {
            return item.placeholderAnswerText;
        }
        else {
            return [FertilityTestItem descriptionForTestAnswer:answer.integerValue];
        }
    }
    
    return item.answer;
}


#pragma mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.isOnboarding ? 1 : 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isOnboarding) {
        return self.testItems.count;
    }
    
    if (section == 0) {
        return self.infoItems.count;
    }
    else if (section == 1) {
        return self.testItems.count;
    }
    else {
        return self.partnerItems.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FertilityTestItem *item = [self fertilityTestItemAtIndexPath:indexPath];
    NSString *answer = [self testAnswerForItem:item];
    
    if (item.isDoctorItem || item.isNurseItem) {
        FertilityTestInputCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FertilityTestingInputCell"
                                                                       forIndexPath:indexPath];
        [cell configureWithItem:item answer:answer];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
        return cell;
    }
    else {
        FertilityTestPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FertilityTestCellReuseIdentifier"
                                                                        forIndexPath:indexPath];
        [cell configureWithItem:item answer:answer];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
}


- (void)fertilityTestPickerCell:(FertilityTestPickerCell *)cell didClickQuestion:(FertilityTestItem *)item
{
    [Tooltip tip:item.question];
    
    NSDictionary *data = @{@"term": item.question, @"source": @"fertility workup"};
    [Logging log:BTN_CLK_FTGLOSSARY_TERMS eventData:data];
}


- (void)fertilityTestPickerCell:(FertilityTestPickerCell *)cell didClickAnswer:(FertilityTestItem *)item
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self showPickerForFertilityTestItem:item atIndexPath:indexPath];
    
    NSDictionary *data = @{@"question": item.testKey};
    [Logging log:BTN_CLK_FTWORKUP_SELECT_QUESTION eventData:data];
}


- (void)fertilityTestInputCell:(FertilityTestInputCell *)cell
                 didInputValue:(NSString *)value
                       forItem:(FertilityTestItem *)item
{
    [item saveInputResult:value];
    self.hasUpdates = YES;
    
    NSDictionary *data = @{@"question": item.testKey, @"answer": value};
    [Logging log:BTN_CLK_FTWORKUP_QUESTION_CHOOSE_ANSWER eventData:data];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.isOnboarding) {
        return nil;
    }
    
    if (section == 0) {
        return @"Info";
    }
    else if (section == 1) {
        return @"Your tests";
    }
    else if (section == 2) {
        return @"Your partner's tests";
    }
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.isOnboarding) {
        return 0;
    }

    return 32;
}


- (void)showPickerForFertilityTestItem:(FertilityTestItem *)item atIndexPath:(NSIndexPath *)indexPath
{
    NSArray *rows = item.isClinicItem ? [FertilityTestItem fertilityClinicOptions] : [FertilityTestItem testAnswerOptions];
    NSUInteger selectedRow = self.isOnboarding ? [self.answeredTests[item.testKey] integerValue] : item.answerIndex;
    
    if (selectedRow > rows.count - 1) {
        selectedRow = rows.count - 1;
    }
    
    [GLGeneralPicker presentCancelableSimplePickerWithTitle:item.question
                                                       rows:rows
                                                selectedRow:(int)selectedRow
                                                  doneTitle:@"Done"
                                                 showCancel:YES
                                              withAnimation:YES
                                             doneCompletion:^(NSInteger row, NSInteger comp)
    {
        if (row == selectedRow) {
            return;
        }
        
        if (self.isOnboarding) {
            NSMutableDictionary *mutableResutls = [self.answeredTests mutableCopy];
            mutableResutls[item.testKey] = @(row);
            self.answeredTests = mutableResutls;
        }
        else {
            if (item.isClinicItem && row == rows.count - 1) {
                row = FertilityClinicOther;
            }
            
            [item savePickerResult:row];
        }
        
        [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        self.hasUpdates = YES;
        
        NSDictionary *data = @{@"question": item.testKey, @"answer": @(row).stringValue};
        [Logging log:BTN_CLK_FTWORKUP_QUESTION_CHOOSE_ANSWER eventData:data];
        
    } cancelCompletion:^(NSInteger row, NSInteger comp) {
        
        NSDictionary *data = @{@"question": item.testKey};
        [Logging log:BTN_CLK_FTWORKUP_QUESTION_CHOOSE_CANCEL eventData:data];
    }];
}


- (BOOL)saveData
{
    if (!self.hasUpdates) {
        return NO;
    }
    
    if (self.isOnboarding) {
        NSMutableDictionary *setting = [[Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS] mutableCopy];
        for (NSString *key in self.answeredTests) {
            NSNumber *answer = self.answeredTests[key];
            if (answer && answer.integerValue > 0) {
                setting[key] = self.answeredTests[key];
            }
        }
        [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:setting];
    }
    else {
        [[User currentUser] save];
        [[User currentUser] pushToServer];
    }
    return YES;
}


- (NSInteger)numberOfAnsweredQuestions
{
    if (self.isOnboarding) {
        NSArray *anwers = self.answeredTests.allValues;
        return [anwers bk_reduceInteger:0 withBlock:^NSInteger(NSInteger result, id obj) {
            return result + ([(NSNumber *)obj integerValue] > 0 ? 1 : 0);
        }];
    }
    
    NSUInteger count = 0;
    count += [self.infoItems bk_reduceInteger:0 withBlock:^NSInteger(NSInteger result, id obj) {
        return result + ([(FertilityTestItem *)obj hasValue] ? 1 : 0);
    }];
    count += [self.testItems bk_reduceInteger:0 withBlock:^NSInteger(NSInteger result, id obj) {
        return result + ([(FertilityTestItem *)obj hasValue] ? 1 : 0);
    }];
    count += [self.partnerItems bk_reduceInteger:0 withBlock:^NSInteger(NSInteger result, id obj) {
        return result + ([(FertilityTestItem *)obj hasValue] ? 1 : 0);
    }];
    return count;
}


@end












