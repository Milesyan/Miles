//
//  DailyLogViewController.m
//  emma
//
//  Created by Ryan Ye on 3/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeAlcohol.h"
#import "DailyLogCellTypeBMI.h"
#import "DailyLogCellTypeCervical.h"
#import "DailyLogCellTypeDigital.h"
#import "DailyLogCellTypeExercise.h"
#import "DailyLogCellTypeExpandable.h"
#import "DailyLogCellTypeIntercourse.h"
#import "DailyLogCellTypeMed.h"
#import "DailyLogCellTypeMucus.h"
#import "DailyLogCellTypeSleep.h"
#import "DailyLogCellTypePeriodFlow.h"
#import "DailyLogCellTypePhysicalDiscomfort.h"
#import "DailyLogCellTypeSmoke.h"
#import "DailyLogCellTypeStressLevel.h"
#import "DailyLogCellTypeTest.h"
#import "DailyLogCellTypeMaleIntercourse.h"
#import "DailyLogCellTypeErection.h"
#import "DailyLogCellTypeMasturbation.h"
#import "DailyLogCellTypeFever.h"
#import "DailyLogCellTypeHeatSource.h"

#import "DailyLogConstants.h"
#import "DailyLogDataProvider.h"
#import "DailyLogUndoManager.h"
#import "DailyLogViewController.h"
#import "DropdownMessageController.h"
#import "FontReplaceableBarButtonItem.h"
#import "HomeViewController.h"
#import "IOS67CompatibleUIButton.h"
// #import "NotesTableViewController.h"
// #import "NotesManager.h"
#import "MedListViewController.h"
#import "MedManager.h"
#import "PillButton.h"
#import "StatusBarOverlay.h"
#import "Tooltip.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "User+Jawbone.h"
#import "User.h"
#import "User+Misfit.h"
#import "UserDailyData.h"
#import "UserDailyData+Symptom.h"
#import "VariousPurposesDataProviderFactory.h"
#import "DailyLogCellTypeSymptom.h"
#import "SymptomViewController.h"
#import "HealthKitManager.h"
#import "GLDailyLogStatisticView.h"
#import "HealthAwareness.h"
#import <AMScrollingNavbar/UIViewController+ScrollingNavbar.h>
#import <objc/runtime.h>
#import "GeniusMainViewController.h"
#import "UserDailyData+HealthKit.h"

#define KEYBOARD_HEIGHT 216 + 40
#define TABLEVIEW_CELL_HEIGHT_DEFAULT 66
#define HEADER_CELL_TAG 99
#define NOT_OPERATABLE_CELLS @[DL_CELL_KEY_EXTRA, DL_CELL_KEY_ADD_MED, DL_CELL_KEY_MED_HEADER, DL_CELL_KEY_MED]

@interface DailyLogViewController () <DailyLogDataReceiver, DailyLogCellTypeSymptomDelegate, SymptomViewControllerDelegate, UIGestureRecognizerDelegate>{
    BOOL keyboardIsShowing;
    NSInteger lastContentOffsetYDiff;
    DailyLogDataProvider *variousPurposesDataProvider;
    UIView *overlay;
    
    DropdownMessageController *dropDownMessageController;
    DailyLogCellStatus status;
    DailyLogUndoManager *undoManager;
}

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableViewTopLayoutConstraint;

@property (strong, nonatomic) IBOutlet FontReplaceableBarButtonItem *editCellRowsButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet IOS67CompatibleUIButton *backArrow;

@property (strong, nonatomic) IBOutlet UITableViewCell *physicalSectionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *emotionalSectionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *fertilitySectionCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *spermHealthSectionCell;


// @property (nonatomic, strong) IBOutlet UITableViewCell *notesHeaderCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *emotionalSymptomViewControllerHeader;
@property (nonatomic, strong) IBOutlet UITableViewCell *physicalSymptomViewControllerHeader;

@property (strong, nonatomic) IBOutlet DailyLogCellTypeTest *cellOvulation;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeTest *cellPregnancyTest;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeDigital *cellTemperture;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeBMI *cellWeight;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeSymptom *cellMood;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeSymptom *cellPhysicalDiscomfort;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeIntercourse *cellIntercourse;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeMucus *cellMucus;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeAlcohol *cellAlcohol;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeSmoke *cellSmoke;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeStressLevel *cellStressLevel;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeExercise *cellActivity;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeCervical *cellCervical;
@property (strong, nonatomic) IBOutlet DailyLogCellTypePeriodFlow *cellPeriodFlow;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeSleep *cellSleep;

@property (strong, nonatomic) IBOutlet UITableViewCell *medHeaderCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellNewMed;
@property (strong, nonatomic) IBOutlet UIView *saveButtonContainer;

@property (strong, nonatomic) IBOutlet DailyLogCellTypeMaleIntercourse *cellMaleIntercourse;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeErection *cellErection;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeMasturbation *cellMasturbation;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeFever *cellFever;
@property (strong, nonatomic) IBOutlet DailyLogCellTypeHeatSource *cellHeatSource;


@property (weak, nonatomic) IBOutlet UILabel *fertilitySectionTitleLable;

@property(nonatomic, strong) NSDictionary *dataTemplate;
@property(nonatomic, strong) NSDictionary *cellTemplate;
@property(nonatomic, strong) UserDailyData *dailyData;
@property(nonatomic) BOOL isFuture;
@property(readonly) User *user;
@property(nonatomic, strong) UITapGestureRecognizer *tap;

@property (nonatomic, weak) IBOutlet GLDailyLogStatisticView* topView;

@property (nonatomic, strong) MedManager *medManager;

- (BOOL)shouldExpandTableCell:(DailyLogCellKey)cellKey;
- (void)findAndResignFirstResponder;
@end

@implementation DailyLogViewController
- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        self = [self initWithNibName:@"DailyLogViewController" bundle:nil];
    }
    return self;
}

#pragma mark - Public setters/getters
- (void)setSelectedDate:(NSDate*)date {
    _selectedDate = date;
    _isFuture = [Utils compareByDay:date toDate:[NSDate date]] == NSOrderedDescending && !EMMA_ALLOW_FUTURE_LOG;

    if (!_isFuture) {
        self.dailyData = [self.user dailyDataOfDate:self.selectedDate];
    } else {
        self.dailyData = nil;
    }
    [self _updateTitle];
}

