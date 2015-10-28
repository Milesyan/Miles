//
//  ReminderDetailViewController.m
//  emma
//
//  Created by Eric Xu on 7/23/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ReminderDetailViewController.h"
#import "AlarmPickerController.h"
#import "User.h"
#import "Logging.h"
#import <GLFoundation/GLGeneralPicker.h>
#import "MedManager.h"
#import "DropdownMessageController.h"
#import "Reminder.h"
#import "NetworkLoadingView.h"
#import "Appointment.h"
#import <SZTextView.h>

#define AC_TAG_DELETE 1
#define AC_TAG_CONFIRM 2


#define USERDEFAULTS_REMINDER_DETAIL_DEBUT @"reminder_detail_first_show"

@interface FrequencyPicker : NSObject<GLGeneralPickerDelegate, GLGeneralPickerDataSource>
{
    Callback doneCb;
}
@property (nonatomic) GLGeneralPicker *picker;

- (void)presentWithSelectedRows:(NSArray *)rows andDoneCallback:(Callback)cb;

@end

@implementation FrequencyPicker

- (id)init {
    self = [super init];
    if (self) {
        self.picker = [GLGeneralPicker picker];
        self.picker.delegate = self;
        self.picker.datasource = self;
        [self.picker setShowStartOverButton:NO];
        [self.picker updateTitle:@"Frequency"];
    }
    return self;
}

- (void)doneButtonPressed {
    if (doneCb) {
        doneCb([self.picker selectedRowInComponent:0], [self.picker selectedRowInComponent:1]);
    }
    
    [self.picker dismiss];
}

- (void)presentWithSelectedRows:(NSArray *)rows andDoneCallback:(Callback)cb {
    doneCb = cb;
    self.picker.datasource = self;
    self.picker.delegate = self;
    [self.picker present];
    [self.picker selectRow:[rows[0] intValue] inComponent:0];
    [self.picker selectRow:[rows[1] intValue] inComponent:1];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if (component == 0)
        return 50;
    else
        return 120;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        return 7;
    } else {
        return 4;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @[@[@"1",@"2",@"3",@"4",@"5",@"6",@"7"],
             @[@"no repeat", @"daily", @"weekly", @"monthly"]][component][row];
}

@end


@interface ReminderDetailViewController () <UIActionSheetDelegate, UITextFieldDelegate> {
    BOOL changed;
    BOOL showMed;
    ReminderSavedCallback savedCallback;
    ReminderDeletedCallback deletedCallback;
    NSString *medForm;
    FrequencyPicker *fp;
}

- (void)changeTimeForTimer:(NSInteger)timerIndex;
- (void)changeFrequency;

- (IBAction)backButtonPressed:(id)sender;
- (IBAction)doneButtonPressed:(id)sender;

// reminder variables
@property (strong, nonatomic) NSString *uuid;
@property (strong, nonatomic) NSString *reminderTitle;
@property (strong, nonatomic) NSString *reminderNote;
@property (nonatomic) int64_t reminderType;
// @property (nonatomic) BOOL isAppt;
@property (nonatomic) BOOL on;
@property (nonatomic) BOOL canEditTitle;
@property (nonatomic) BOOL canEditRepeat;
@property (nonatomic) BOOL canDelete;

// we have repeatWay in "*.h" file
@property (nonatomic) NSInteger frequency;
@property (nonatomic) NSInteger medPerTake;
@property (nonatomic, strong) NSString *medPerTakeUnit;
@property (nonatomic, strong) NSArray *whenList;
// @property (strong, nonatomic) NSDate *whenDate;

// IBOutlet
@property (strong, nonatomic) IBOutlet UILabel *repeatLabel;
@property (strong, nonatomic) IBOutlet UILabel *medTakeLabel;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *whenListLabels;
@property (strong, nonatomic) IBOutlet UILabel *time1Label;
@property (strong, nonatomic) IBOutlet UITextField *reminderTitleField;
@property (weak, nonatomic) IBOutlet SZTextView *reminderNoteView;
@property (strong, nonatomic) IBOutlet UIView *deleteButtonView;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;

@property (strong, nonatomic) IBOutlet UISwitch *active;

