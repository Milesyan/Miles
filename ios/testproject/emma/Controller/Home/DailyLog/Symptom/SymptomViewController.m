//
//  SymptomViewController.m
//  emma
//
//  Created by Peng Gu on 7/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "SymptomViewController.h"
#import "SymptomTableViewCell.h"
#import "Utils.h"
#import "UserDailyData+Symptom.h"
#import "DailyLogUndoManager.h"
#import "Logging.h"
#import "User.h"


@interface SymptomViewController () <SymptomTableViewCellDelegate>

@property (nonatomic, strong) NSArray *sortedSymptomNames;
@property (nonatomic, strong) NSMutableDictionary *seletedSymptoms;
@property (nonatomic, strong) NSDictionary *symptomNamesMapping;

@property (nonatomic, assign) uint64_t currentSymptom1;
@property (nonatomic, assign) uint64_t currentSymptom2;

@property (nonatomic, strong) UILabel *intensityLabel;

@end


@implementation SymptomViewController

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
    
    SEL sortor = @selector(localizedCaseInsensitiveCompare:);
    
    if (self.symptomType == SymptomTypePhysical) {
        self.navigationItem.title = @"Physical";
        self.symptomNamesMapping = [[User currentUser] isMale] ? PhysicalSymptomNamesForMale : PhysicalSymptomNames;
        self.sortedSymptomNames = [self.symptomNamesMapping.allValues sortedArrayUsingSelector:sortor];
        
        NSNumber *valObj1 = [self.dailyLogUndoManager currentValueForKey:PHYSICAL_SYMPTOM_ONE_KEY];
        NSNumber *valObj2 = [self.dailyLogUndoManager currentValueForKey:PHYSICAL_SYMPTOM_TWO_KEY];
        
        if (valObj1 && !isNSNull(valObj1)) {
            self.currentSymptom1 = valObj1.unsignedLongLongValue;
        }
        else {
            self.currentSymptom1  = self.userDailyData.physicalSymptom1;
        }
        
        if (valObj2 && !isNSNull(valObj2)) {
            self.currentSymptom2= valObj2.unsignedLongLongValue;
        }
        else {
            self.currentSymptom2 = self.userDailyData.physicalSymptom2;
        }

    }
    else {
        self.navigationItem.title = @"Emotional";
        self.symptomNamesMapping = EmotionalSymptomNames;
        self.sortedSymptomNames = [self.symptomNamesMapping.allValues sortedArrayUsingSelector:sortor];
        NSNumber *valObj1 = [self.dailyLogUndoManager currentValueForKey:EMOTIONAL_SYMPTOM_ONE_KEY];
        NSNumber *valObj2 = [self.dailyLogUndoManager currentValueForKey:EMOTIONAL_SYMPTOM_TWO_KEY];
        
        if (valObj1 && !isNSNull(valObj1)) {
            self.currentSymptom1 = valObj1.unsignedLongLongValue;
        }
        else {
            self.currentSymptom1  = self.userDailyData.emotionalSymptom1;
        }
        
        if (valObj2 && !isNSNull(valObj2)) {
            self.currentSymptom2= valObj2.unsignedLongLongValue;
        }
        else {
            self.currentSymptom2 = self.userDailyData.emotionalSymptom2;
        }
    }
    
    self.seletedSymptoms = [[UserDailyData getSymptomsFromFieldOneValue:self.currentSymptom1
                                                          fieldTwoValue:self.currentSymptom2
                                                                   type:self.symptomType] mutableCopy];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.delegate respondsToSelector:@selector(symptomViewControllerDidAppear:)]) {
        [self.delegate symptomViewControllerDidAppear:self];
    }
    
    NSString *event = self.symptomType == SymptomTypePhysical ? PAGE_IMP_PHYSICAL_SYMPTOMS : PAGE_IMP_EMOTIONAL_SYMPTOMS;
    [Logging log:event];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
        
    [UserDailyData convertSymptomsToValues:self.seletedSymptoms
                                      type:self.symptomType
                                completion:^(uint64_t sympValue1, uint64_t sympValue2)
     {
         self.currentSymptom1 = sympValue1;
         self.currentSymptom2 = sympValue2;
         
         SEL delegateSel = @selector(symptomViewController:didUpdateSymptoms:fieldOneValue:fieldTwoValue:);
         if (self.delegate && [self.delegate respondsToSelector:delegateSel]) {
             [self.delegate symptomViewController:self
                                didUpdateSymptoms:self.seletedSymptoms
                                    fieldOneValue:[NSNumber numberWithUnsignedLongLong:sympValue1]
                                    fieldTwoValue:[NSNumber numberWithUnsignedLongLong:sympValue2]];
         }
         
     }];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sortedSymptomNames.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SymptomTableViewCell *cell = (SymptomTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"SymptomCell"
                                                                                        forIndexPath:indexPath];
    NSString *sympName = self.sortedSymptomNames[indexPath.row];
    
    NSNumber *sympIndex = [[self.symptomNamesMapping allKeysForObject:sympName] firstObject];
    NSNumber *intensityNumber = [self.seletedSymptoms objectForKey:sympIndex];
    SymptomIntensity intensity = intensityNumber ? [intensityNumber integerValue] : SymptomIntensityNone;
    
    [cell configureWithSymptomName:sympName
                       symptomType:self.symptomType
                         intensity:intensity
                          delegate:self];
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


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (!self.tableViewHeader) {
        return;
    }
    
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
    header.contentView.backgroundColor = [UIColor colorWithRed:90/255.0 green:98/255.0 blue:210/255.0 alpha:1.0];
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{    
    return self.tableViewHeader;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 66;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return self.tableViewHeader ? 25 : 0;
}


#pragma mark - Cell Delegate
- (void)SymptomTableViewCell:(SymptomTableViewCell *)cell didChangeSymptomIntensity:(SymptomIntensity)intensity
{
    NSString *sympName = cell.symptomLabel.text;
    NSNumber *symp = [[self.symptomNamesMapping allKeysForObject:sympName] firstObject];
    self.seletedSymptoms[symp] = @(intensity);
    
    if (intensity == SymptomIntensityNone) {
        [self.seletedSymptoms removeObjectForKey:symp];
    }
    
    // Logging the click
    NSString *clickType = intensity == SymptomIntensityNone ? CLICK_TYPE_YES_UNSELECT : CLICK_TYPE_YES_SELECT;
    NSNumber *time = @((int64_t)[self.userDailyData.nsdate timeIntervalSince1970]);
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:@{@"daily_time": time,
                                                                                @"click_type": clickType,
                                                                                @"intensity": @(intensity)}];
    
    NSString *buttonType = nil;
    if (self.symptomType == SymptomTypePhysical) {
        buttonType = BTN_CLK_HOME_PHYSICAL_SYMPTOM_TYPE;
        [data setObject:symp forKey:@"discomfort"];
    }
    else {
        buttonType = BTN_CLK_HOME_EMOTION_SYMPTOM_TYPE;
        [data setObject:symp forKey:@"emotion"];
    }
    
    [Logging log:buttonType eventData:data];
}


#pragma mark - actions
- (IBAction)backButtonPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}


@end