- (void)_updateTitle {
    self.title = [self.selectedDate toReadableDate];
}

#pragma mark - Data shortcut
- (User *)user {
    return [User currentUser];
}

- (BOOL)hadSex {
    id val = [undoManager currentValueForKey:DL_CELL_KEY_INTERCOURSE];
    if ([val isEqual:[NSNull null]]) {
        return NO;
    }
    return [[undoManager currentValueForKey:DL_CELL_KEY_INTERCOURSE] intValue] > 1;
}

- (BOOL)shouldExpandTableCell:(DailyLogCellKey)cellKey {
    if (DailyLogCellStatusEditing == status) {
        return NO;
    }
    
    NSArray *notExpandCells = @[DL_CELL_KEY_SECTION_PHYSICAL, DL_CELL_KEY_SECTION_SPERM_HEALTH, DL_CELL_KEY_ERECTION, DL_CELL_KEY_SECTION_EMOTIONAL, DL_CELL_KEY_SECTION_FERTILITY, DL_CELL_KEY_BBT, DL_CELL_KEY_WEIGHT, DL_CELL_KEY_CERVICAL, DL_CELL_KEY_MED, DL_CELL_KEY_ADD_MED, DL_CELL_KEY_SLEEP];
    if ([notExpandCells indexOfObject:cellKey] != NSNotFound) {
        return NO;
    }

    id currentValue = [undoManager currentValueForKey:cellKey];
    currentValue = [currentValue isEqual:[NSNull null]] ? nil : currentValue;
    if ([cellKey isEqual:DL_CELL_KEY_OVTEST] ||
        [cellKey isEqual:DL_CELL_KEY_PREGNANCYTEST]) {
        return [currentValue intValue] > 0;
    }
    if ([cellKey isEqual:DL_CELL_KEY_EXERCISE]) {
        
    }
    return [currentValue intValue] > 1;
}

#pragma mark - Base class methods override
- (void)viewDidLoad {
    [super viewDidLoad];
    
    status = DailyLogCellStatusNormal;
    variousPurposesDataProvider = [VariousPurposesDataProviderFactory generateDailyLogDataProviderWithReceiver:self date:self.selectedDate abstract:[DailyLogDataProvider generateAbatractForUser:self.user dailyData:self.dailyData]];
    self.cellTemplate = @{
         DL_CELL_KEY_BBT: self.cellTemperture,
         DL_CELL_KEY_INTERCOURSE: self.user.isFemale ? self.cellIntercourse : self.cellMaleIntercourse,
         DL_CELL_KEY_OVTEST: self.cellOvulation,
         DL_CELL_KEY_PREGNANCYTEST: self.cellPregnancyTest,
         DL_CELL_KEY_MOODS: self.cellMood,
         DL_CELL_KEY_PHYSICALDISCOMFORT: self.cellPhysicalDiscomfort,
         DL_CELL_KEY_CM: self.cellMucus,
         DL_CELL_KEY_WEIGHT: self.cellWeight,
         DL_CELL_KEY_SMOKE: self.cellSmoke,
         DL_CELL_KEY_STRESS_LEVEL: self.cellStressLevel,
         DL_CELL_KEY_ALCOHOL: self.cellAlcohol,
         DL_CELL_KEY_EXERCISE: self.cellActivity,
         DL_CELL_KEY_CERVICAL: self.cellCervical,
         DL_CELL_KEY_PERIOD_FLOW: self.cellPeriodFlow,
         DL_CELL_KEY_ADD_MED: self.cellNewMed,
         DL_CELL_KEY_MED_HEADER: self.medHeaderCell,
         DL_CELL_KEY_SLEEP: self.cellSleep,
         DL_CELL_KEY_ERECTION: self.cellErection,
         DL_CELL_KEY_MASTURBATION: self.cellMasturbation,
         DL_CELL_KEY_HEAT_SOURCE: self.cellHeatSource,
         DL_CELL_KEY_FEVER: self.cellFever
         };
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self
        action:@selector(dismissKeyboard)];
    overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [overlay setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.1]];
    
    UIView *topOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 130)];
    [topOverlay setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]];
    [overlay addSubview:topOverlay];
    
    UIView *bottomOverlay = [[UIView alloc]  initWithFrame:CGRectMake(0, 196, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [bottomOverlay setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]];
    [overlay addSubview:bottomOverlay];
    
    dropDownMessageController = [DropdownMessageController sharedInstance];
    undoManager = [[DailyLogUndoManager alloc] init];
    [self _setInitialValueForUndoManager];
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0);
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    self.medManager = [[MedManager alloc] initWithDate:[Utils dailyDataDateLabel:self.selectedDate]];
    
    if (!self.user.isFemale) {
        self.fertilitySectionTitleLable.text = @"Sperm Health";
    }
    
    [self addSensitiveItemInfoForSectionHeaderIfNeeded:self.spermHealthSectionCell];
    [self addSensitiveItemInfoForSectionHeaderIfNeeded:self.fertilitySectionCell];
    [self addSensitiveItemInfoForSectionHeaderIfNeeded:self.physicalSectionCell];
}