@property (strong, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;


- (IBAction)tapped:(id)sender;
- (IBAction)onDelete:(id)sender;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *cellRightViews;


@end

@implementation ReminderDetailViewController

static AlarmPickerController *alarmPickerController = nil;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setModel:(Reminder *)model {
//    _model = model;
    // before calling this function, "isAppointment" should be set
    if (model) {
        _uuid            = model.uuid;
        _reminderTitle   = model.title;
        _reminderNote    = model.note;
        _reminderType    = model.type;
        // _isAppt          = model.isAppt;
        _canEditTitle    = !(model.flags & REMINDER_FLAG_LOCK_TITLE);
        _canEditRepeat   = !(model.flags & REMINDER_FLAG_LOCK_REPEAT);
        _canDelete       = !(model.flags & REMINDER_FLAG_LOCK_DELETE);
        _on              = model.on;
        _repeatWay       = model.repeat;
        _frequency       = model.frequency;
        _medPerTake      = model.medPerTake;
        _medPerTakeUnit  = model.medPerTakeUnit;
        _whenList        = [model startDateList];
        if (self.isAppointment) {
            self.navigationItem.title = @"Appointment detail";
        } else {
            self.navigationItem.title = @"Reminder detail";
        }
    } else {
        // add a reminder
        if (self.isAppointment) {
            _canEditRepeat = NO;
            self.navigationItem.title = @"Appointment";
        } else {
            _canEditRepeat = YES;
            self.navigationItem.title = @"Reminder";
        }
        _uuid            = nil;
        _canEditTitle    = YES;
        _canDelete       = NO;
        _frequency     = 1;
        _repeatWay     = REPEAT_NO;
        _medPerTake    = 0;
        _reminderTitle   = @"";
        _reminderNote    = @"";
    }
}

- (void)setMedicineForm:(NSString *)form {
    medForm = form;
}

- (void)setMedicineName:(NSString *)medName andForm:(NSString *)form {
    _reminderTitle = [NSString stringWithFormat:@"Take %@", medName];
    medForm = form;
    _medPerTake = 1;
    _medPerTakeUnit = [MedManager unitOfPerTakeForForm:form withPlural:NO];
}

- (void)setShowMed:(BOOL)show {
    showMed = show;
}
- (void)setPrefilledTitle:(NSString *)title {
    _reminderTitle = title;
}

- (void)setReminderSavedCallback:(ReminderSavedCallback)cb {
    savedCallback = cb;
}

- (void)setReminderDeletedCallback:(ReminderDeletedCallback)cb {
    deletedCallback = cb;
}

- (void)setRepeatWay:(REPEAT)repeatWay {
    _repeatWay = repeatWay;
    changed = YES;
    [self updateDoneButtonState];
}

- (void)setReminderType:(int64_t)reminderType {
    _reminderType = reminderType;
}

- (IBAction)switched:(id)sender {
    changed = YES;
    [self updateDoneButtonState];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    alarmPickerController = [[AlarmPickerController alloc] initWithNibName:@"AlarmPickerController" bundle:nil];
    [alarmPickerController setDatePickerMode:UIDatePickerModeDateAndTime];
    
    self.deleteButton.layer.cornerRadius = 18;
    [self.deleteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    
    self.tableView.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);
    
    [self.reminderNoteView setPlaceholder:@"add a note"];
    self.reminderNoteView.frame = CGRectMake(10, 10, SCREEN_WIDTH - 20, 110);
    
    for (UIView *v in self.cellRightViews) {
        v.frame = setRectX(v.frame, SCREEN_WIDTH - v.frame.size.width - 15);
    }
    
    if (!self.whenList) {
        self.whenList = @[TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER];
    }
    if (!self.frequency) {
        self.frequency = 1;
    }
    if (!self.repeatWay) {
        self.repeatWay = REPEAT_NO;
    }
    if (!self.medPerTake && showMed) {
        self.medPerTake = 1;
    }
    if (!self.medPerTakeUnit) {
        self.medPerTakeUnit = @"";
    }
    
    changed = NO;
    self.deleteButtonView.centerX = SCREEN_WIDTH / 2.0;
    
    // self.reminderNoteView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [CrashReport leaveBreadcrumb:@"ReminderDetailViewController"];
    [self.navigationController.navigationBar setNeedsLayout];
    [self redrawPage];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![Utils getDefaultsForKey:USERDEFAULTS_REMINDER_DETAIL_DEBUT] && !self.uuid) {
        [[DropdownMessageController sharedInstance] postMessage:@"Set a time below"
                                                       duration:3
                                                       position:80
                                                         inView:self.view.window];
        [Utils setDefaultsForKey:USERDEFAULTS_REMINDER_DETAIL_DEBUT withValue:@(1)];
    }
}

