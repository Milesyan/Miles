//
//  GLPeriodEditorViewController.m
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-23.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLPeriodEditorViewController.h"
#import "GLPeriodTableViewController.h"
#import "GLPeriodCalendarViewController.h"
#import "GLPeriodEditorChildViewController.h"
#import "GLPeriodEditorHeader.h"
#import "GLCycleData.h"
#import "GLDateUtils.h"
#import "GLCalendarView.h"
#import "GLCalendarDayCell.h"
#import <GLFoundation/GLTheme.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import "GLPeriodEditorTipsPopup.h"

@interface GLPeriodEditorViewController ()
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) UILabel *titleLabel;
@property (nonatomic, weak) GLPeriodCalendarViewController *calendarVC;
@property (nonatomic, weak) GLPeriodEditorChildViewController *tableVC;
@property (nonatomic) BOOL needsReload;
@end

@implementation GLPeriodEditorViewController

static NSString *_classForStoryboard;
+ (void)useSubclass:(NSString *)classString
{
    if ([NSClassFromString(classString) isSubclassOfClass:[self class]]) {
        _classForStoryboard = [classString copy];
    } else {
        _classForStoryboard = nil;
    }
}

+ (GLPeriodEditorNavigationViewController *)instance
{
    return [GLPeriodEditorViewController instanceOfSubClass:NSStringFromClass([GLPeriodEditorViewController class])];
}

+ (GLPeriodEditorNavigationViewController *)instanceOfSubClass:(NSString *)classString
{
    [self useSubclass:classString];
    return [[UIStoryboard storyboardWithName:@"GLPeriodEditor" bundle:nil] instantiateInitialViewController];
}

+ (instancetype)alloc
{
    if (_classForStoryboard == nil) {
        return [super alloc];
    } else {
        if (NSClassFromString(_classForStoryboard) != [self class]) {
            GLPeriodEditorViewController *subclassedVC = [NSClassFromString(_classForStoryboard) alloc];
            return subclassedVC;
        } else {
            return [super alloc];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.scrollEnabled = YES;
    self.scrollView.bounces = NO;
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [GLTheme semiBoldFont:24];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    
    GLPeriodCalendarViewController *calendarVC = [GLPeriodCalendarViewController instance];
    calendarVC.firstDate = self.firstDate;
    calendarVC.lastDate = self.lastDate;
    calendarVC.hideBottomBar = self.hideBottomBar;
    self.calendarVC = calendarVC;
    
    GLPeriodEditorChildViewController *tableVC = [GLPeriodTableViewController instance];
    self.tableVC = tableVC;
    
    [@[calendarVC, tableVC] enumerateObjectsUsingBlock:^(GLPeriodEditorChildViewController *vc, NSUInteger idx, BOOL *stop) {
        vc.containerViewController = self;
        vc.cycleDataList = self.cycleDataList;
        [self addChildViewController:vc];
    }];
    
    self.statusBarStyle = UIStatusBarStyleDefault;
    
    [self.leftNavButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -8, 0, 0)];
    [self.leftNavButton setImageEdgeInsets:UIEdgeInsetsMake(0, -8, 0, 0)];
    [self.rightNavButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -8)];
    [self.rightNavButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -8)];
    
    [self subscribe:EVENT_PERIOD_EDITOR_INDICATE_CAN_RELOAD_DATA selector:@selector(reloadDataIfNeeded)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.segmentedControl.width = self.view.width - 170;
    self.cycleDataList = [self initialData];
    [self scrollToPage:0 animated:NO];
    self.segmentedControl.selectedSegmentIndex = 0;
}

- (void)setCycleDataList:(NSMutableArray *)cycleDataList
{
    _cycleDataList = [[self sortedResultFor:cycleDataList] mutableCopy];
    [self.childViewControllers enumerateObjectsUsingBlock:^(GLPeriodEditorChildViewController *vc, NSUInteger idx, BOOL *stop) {
        vc.cycleDataList = _cycleDataList;
    }];
}

- (void)reloadData
{
    if (self.mode == MODE_EDITING) {
        self.needsReload = YES;
        return;
    }
    self.needsReload = YES;
    [self reloadDataIfNeeded];
}

- (void)reloadDataIfNeeded
{
    if (self.needsReload) {
        self.needsReload = NO;
        self.cycleDataList = [self initialData];
        [self.childViewControllers enumerateObjectsUsingBlock:^(GLPeriodEditorChildViewController *vc, NSUInteger idx, BOOL *stop) {
            [vc reloadData];
        }];
    }
}



- (void)reloadCalendarView
{
    self.cycleDataList = [self initialData];
    [self.calendarVC reloadData];
}

- (void)setHideBottomBar:(BOOL)hideBottomBar
{
    _hideBottomBar = hideBottomBar;
    self.calendarVC.hideBottomBar = hideBottomBar;
}

- (void)showSegmentedControlTitle
{
    self.navigationItem.titleView = self.segmentedControl;
}

