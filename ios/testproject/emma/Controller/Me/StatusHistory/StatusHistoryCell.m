//
//  StatusCell.m
//  emma
//
//  Created by ltebean on 15/6/17.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "StatusHistoryCell.h"
#import <GLPeriodEditor/GLDateUtils.h>
#import "BaseDatePicker.h"
#import "StatusHistoryDatePicker.h"
#import "GLGeneralPicker.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "UserStatusDataManager.h"

@interface StatusHistoryCell()<DatePickerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *beginDateButton;
@property (weak, nonatomic) IBOutlet UIButton *endDateButton;
@property (nonatomic, strong) UserStatus *originalData;
@property (nonatomic) BOOL inEdit;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *optionButtons;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;

@end

@implementation StatusHistoryCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    [self subscribe:EVENT_HISTORY_CELL_DID_BEGIN_EDIT selector:@selector(cellDidBeginEdit:)];
    [self.editButton setTitleColor:UIColorFromRGB(0xbbbbbb) forState:UIControlStateDisabled];
}

- (void)didWantToDelete
{
    [self.delegate statusHistoryCell:self didWantToDeleteStatus:self.data];
}


- (void)cellDidBeginEdit:(Event *)event
{
    if (event.data != self && self.inEdit) {
        self.inEdit = NO;
        self.data = self.originalData;
    }
    [self hideDeleteButton];
}

