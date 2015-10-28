//
//  ChooseTreatmentViewController.m
//  emma
//
//  Created by Jirong Wang on 11/4/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ChooseTreatmentViewController.h"
#import "PillButton.h"
#import "User.h"
#import "HealthProfileData.h"
#import "TreatmentStartPicker.h"
#import "FontReplaceableBarButtonItem.h"
#import "NetworkLoadingView.h"
#import <BlocksKit/UIActionSheet+BlocksKit.h>

@interface TreatmentSettings : NSObject

@property (nonatomic) int64_t fertilityTreatment;
@property (nonatomic) NSString * treatmentStartdate;

@end

@implementation TreatmentSettings

- (id)init {
    self = [super init];
    if (self) {
        self.fertilityTreatment = FertilityTreatmentTypeMedications;
        self.treatmentStartdate = @"";
    }
    return self;
}

@end

@interface ChooseTreatmentViewController () <ExclusivePillButtonGroupDelegate, DatePickerDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentContainerIUI;
@property (weak, nonatomic) IBOutlet UIView *contentContainerIVF;

@property (weak, nonatomic) IBOutlet UILabel *labelWhenIUI;

@property (weak, nonatomic) IBOutlet UILabel *labelWhenIVF;

@property (weak, nonatomic) IBOutlet GroupedPillButton *chkButtonMed;
@property (weak, nonatomic) IBOutlet GroupedPillButton *chkButtonIUI;
@property (weak, nonatomic) IBOutlet GroupedPillButton *chkButtonIVF;

@property (weak, nonatomic) IBOutlet PillButton *buttonIUI;
@property (weak, nonatomic) IBOutlet PillButton *buttonIVF;

@property (weak, nonatomic) IBOutlet FontReplaceableBarButtonItem *saveButton;

- (IBAction)changeStartIUI:(id)sender;
- (IBAction)changeStartIVF:(id)sender;
- (IBAction)saveClicked:(id)sender;

@property (nonatomic) TreatmentSettings * originSettings;
@property (nonatomic) TreatmentSettings * currentSettings;

@property (nonatomic) ExclusivePillButtonGroup * checkButtons;
- (IBAction)backButtonPressed:(id)sender;

@end

@implementation ChooseTreatmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // set data model
    self.originSettings = [[TreatmentSettings alloc] init];
    self.currentSettings = [[TreatmentSettings alloc] init];
    User * u = [User currentUser];
    if (u) {
        self.originSettings.fertilityTreatment = u.settings.fertilityTreatment;
        self.originSettings.treatmentStartdate = [u.settings.treatmentStartdate copy];
        self.currentSettings.fertilityTreatment = u.settings.fertilityTreatment;
        self.currentSettings.treatmentStartdate = @"";
    }
    // set views based on model data
    [self setupViews];
}

