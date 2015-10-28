//
//  GLOnboardingPeriodEditorBaseViewController.m
//  GLPeriodEditor
//
//  Created by ltebean on 15-4-30.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLOnboardingPeriodCalendarBaseViewController.h"
#import "GLCalendarDayCell.h"
#import "GLCalendarView.h"
#import <GLFoundation/GLTheme.h>
#import "GLPeriodEditorHeader.h"
#import <GLFoundation/GLMarkdownLabel.h>
#import "GLDateUtils.h"
#import "GLCalendarDateRange.h"
#import "GLCycleData+GLCalendarDateRange.h"

@interface GLOnboardingPeriodCalendarBaseViewController ()<GLCalendarViewDelegate>
@property (nonatomic, weak) GLCalendarDateRange *rangeUnderEdit;
@property (weak, nonatomic) IBOutlet GLCalendarView *calendarView;
@property (weak, nonatomic) IBOutlet GLMarkdownLabel *tip;

@end

@implementation GLOnboardingPeriodCalendarBaseViewController

static NSString *_classForStoryboard;
+ (void)useSubclass:(NSString *)classString
{
    if ([NSClassFromString(classString) isSubclassOfClass:[self class]]) {
        _classForStoryboard = [classString copy];
    } else {
        _classForStoryboard = nil;
    }
}

+ (instancetype)instanceOfSubClass:(NSString *)classString
{
    [self useSubclass:classString];
    return [[UIStoryboard storyboardWithName:@"GLPeriodEditor" bundle:nil] instantiateViewControllerWithIdentifier:@"Onboarding"];
}

+ (instancetype)alloc
{
    if (_classForStoryboard == nil) {
        return [super alloc];
    } else {
        if (NSClassFromString(_classForStoryboard) != [self class]) {
            GLOnboardingPeriodCalendarBaseViewController *subclassedVC = [NSClassFromString(_classForStoryboard) alloc];
            return subclassedVC;
        } else {
            return [super alloc];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.doneButton setTitleColor:[UIColor colorFromWebHexValue:@"a6a6a6"] forState:UIControlStateDisabled];
    [self.doneButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -8)];
    self.doneButton.enabled = NO;

    self.calendarView.delegate = self;
    self.calendarView.showMaginfier = YES;
    self.calendarView.backToTodayButtonDisplayOptions = HideBackToTodayButtonAfterToday;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSMutableArray *ranges = [NSMutableArray array];
    self.cycleData = [self initialCycleData];
    if (self.cycleData) {
        [ranges addObjectsFromArray:[self.cycleData dateRanges]];
    }
    self.calendarView.ranges = ranges;
    [self.calendarView reload];
    [self updateUI];
   
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ranges.count > 0) {
            GLCalendarDateRange *range = ranges[0];
            [self.calendarView beginToEditRange:range];
            [self.calendarView scrollToDate:range.beginDate animated:NO];
        } else {
            [self.calendarView scrollToDate:self.calendarView.lastDate animated:NO];
        }
    });
    if (!self.showCancelButton) {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (GLCycleData *)initialCycleData
{
    return nil;
}

- (void)updateUI
{
    if (!self.cycleData) {
        [self setTipLabelText:NSLocalizedStringFromTable(@"Tap on your last period start date.\nApproximate if you can't remember.", @"GLPeriodEditorLocalizedString", nil)];
        
    } else {
        [self setTipLabelText:NSLocalizedStringFromTable(@"Drag end points to adjust its length.\nClick \"Done\" once you're finished!", @"GLPeriodEditorLocalizedString", nil)];
        self.doneButton.enabled = YES;
    }
}

- (void)setTipLabelText:(NSString *)text
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 6;
    NSDictionary *attributes = @{NSFontAttributeName: [GLTheme defaultFont:17], NSParagraphStyleAttributeName:paragraphStyle};
    self.tip.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (BOOL)calenderView:(GLCalendarView *)calendarView canAddRangeWithBeginDate:(NSDate *)beginDate
{
    if ([GLDateUtils daysBetween:self.today and:beginDate] > 0) {
        return NO;
    }
    if (self.cycleData) {
        return NO;
    } else {
        return YES;
    }
}

- (GLCalendarDateRange *)calenderView:(GLCalendarView *)calendarView rangeToAddWithBeginDate:(NSDate *)beginDate
{
    NSDate* endDate = [GLDateUtils dateByAddingDays:(self.periodLength - 1) toDate:beginDate];
    GLCalendarDateRange *range = [GLCalendarDateRange rangeWithBeginDate:beginDate endDate:endDate];
    range.backgroundColor = [GLCycleAppearance sharedInstance].backgroundColorForPeriod ?: GLOW_COLOR_PINK;
    range.editable = YES;
    self.cycleData = [GLCycleData dataWithPeriodBeginDate:beginDate periodEndDate:endDate];
    range.binding = self.cycleData;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.calendarView beginToEditRange:range];
    });
    [self updateUI];
    return range;
}

- (void)calenderView:(GLCalendarView *)calendarView beginToEditRange:(GLCalendarDateRange *)range
{
    self.rangeUnderEdit = range;
}

- (void)calenderView:(GLCalendarView *)calendarView finishEditRange:(GLCalendarDateRange *)range continueEditing:(BOOL)continueEditing
{
    self.cycleData.periodBeginDate = range.beginDate;
    self.cycleData.periodEndDate = range.endDate;
}

- (BOOL)calenderView:(GLCalendarView *)calendarView canUpdateRange:(GLCalendarDateRange *)range toBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate
{
    if ([GLDateUtils daysBetween:self.today and:beginDate] > 0) {
        return NO;
    }
    self.cycleData.periodBeginDate = beginDate;
    self.cycleData.periodEndDate = endDate;
    return YES;
}

- (void)calenderView:(GLCalendarView *)calendarView didUpdateRange:(GLCalendarDateRange *)range toBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate
{
    
}

- (NSInteger)periodLength
{
    return 5;
}

- (NSDate *)today
{
    return [GLDateUtils cutDate:[NSDate date]];
}


- (IBAction)doneButtonPressed:(id)sender
{
    [self didClickDoneButtonWithCycleData:self.cycleData];
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didClickDoneButtonWithCycleData:(GLCycleData *)cycleData
{
    
}

@end