- (void)setInEdit:(BOOL)inEdit
{
    _inEdit = inEdit;
    if (inEdit) {
        [self publish:EVENT_HISTORY_CELL_DID_BEGIN_EDIT data:self];
        for (UIButton *button in self.optionButtons) {
            [button setTitleColor:GLOW_COLOR_PURPLE forState:UIControlStateNormal];
            button.enabled = YES;
        }
        if (self.data.status != STATUS_PREGNANT) {
            [self.statusButton setTitleColor:GLOW_COLOR_PURPLE forState:UIControlStateNormal];
            self.statusButton.enabled = YES;
        } else {
            [self.statusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            self.statusButton.enabled = NO;
        }
        self.cancelButton.hidden = NO;
        [self.editButton setTitle:@"Save" forState:UIControlStateNormal];
        self.contentView.backgroundColor = UIColorFromRGB(0xf1f1f1);
    } else {
        for (UIButton *button in self.optionButtons) {
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.enabled = NO;
        }
        [self.statusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.statusButton.enabled = NO;
      
        self.cancelButton.hidden = YES;
        [self.editButton setTitle:@"Edit" forState:UIControlStateNormal];
        self.contentView.backgroundColor = [UIColor whiteColor];
    }
}

- (void)setData:(UserStatus *)data
{
    _data = [data copy];
    self.originalData = data;
    [self updateUI];
    self.inEdit = NO;
  
}

- (void)updateUI
{
    NSDate *beginDate = self.data.startDate;
    NSDate *endDate = self.data.endDate;


    NSString *beginDateText = [self textForDate:beginDate];
    [self.beginDateButton setTitle:beginDateText forState:UIControlStateNormal];
    [self.beginDateButton sizeToFit];
    if (endDate) {
        [self.endDateButton setTitle:[self textForDate:endDate] forState:UIControlStateNormal];
    } else {
        [self.endDateButton setTitle:@"unknown" forState:UIControlStateNormal];
    }
    [self.endDateButton sizeToFit];
    
    [self.statusButton setTitle:[self.data shortDescription] forState:UIControlStateNormal];
    [self.statusButton sizeToFit];
    
    if ([User currentUser].isSecondary) {
        self.editButton.enabled = NO;
    } else {
        self.editButton.enabled = YES;
    }
}

- (NSString *)textForDate:(NSDate *)date
{
    NSCalendarUnit flags = NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear;
    NSDateComponents *dateComponents = [[GLDateUtils calendar] components:flags fromDate:date];
    return [NSString stringWithFormat:@"%@ %ld", [GLDateUtils monthText:dateComponents.month], (long)dateComponents.day];
}

- (IBAction)statusButtonPressed:(id)sender
{
    NSArray *options = @[@(TREATMENT_TYPE_PREPARING), @(TREATMENT_TYPE_MED), @(TREATMENT_TYPE_IUI), @(TREATMENT_TYPE_IVF)];
    
    NSInteger selectedRow = [options indexOfObject:@(self.data.status)];
    
    NSMutableArray *rows = [NSMutableArray array];
    for (NSNumber *option in options) {
        [rows addObject:[UserStatus fullDescriptionForTreatmentType:[option integerValue]]];
    }
    
    [GLGeneralPicker presentCancelableSimplePickerWithTitle:@"Choose treatment type" rows:rows selectedRow:(int)selectedRow doneTitle:@"OK" showCancel:YES withAnimation:YES doneCompletion:^(NSInteger row, NSInteger comp) {
        self.data.treatmentType = [options[row] integerValue];
        [self.statusButton setTitle:[UserStatus shortDescriptionForTreatmentType:self.data.treatmentType] forState:UIControlStateNormal];
        [self.statusButton sizeToFit];
    } cancelCompletion:^(NSInteger row, NSInteger comp) {
        
    }];}

- (IBAction)beginDateButtonPressed:(id)sender
{
    [self showDatePickerWithType:TYPE_BEGIN_DATE date:self.data.startDate minimumDate:nil maximumDate:self.data.endDate];
}

- (IBAction)endDateButtonPressed:(id)sender
{
    [self showDatePickerWithType:TYPE_END_DATE date:self.data.endDate minimumDate:self.data.startDate maximumDate:nil];
}

- (IBAction)editButtonPressed:(id)sender {
    if (!self.inEdit) {
        self.inEdit = YES;
        return;
    } else {
        if ([self validateData]) {
            [self.delegate statusHistoryCell:self didUpdateStatus:self.originalData to:self.data];
        }
    }
}

- (BOOL)validateData
{
    if ([GLDateUtils daysBetween:self.data.startDate and:self.data.endDate] < 0) {
        [self showErrorMessage:@"Start date is later then end date"];
        return NO;
    }
    return YES;
}

- (void)showErrorMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}


- (IBAction)cancelButtonPressed:(id)sender
{
    self.inEdit = NO;
    self.data = self.originalData;
}


- (void)showDatePickerWithType:(NSInteger)type date:(NSDate *)date minimumDate:(NSDate *)minimumDate maximumDate:(NSDate *)maximumDate
{
    StatusHistoryDatePicker *picker = [[StatusHistoryDatePicker alloc] initWithMinimumDate:minimumDate maximumDate:maximumDate];
    picker.delegate = self;
    picker.type = type;
    if (self.data.status == STATUS_PREGNANT) {
        picker.view.height = 260;
    }
    [picker present];

    if (self.data.status == STATUS_PREGNANT) {
        picker.topLabel.text = @"";
        picker.descriptionLabel.font = [Utils defaultFont:16];
        picker.descriptionLabel.textColor = [UIColor blackColor];
        if (type == TYPE_BEGIN_DATE) {
            picker.descriptionLabel.text = @"Start date";
        } else {
            picker.descriptionLabel.text = @"End date";
        }
    } else {
        if (type == TYPE_BEGIN_DATE) {
            picker.topLabel.text = @"Treatment start date";
        } else {
            picker.topLabel.text = @"Treatment end date";
        }
    }
    [picker setDate:date];
}

- (void)datePicker:(StatusHistoryDatePicker *)picker didDismissWithDate:(NSDate *)date
{
    if (!date) {
        return;
    }
    NSString *text = [self textForDate:date];
    if (picker.type == TYPE_BEGIN_DATE) {
        self.data.startDate = date;
        [self.beginDateButton setTitle:text forState:UIControlStateNormal];
        [self.beginDateButton sizeToFit];
    } else {
        self.data.endDate = date;
        [self.endDateButton setTitle:text forState:UIControlStateNormal];
        [self.endDateButton sizeToFit];
    }
}

- (void)dealloc
{
    [self unsubscribeAll];
}
@end