- (void)_setInitialValueForUndoManager {
    //set initial value for normal log keys
    for (NSString *cellKey in DL_CELL_NORMAL_KEYS) {
        NSString *valKey = cellKey;
        id valueFromDailyData = [self.dailyData valueForKey:valKey];
        [undoManager recordValueForKey:cellKey value:valueFromDailyData];
    }


    
    //handle legacy moods->stressed data
    if ((self.dailyData.moods & DL_MOOD_NEGATIVE_STRESSED) &&
        !self.dailyData.stressLevel) {
        [undoManager recordValueForKey:DL_CELL_KEY_STRESS_LEVEL value:
            @(DL_DEFAULT_STRESS)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    // don't call [super viewWillAppear:] so tableview won't auto scroll when editing uitextfield
//    [super viewWillAppear:animated];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];

    [self.tableView reloadData];
    [self _refreshSaveButton];
    
    [self.editCellRowsButton setImage:[self getEditIcon]];
    if (!IOS8_OR_ABOVE) {
        [self.topView setupTintColor];
    }
    [self followScrollView:self.tableView usingTopConstraint:self.tableViewTopLayoutConstraint];
    [self setUseSuperview:YES];
    [[self panGesture] setDelegate:self];
    
    if (self.needsToScrollToWeightCell) {
        [self.tableView reloadData];
        [self scrollToWeightCell];
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];

    [CrashReport leaveBreadcrumb:@"DailyLogViewController"];
    [Logging log:PAGE_IMP_HOME_DAILYLOG eventData:@{@"daily_time" : @((int64_t)[self.selectedDate timeIntervalSince1970])}];
    self.user.autoSave = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self subscribe:EVENT_USER_SYNC_COMPLETED selector:@selector(refreshData:)];
    [self subscribe:EVENT_BRAND_PICKER_DID_SHOW selector:@selector(brandPickerDidShow:)];
    [self subscribe:EVENT_BRAND_PICKER_DID_HIDE selector:@selector(brandPickerDidHide:)];
    [self subscribeOnce:EVENT_TOOLTIP_KEYWORDS_RECEIVED selector:@selector(tooltipKeywordsUpdatedFromServer:)];
    
    [self subscribe:EVENT_GO_FERTILITY selector:@selector(goFertilitySection:)];
    [self subscribe:EVENT_GO_PHYSICAL selector:@selector(goPhysicalSection:)];
    [self subscribe:EVENT_GO_EMOTIONAL selector:@selector(goEmotionalSection:)];

    NSNumber * openOption = (NSNumber *)[Utils getDefaultsForKey:DAILY_PAGE_OPEN_OPTION];;
    if (openOption) {
        [Utils setDefaultsForKey:DAILY_PAGE_OPEN_OPTION withValue:nil];
        [self.cellTemperture openTemperaturePanel];
    }

    id newMed = [Utils getDefaultsForKey:USERDEFAULTS_NEW_MED];
    GLLog(@"new med: %@", newMed);
    if (newMed) {
        [self medAdded:nil];
        [Utils setDefaultsForKey:USERDEFAULTS_NEW_MED withValue:nil];
        GLLog(@"new med after: %@", [Utils getDefaultsForKey:USERDEFAULTS_NEW_MED]);
    }
    
    [self _reloadStats];
//    
//    if (self.needsToScrollToWeightCell) {
//        [self scrollToWeightCell];
//    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [self.saveButtonContainer removeFromSuperview];
    [self unsubscribeAll];
    editIcon = nil;
    
    self.navigationController.navigationBar.shadowImage = nil;
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];

    [self showNavBarAnimated:NO];
    [self stopFollowingScrollView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.dailyData = nil;
}

#pragma mark - Event/observer selectors
- (void)medAdded:(Event *)event {
    [dropDownMessageController postMessage:@"New med / supplement added!"
                                  duration:3
                                  inWindow:self.view.window];
}

- (void)refreshData:(Event *)evt {
    self.dailyData = [self.user dailyDataOfDate:self.selectedDate];
    [self.tableView reloadData];
}


- (void)keyboardWillShow:(NSNotification *)note
{
    UIView *fr = (UIView *)[self.view findFirstResponder];
    UITableViewCell *cell = (UITableViewCell *)fr.superview;
    
    CGPoint x = [fr.superview convertPoint:fr.frame.origin toView:nil];
    CGPoint y = self.tableView.contentOffset;
    NSInteger scrollCellOffset = cell.frame.size.height - (SCREEN_HEIGHT - x.y);
    scrollCellOffset = scrollCellOffset < 0 ? 0 : scrollCellOffset;
    
    lastContentOffsetYDiff = x.y - scrollCellOffset - 44 - 20 - 66;
    
    if (x.y + 66 > SCREEN_HEIGHT) {
        lastContentOffsetYDiff += x.y + 44 + 20 + 66 - SCREEN_HEIGHT;
    }
    y.y += lastContentOffsetYDiff;
    
    keyboardIsShowing = YES;
    
    overlay.alpha = 0;
    [self.view.window addSubview:overlay];
    
    [self.tableView setContentOffset:y animated:NO];
    
    [UIView animateWithDuration:0.3 animations:^{
        overlay.alpha = 1;
    } completion:^(BOOL finished) {
    }];
}


- (void)keyboardWillHide:(NSNotification *)note
{
    CGPoint y = self.tableView.contentOffset;

    if (self.tableView.contentOffset.y > KEYBOARD_HEIGHT) {
        y.y -= lastContentOffsetYDiff;
        [self.tableView setContentOffset:y animated:YES];
    }
    lastContentOffsetYDiff = 0;
    keyboardIsShowing = NO;
    [self.view removeGestureRecognizer:self.tap];
    
    [UIView animateWithDuration:0.1 animations:^{
        overlay.alpha = 0;
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
        overlay.alpha = 1;
    }];

}

static float tableViewContentInsetBottom;
- (void)brandPickerDidShow:(Event *)e
{
    GLLog(@"e: %@ %@", e.data,[NSValue valueWithUIEdgeInsets:self.tableView.contentInset]);
    UIEdgeInsets inset = self.tableView.contentInset;
    tableViewContentInsetBottom = inset.bottom;
    self.tableView.contentInset = UIEdgeInsetsMake(inset.top, 0, 206, 0);

    if ([e.data isEqual:DL_CELL_KEY_OVTEST]) {
        [self.tableView scrollToRowAtIndexPath:[variousPurposesDataProvider
            indexPathForDailyLogCellKey:DL_CELL_KEY_OVTEST] atScrollPosition:
            UITableViewScrollPositionBottom animated:YES];
    } else {
        [self.tableView scrollToRowAtIndexPath:
            [variousPurposesDataProvider indexPathForDailyLogCellKey:
            DL_CELL_KEY_PREGNANCYTEST]
            atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)brandPickerDidHide:(Event *)e
{
    GLLog(@"eee: %@", e.obj);
    UITableViewCell *cell = (UITableViewCell *)e.obj;
    UIEdgeInsets inset = self.tableView.contentInset;

    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(inset.top, 0, tableViewContentInsetBottom, 0);
        if (e) {
            [self.tableView scrollRectToVisible:cell.frame animated:YES];
        }
    }];
}

- (void)dismissKeyboard {
    [self findAndResignFirstResponder];
}

- (void)addSensitiveItemInfoForSectionHeaderIfNeeded:(UITableViewCell *)headerCell
{
    if (!self.user.partner) {
        return;
    }
    CGFloat centerY = 24 / 2;

    UILabel *label = [[UILabel alloc] init];
    label.font = [Utils defaultFont:13];
    label.text = @"Hidden from partner = ";
    [label sizeToFit];
    label.centerY = centerY;
    label.right = SCREEN_WIDTH - 15;
    [headerCell addSubview:label];
    
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 11, 11)];
    iconView.centerY = centerY;
    iconView.right = SCREEN_WIDTH - 3;
    iconView.image = [UIImage imageNamed:@"hidden-icon"];
    [headerCell addSubview:iconView];
}

