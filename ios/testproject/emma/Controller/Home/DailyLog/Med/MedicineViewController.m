//
//  MedicineViewController.m
//  emma
//
//  Created by Eric Xu on 12/30/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "MedicineViewController.h"
#import "FontReplaceableBarButtonItem.h"
#import "MedManager.h"
#import "MedSearchController.h"
#import "ReminderDetailViewController.h"
#import <GLFoundation/GLGeneralPicker.h>
#import "User.h"
#import "Reminder.h"

#define TAG_TF_NAME 1
#define TAG_TF_FORM 2
#define TAG_TF_PACK 3
#define TAG_TF_DOSG 4

#define TAG_AS_CHANGES 11
#define TAG_AS_FORMS 12
#define TAG_AS_DELETE 13

#define PLACE_HOLDER @"Enter name"

@interface MedicineViewController () <UITextFieldDelegate, UIActionSheetDelegate, UISearchBarDelegate, UISearchDisplayDelegate> {
    Medicine *model;
    
    NSArray *dataSourceArray;
    NSString *userSearchText;
    NSAttributedString *createMedAttrStr;
    
    UILabel *titleLabel;

    NSInteger total;
}
@property (nonatomic) BOOL hasChanges;


@property (strong, nonatomic) IBOutlet FontReplaceableBarButtonItem *saveButton;

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UILabel *medName;
@property (strong, nonatomic) IBOutlet UITextField *medForm;
@property (strong, nonatomic) IBOutlet UITextField *medTotalInPackage;
@property (strong, nonatomic) IBOutlet UIToolbar *medTotalInputAccessoryView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *medTotalDoneButton;


@property (strong, nonatomic) NSString *reminderUUID;
@property (strong, nonatomic) NSString *oldReminderUUID;
@property (nonatomic, copy) NSString *oldMedName;

@property (strong, nonatomic) IBOutlet UITableViewCell *addReminderCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *reminderCell;
@property (strong, nonatomic) IBOutlet UILabel *reminderTitle;
@property (strong, nonatomic) IBOutlet UILabel *reminderTime;
@property (strong, nonatomic) IBOutlet UISwitch *reminderSwitch;

@property (strong, nonatomic) IBOutlet UIButton *deleteButton;

@property (strong, nonatomic) UINavigationController *reminderNavController;
@property (strong, nonatomic) ReminderDetailViewController *reminderController;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *searchbarConstraintWidth;

- (IBAction)medTotalDonePressed:(id)sender;
- (IBAction)saveButtonPressed:(id)sender;
- (IBAction)backButtonPressed:(id)sender;
- (IBAction)deleteButtonPressed:(id)sender;

@end

@implementation MedicineViewController

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

    self.hasChanges = NO;
    self.saveButton.enabled = NO;
    
    self.deleteButton.layer.cornerRadius = 18;
    [self.deleteButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];

    titleLabel = [[UILabel alloc] init];
    [titleLabel setFont:[Utils boldFont:22]];
    [titleLabel setTextColor:UIColorFromRGB(0x5B5B5B)];
    [self.navigationItem setTitleView:titleLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self drawPage];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.delegate respondsToSelector:
        @selector(afterMedicineViewWillDisappear)]) {
        [self.delegate afterMedicineViewWillDisappear];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([self.delegate respondsToSelector:
        @selector(afterMedicineViewDidDisappear)]) {
        [self.delegate afterMedicineViewDidDisappear];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)drawPage {
    if (model) {
        // modify flow
        titleLabel.text = @"Med/supplement";
        self.deleteButton.hidden = NO;
        self.medName.textColor = [UIColor darkTextColor];
        self.medName.text = model.name;
        self.medForm.text = model.form;
        // self.medForm.text = [MedManager getForm:model.name];
    } else {
        // create flow
        titleLabel.text = @"New med/supplement";
        self.deleteButton.hidden = YES;
    }
    [self updateTotalInPackage];
    [self checkSaveButtonStatus];
    self.medTotalInPackage.inputAccessoryView = self.medTotalInputAccessoryView;
    
    self.searchBar.hidden = YES;
    
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel sizeToFit];
}