- (void)setupViews {
    self.checkButtons = [[ExclusivePillButtonGroup alloc] init];
    [self.checkButtons addButton:self.chkButtonMed];
    [self.checkButtons addButton:self.chkButtonIUI];
    [self.checkButtons addButton:self.chkButtonIVF];
    self.checkButtons.delegate = self;
    
    self.chkButtonMed.selected = NO;
    self.chkButtonIUI.selected = NO;
    self.chkButtonIVF.selected = NO;
    if (self.originSettings.fertilityTreatment == FertilityTreatmentTypeMedications) {
        self.chkButtonMed.selected = YES;
    } else if (self.originSettings.fertilityTreatment == FertilityTreatmentTypeIUI) {
        self.chkButtonIUI.selected = YES;
    } else {
        self.chkButtonIVF.selected = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self redrawPage];
    
    if (self.popupStartPickerOnAppearing) {
        if (self.originSettings.fertilityTreatment == FertilityTreatmentTypeIUI) {
            [self.buttonIUI sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
        else if (self.originSettings.fertilityTreatment == FertilityTreatmentTypeIVF) {
            [self.buttonIVF sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_ME_TREATMENT_TYPE];
}

- (void)redrawPage {
    NSDate * shownDate = [self shownOriginalDate];
    NSDate * currentDate = nil;
    if ([Utils isNotEmptyString:self.currentSettings.treatmentStartdate]) {
        currentDate = [Utils dateWithDateLabel:self.currentSettings.treatmentStartdate];
    }
    
    if (self.currentSettings.fertilityTreatment == FertilityTreatmentTypeMedications) {
        self.contentContainerIUI.hidden = YES;
        self.contentContainerIVF.hidden = YES;
    } else if (self.currentSettings.fertilityTreatment == FertilityTreatmentTypeIUI) {
        self.contentContainerIUI.hidden = NO;
        self.contentContainerIVF.hidden = YES;
        
        if (!currentDate) {
            self.buttonIUI.selected = NO;
            NSString * tmp = shownDate ? [shownDate toReadableDate] : @"Choose";
            [self.buttonIUI setTitle:tmp forState:UIControlStateNormal];
            [self.buttonIUI setTitle:tmp forState:UIControlStateSelected];
            [self.buttonIUI setTitle:tmp forState:UIControlStateHighlighted];
        } else {
            self.buttonIUI.selected = YES;
            [self.buttonIUI setTitle:[currentDate toReadableDate] forState:UIControlStateSelected];
            [self.buttonIUI setTitle:[currentDate toReadableDate] forState:UIControlStateHighlighted];
        }
    } else {
        self.contentContainerIUI.hidden = YES;
        self.contentContainerIVF.hidden = NO;
        
        if (!currentDate) {
            self.buttonIVF.selected = NO;
            NSString * tmp = shownDate ? [shownDate toReadableDate] : @"Choose";
            [self.buttonIVF setTitle:tmp forState:UIControlStateNormal];
            [self.buttonIVF setTitle:tmp forState:UIControlStateSelected];
            [self.buttonIVF setTitle:tmp forState:UIControlStateHighlighted];
        } else {
            self.buttonIVF.selected = YES;
            [self.buttonIVF setTitle:[currentDate toReadableDate] forState:UIControlStateSelected];
            [self.buttonIVF setTitle:[currentDate toReadableDate] forState:UIControlStateHighlighted];
        }
    }
    [self checkDoneButton];
    
    [self.tableView reloadData];
}

- (NSDate *)shownOriginalDate {
    if ((self.originSettings.fertilityTreatment != FertilityTreatmentTypeMedications) &&
        (self.currentSettings.fertilityTreatment == self.originSettings.fertilityTreatment)) {
        return [Utils dateWithDateLabel:self.originSettings.treatmentStartdate];
    } else {
        return nil;
    }
}

- (void)checkDoneButton {
    self.saveButton.enabled = [self canSave];
}

- (BOOL)canSave {
    if (self.currentSettings.fertilityTreatment == FertilityTreatmentTypeMedications) {
        // if original is not Medical
        return (self.originSettings.fertilityTreatment != FertilityTreatmentTypeMedications);
    } else {
        // current treatmentStartDate is not null
        if ([Utils isNotEmptyString:self.currentSettings.treatmentStartdate]) {
            if ((self.currentSettings.fertilityTreatment == self.originSettings.fertilityTreatment) && ([self.originSettings.treatmentStartdate isEqualToString:self.currentSettings.treatmentStartdate])) {
                return NO;
            } else {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 86;
    } else if (indexPath.row == 1) {
        // IUI
        if (self.currentSettings.fertilityTreatment == FertilityTreatmentTypeIUI) {
            return 136;
        }
    } else {
        // IVF
        if (self.currentSettings.fertilityTreatment == FertilityTreatmentTypeIVF) {
            return 136;
        }
    }
    return 86;
}


#pragma mark - IBAction
- (IBAction)changeStartIUI:(id)sender {
    [self openDatePicker];
}

- (IBAction)changeStartIVF:(id)sender {
    [self openDatePicker];
}

- (IBAction)saveClicked:(id)sender {
    if (![self canSave]) {
        return;
    }
    [Logging log:BTN_CLK_TREATMENT_PAGE_SAVE];
    [self doSave];
}

- (IBAction)backButtonPressed:(id)sender {
    if (![self canSave]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        UIActionSheet *actionSheet = [UIActionSheet bk_actionSheetWithTitle:@"Do you want to save your changes?"];
        [actionSheet bk_setCancelButtonWithTitle:@"Cancel" handler:^{
        }];
        [actionSheet bk_setDestructiveButtonWithTitle:@"No, don’t save" handler:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [actionSheet bk_addButtonWithTitle:@"Yes, save my changes" handler:^{
            [self doSave];
        }];
        [actionSheet showInView:self.view];
    }
}

- (void)doSave {
    NSDictionary * savedSettings = @{
                                     SETTINGS_KEY_TREATMENT_TYPE : @(self.currentSettings.fertilityTreatment),
                                     SETTINGS_KEY_TREATMENT_STARTDATE : self.currentSettings.treatmentStartdate
                                     };
    [self.navigationController popViewControllerAnimated:NO];
    [self publish:EVENT_SWITCHING_PURPOSE_INFO_MADE_UP data:@{@"settings":savedSettings, @"target":@(AppPurposesTTCWithTreatment)}];
}

- (void)openDatePicker {
    TreatmentStartPicker * datePicker = [[TreatmentStartPicker alloc] init];
    datePicker.delegate = self;
    [datePicker present];
    if ([Utils isNotEmptyString:self.currentSettings.treatmentStartdate]) {
        NSDate * d = [Utils dateWithDateLabel:self.currentSettings.treatmentStartdate];
        [datePicker setDate:d];
    }
}

- (void)datePicker:(BaseDatePicker *)datePicker didDismissWithDate:(NSDate *)date {
    /*
     * We save string instead of date
     */
    self.currentSettings.treatmentStartdate = [date toDateLabel];
    if (([self.currentSettings.treatmentStartdate isEqualToString:self.originSettings.treatmentStartdate]) &&
        (self.currentSettings.fertilityTreatment == self.originSettings.fertilityTreatment)) {
        self.currentSettings.treatmentStartdate = @"";
    }
    [self redrawPage];
}

- (void)pillButtonDidChange:(GroupedPillButton *)button {
    if (button.selected == NO) {
        button.selected = YES;
    } else {
        if (button == self.chkButtonMed) {
            self.currentSettings.fertilityTreatment = FertilityTreatmentTypeMedications;
        } else if (button == self.chkButtonIUI) {
            self.currentSettings.fertilityTreatment = FertilityTreatmentTypeIUI;
        } else {
            self.currentSettings.fertilityTreatment = FertilityTreatmentTypeIVF;
        }
        self.currentSettings.treatmentStartdate = @"";
        [self redrawPage];
    }
}

@end