#pragma mark - UITableView delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:
    (NSInteger)section
{
    return [[variousPurposesDataProvider dailyLogCellKeyOrderWithMeds] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DailyLogCellKey cellKey = [variousPurposesDataProvider dailyLogCellKeyForIndexPath:indexPath];
    NSString *valKey = cellKey;
    DailyLogCellTypeBase *cell;

    NSString *medName = nil;
    if([cellKey isEqual:DL_CELL_KEY_SECTION_PHYSICAL]) {
        return self.physicalSectionCell;
    } else if([cellKey isEqual:DL_CELL_KEY_SECTION_EMOTIONAL]) {
        return self.emotionalSectionCell;
    } else if([cellKey isEqual:DL_CELL_KEY_SECTION_FERTILITY]) {
        return self.fertilitySectionCell;
    } else if ([cellKey isEqual:DL_CELL_KEY_MED_HEADER]) {
        return self.medHeaderCell;
    } else if ([cellKey isEqual:DL_CELL_KEY_SECTION_SPERM_HEALTH]) {
        return self.spermHealthSectionCell;
    }
    else if ([cellKey isEqual:DL_CELL_KEY_ADD_MED]) {
        if (DailyLogCellStatusEditing == status) {
            self.cellNewMed.userInteractionEnabled = NO;
        }
        else {
            self.cellNewMed.userInteractionEnabled = YES;
        }
        
        for (UIView *view in self.cellNewMed.contentView.subviews) {
            if ([view isKindOfClass:[UILabel class]] && view.tag == 1) {
                NSInteger num = self.medManager.numberOfLogs;
                NSString *text = num > 0 ? [NSString stringWithFormat:@"%ld logged", num] : nil;
                [(UILabel *)view setText:text];
            }
        }
        
        return self.cellNewMed;
    }
    else if ([cellKey isEqual:DL_CELL_KEY_MED]) {
        medName = [variousPurposesDataProvider nameOfMedicineForIndexPath:
            indexPath];
        Medicine *med = [MedManager userMedWithName:medName];
        if (med) {
            cell = [DailyLogCellTypeMed getCellForMedicine:med];
        } else {
            cell = [DailyLogCellTypeMed getCellForMedName:medName];
        }
        valKey = DL_CELL_KEY_MEDS;
    }
    else {
        cell = self.cellTemplate[cellKey];
    }

    cell.delegate = self;
    cell.dataKey = cellKey;

    if ([cellKey isEqual:DL_CELL_KEY_PERIOD_FLOW]) {
        [(DailyLogCellTypePeriodFlow *)cell setInPeriod:([self.user predictionForDate:self.selectedDate] == kDayPeriod)];
    }
 
    id cellCurrentValue = medName
        ? [undoManager currentValueForMedName:medName]
        : [undoManager currentValueForKey:cellKey];
    
    if (!cellCurrentValue) {
        id valueFromDailyData = [self.dailyData valueForKey:valKey];
        [cell setValue:valueFromDailyData forDate:self.selectedDate];
    }
    else {
        cellCurrentValue = [cellCurrentValue isEqual:[NSNull null]] ? nil : cellCurrentValue;
        if (medName) {
            [((DailyLogCellTypeMed*) cell) setDirectValue:cellCurrentValue
                forDate:self.selectedDate];
        }
        else {
            [cell setValue:cellCurrentValue forDate:self.selectedDate];
        }
    }
    
    if ([cellKey isEqual:DL_CELL_KEY_INTERCOURSE]) {
        if ([cell isKindOfClass:[DailyLogCellTypeIntercourse class]]) {
            [(DailyLogCellTypeIntercourse *)cell setPurposeTTC:![self.user isAvoidingPregnancy]];
        }
    }
    else if ([cellKey isEqual:DL_CELL_KEY_PHYSICALDISCOMFORT] || [cellKey isEqual:DL_CELL_KEY_MOODS]) {
        SymptomType sympType;
        uint64_t sympValue1, sympValue2;
        
        if ([cellKey isEqual:DL_CELL_KEY_PHYSICALDISCOMFORT]) {
            sympType = SymptomTypePhysical;
            cell = self.cellPhysicalDiscomfort;
            
            NSNumber *valObj1 = [undoManager currentValueForKey:PHYSICAL_SYMPTOM_ONE_KEY];
            NSNumber *valObj2 = [undoManager currentValueForKey:PHYSICAL_SYMPTOM_TWO_KEY];
            
            if (valObj1 && !isNSNull(valObj1)) {
                sympValue1 = valObj1.unsignedLongLongValue;
            } else {
                sympValue1 = self.dailyData.physicalSymptom1;
            }
            
            if (valObj2 && !isNSNull(valObj2)) {
                sympValue2 = valObj2.unsignedLongLongValue;
            } else {
                sympValue2 = self.dailyData.physicalSymptom1;
            }
        }
        else {
            sympType = SymptomTypeEmotional;
            cell = self.cellMood;
            
            NSNumber *valObj1 = [undoManager currentValueForKey:EMOTIONAL_SYMPTOM_ONE_KEY];
            NSNumber *valObj2 = [undoManager currentValueForKey:EMOTIONAL_SYMPTOM_TWO_KEY];
            
            if (valObj1 && !isNSNull(valObj1)) {
                sympValue1 = valObj1.unsignedLongLongValue;
            } else {
                sympValue1 = self.dailyData.emotionalSymptom1;
            }
            
            if (valObj2 && !isNSNull(valObj2)) {
                sympValue2 = valObj2.unsignedLongLongValue;
            } else {
                sympValue2 = self.dailyData.emotionalSymptom2;
            }
        }
        
        if (status == DailyLogCellStatusEditing) {
        }
        else {
            [(DailyLogCellTypeSymptom *)cell configureWithValueOne:sympValue1
                                                          valueTwo:sympValue2
                                                       symptomType:sympType];
        }
    }
    
    if (DETECT_TIPS) {
        cell.label.userInteractionEnabled = YES;
        cell.label.lineBreakMode = NSLineBreakByWordWrapping;
        
        [cell.label clearCallbacks];
        for (NSString *kw in [Tooltip keywords]) {
            [cell.label setCallback:^(NSString *str) {
                [Tooltip tip:str];
            } forKeyword:kw];
        }
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
  
    if (DailyLogCellStatusEditing == status && [variousPurposesDataProvider canHideRowAtIndexPath:indexPath]){
        cell.label.userInteractionEnabled = NO;
        CGFloat height = [self tableView:self.tableView heightForRowAtIndexPath:indexPath];
        if ([variousPurposesDataProvider isCellHiddenAtIndexPath:indexPath]) {
            [cell.label setAlpha: 0.3f];
            [cell enterEditingVisibility:NO height:height];
        }
        else {
            [cell.label setAlpha: 1.f];
            [cell enterEditingVisibility:YES height:height];
        }
    }
    else {
        [cell.label setAlpha: 1.f];
        [cell exitEditing];
    }
    if (medName) {
        cell.label.userInteractionEnabled = YES;
        if (DailyLogCellStatusEditing == status) {
            cell.userInteractionEnabled = NO;
        }
        else {
            cell.userInteractionEnabled = YES;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (HEADER_CELL_TAG != cell.tag) {
        cell.backgroundColor = UIColorFromRGB(0xFBFAF7);
    }
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    DailyLogCellKey cellKey = [variousPurposesDataProvider dailyLogCellKeyForIndexPath:indexPath];
    if ([cellKey isEqual:DL_CELL_KEY_MED]) {
        NSString *medName = [variousPurposesDataProvider nameOfMedicineForIndexPath:indexPath];
        CGSize size = [UILabel sizeForText:[[NSAttributedString alloc] initWithString:medName] inBound:CGSizeMake(180, MAXFLOAT)];
        return size.height + 45;
    }
    else {
        return [self _heightForDailyLogCellKey:cellKey];
    }
}

- (CGFloat)_heightForDailyLogCellKey:(DailyLogCellKey)cellKey {
    if ([cellKey isEqual:DL_CELL_KEY_SECTION_PHYSICAL] ||
        [cellKey isEqual:DL_CELL_KEY_SECTION_EMOTIONAL] ||
        [cellKey isEqual:DL_CELL_KEY_SECTION_FERTILITY] ||
        [cellKey isEqual:DL_CELL_KEY_SECTION_SPERM_HEALTH] ||
        [cellKey isEqual:DL_CELL_KEY_MED_HEADER]) {
        return 24;
    }
    else if ([cellKey isEqual:DL_CELL_KEY_WEIGHT]) {
        return 80;
    }
    else if ([cellKey isEqual:DL_CELL_KEY_PHYSICALDISCOMFORT] || [cellKey isEqual:DL_CELL_KEY_MOODS]) {
        return 90;
    }
    else if ([self shouldExpandTableCell:cellKey]) {
        if ([cellKey isEqual:DL_CELL_KEY_CM]) {
            return 304;
        }
        else if ([cellKey isEqual:DL_CELL_KEY_INTERCOURSE]) {
            if ([self.user isMale]) {
                return 198;
            }
            if ([self.user isAvoidingPregnancy]) {
                return 212;
            } else if ([self.user isIUIOrIVF]) {
                return 252;
            } else {
                return 252;
            }
        }
        else if ([cellKey isEqual:DL_CELL_KEY_SMOKE]) {
            return 170;
        }
        else if ([cellKey isEqual:DL_CELL_KEY_ALCOHOL]) {
            return 170;
        }
        else if ([cellKey isEqual:DL_CELL_KEY_STRESS_LEVEL]) {
            return 170;
        }
        else if ([cellKey isEqual:DL_CELL_KEY_PREGNANCYTEST]) {
            return 160;
        }
        else if ([cellKey isEqual:DL_CELL_KEY_OVTEST]) {
            return 160;
        }
        else if ([cellKey isEqual:DL_CELL_KEY_PERIOD_FLOW]) {
            return 176;
        }
        else if ([cellKey isEqual:DL_CELL_KEY_EXERCISE]) {
            return 160;
        }
        else if ([cellKey isEqual:DL_CELL_KEY_MASTURBATION]) {
            return 160;
        }
        else if ([cellKey isEqual:DL_CELL_KEY_HEAT_SOURCE]) {
            return 198;
        }
        else if ([cellKey isEqual:DL_CELL_KEY_FEVER]) {
            return 160;
        }
        else {
            return 186;
        }
    } else {
        return 66;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (DailyLogCellStatusEditing == status) {
        return;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    DailyLogCellKey cellKey = [variousPurposesDataProvider dailyLogCellKeyForIndexPath:indexPath];
    if ([cellKey isEqual:DL_CELL_KEY_ADD_MED]) {
        [self _hideSaveButton];
        [self performSegueWithIdentifier:@"MedListSegueIdentifier" sender:nil from:self];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"MedListSegueIdentifier"]) {
        MedListViewController *vc = (MedListViewController *)segue.destinationViewController;
        vc.medManager = self.medManager;
        vc.date = self.medManager.date;
    }
    else if ([segue.identifier isEqual:@"Symptoms"]) {
        SymptomViewController *vc = (SymptomViewController *)[segue.destinationViewController topViewController];
        vc.symptomType = (sender == self.cellPhysicalDiscomfort) ? SymptomTypePhysical : SymptomTypeEmotional;
        vc.dailyLogUndoManager = undoManager;
        vc.userDailyData = self.dailyData;
        vc.tableViewHeader = vc.symptomType == SymptomTypePhysical ? self.physicalSymptomViewControllerHeader : nil;
        vc.delegate = self;
    }

}

#pragma mark - MedicineViewController delegate
- (void)afterMedicineViewWillDisappear {
    [variousPurposesDataProvider refreshMedsAbstractForUser:self.user dailyData:self.dailyData];
}

- (void)afterMedicineViewDidDisappear {
    [self _refreshSaveButton];
}

- (void)onConfirmDeleteMed:(NSString *)medName {
    [undoManager popMed:medName];
}

#pragma mark - Save process
- (DailyLogCellSaveResult)save
{
    if ([self hasChanges] || self.medManager.hasUpdatesForMedLogs) {
        self.dailyData = [UserDailyData
            tset:[Utils dailyDataDateLabel:self.selectedDate]
            forUser:self.user];
        
        for (DailyLogCellKey key in undoManager.valueHistory) {
            if ([key isEqual:DL_CELL_KEY_MEDS]) continue;
            
            /*
            if ([SYMPTOM_KEYS containsObject:key] && [undoManager.valueHistory[key] count] > 1) {
                [self.dailyData update:key value:[undoManager currentValueForKey:key]];
            }
            */
            id value = [undoManager currentValueForKey:key];
            
            if ([[undoManager getValueHistoryForKey:key] count] > 1) {
                [self.dailyData update:key value:value];
                [self.dailyData pushToHealthKitForKey:key value:value];
            }
        }
        if (undoManager.valueHistory[DL_CELL_KEY_MEDS]) {
            for (NSString *medName in
                undoManager.valueHistory[DL_CELL_KEY_MEDS]) {
                
                if ([undoManager.valueHistory[DL_CELL_KEY_MEDS][medName]
                    count] > 1) {
                    
                    [self.dailyData logMed:medName withValue:
                        [undoManager currentValueForMedName:medName]];
                }
            }   
        }
        
        [self.medManager saveUpdatedMedLogs];

        [self.user save];
        [self.user pushToServer];
        [self.user publish:EVENT_MULTI_DAILY_DATA_UPDATE data:DEFAULT_PB];
        [self.user publish:EVENT_DAILY_DATA_UPDATE_TO_CAL_ANIME];
        
        if (self.user.tutorialCompleted && (self.dailyData.pregnancyTest % 10 == LOG_VAL_POSITIVE)) {
            [self publish:EVENT_DAILY_LOG_PREGNANT];
        }
        
        [self.user jawboneOnDailyDataUpdated:self.selectedDate];

        GLLog(@"magic and science at work!");
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

        return dailyLogCellSaveSuccessful;
    }
    return dailyLogCellSaveSuccessful;
}

- (BOOL)hasChanges {
    return [undoManager hasChanges];
}

#pragma mark - IBAction
static UIImage *editIcon = nil;
- (UIImage *)getEditIcon {
    if (!editIcon) {
        editIcon = [UIImage imageNamed:@"dailylog-customize"];
    }
    return editIcon;
}

- (IBAction)editRowsButtonPressed:(id)sender {
    if (DailyLogCellStatusEditing != status) {
        [Logging log:BTN_CLK_CUSTOMIZE_LOG];
    
        [self _hideSaveButton];
        status = DailyLogCellStatusEditing;
        [variousPurposesDataProvider setIsEditing:YES];
        [self.editCellRowsButton setTitle:@"Save"];
        [self.editCellRowsButton setTitleTextAttributes:@{
            NSFontAttributeName: [Utils defaultFont:18]
        } forState:UIControlStateNormal];
        [self.editCellRowsButton setImage:nil];
        [self.backButton setEnabled:NO];
        self.backArrow.hidden = YES;
        [self.navigationItem setTitle:@"Customize log"];
        
        [UIView transitionWithView:self.tableView duration:0.5f options:
            UIViewAnimationOptionTransitionFlipFromRight animations:^(void) {
        
            [self.tableView reloadData];
        } completion:NULL];
    }
    else if (DailyLogCellStatusEditing == status) {
        status = DailyLogCellStatusNormal;
        [variousPurposesDataProvider setIsEditing:NO];
        [self.editCellRowsButton setTitle:@""];
        [self.editCellRowsButton setImage:[self getEditIcon]];
        [self.backButton setEnabled:YES];
        self.backArrow.hidden = NO;
        [self.navigationItem setTitle:[self.selectedDate toReadableDate]];
        [UIView transitionWithView:self.tableView duration:0.5f options:
            UIViewAnimationOptionTransitionFlipFromLeft animations:^(void) {
    
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
            if ([self hasChanges]) {
                [self _refreshSaveButton];
            }
            NSString *rowEditingSummary = [variousPurposesDataProvider
                rowEditingSummary];
            if (rowEditingSummary) {
                [dropDownMessageController postMessage:rowEditingSummary
                    duration:2 inWindow:self.view.window];
            }
        }];
        return;
    }
    return;
}
- (IBAction)saveButtonPressed:(id)sender {
    [Logging log:BTN_CLK_HOME_DAILYLOG_SAVE];
    [self save];
    [self publish:EVENT_DAILY_LOG_SAVED data:self.selectedDate];
    [self publish:EVENT_DAILY_LOG_EXIT];
    [self exit];
}

- (IBAction)backButtonPressed:(id)sender {
    
    if (self.hasChanges) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc]
            initWithTitle:@"Do you want to save your changes?"
            delegate:self cancelButtonTitle:@"Cancel"
            destructiveButtonTitle:@"No, please discard"
            otherButtonTitles:@"Yes, save my changes", nil];
        [actionSheet showInView:self.view];
    }
    else {
        [self publish:EVENT_DAILY_LOG_EXIT];
        [Logging log:BTN_CLK_HOME_DAILYLOG_BACK eventData:@{@"save": @NO}];
        [self exit];
    }
}

- (void)exit
{
    if (self.navigationController) {
        if (self.navigationController.viewControllers[0] == self) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES from:self];            
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void)scrollToWeightCell
{
    NSIndexPath *indexPath = [variousPurposesDataProvider indexPathForDailyLogCellKey:DL_CELL_KEY_WEIGHT];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    [self.cellWeight openPicker];
}

#pragma mark - UIActionSheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    if (buttonIndex == 1) {
        [Logging log:BTN_CLK_HOME_DAILYLOG_BACK eventData:@{@"save": @YES}];
        [self save];
        [self publish:EVENT_DAILY_LOG_SAVED data:self.selectedDate];
    } else {
        [Logging log:BTN_CLK_HOME_DAILYLOG_BACK eventData:@{@"save": @NO}];
        [self.user rollback];
    }
    [self publish:EVENT_DAILY_LOG_EXIT];
    [self exit];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqual:DL_CELL_KEY_INTERCOURSE]) {
        GLLog(@"intercourse changed: %@->%@: %@", change[@"old"], change[@"new"], [change[@"new"] class]);
        if (change[@"new"] && ![change[@"new"] isKindOfClass:[NSNull class]]) {
//            [self.cellPhysicalDiscomfort performSelector:@selector(hadSex:) withObject:[NSNumber numberWithBool:([change[@"new"] integerValue] > 1)]];
        }

    }
}