#pragma mark - init functions
- (void)setModel:(Medicine *)_model {
    /*
     * Interface for Daily Log / Medical Log,
     * In these cases, we don't have medicine view controller displayed
     */
    if (_model) {
        model = _model;
        total = model.total;
        self.reminderUUID = model.reminderUUID;
        self.oldReminderUUID = model.reminderUUID;
    } else {
        model = nil;
        total = 0;
        self.reminderUUID = nil;
        self.oldReminderUUID = nil;
    }
}

- (void)setMedicineNameFromSearch:(NSString *)medName {
    /*
     * Interface for search
     * in this case, the medicine view controller is displayed
     */
    
    self.oldMedName = self.medName.text;
    
    Medicine *med = [MedManager userMedWithName:medName];
    [self setModel:med];
    if (self.medName) {
        self.medName.textColor = [UIColor darkTextColor];
        self.medName.text = medName;
        self.medForm.text = [MedManager getForm:medName];
    }
    [self drawPage];

    /*
    if (self.medName) {
        self.medName.textColor = [UIColor darkTextColor];
        self.medName.text = medName;
        self.medForm.text = [MedManager getForm:medName];
        
        Medicine *med = [MedManager userMedWithName:medName];
        if (med) {
            self.medForm.text = med.form;
            total = med.total;
            [self updateTotalInPackage];
            if ([Utils isEmptyString:self.reminderUUID]) {
                self.reminderUUID = med.reminderUUID;
                oldReminderUUId = med.reminderUUID;
            }
        }
     
    } else {
        model = [MedManager userMedWithName:medName];
    }
    
    [self updateTotalInPackage];
    [self checkSaveButtonStatus];
    self.searchBar.hidden = YES;
    */
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 2;
    } else return 1;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        self.searchBar.hidden = NO;
        self.searchbarConstraintWidth.constant = SCREEN_WIDTH;
        [self.searchBar becomeFirstResponder];
        
        if (![self.medName.text isEqual:PLACE_HOLDER]) {
            [self.searchBar setText:self.medName.text];
            [self.searchBar.delegate searchBar:self.searchBar textDidChange:self.searchBar.text];
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self chooseForm];
        } else if (indexPath.row == 1) {
            [self.medTotalInPackage becomeFirstResponder];
        }
    } else if (indexPath.section == 2){
        //reminder
        [self openReminderPage];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2){
        Reminder *reminder = [Reminder getReminderByUUID:self.reminderUUID];
        if (reminder) {
            self.reminderTitle.text = reminder.title;
            self.reminderTime.text = [Utils reminderDateLabel:[reminder nextWhen]];
            self.reminderSwitch.on = reminder.on;
            return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
        } else {
            return [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
        }
    } else
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        if ([Reminder getReminderByUUID:self.reminderUUID]) {
            return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
        } else {
            return [super tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
        }
    } else
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (!model) {
        return [super tableView:tableView titleForHeaderInSection:section];
    } else {
        return @[@"Med/supplement name", @"Form and quantity", @"Reminder", @""][section];
    }
}

#pragma mark - IBActions
- (IBAction)tapped:(id)sender {
    if ([self.medTotalInPackage isFirstResponder]) {
        [self.medTotalInPackage resignFirstResponder];
    }
}

- (IBAction)reminderSwitched:(id)sender {
    UISwitch *swc = (UISwitch *)sender;
    if (self.reminderUUID) {
        User *u = [User currentUser];
        Reminder *r = [Reminder getReminderByUUID:self.reminderUUID];
        if (r) {
            r.on = swc.on;
        }
        [u save];
    }
}


- (IBAction)backButtonPressed:(id)sender {
//#warning TODO: check changes and prompt confirmation
    [self confirmCancel];
}

- (IBAction)deleteButtonPressed:(id)sender {
//#warning TODO: confirm before delte
    [self confirmDelete];
}

