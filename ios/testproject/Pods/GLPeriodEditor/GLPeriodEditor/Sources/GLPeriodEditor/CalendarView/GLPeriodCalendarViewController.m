//
//  GLPeriodCalendarViewController.m
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-23.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLPeriodCalendarViewController.h"
#import "GLCalendarView.h"
#import "GLDateUtils.h"
#import "GLPeriodEditorHeader.h"
#import "GLCalendarDayCell.h"
#import "UINavigationBar+BackgroundColor.h"
#import "GLCalendarDateRange.h"
#import <GLFoundation/GLMarkdownLabel.h>
#import "GLCycleData+GLCalendarDateRange.h"
#import <GLFoundation/GLTheme.h>
#import <GLFoundation/GLPillGradientButton.h>

#define ACTION_SHEET_CONFIRM_ADD 1
#define ACTION_SHEET_CONFIRM_DELETE 2
#define ACTION_SHEET_CONFIRM_SAVE 3

#define NAVBAR_COLOR [UIColor colorWithRed:(247/255.0) green:(247/255.0) blue:(247/255.0) alpha:1]


@interface GLPeriodCalendarViewController () <GLCalendarViewDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UIView *tipContainer;
@property (weak, nonatomic) IBOutlet GLCalendarView *calendarView;
@property (weak, nonatomic) IBOutlet GLMarkdownLabel *tip1;
@property (weak, nonatomic) IBOutlet GLMarkdownLabel *tip2;
@property (weak, nonatomic) IBOutlet GLPillGradientButton *changePeriodButton;
@property (weak, nonatomic) IBOutlet UIToolbar *changePeriodButtonContainer;
@property (nonatomic, strong) GLCalendarDateRange *rangeUnderEdit;
@property (nonatomic, weak) GLCalendarDateRange *rangeToConfirmSave;
@property (nonatomic, strong) NSMutableArray *rangesToHide;
@end

@implementation GLPeriodCalendarViewController
+ (instancetype)instance
{
    return [[UIStoryboard storyboardWithName:@"GLPeriodEditor" bundle:nil] instantiateViewControllerWithIdentifier:@"GLPeriodCalendarViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.calendarView.showMaginfier = YES;
    self.calendarView.backToTodayButtonDisplayOptions = HideBackToTodayButtonAfterToday;
    self.calendarView.firstDate = self.firstDate;
    self.calendarView.lastDate = self.lastDate;
    self.calendarView.delegate = self;
    self.rangesToHide = [NSMutableArray array];
    [self.changePeriodButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self setMode:MODE_NORMAL animated:NO];
    [self subscribe:EVENT_PERIOD_EDITOR_CALENDAR_VIEW_NEEDS_RELOAD selector:@selector(reloadData)];
    [self reloadData];
    
    NSDate *selectedDate;
    if (self.containerViewController.delegate) {
        selectedDate = [self.containerViewController.delegate selectedDate];
    } else {
        selectedDate = self.calendarView.lastDate;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.calendarView scrollToDate:selectedDate animated:NO];
    });
    
    self.changePeriodButtonContainer.hidden = self.hideBottomBar;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unsubscribeAll];
}


- (void)reloadData
{
    self.calendarView.ranges = [self rangesFromCycleDataList:self.cycleDataList];

    [self.calendarView reload];
    [self.rangesToHide removeAllObjects];
//    self.rangeUnderEdit = nil;
    self.rangeToConfirmSave = nil;
    self.changePeriodButtonContainer.hidden = self.hideBottomBar;
    [self showChangePeriodButtonIfNeededWithAnimation:YES];
}

- (NSMutableArray *)rangesFromCycleDataList:(NSArray *)cycleDataList;
{
    NSMutableArray* allRanges = [NSMutableArray array];
    for (GLCycleData *cycleDate in self.cycleDataList) {
        [allRanges addObjectsFromArray:[cycleDate dateRanges]];
    }
    return allRanges;
}

- (void)setMode:(MODE)mode animated:(BOOL)animated
{
    [super setMode:mode];
    [self ajdustLookToMode:mode animated:animated];
}