#pragma mark - Update Symptoms
- (void)symptomCellNeedsToPresentSymptomViewController:(DailyLogCellTypeSymptom *)cell
{
    [self performSegueWithIdentifier:@"Symptoms" sender:cell from:self];
}


- (void)symptomViewControllerDidAppear:(SymptomViewController *)viewController
{
    BOOL isPhysical = viewController.symptomType == SymptomTypePhysical;
    DailyLogCellTypeSymptom *cell =  isPhysical ? self.cellPhysicalDiscomfort : self.cellMood;
    [cell setHighlighted:NO animated:NO];
}


- (void)symptomViewController:(SymptomViewController *)viewController
            didUpdateSymptoms:(NSDictionary *)symptoms
                fieldOneValue:(NSNumber *)value1
                fieldTwoValue:(NSNumber *)value2
{
    
    SymptomType stype = viewController.symptomType;
    
    NSString *key1 = stype == SymptomTypePhysical ? PHYSICAL_SYMPTOM_ONE_KEY : EMOTIONAL_SYMPTOM_ONE_KEY;
    NSString *key2 = stype == SymptomTypePhysical ? PHYSICAL_SYMPTOM_TWO_KEY : EMOTIONAL_SYMPTOM_TWO_KEY;

    void (^undoManagerRecordValues)() = ^() {
        [undoManager recordValueForKey:key1 value:value1];
        [undoManager recordValueForKey:key2 value:value2];
        [undoManager recordAction:@[key1, key2]];
        [self.tableView reloadData];
    };
    
    NSNumber *currValue1 = [undoManager currentValueForKey:key1];
    NSNumber *currValue2 = [undoManager currentValueForKey:key2];
    if (isNSNull(currValue1)) {
        currValue1 = nil;
    }
    if (isNSNull(currValue2)) {
        currValue2 = nil;
    }
    
    if (!currValue1 && !currValue2) {
        UserDailyData *udd = self.dailyData;
        uint64_t oldValue1 = stype == SymptomTypePhysical ? udd.physicalSymptom1 : udd.emotionalSymptom1;
        uint64_t oldValue2 = stype == SymptomTypePhysical ? udd.physicalSymptom2 : udd.emotionalSymptom2;
        
        if (oldValue1 == value1.unsignedLongLongValue && oldValue2 == value2.unsignedLongLongValue) {
            [self _refreshSaveButton];
            return;
        }
        undoManagerRecordValues();
    }
    else {
        BOOL value1Changed = ![currValue1 isEqualToNumber:value1];
        BOOL value2Changed = ![currValue2 isEqualToNumber:value2];
        
        if (value1Changed || value2Changed) {
            undoManagerRecordValues();
        }
    }

    self.dailyData = [UserDailyData tset:[Utils dailyDataDateLabel:self.selectedDate] forUser:self.user];
    self.hasChanges = YES;
    [self _refreshSaveButton];
}