- (void)showLabelTitleWithText:(NSString *)text
{
    self.navigationItem.titleView = self.titleLabel;
    self.titleLabel.text = text;
}

- (NSMutableArray *)initialData
{
    return [self.dataSource initialDataForPeriodEditor:self];
}

- (void)didUpdateCycleData:(GLCycleData *)cycleData withPeriodBeginDate:(NSDate *)periodBeginDate periodEndDate:(NSDate *)periodEndDate
{
    [self.delegate editor:self didUpdateCycleData:cycleData withPeriodBeginDate:periodBeginDate periodEndDate:periodEndDate];
    cycleData.periodBeginDate = periodBeginDate;
    cycleData.periodEndDate = periodEndDate;
}

- (void)didAddCycleData:(GLCycleData *)cycleData
{
    [self.delegate editor:self didAddCycleData:cycleData];
    [self.cycleDataList addObject:cycleData];
    self.cycleDataList = self.cycleDataList;
}

- (void)didRemoveCycleData:(GLCycleData *)cycleData
{
    [self.delegate editor:self didRemoveCycleData:cycleData];
    [self.cycleDataList removeObject:cycleData];
}

- (void)didClickInfoIcon
{
    if (self.delegate) {
        [self.delegate editorDidClickInfoIcon:self];
    } else {
        [GLPeriodEditorTipsPopup presentWithURL:@"http://localhost:8080/term/period_editor_tips"]; 
    }
}

- (void)didWantToAddCycleNearExistingOne
{
    [[GLDropdownMessageController sharedInstance] postMessage:NSLocalizedStringFromTable(@"You can't add a period near an existing period", @"GLPeriodEditorLocalizedString", nil) duration:1.5f inWindow:self.view.window];
}

- (void)didWantToAddCycleInFuture
{
    [[GLDropdownMessageController sharedInstance] postMessage:NSLocalizedStringFromTable(@"You can't add a new period in the future.", @"GLPeriodEditorLocalizedString", nil) duration:1.5f inWindow:self.view.window];
}

- (void)didWantToDeleteTheLatestCycle
{
    [[GLDropdownMessageController sharedInstance] postMessage:NSLocalizedStringFromTable(@"Sorry, your latest period cannot be deleted", @"GLPeriodEditorLocalizedString", nil) duration:1.5f inWindow:self.view.window];
}

- (void)didWantToUpdateBeginDateToFutuerDays
{
    [[GLDropdownMessageController sharedInstance] postMessage:NSLocalizedStringFromTable(@"Can't record a period start date in the future.", @"GLPeriodEditorLocalizedString", nil) duration:1.5f inWindow:self.view.window];
}


- (void)didReceiveLoggingEvent:(LOGGING_EVENT)event data:(id)data
{
    [self.delegate editor:self didReceiveLoggingEvent:event data:data];
}

- (NSArray *)sortedResultFor:(NSArray *)cycleDataList;
{
    return [cycleDataList sortedArrayUsingComparator:^NSComparisonResult(GLCycleData *data1, GLCycleData *data2) {
        return [data2.periodBeginDate compare:data1.periodBeginDate];
    }];
}

- (void)setMode:(MODE)mode
{
    _mode = mode;
    if (mode == MODE_EDITING) {
        self.scrollEnabled = NO;
    } else {
        self.scrollEnabled = YES;
    }
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    _scrollEnabled = scrollEnabled;
    self.segmentedControl.userInteractionEnabled = scrollEnabled;
    self.scrollView.scrollEnabled = scrollEnabled;
}

- (IBAction)leftNavButtonPressed:(UIButton *)sender
{
    [[self currentChildViewController] leftNavButtonPressed:sender];
}

- (IBAction)rightNavButtonPressed:(id)sender
{
    [[self currentChildViewController] rightNavButtonPressed:sender];
}


- (void)didScrollToPage:(int)page
{
    if (page == 0) {
        [self didReceiveLoggingEvent:BTN_CLK_VIEW_CAL_VIEW data:nil];
    } else if (page == 1) {
        [self didReceiveLoggingEvent:BTN_CLK_VIEW_LIST_VIEW data:nil];
    }
    [super didScrollToPage:page];
    self.segmentedControl.selectedSegmentIndex = page;
    [super setNeedsStatusBarAppearanceUpdate];
}

- (IBAction)segmentedControlPressed:(id)sender
{
    NSInteger page = self.segmentedControl.selectedSegmentIndex;
    if (page == 0) {
        [self didReceiveLoggingEvent:BTN_CLK_VIEW_CAL_VIEW data:nil];
    } else if (page == 1) {
        [self didReceiveLoggingEvent:BTN_CLK_VIEW_LIST_VIEW data:nil];
    }
    [self scrollToPage:(int)page animated:YES];
}

- (GLPeriodEditorChildViewController *)currentChildViewController
{
    return self.childViewControllers[self.segmentedControl.selectedSegmentIndex];
}

- (void)setStatusBarStyle:(UIStatusBarStyle)barStyle
{
    _statusBarStyle = barStyle;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.statusBarStyle;
}
@end
