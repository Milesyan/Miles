//
//  AddStatusHistoryView.m
//  emma
//
//  Created by ltebean on 15/6/23.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "AddStatusHistoryView.h"
#import "GLGeneralPicker.h"
#import "StatusHistoryDatePicker.h"
#import <GLPeriodEditor/GLDateUtils.h>
#import "UserStatusDataManager.h"

@interface AddStatusHistoryView()<DatePickerDelegate>

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (weak, nonatomic) IBOutlet UIButton *beginDateButton;
@property (weak, nonatomic) IBOutlet UIButton *endDateButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *hyphenLabel;
@property (nonatomic, strong) UserStatus *data;

@end

@implementation AddStatusHistoryView
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self load];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self load];
    }
    return self;
}

- (void)load
{
    [[NSBundle bundleForClass:[self class]] loadNibNamed:@"AddStatusHistoryView" owner:self options:nil];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.containerView.frame = self.bounds;
    [self addSubview: self.containerView];
    [self.saveButton setTitleColor:UIColorFromRGB(0xbbbbbb) forState:UIControlStateDisabled];
    
    [self setupToInitialLook];
}

- (void)setupToInitialLook
{
    self.containerView.backgroundColor = UIColorFromRGB(0xf1f1f1);
    
    [self.statusButton setTitle:@"Choose treatment" forState:UIControlStateNormal];
    [self.statusButton sizeToFit];
    
    [self.beginDateButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.beginDateButton sizeToFit];
    self.beginDateButton.hidden = YES;
    
    [self.endDateButton setTitle:@"End" forState:UIControlStateNormal];
    [self.endDateButton sizeToFit];
    self.endDateButton.hidden = YES;
    
    self.hyphenLabel.hidden = YES;

    self.saveButton.enabled = NO;
    self.data = [UserStatus new];
    self.data.status = STATUS_TREATMENT;
}

- (IBAction)statusButtonPressed:(id)sender {
    
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
        
        [self enableSaveButtonIfNecessary];
        self.beginDateButton.hidden = NO;
        self.endDateButton.hidden = NO;
        self.hyphenLabel.hidden = NO;
    } cancelCompletion:^(NSInteger row, NSInteger comp) {
        
    }];
}

- (void)enableSaveButtonIfNecessary
{
    if (self.data.status > 0 && self.data.startDate && self.data.endDate) {
        self.saveButton.enabled = YES;
    }
}

- (IBAction)beginDateButtonPressed:(id)sender
{
    [self showDatePickerWithType:TYPE_BEGIN_DATE date:self.data.startDate minimumDate:nil maximumDate:self.data.endDate];
}

- (IBAction)endDateButtonPressed:(id)sender
{
    [self showDatePickerWithType:TYPE_END_DATE date:self.data.endDate minimumDate:self.data.startDate maximumDate:nil];
}


- (IBAction)cancelButtonPressed:(id)sender {
    [self.delegate addStatusHistoryViewDidCancel:self];
}

- (IBAction)editButtonPressed:(id)sender {
    if ([self validateData]) {
        [self.delegate addStatusHistoryView:self didWantToAddStatusHistory:self.data];
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

- (void)showDatePickerWithType:(NSInteger)type date:(NSDate *)date minimumDate:(NSDate *)minimumDate maximumDate:(NSDate *)maximumDate
{
    StatusHistoryDatePicker *picker = [[StatusHistoryDatePicker alloc] initWithMinimumDate:minimumDate maximumDate:maximumDate];
    picker.delegate = self;
    picker.type = type;
    [picker present];
    if (type == TYPE_BEGIN_DATE) {
        picker.topLabel.text = @"Treatment start date";
    } else {
        picker.topLabel.text = @"Treatment end date";
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
    [self enableSaveButtonIfNecessary];
}

- (NSString *)textForDate:(NSDate *)date
{
    NSCalendarUnit flags = NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear;
    NSDateComponents *dateComponents = [[GLDateUtils calendar] components:flags fromDate:date];
    return [NSString stringWithFormat:@"%@ %ld", [GLDateUtils monthText:dateComponents.month], (long)dateComponents.day];
}




@end