#pragma mark - DailyLogCellDelegate
- (void)scrollToBottom {
    [self.tableView
            scrollToRowAtIndexPath:[variousPurposesDataProvider indexPathForDailyLogCellKey:[[variousPurposesDataProvider dailyLogCellKeyOrder] lastObject]]
            atScrollPosition:UITableViewScrollPositionBottom
            animated:YES];
}

- (NSInteger)fromMfpFlag
{
    return self.dailyData.fromMfpFlag;
}

- (void)refreshLayout {
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)updateMed:(NSString *)medName withValue:(id)val {
    [undoManager recordValueMedsName:medName value:val withPadding:YES];
    [self _refreshSaveButton];
    self.hasChanges = YES;
}


- (void)updateDailyData:(NSString *)key withValue:(id)val
{
    NSIndexPath *ip = [variousPurposesDataProvider indexPathForDailyLogCellKey:key];
    DailyLogCellKey cellKey = [variousPurposesDataProvider dailyLogCellKeyForIndexPath:ip];
    BOOL shouldExpandOld = [self shouldExpandTableCell:cellKey];

    [undoManager recordValueForKey:cellKey value:val];
    [undoManager recordAction:@[cellKey]];
    
    if ([cellKey isEqual:DL_CELL_KEY_PHYSICALDISCOMFORT] || [cellKey isEqual:DL_CELL_KEY_MOODS]) {
        NSInteger value = [val integerValue];
        if (value == 0 || value == DAILY_LOG_VAL_NO) {
            BOOL isPhysical = [cellKey isEqual:DL_CELL_KEY_PHYSICALDISCOMFORT];
            NSString *key1 = isPhysical ? PHYSICAL_SYMPTOM_ONE_KEY : EMOTIONAL_SYMPTOM_ONE_KEY;
            NSString *key2 = isPhysical ? PHYSICAL_SYMPTOM_TWO_KEY : EMOTIONAL_SYMPTOM_TWO_KEY;
            
            [undoManager recordValueForKey:key1 value:@(0)];
            [undoManager recordValueForKey:key2 value:@(0)];
            [undoManager recordAction:@[key1, key2]];
            
            [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
        }
    }

    // Force update dailyData property in case it gets cleared and updated 
    self.dailyData = [UserDailyData tset:[Utils dailyDataDateLabel:self.selectedDate] forUser:self.user];
    GLLog(@"k:%@, v:%@, date:%@", key, val, self.dailyData.date);
    //[self.dailyData update:key value:val];
    
    if ([key isEqual:DL_CELL_KEY_INTERCOURSE] && [val integerValue] < 2) {
        //do not have sex, then check if physical_discomfort has 'Pain during sex', pop it if there were.
        NSNumber *physicalDiscomfort = [undoManager currentValueForKey:DL_CELL_KEY_PHYSICALDISCOMFORT];
        
        if (!isNSNull(physicalDiscomfort) && physicalDiscomfort &&
            ([physicalDiscomfort intValue] & PD_PAIN_DURING_SEX)) {
            
            [undoManager recordValueForKey:DL_CELL_KEY_PHYSICALDISCOMFORT
                                     value:@([physicalDiscomfort intValue] - PD_PAIN_DURING_SEX)];
        }
        
        NSNumber *physicalSymptom2 = [undoManager currentValueForKey:PHYSICAL_SYMPTOM_TWO_KEY];
        if (physicalSymptom2 && !isNSNull(physicalSymptom2)) {
            BOOL hasSexPain = [UserDailyData symptom:PhysicalSymptomPainDuringSex
                                             inValue:physicalSymptom2.unsignedLongLongValue];
            if (hasSexPain) {
                uint64_t newVal = [UserDailyData removeSymptom:physicalSymptom2.unsignedLongLongValue
                                                     fromValue:physicalSymptom2.unsignedLongLongValue];
                [undoManager recordValueForKey:PHYSICAL_SYMPTOM_TWO_KEY value:@(newVal)];
            }
        }
    }

    BOOL shouldExpandNew = [self shouldExpandTableCell:cellKey];

    if (shouldExpandOld != shouldExpandNew) {
        [self refreshLayout];
    }
    self.hasChanges = YES;
    [self _refreshSaveButton];
    [self _reloadStats];
}

- (void)_refreshSaveButton {
    if ([undoManager hasChanges] || self.medManager.hasUpdatesForMedLogs) {
        [self _showSaveButton];
    }
    else {
        [self _hideSaveButton];
    }
}

- (void)_showSaveButton {
    if ([self.view.subviews containsObject:self.saveButtonContainer]) {
        return;
    }
    
    [self.view addSubview:self.saveButtonContainer];
    
    self.saveButtonContainer.hidden = NO;
    self.saveButtonContainer.width = SCREEN_WIDTH;
    self.saveButtonContainer.top = self.view.height;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.saveButtonContainer.top = self.view.height - self.saveButtonContainer.height;
    }];
}