- (void)setMode:(MODE)mode
{
    [super setMode:mode];
    [self ajdustLookToMode:mode animated:YES];
}

- (void)ajdustLookToMode:(MODE)mode animated:(BOOL)animated
{
    CGFloat duration = animated ? 0.2 : 0;
    if (mode == MODE_EDITING) {
        [UIView animateWithDuration:duration animations:^{
            UIColor *backgroundColor = [GLCycleAppearance sharedInstance].backgroundColorForPeriod ?: GLOW_COLOR_PINK;
            
            [self.navigationController.navigationBar gl_setBackgroundColor:backgroundColor];
            [self.containerViewController setStatusBarStyle:UIStatusBarStyleLightContent];
            [self.containerViewController showLabelTitleWithText:[self descriptionForRange:self.rangeUnderEdit]];
            self.tipContainer.backgroundColor = backgroundColor;
            
            UIButton *leftNavButton = self.containerViewController.leftNavButton;
            [leftNavButton setImage:nil forState:UIControlStateNormal];
            [leftNavButton setTitle:NSLocalizedStringFromTable(@"Delete", @"GLPeriodEditorLocalizedString", nil) forState:UIControlStateNormal];
            [leftNavButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [leftNavButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

            UIButton *rightNavButton = self.containerViewController.rightNavButton;
            [rightNavButton setImage:nil forState:UIControlStateNormal];
            [rightNavButton setTitle:NSLocalizedStringFromTable(@"Save", @"GLPeriodEditorLocalizedString", nil) forState:UIControlStateNormal];
            rightNavButton.titleLabel.font = [GLTheme boldFont:19];
            [rightNavButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [rightNavButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
            
            self.tip1.markdownText = NSLocalizedStringFromTable(@"Drag end points to adjust its length", @"GLPeriodEditorLocalizedString", nil);
            self.tip2.markdownText = NSLocalizedStringFromTable(@"Click **Delete** to delete a cycle", @"GLPeriodEditorLocalizedString", nil);
            
            
            [self hideAllPredictions];
        }];
        [self hideChangePeriodButtonWithAnimation:YES];
    } else {
        [UIView animateWithDuration:duration animations:^{
            [self.navigationController.navigationBar gl_setBackgroundColor:NAVBAR_COLOR];
            [self.containerViewController setStatusBarStyle:UIStatusBarStyleDefault];
            [self.containerViewController showSegmentedControlTitle];
            self.tipContainer.backgroundColor = GLOW_COLOR_PURPLE;

            UIButton *leftNavButton = self.containerViewController.leftNavButton;
            [leftNavButton setImage:[UIImage imageNamed:@"gl-foundation-back.png"] forState:UIControlStateNormal];
            [leftNavButton setTitle:@"" forState:UIControlStateNormal];
            [leftNavButton setTitleColor:GLOW_COLOR_PURPLE forState:UIControlStateNormal];

            UIButton *rightNavButton = self.containerViewController.rightNavButton;
            [rightNavButton setImage:[UIImage imageNamed:@"gl-period-editor-icon-info.png"] forState:UIControlStateNormal];
            [rightNavButton setTitle:@"" forState:UIControlStateNormal];
            [rightNavButton setTitleColor:GLOW_COLOR_PURPLE forState:UIControlStateNormal];
            
            NSString *textForTip1 = [GLCycleAppearance sharedInstance].textForPeriodColor ?: NSLocalizedStringFromTable(@"Tap on pink periods to **edit/delete**", @"GLPeriodEditorLocalizedString", nil);
            self.tip1.markdownText = NSLocalizedStringFromTable(textForTip1, @"GLPeriodEditorLocalizedString", nil);
            self.tip2.markdownText = NSLocalizedStringFromTable(@"Tap on other days to **add new cycles**", @"GLPeriodEditorLocalizedString", nil);
            
            [self showAllPredictions];
        }];
        [self showChangePeriodButtonIfNeededWithAnimation:YES];
    }
}

- (void)leftNavButtonPressed:(UIButton *)sender
{
    if (self.mode == MODE_EDITING) {
        [self promptConfirmDelete];
        [self sendLoggingEvent:BTN_CLK_CAL_VIEW_PERIOD_DEL data:nil];
    } else {
        [super leftNavButtonPressed:sender];
    }
}

- (void)rightNavButtonPressed:(UIButton *)sender
{
    if (self.mode == MODE_EDITING) {
        self.mode = MODE_NORMAL;
        GLCycleData *cycleData = self.rangeUnderEdit.binding;
        BOOL modified = ![cycleData sameAsRange:self.rangeUnderEdit];
        if (modified) {
            [self updateCycleData:cycleData withPeriodBeginDate:self.rangeUnderEdit.beginDate periodEndDate:self.rangeUnderEdit.endDate];
            [self publish:EVENT_PERIOD_EDITOR_TABLEVIEW_NEEDS_RELOAD];
            [self sendLoggingEvent:BTN_CLK_CAL_VIEW_PERIOD_SAVE data:cycleData];
        } else {
            [self sendLoggingEvent:BTN_CLK_CAL_VIEW_PERIOD_SAVE data:nil];
        }
        [self.calendarView forceFinishEdit];
        self.rangeUnderEdit = nil;
    } else {
        [super rightNavButtonPressed:sender];
    }
}

- (void)showAllPredictions
{
    for (GLCalendarDateRange *range in self.rangesToHide) {
        [self.calendarView addRange:range];
    }
    [self.rangesToHide removeAllObjects];
}

- (void)hideAllPredictions
{
    NSArray *ranges = [self.calendarView.ranges copy];
    for (GLCalendarDateRange *range in ranges) {
        if (!range.editable) {
            [self.calendarView removeRange:range];
            [self.rangesToHide addObject:range];
        }
    }
}

# pragma mark - GLCalendarView delegate

- (BOOL)calenderView:(GLCalendarView *)calendarView canAddRangeWithBeginDate:(NSDate *)beginDate
{
    if ([beginDate timeIntervalSinceNow] > 0) {
        [self.containerViewController didWantToAddCycleInFuture];
        return NO;
    }
    
    NSInteger predictedPeriodLength = self.predictedPeriodLength;
    
    for (GLCycleData *data in self.cycleDataList) {
        if (data.isFuture || data.showAsPrediction) {
            continue;
        }
        // too close to existing pb
        NSInteger dateToPb = [GLDateUtils daysBetween:beginDate and:data.periodBeginDate];
        if (dateToPb >= 0 && dateToPb <= predictedPeriodLength + 2) {
            [self.containerViewController didWantToAddCycleNearExistingOne];
            return NO;
        }
        // too close to existing pe
        NSInteger peToDate = [GLDateUtils daysBetween:data.periodEndDate and:beginDate];
        if (peToDate >= 0 && peToDate <= 3) {
            [self.containerViewController didWantToAddCycleNearExistingOne];
            return NO;
        }
    }
    [self hideAllPredictions];
    return YES;
}

- (GLCalendarDateRange *)calenderView:(GLCalendarView *)calendarView rangeToAddWithBeginDate:(NSDate *)beginDate
{
    [self promptConfirmAddWithDate:beginDate];
    NSDate *endDate = [GLDateUtils dateByAddingDays:(self.predictedPeriodLength - 1) toDate:beginDate];
    GLCalendarDateRange *range = [GLCalendarDateRange rangeWithBeginDate:beginDate endDate:endDate];
    range.backgroundColor = [GLCycleAppearance sharedInstance].backgroundColorForPeriod ?: GLOW_COLOR_PINK;
    self.rangeUnderEdit = range;
    return range;
}

- (void)calenderView:(GLCalendarView *)calendarView beginToEditRange:(GLCalendarDateRange *)range
{
    self.rangeUnderEdit = range;
    self.mode = MODE_EDITING;
}

- (void)calenderView:(GLCalendarView *)calendarView finishEditRange:(GLCalendarDateRange *)range continueEditing:(BOOL)continueEditing
{
    GLCycleData *cycleDate = range.binding;
    if (![cycleDate sameAsRange:range]) {
        self.rangeToConfirmSave = range;
        [self promptConfirmSave];
    } else {
        self.rangeUnderEdit = nil;
        if (!continueEditing) {
            self.mode = MODE_NORMAL;
        }
    }
}

- (BOOL)calenderView:(GLCalendarView *)calendarView canUpdateRange:(GLCalendarDateRange *)range toBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate
{
    NSDate *today = self.today;
    GLCycleData *currentCycleData = range.binding;
    // future dates
    if ([range.beginDate compare:today] == NSOrderedDescending) {
        return NO;
    }
    if ([beginDate compare:today] == NSOrderedDescending) {
        [self.containerViewController didWantToUpdateBeginDateToFutuerDays];
        return NO;
    }
    if ([GLDateUtils date:beginDate isSameDayAsDate:endDate]) {
        return NO;
    }
    
    BOOL updateBeginDate = ![GLDateUtils date:range.beginDate isSameDayAsDate:beginDate];
    
    if (updateBeginDate) {
        GLCycleData *previousCycleData = [self previousCycleData:currentCycleData];
        if (!previousCycleData) {
            return YES;
        }
        NSDate *previousPeriodEndDate = previousCycleData.periodEndDate;
        NSInteger daysToPreiouvsPe = [GLDateUtils daysBetween:previousPeriodEndDate and:beginDate];
        if (daysToPreiouvsPe <= 3) {
            return NO;
        }
    } else {
        GLCycleData *nextCycleData = [self nextCycleData:currentCycleData];
        if (!nextCycleData || nextCycleData.isFuture) {
            return YES;
        }
        NSDate *nextPeriodBeginDate = nextCycleData.periodBeginDate;
        // too close to next pb
        NSInteger daysToNextPb = [GLDateUtils daysBetween:endDate and:nextPeriodBeginDate];
        if (daysToNextPb <= 3) {
            return NO;
        }
    }
    return YES;
}

- (void)calenderView:(GLCalendarView *)calendarView didUpdateRange:(GLCalendarDateRange *)range toBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate
{
    [self.containerViewController showLabelTitleWithText:[self descriptionForRange:self.rangeUnderEdit]];
}

# pragma mark - change period button
- (void)setHideBottomBar:(BOOL)hideBottomBar {
    _hideBottomBar = hideBottomBar;
    self.changePeriodButtonContainer.hidden = hideBottomBar;
}

- (void)showChangePeriodButtonIfNeededWithAnimation:(BOOL)animated
{
    if (self.hideBottomBar) {
        return;
    }
    GLCycleData *cycleDate = [self availableCycleDataForShortcutButton];
    if (!cycleDate) {
        [self hideChangePeriodButtonWithAnimation:NO];
        return;
    }
    BOOL isTodayInPeriod = [cycleDate periodContainsDate:self.today];
    if (isTodayInPeriod) {
        [self.changePeriodButton setTitle:NSLocalizedStringFromTable(@"My period is late", @"GLPeriodEditorLocalizedString", nil) forState:UIControlStateNormal];
    } else {
        [self.changePeriodButton setTitle:NSLocalizedStringFromTable(@"My period started today", @"GLPeriodEditorLocalizedString", nil) forState:UIControlStateNormal];
    }
    [UIView animateWithDuration:(animated ? 0.3 : 0) animations:^{
        self.changePeriodButtonContainer.transform = CGAffineTransformIdentity;
    }];
}

- (void)hideChangePeriodButtonWithAnimation:(BOOL)animated;
{
    [UIView animateWithDuration:(animated ? 0.3 : 0) animations:^{
        self.changePeriodButtonContainer.transform = CGAffineTransformMakeTranslation(0, 64);
    }];
}

- (IBAction)changePeriodButtonPressed:(id)sender
{
    NSDate *today = self.today;
    GLCycleData *cycleDate = [self availableCycleDataForShortcutButton];
    if ([cycleDate periodContainsDate:today]) {
        // my period is late
        NSInteger days = [GLDateUtils daysBetween:cycleDate.periodBeginDate and:[GLDateUtils dateByAddingDays:2 toDate:today]];
        [self shiftCycleData:cycleDate ByDays:days];
        [self sendLoggingEvent:BTN_CLK_CAL_VIEW_PERIOD_IS_LATE data:nil];
    } else {
        // my period started today
        NSInteger days = [GLDateUtils daysBetween:today and:cycleDate.periodBeginDate];
        [self shiftCycleData:cycleDate ByDays:-days];
        [self sendLoggingEvent:BTN_CLK_CAL_VIEW_PERIOD_STARTED_TODAY data:nil];
    }
    [self hideChangePeriodButtonWithAnimation:YES];
    [self publish:EVENT_PERIOD_EDITOR_TABLEVIEW_NEEDS_RELOAD];
}

- (void)shiftCycleData:(GLCycleData *)cycleData ByDays:(NSInteger)days
{
    GLCalendarDateRange *range = [self rangeForCycleData:cycleData];
    NSDate *beginDate = [GLDateUtils dateByAddingDays:days toDate:cycleData.periodBeginDate];
    NSDate *endDate = [GLDateUtils dateByAddingDays:days toDate:cycleData.periodEndDate];
    [self updateCycleData:cycleData withPeriodBeginDate:beginDate periodEndDate:endDate];

    [cycleData updatePeriodRangeLook:range];
    [self.calendarView updateRange:range withBeginDate:beginDate endDate:endDate];
}

- (GLCalendarDateRange *)rangeForCycleData:(GLCycleData *)cycleData
{
    for (GLCalendarDateRange *range in self.calendarView.ranges) {
        if (range.binding == cycleData) {
            return range;
        }
    }
    return nil;
}

- (GLCycleData *)availableCycleDataForShortcutButton
{
    NSDate *today = self.today;
    
    GLCycleData *cycleDataContainsToday;
    GLCycleData *cycleDataInNearFuture;
    
    for (GLCycleData *cycleData in self.cycleDataList) {
        if ([cycleData periodContainsDate:today]) {
            cycleDataContainsToday = cycleData;
            break;
        }
        NSInteger dayDiffs = [GLDateUtils daysBetween:today and:cycleData.periodBeginDate];
        if (dayDiffs > 0 && dayDiffs < 10) {
            cycleDataInNearFuture = cycleData;
        }
    }
    if (cycleDataContainsToday) {
        return cycleDataContainsToday;
    }
    if (cycleDataInNearFuture) {
        return cycleDataInNearFuture;
    }
    return nil;
}

# pragma mark - action sheet

- (void)promptConfirmSave
{
    [self showConfirmActionSheetWithTitle:nil
                              cancelTitle:NSLocalizedStringFromTable(@"Undo", @"GLPeriodEditorLocalizedString", nil)
                             confirmTitle:NSLocalizedStringFromTable(@"Save last change", @"GLPeriodEditorLocalizedString", nil) tag:ACTION_SHEET_CONFIRM_SAVE];
}

- (void)promptConfirmDelete {
    
    [self showConfirmActionSheetWithTitle:nil
                              cancelTitle:NSLocalizedStringFromTable(@"Cancel", @"GLPeriodEditorLocalizedString", nil)
                             confirmTitle:NSLocalizedStringFromTable(@"Delete period", @"GLPeriodEditorLocalizedString", nil) tag:ACTION_SHEET_CONFIRM_DELETE];
}

- (void)promptConfirmAddWithDate:(NSDate *)date
{
    [self hideChangePeriodButtonWithAnimation:YES];
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale currentLocale];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"Md" options:0 locale:dateFormatter.locale];
    }
    NSString *confirmString = [NSString stringWithFormat:
                               NSLocalizedStringFromTable(@"Add %@ as start date", @"GLPeriodEditorLocalizedString", nil), [dateFormatter stringFromDate:date]];
    [self showConfirmActionSheetWithTitle:nil cancelTitle:NSLocalizedStringFromTable(@"Cancel", @"GLPeriodEditorLocalizedString", nil)
                             confirmTitle:confirmString tag:ACTION_SHEET_CONFIRM_ADD];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == ACTION_SHEET_CONFIRM_ADD) {
        // cancel
        if (buttonIndex == 0) {
            if (!self.rangeUnderEdit) {
                return;
            }
            GLCycleData *cycleData = [GLCycleData dataWithPeriodBeginDate:self.rangeUnderEdit.beginDate periodEndDate:self.rangeUnderEdit.endDate];
            [self addCycleData:cycleData];
            self.rangeUnderEdit.binding = cycleData;
            [self publish:EVENT_PERIOD_EDITOR_TABLEVIEW_NEEDS_RELOAD];
            [self sendLoggingEvent:BTN_CLK_CAL_VIEW_PERIOD_ADD_CONFIRM data:cycleData];
        } else if (buttonIndex == 1){
            [self.calendarView removeRange:self.rangeUnderEdit];
            [self showAllPredictions];
        }
        self.rangeUnderEdit = nil;
        return;
    }
    if (actionSheet.tag == ACTION_SHEET_CONFIRM_DELETE) {
        // delete
        if (buttonIndex == 0) {
            GLCycleData *cycleData = self.rangeUnderEdit.binding;
            [self sendLoggingEvent:BTN_CLK_CAL_VIEW_PERIOD_DEL_CONFIRM data:cycleData];
            [self removeCycleData:cycleData];
            [self.calendarView removeRange:self.rangeUnderEdit];
            self.rangeUnderEdit = nil;
            self.mode = MODE_NORMAL;
            [self publish:EVENT_PERIOD_EDITOR_TABLEVIEW_NEEDS_RELOAD];
        }
        return;
    }
    if (actionSheet.tag == ACTION_SHEET_CONFIRM_SAVE) {
        if (buttonIndex == 0) {
            // confirm change
            GLCycleData *cycleData = self.rangeToConfirmSave.binding;
            [self updateCycleData:cycleData withPeriodBeginDate:self.rangeToConfirmSave.beginDate periodEndDate:self.rangeToConfirmSave.endDate];
            [self publish:EVENT_PERIOD_EDITOR_TABLEVIEW_NEEDS_RELOAD];
        } else if (buttonIndex == 1) {
            // undo change
            GLCycleData *cycleData = self.rangeToConfirmSave.binding;
            [self.calendarView updateRange:self.rangeToConfirmSave withBeginDate:cycleData.periodBeginDate endDate:cycleData.periodEndDate];
        }
        // if no continious editing
        if (self.rangeUnderEdit == self.rangeToConfirmSave) {
            self.mode = MODE_NORMAL;
            [self publish:EVENT_PERIOD_EDITOR_INDICATE_CAN_RELOAD_DATA];
        }
    }
}