- (void)redrawPage {
    // active button
    if (self.uuid) {
        self.active.on = self.on;
    }
    // delete button
    self.deleteButton.hidden = !self.canDelete;
    // title and note
    self.reminderTitleField.text = self.reminderTitle;
    self.reminderNoteView.text   = self.reminderNote;
    if (!self.canEditTitle) {
        self.reminderTitleField.enabled = NO;
    }
    // when list fields
    for (int i=0; i<[self.whenList count]; i++) {
        id time = self.whenList[i];
        if ([time isEqual:TIME_HOLDER]) {
            [(UILabel *)self.whenListLabels[i] setText:@"Set a time"];
        } else {
            [(UILabel *)self.whenListLabels[i] setText:[Utils reminderDateLabel:time]];
        }
    }
    // repeat
    [self updateRepeatCell];
    // med
    self.medTakeLabel.text = [NSString stringWithFormat:@"%ld %@", (long)self.medPerTake, self.medPerTakeUnit];

    [self updateDoneButtonState];
}

- (void)updateRepeatCell {
    self.repeatLabel.text = [Reminder repeatLabel:self.repeatWay time:self.frequency];
    if (!self.canEditRepeat) {
        self.repeatLabel.enabled = NO;
    }
    self.time1Label.text = self.frequency == 1? @"Time": @"Time 1";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
#pragma mark - Table view delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        NSInteger rows = 3;
        if (self.medPerTake && showMed) {
            rows += 1;
        }
        if (self.frequency > 1) {
            rows += self.frequency - 1;
        }
        return rows;
    } else if (section == 2) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        //"Reminder title" row,
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else if(indexPath.section == 1){
        if (indexPath.row  < self.frequency) {
            return [super tableView:tableView cellForRowAtIndexPath:indexPath];
        } else if (indexPath.row == self.frequency){
            //Repeat
            return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:7 inSection:1]];
        } else if (indexPath.row == self.frequency + 1) {
            if (self.medPerTake && showMed) {
                //med cell
                return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:8 inSection:1]];
            } else {
                //on/off
                return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:9 inSection:1]];
            }
        } else if (indexPath.row == self.frequency + 2) {
            return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:9 inSection:1]];
        }
    }

    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        //"Reminder title" row,
        [self.reminderTitleField becomeFirstResponder];
        [self.reminderNoteView resignFirstResponder];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if(indexPath.section == 1){
        [self.reminderTitleField resignFirstResponder];
        [self.reminderNoteView resignFirstResponder];

        if (indexPath.row  < self.frequency) {
            [self changeTimeForTimer:indexPath.row];
        } else if (indexPath.row == self.frequency){
            //Repeat
            [self changeFrequency];
        } else if (indexPath.row == self.frequency + 1) {
            if (self.medPerTake && showMed) {
                //med cell
                [self changeMedTake];
            } else {
                //on/off
            }
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (indexPath.section == 2) {
        [self.reminderTitleField resignFirstResponder];
        [self.reminderNoteView becomeFirstResponder];
    }
}

#pragma mark -
- (void)changeMedTake {
    NSMutableArray *rows = [NSMutableArray array];
    NSString *unit = [MedManager unitOfPerTakeForForm:medForm withPlural:NO];
    NSString *units = [MedManager unitOfPerTakeForForm:medForm withPlural:YES];
    for (NSInteger i = 0; i < 10; i++) {
        [rows addObject:[NSString stringWithFormat:@"%ld %@", (i + 1), (i > 0? units: unit)]];
    }
    [GLGeneralPicker presentSimplePickerWithTitle:@"Quantity per dosage"
                                           rows:rows
                                    selectedRow:(self.medPerTake - 1)
                                     showCancel:NO
                                 doneCompletion:^(NSInteger row, NSInteger comp) {
                                     self.medPerTake = row + 1;
                                     self.medPerTakeUnit = row > 0? units: unit;
                                     self.medTakeLabel.text = rows[row];
                                 }
                               cancelCompletion:nil];
}

- (void)changeTimeForTimer:(NSInteger)timerIndex;
{
    GLLog(@"%d", timerIndex);
    //[Logging log:BTN_CLK_GNS_RMD_TIME];
    [self showAlarmTimePickerForIndex:timerIndex];
}

- (void)changeFrequency
{
    if (self.canEditRepeat) {
        if (!fp) {
            fp = [[FrequencyPicker alloc] init];
        }
        
        NSInteger row1 = 0;
        NSInteger row2 = 0;
        
        switch (self.repeatWay) {
            case REPEAT_NO:
            {
                row1 = self.frequency - 1;
            }
                break;
            case REPEAT_DAILY:
            {
                row1 = self.frequency - 1;
                row2 = 1;
            }
                break;
            case REPEAT_WEEKLY:
            {
                row1 = self.frequency - 1;
                row2 = 2;
            }
                break;
            case REPEAT_MONTHLY:
            {
                row1 = self.frequency - 1;
                row2 = 3;
            }
                break;
            default:
                break;
        }
        [fp presentWithSelectedRows:@[@(row1), @(row2)]
                    andDoneCallback:^(NSInteger row, NSInteger comp) {
                        self.frequency = row + 1;
                        self.repeatWay = [@[@(REPEAT_NO), @(REPEAT_DAILY), @(REPEAT_WEEKLY), @(REPEAT_MONTHLY)][comp] intValue];
                        [self updateRepeatCell];
                        [self.tableView reloadData];
                        changed = YES;
                    }];
    }
}

- (BOOL)hasChanges {
    return changed;
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)backButtonPressed:(id)sender {
    //[Logging log:BTN_CLK_GNS_RMD_EDIT_BACK];
    if ([self hasChanges]) {
        [self onBack];
    } else {
        [self dismiss];
    }
}

- (IBAction)doneButtonPressed:(id)sender {
    //[Logging log:BTN_CLK_GNS_RMD_EDIT_DONE];
    NSString *title = [Utils trim:self.reminderTitleField.text];
    if ([Utils isEmptyString:title]) {
        [self.reminderTitleField becomeFirstResponder];
        return;
    }
    // set values that never checkced in done button
    self.on = self.active.on;
    self.reminderNote = [Utils trim:self.reminderNoteView.text];
    

    BOOL timeSet = YES;
    for (NSInteger i = 0; i < self.frequency; i ++) {
        timeSet = timeSet && ![self.whenList[i] isEqual:TIME_HOLDER];
    }
    if (!timeSet) {
        [[DropdownMessageController sharedInstance] postMessage:@"Set a time" duration:3.0 inView:self.view];
    } else {
        User *user = [User currentUser];
        [self subscribeOnce:EVENT_REMINDER_UPDATE_RESPONSE selector:@selector(updateReminderCallback:)];
        [NetworkLoadingView show];
        if (!self.isAppointment) {
            [Reminder createOrUpdateReminder:self.uuid
                                        type:self.reminderType
                                   withTitle:title
                                        note:self.reminderNote
                                        when:self.whenList
                                      repeat:self.repeatWay
                                   frequency:self.frequency
                                          on:self.on
                                    medCount:self.medPerTake
                                  andMedUnit:self.medPerTakeUnit
                                     forUser:user];
        } else {
            id obj = [self.whenList objectAtIndex:0];
            NSDate * when = nil;
            if ([obj isKindOfClass:[NSDate class]]) {
                when = (NSDate *)obj;
            } else {
                return;
            }
            [Appointment createOrUpdateAppointment:self.uuid
                                             title:title
                                              note:self.reminderNote
                                              when:when
                                            repeat:self.repeatWay
                                                on:self.on
                                           forUser:user];
        }
    }
}

- (void)updateReminderCallback:(Event *)event {
    [NetworkLoadingView hide];
    // User *user = [User currentUser];
    
    NSDictionary * result = (NSDictionary *)event.data;
    if ([result[@"rc"] intValue] == RC_SUCCESS) {
        // success
        Reminder * r = (Reminder *)[result objectForKey:@"reminder"];
        if (r) {
            if (savedCallback) {
                savedCallback(r);
            }
        }
        [self dismiss];
    } else {
        NSString * message = result[@"msg"];
        [[DropdownMessageController sharedInstance] postMessage:message duration:3.0 inView:self.view];
    }
}

- (IBAction)tapped:(id)sender {
    if (sender != self.reminderTitleField) {
        [self.reminderTitleField resignFirstResponder];
    }
}

- (IBAction)onDelete:(id)sender {
    UIActionSheet *ac = [[UIActionSheet alloc] initWithTitle:@"Are you sure?"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel, forget it"
                                      destructiveButtonTitle:@"Yes, delete it"
                                           otherButtonTitles: nil];
    ac.tag = AC_TAG_DELETE;
    [ac showInView:self.view];
}

- (void)onBack {
    UIActionSheet *ac = [[UIActionSheet alloc] initWithTitle:@"Do you want to save your changes?"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:@"No, please discard"
                                           otherButtonTitles:@"Yes, save my changes", nil];
    ac.tag = AC_TAG_CONFIRM;
    [ac showInView:self.view];
}

- (void)showAlarmTimePickerForIndex:(NSInteger)index {
    if (!alarmPickerController) {
        alarmPickerController = [[AlarmPickerController alloc] initWithNibName:@"AlarmPickerController" bundle:nil];
    }

    if ((!self.whenList) || ([self.whenList count] == 0)) {
        self.whenList = @[TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER,TIME_HOLDER, TIME_HOLDER, TIME_HOLDER];
    }

    id time = self.whenList[index];
    if ([time isEqual:TIME_HOLDER]) {
        time = [NSDate date];
    }
    
    NSInteger mode = self.repeatWay == REPEAT_DAILY? UIDatePickerModeTime: UIDatePickerModeDateAndTime;

    [alarmPickerController setSelectedDate:time];

    if (self.uuid) {
        if ((self.reminderType == REMINDER_TYPE_SYS_IUD) ||
            (self.reminderType == REMINDER_TYPE_SYS_VRING)){
            [alarmPickerController setDatePickerMode:UIDatePickerModeDateAndTime];
        } else {
            [alarmPickerController setDatePickerMode:mode];
        }
    } else {
        [alarmPickerController setDatePickerMode:mode];
    }

    if (alarmPickerController.datePickerMode == UIDatePickerModeTime) {
        [alarmPickerController setMinDate:[Utils dateByAddingDays:-1 toDate:time]];
    } else {
        [alarmPickerController setMinDate:[NSDate date]];
    }

    self.deleteButton.hidden = !self.canDelete;

    [alarmPickerController present:self.view.window withPickDateCallback:^(NSDate *date) {
        NSDate * when = nil;
        if (self.uuid && self.reminderType == REMINDER_TYPE_SYS_BBT) {
            NSCalendar *cal = [Utils calendar];
            NSDateComponents *components;

            NSDateComponents *dateComponents = [cal components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:date];
            NSInteger bbtHour = dateComponents.hour;
            NSInteger bbtMinute = dateComponents.minute;
            NSDateComponents *now = [cal components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[NSDate date]];
            
            if (bbtHour < now.hour || (bbtHour == now.hour &&  bbtMinute <= now.minute)) {
                components = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[Utils dateByAddingDays:1 toDate:[NSDate date]]];
            } else {
                components = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[NSDate date]];
            }
            [components setHour:bbtHour];
            [components setMinute:bbtMinute];

            when = [cal dateFromComponents:components];
        } else {
            when = date;
        }
        
        [(UILabel *)self.whenListLabels[index] setText:[Utils reminderDateLabel:when]];
        NSMutableArray *arr = [self.whenList mutableCopy];
        [arr replaceObjectAtIndex:index withObject:[when copy]];
        self.whenList = [NSArray arrayWithArray:arr];
        
        changed = YES;
        [self updateDoneButtonState];

        if (self.canDelete) {
            self.deleteButtonView.hidden = NO;
        }
    } withCancelCallback:^() {
        if (self.canDelete) {
            self.deleteButtonView.hidden = NO;
        }
    }];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == AC_TAG_DELETE && buttonIndex == actionSheet.destructiveButtonIndex) {
        if (self.uuid) {
            Reminder *r = [Reminder getReminderByUUID:self.uuid];
            if (r) {
                NSString *uuid = r.uuid;
                if (self.isAppointment) {
                    [Appointment deleteAppointment:uuid forUser:[User currentUser]];
                } else {
                    [Reminder deleteByUUID:uuid];
                }
                if (deletedCallback) {
                    deletedCallback(uuid);
                }
                self.reminderTitle = @"";
                self.reminderTitleField.text = @"";
                self.whenList = @[TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER];
                self.frequency = 1;
                self.repeatWay = REPEAT_NO;

                /* this log moved to server
                [Logging log:BTN_CLK_GNS_RMD_REMOVED
                   eventData:@{
                               @"repeat": @(repeat),
                               @"when": @(when),
                               @"readable_id":[NSString stringWithFormat:@"RMD_%@_%@", title, uuid]}];
                 */
            }
        }
        [self dismiss];
    } else if (actionSheet.tag == AC_TAG_CONFIRM) {
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                self.reminderTitle = @"";
                self.reminderTitleField.text = @"";
                self.whenList = @[TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER, TIME_HOLDER];
                self.frequency = 1;
                self.repeatWay = REPEAT_NO;

                [self dismiss];
            } else {
                [self doneButtonPressed:actionSheet];
            }
        }
    }
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return !self.uuid || self.canEditTitle;
}

- (IBAction)textFieldEditingChanged:(id)sender {
    changed = YES;
    [self updateDoneButtonState];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark -
- (void)updateDoneButtonState {
    BOOL enabled = YES;

    enabled = enabled && [Utils isNotEmptyString:self.reminderTitleField.text];
    for (NSInteger i = 0; i < self.frequency; i ++) {
        enabled = enabled && ![self.whenList[i] isEqual:TIME_HOLDER];
    }

    self.doneButton.enabled = enabled;
}
@end