- (void)_hideSaveButton {
    if (![self.view.subviews containsObject:self.saveButtonContainer]) {
        return;
    }
    
    [self.view addSubview:self.saveButtonContainer];
    self.saveButtonContainer.top = self.view.height - self.saveButtonContainer.height;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.saveButtonContainer.top = self.view.height;
    } completion:^(BOOL finished) {
        [self.saveButtonContainer removeFromSuperview];
        [self.saveButtonContainer setHidden:YES];
    }];
}

- (void)setDailyData:(UserDailyData *)dailyData {
    if (_dailyData) {
        [_dailyData removeObserver:self forKeyPath:DL_CELL_KEY_INTERCOURSE];
    }
    _dailyData = dailyData;
    if (_dailyData) {
        [_dailyData addObserver:self forKeyPath:DL_CELL_KEY_INTERCOURSE
            options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
            context:nil];
    }
}

- (void)findAndResignFirstResponder {
    id fr = [self.tableView findAndResignFirstResponder];
    [self publish:EVENT_KEYBOARD_DISMISSED data:fr];
}

#pragma mark - Tooltip
- (void)tooltipKeywordsUpdatedFromServer:(Event *)event;
{
    NSArray *arr = (NSArray *)event.data;
    [Tooltip updateKeywords:arr];
    [self.tableView reloadData];
}