- (void)confirmDelete {
    NSString *title = [NSString stringWithFormat:@"Are you sure you want to delete %@?", self.medName.text];
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"No" destructiveButtonTitle:@"Yes, delete!" otherButtonTitles:nil];
    as.tag = TAG_AS_DELETE;
    [as showInView:[self.view window]];
}

- (void)confirmCancel {
    if (self.hasChanges) {
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Save your changes?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"No, please discard" otherButtonTitles:@"Yes, save my changes", nil];
        as.tag = TAG_AS_CHANGES;
        [as showInView:[self.view window]];
    } else
        [self.navigationController popViewControllerAnimated:YES from:self];
}

- (void)checkSaveButtonStatus {
    BOOL buttonEnabled = YES;

    buttonEnabled = buttonEnabled && ([Utils isNotEmptyString:self.medName.text] && ![self.medName.text isEqual:PLACE_HOLDER]);
    buttonEnabled = buttonEnabled && [Utils isNotEmptyString:self.medForm.text];
    buttonEnabled = buttonEnabled && total > 0;//[Utils isNotEmptyString:self.medTotalInPackage.text];

    self.saveButton.enabled = buttonEnabled;
}

- (void)doSave {
    [self checkSaveButtonStatus];
    if (!self.saveButton.enabled) {
        return;
    }
    
    Medicine *med = [[Medicine alloc] init];
    med.name = self.medName.text;
    med.form = self.medForm.text;
    med.total = total;//[self.medTotalInPackage.text intValue];
    med.reminderUUID = self.reminderUUID;
    
    if (model) {
        med.id = model.id;
    }
    else {
        med.id = [Utils generateUUID];
        [Utils setDefaultsForKey:USERDEFAULTS_NEW_MED withValue:@(1)];
    }

    [MedManager user:[User currentUser] upsertMed:med];
    self.hasChanges = NO;
    
    if (!self.isEditingMedication &&
        [self.delegate respondsToSelector:@selector(medicineViewControllerDidAddNewMedicationWithName:)]) {
        
        [self.delegate medicineViewControllerDidAddNewMedicationWithName:med.name];
        [self.navigationController popViewControllerAnimated:YES from:self];
        return;
    }
    
    if (self.isEditingMedication && self.oldMedName && ![self.medName.text isEqual:self.oldMedName]) {
        
        // delete the old medication
        [MedManager user:[User currentUser] removeMed:self.oldMedName];
        
        if([self.delegate respondsToSelector:@selector(medicineViewControllerDidUpdateMedicationWithName:)]) {
            [self.delegate medicineViewControllerDidUpdateMedicationWithName:med.name];
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (IBAction)saveButtonPressed:(id)sender {
    [self doSave];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.medTotalInPackage) {
        total = [textField.text integerValue];
        [self updateTotalInPackage];
    }

    [self checkSaveButtonStatus];
    self.hasChanges = YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    switch (textField.tag) {
        case TAG_TF_NAME:
            break;
        case TAG_TF_FORM: {
            [self chooseForm];
            [textField resignFirstResponder];
        }
            break;
        case TAG_TF_PACK:{
            if (total) {
                self.medTotalInPackage.text = [NSString stringWithFormat:@"%ld", (long)total];
            }
        }
            break;
        case TAG_TF_DOSG:
            break;
            
        default:
            break;
    }
}

- (void)chooseForm {
    NSArray *forms = [MedManager medForms];
    NSInteger index = [forms indexOfObject:self.medForm.text];
    if (index == NSNotFound) {
        index = 0;
    }
    
    [GLGeneralPicker presentSimplePickerWithTitle:@"Enter form"
                                           rows:forms
                                    selectedRow:(int)index
                                     showCancel:NO
                                 doneCompletion:^(NSInteger row, NSInteger comp) {
                                     self.medForm.text = [MedManager medForms][row];
                                     self.hasChanges = YES;
                                     [self updateTotalInPackage];
                                     [self checkSaveButtonStatus];
                                 }
                               cancelCompletion:nil];
}

- (void)updateTotalInPackage {
    if (total) {
        self.medTotalInPackage.text = [NSString stringWithFormat:@"%ld %@", (long)total, [MedManager unitOfTotalInPackageForForm:self.medForm.text withPlural:(total != 1)]];
    } else {
        self.medTotalInPackage.text = @"";
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (actionSheet.tag) {
        case TAG_AS_DELETE:
        {
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                //delete
                if (model) {
                    [MedManager user:[User currentUser] removeMed:model.name];
                    [Reminder deleteByUUID:model.reminderUUID];
                    if ([self.delegate respondsToSelector:
                        @selector(onConfirmDeleteMed:)]) {
                        [self.delegate onConfirmDeleteMed:model.name];
                    }
                }
                
                [self.navigationController popViewControllerAnimated:YES from:self];
            }
        }
            break;
        case TAG_AS_FORMS:
        {
            self.medForm.text = [MedManager medForms][buttonIndex];
            [self updateTotalInPackage];
        }
            break;
        case TAG_AS_CHANGES:
        {
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                // rollback
                if (self.reminderUUID) {
                    // if we have reminder set, and the original med has a different reminder
                    // delete it
                    if ([Utils isEmptyString:self.oldReminderUUID] ||
                        ![self.oldReminderUUID isEqualToString:self.reminderUUID]) {
                        [Reminder deleteByUUID:self.reminderUUID];
                    }
                }
                [self.navigationController popViewControllerAnimated:YES from:self];
            } else if (buttonIndex == actionSheet.cancelButtonIndex) {
                //
            } else {
                [self doSave];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark -
- (void)openReminderPage {
    if (!self.reminderController || !self.reminderNavController) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"reminder" bundle:nil];
        self.reminderNavController = [storyboard instantiateViewControllerWithIdentifier:@"detailNav"];
        self.reminderController = (ReminderDetailViewController *) self.reminderNavController.viewControllers[0];
        self.reminderController.isAppointment = NO;
    }

    __weak MedicineViewController *_self = self;
    Reminder * rmd = nil;
    if ([Utils isNotEmptyString:self.reminderUUID]) {
        rmd = [Reminder getReminderByUUID:self.reminderUUID];
        if (!rmd) {
            model.reminderUUID = nil;
            self.reminderUUID = nil;
        }
    }
    
    // initial remiderDetailViewController, basded on rmd
    if (rmd) {
        [self.reminderController setModel:[Reminder getReminderByUUID:self.reminderUUID]];
        [self.reminderController setReminderDeletedCallback:^(NSString *reminderID) {
            _self.reminderUUID = nil;
            _self.hasChanges = YES;
        }];
        [self.reminderController setMedicineForm:self.medForm.text];
    } else {
        if ([Utils isNotEmptyString:self.medName.text] && ![self.medName.text isEqual:PLACE_HOLDER]) {
            [self.reminderController setPrefilledTitle:[NSString stringWithFormat:@"Take %@", self.medName.text]];
        }
        [self.reminderController setModel:nil];
        // set medName and medForm
        if ([Utils isNotEmptyString:self.medName.text] && ![self.medName.text isEqual:PLACE_HOLDER]) {
            [self.reminderController setMedicineName:self.medName.text andForm:self.medForm.text];
        }
        // TODO, peng, do you use the same view controller?
        [self.reminderController setReminderType:REMINDER_TYPE_MEDICINE_DAILY];
    }

    // save call back
    [self.reminderController setReminderSavedCallback:^(Reminder *r) {
        _self.reminderUUID = r.uuid;
        _self.hasChanges = YES;
    }];
    
    [self.reminderController setShowMed:YES];
    [self presentViewController:self.reminderNavController animated:YES completion:nil];
}

- (IBAction)medTotalDonePressed:(id)sender {
    [self.medTotalInPackage resignFirstResponder];
}
@end