- (void)showConfirmActionSheetWithTitle:(NSString *)title cancelTitle:(NSString *)cancelTitle confirmTitle:(NSString *)confirmTitle tag:(NSInteger)tag
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:title
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:confirmTitle
                                  otherButtonTitles:nil];
    actionSheet.tag = tag;
    [actionSheet showInView:self.view];
}

# pragma mark - helper
- (NSInteger)predictedPeriodLength
{
    GLCycleData *cycleData = self.cycleDataList.firstObject;
    if (cycleData) {
        return cycleData.periodLength;
    } else {
        return 5;
    }
}

- (GLCycleData *)previousCycleData:(GLCycleData *)cycleData
{
    NSInteger index = [self.cycleDataList indexOfObject:cycleData];
    if (index + 1 < self.cycleDataList.count) {
        return self.cycleDataList[index + 1];
    } else {
        return nil;
    }
}

- (GLCycleData *)nextCycleData:(GLCycleData *)cycleData
{
    NSInteger index = [self.cycleDataList indexOfObject:cycleData];
    if (index - 1 >= 0) {
        return self.cycleDataList[index - 1];
    } else {
        return nil;
    }
}

- (NSString *)descriptionForRange:(GLCalendarDateRange *)range
{
    return [GLDateUtils descriptionForBeginDate:range.beginDate endDate:range.endDate];
}

static NSDate *today;
- (NSDate *)today
{
    if (!today) {
        today = [GLDateUtils cutDate:[NSDate date]];
    }
    return today;
}


@end