#pragma mark - Hide/Unhide log cell
- (void)setCell:(DailyLogCellTypeBase *)cell visible:(BOOL)isVisibile {
    if (DailyLogCellStatusEditing != status) {
        return;
    }
    if (isVisibile) {
        [variousPurposesDataProvider unhideCellAtIndexPath:
            [self.tableView indexPathForCell:cell]];
    }
    else {
        [variousPurposesDataProvider hideCellAtIndexPath:
            [self.tableView indexPathForCell:cell]];
    }
    [self.tableView reloadData];
}

#pragma mark - top view
- (void)_reloadStats
{
    NSMutableDictionary * undoDailyData = [[NSMutableDictionary alloc] init];
    for (NSString *cellKey in DL_CELL_NORMAL_KEYS) {
        id v = [undoManager currentValueForKey:cellKey];
        if (v) {
            [undoDailyData setObject:v forKey:cellKey];
        }
    }
    
    [self.topView reloadWithDailyData:undoDailyData];
}


#pragma mark - Gesture

- (UIPanGestureRecognizer*)panGesture {	return objc_getAssociatedObject(self, @selector(panGesture)); }

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    return YES;
}

#pragma mark - GLLogStatistic handler
- (void)goFertilitySection:(Event *)event {
    NSIndexPath * idxPath = [variousPurposesDataProvider indexPathForDailyLogCellKey:DL_CELL_KEY_SECTION_FERTILITY];
    if (!idxPath) {
        idxPath = [variousPurposesDataProvider indexPathForDailyLogCellKey:DL_CELL_KEY_SECTION_SPERM_HEALTH];
    }
    [self.tableView scrollToRowAtIndexPath:idxPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}
- (void)goPhysicalSection:(Event *)event {
    NSIndexPath * idxPath = [variousPurposesDataProvider indexPathForDailyLogCellKey:DL_CELL_KEY_SECTION_PHYSICAL];
    [self.tableView scrollToRowAtIndexPath:idxPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}
- (void)goEmotionalSection:(Event *)event {
    NSIndexPath * idxPath = [variousPurposesDataProvider indexPathForDailyLogCellKey:DL_CELL_KEY_SECTION_EMOTIONAL];
    [self.tableView scrollToRowAtIndexPath:idxPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

@end
