//
//  GLLineChartViewController.m
//  kaylee
//
//  Created by Allen Hsu on 12/3/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <GLFoundation/GLMarkdownLabel.h>
#import <GLFoundation/GLPillGradientButton.h>

#import "GLLineChartViewController.h"
#import "User.h"
#import "GLLineChartView.h"
#import "UserDailyData.h"
#import "GLChartDataProvider.h"
#import "PeriodInfo.h"
#import "ExportReportDialog.h"
#import "DailyLogViewController.h"

@interface GLLineChartViewController () <UIScrollViewDelegate, GLLineChartViewDelegate, GLLineChartViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *titleDividerView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *infoPanel;
@property (weak, nonatomic) IBOutlet GLLineChartView *chartView;
@property (weak, nonatomic) IBOutlet UIButton *exportReportButton;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *dtLabels;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *ddLabels;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *cycleDayLabel;
@property (weak, nonatomic) IBOutlet UIView *emptyOverlay;
@property (weak, nonatomic) IBOutlet GLMarkdownLabel *placeholder;
@property (weak, nonatomic) IBOutlet GLPillGradientButton *gotoButton;
@end

@implementation GLLineChartViewController

+ (id)getInstance {
    return [[UIStoryboard storyboardWithName:@"chart" bundle:nil] instantiateViewControllerWithIdentifier:@"LineChart"];
}

- (void)setDemoMode:(BOOL)demoMode
{
    if (_demoMode != demoMode) {
        _demoMode = demoMode;
    }
    [self showEmptyOverlayIfNeeded];
}

- (void)showEmptyOverlayIfNeeded
{
    self.emptyOverlay.hidden = !self.inFullView || !self.demoMode;
    if (!self.emptyOverlay.hidden) {
        if ([self.dataProvider respondsToSelector:@selector(placeholderStringOfLineChart:)]) {
            self.placeholder.markdownText = [self.dataProvider placeholderStringOfLineChart:self.chartView];
        }
        if ([self.dataProvider respondsToSelector:@selector(placeholderButtonTitleOfLineChart:)]) {
            NSString *title = [self.dataProvider placeholderButtonTitleOfLineChart:self.chartView];
            if (!title || title.length <= 0) {
                self.gotoButton.hidden = YES;
            } else {
                self.gotoButton.hidden = NO;
                [self.gotoButton setTitle:title forState:UIControlStateNormal];
            }
        } else {
            self.gotoButton.hidden = YES;
        }
        self.placeholder.width = 280.0;
        [self.placeholder sizeToFit];
        self.placeholder.width = 280.0;
        self.gotoButton.top = self.placeholder.bottom + 20.0;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demoMode = YES;
    
    [self.gotoButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    
    // Do any additional setup after loading the view.
    self.titleLabel.text = self.title;
    
    self.dtLabels = [self.dtLabels sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"tag" ascending:YES]]];
    self.ddLabels = [self.ddLabels sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"tag" ascending:YES]]];
    for (UILabel *label in self.dtLabels) {
        label.text = @"";
    }
    for (UILabel *label in self.ddLabels) {
        label.text = @"";
    }
    
    self.chartView.delegate = self;
    self.chartView.dataSource = self;
    self.chartView.indicatorOffsetX = self.view.width - 50.0;
    
    NSMutableAttributedString *exportString = [[NSMutableAttributedString alloc] initWithString:@"Export PDF Report"];
    NSDictionary *attrs = @{NSUnderlineStyleAttributeName: [NSNumber numberWithInteger:NSUnderlineStyleSingle],
                            NSFontAttributeName: [Utils defaultFont:14],
                            NSForegroundColorAttributeName: [UIColor whiteColor]};
    [exportString addAttributes:attrs range:NSMakeRange(0, exportString.length)];
    [self.exportReportButton setAttributedTitle:exportString forState:UIControlStateNormal];
    
    self.exportReportButton.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 8, 0);
    self.exportReportButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.exportReportButton sizeToFit];
    
    if (!self.showExportReportButton) {
        self.exportReportButton.hidden = YES;
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([User currentUser].isSecondaryOrSingleMale) {
        self.exportReportButton.hidden = YES;
    } else {
        self.exportReportButton.hidden = NO;
    }
    if (!self.showExportReportButton) {
        self.exportReportButton.hidden = YES;
    }

    self.chartView.showCycleDay = [self.dataProvider needsShowCycleDay];
    self.chartView.showPeriodBg = [self.dataProvider needsShowPeriodBg];
    [self reloadData];


}


- (IBAction)didClickCloseButton:(id)sender {
    [self close];
}

- (void)thumbToFullBegin
{
    if (self.pageImpressionKey) {
        [Logging log:self.pageImpressionKey];
    }
}

- (void)showThumbView
{
    [self fullToThumb];
    [self fullToThumbCompletion];
}

- (void)showFullView
{
    [self thumbToFull];
    [self thumbToFullCompletion];
}

- (void)fullToThumb
{
    self.infoPanel.alpha = 0.0;
    self.headerView.height = 40.0;
    self.titleLabel.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.titleLabel.layer.shouldRasterize = YES;
    self.titleLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.titleLabel.origin = CGPointMake(10.0, 11.0);
    self.titleDividerView.alpha = 0.3;
    self.titleDividerView.frame = CGRectMake(10, 35, self.view.width - 20.0, 1);
    self.closeButton.alpha = 0;
    
    self.chartView.layer.shouldRasterize = YES;
    self.chartView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.chartView.frame = CGRectMake(0.0, self.headerView.bottom, self.view.width, self.view.height - self.headerView.bottom);
    self.chartView.alpha = 0.0;
    self.chartView.showGrid = NO;
    self.chartView.showIndicator = NO;
    self.chartView.indicatorOffsetX = self.chartView.width - 20.0;
    
    self.infoPanel.top = self.view.height;
    [self showEmptyOverlayIfNeeded];
}

- (void)fullToThumbCompletion
{
    NSInteger daysInView = BASE_DAYS_IN_VIEW;
    if ([self.dataProvider respondsToSelector:@selector(preferredDaysInViewOfLineChart:)]) {
        daysInView = [self.dataProvider preferredDaysInViewOfLineChart:self.chartView];
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.chartView.alpha = 1.0;
        self.chartView.showToday = YES;
        self.chartView.indicatorOffsetX = self.chartView.width - 20.0;
        self.chartView.daysInView = daysInView;
        [self.chartView backToLatestDateAnimated:NO];
    }];
}

- (void)thumbToFull
{
    NSInteger daysInView = BASE_DAYS_IN_VIEW;
    if ([self.dataProvider respondsToSelector:@selector(preferredDaysInViewOfLineChart:)]) {
        daysInView = [self.dataProvider preferredDaysInViewOfLineChart:self.chartView];
    }
    self.infoPanel.alpha = 1.0;
    self.headerView.height = 90.0;
    self.titleLabel.transform = CGAffineTransformIdentity;
    self.titleLabel.origin = CGPointMake(20.0, 36.0);
    self.titleDividerView.frame = CGRectMake(20.0, 80, self.view.width - 40.0, 1);
    self.titleDividerView.alpha = 0.0;
    self.chartView.indicatorOffsetX = self.chartView.width - 50.0;
    self.chartView.frame = CGRectMake(0.0, self.headerView.bottom, self.view.width, self.view.height - self.infoPanel.height - self.headerView.bottom);
    self.chartView.showGrid = YES;
    self.chartView.showIndicator = YES;
    self.chartView.showToday = NO;
    self.chartView.daysInView = daysInView;
    [self.chartView backToLatestDateAnimated:NO];
    self.closeButton.alpha = 1;
    
    self.infoPanel.top = self.view.height - self.infoPanel.height;
    [self showEmptyOverlayIfNeeded];
}

- (void)thumbToFullCompletion
{
//    [self.chartView backToLatestDateAnimated:YES];
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    self.titleLabel.text = title;
}

- (void)reloadData
{
    [self.dataProvider reloadData];
}

- (void)reloadChartView
{
    [self.chartView backToLatestDateAnimated:NO];
}

- (IBAction)gotoTargetPage:(id)sender {

    if ([self.dataProvider respondsToSelector:@selector(targetEventOfLineChart:)]) {
        NSString *event = [self.dataProvider targetEventOfLineChart:self.chartView];
        if (event) {
            if ([event isEqualToString:EVENT_GO_CONNECTING_3RD_PARTY]) {
                [Logging log:BTN_CLK_GOTOME_FROM_CHART];
                [self closeWithCallback:^{
                    [self publish:event];
                }];
            } else if ([event isEqualToString:EVENT_GO_DAILYLOG_WEIGHT]){
                DailyLogViewController* vc = (DailyLogViewController *)[UIStoryboard dailyLog];
                vc.selectedDate = [NSDate date];
                vc.needsToScrollToWeightCell = YES;
                UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
                [self presentViewController:nav animated:YES completion:nil];
            }
        }
    }
}

- (IBAction)exportReportButtonPressed:(id)sender {
    [[[ExportReportDialog alloc] initWithUser:[User currentUser]] present];
}

#pragma mark - GLLineChartViewDelegate

- (void)lineChart:(GLLineChartView *)lineChart didSelectDateIndex:(NSInteger)dateIndex
{
    NSDate *d = [Utils dateIndexToDate:(int)dateIndex];
    self.dateLabel.text = [Utils formatedWithFormat:@"MMM d, YYYY" date:d];
    
    NSInteger cd = [[PeriodInfo sharedInstance] cycleDayForDateIndex:dateIndex];
    NSInteger ov = [[PeriodInfo sharedInstance] ovulationDayForDateIndex:dateIndex];
   
    if (self.dataProvider.needsShowCycleDay) {
        NSString *cdText = (int)cd <= 0 ? nil : [NSString stringWithFormat:@"Cycle day %ld", (long)cd];
        NSString *ovText = (int)ov <= 0 ? nil : [NSString stringWithFormat:@"DPO %ld", (long)ov];
        
        if (cdText) {
            if (ovText && ![User currentUser].isFertilityTreatmentUser) {
                cdText = [cdText stringByAppendingFormat:@", %@", ovText];
            }
            self.cycleDayLabel.text = cdText;
        } else {
            self.cycleDayLabel.text = @"";
        }
        
    } else {
        self.cycleDayLabel.text = @"";
    }
    
    
    NSArray *keys = nil;
    NSDictionary *info = nil;
    if ([self.dataProvider respondsToSelector:@selector(lineChart:infoKeysForDateIndex:)] && [self.dataProvider respondsToSelector:@selector(lineChart:infoListForDateIndex:)]) {
        keys = [self.dataProvider lineChart:lineChart infoKeysForDateIndex:dateIndex];
        info = [self.dataProvider lineChart:lineChart infoListForDateIndex:dateIndex];
    }
    NSInteger n = MIN(self.ddLabels.count, self.dtLabels.count);
    CGFloat maxDtWidth = 0.0;
    for (NSInteger i = 0; i < n; ++i) {
        UILabel *dt = self.dtLabels[i];
        UILabel *dd = self.ddLabels[i];
        NSString *key = @"";
        NSString *value = @"";
        if (i < keys.count) {
            key = keys[i];
            value = info[key];
            if (key.length > 0) {
                key = [key stringByAppendingString:@":"];
            }
            if (value.length == 0) {
                value = @"--";
            }
        }
        dt.text = key;
        dd.text = value;
        
        [dt sizeToFit];
        dt.height = 15.0;
        maxDtWidth = MAX(maxDtWidth, dt.width);
    }
    
    for (NSInteger i = 0; i < n; ++i) {
        UILabel *dt = self.dtLabels[i];
        UILabel *dd = self.ddLabels[i];
        dt.width = maxDtWidth;
        dd.left = dt.right + 5.0;
    }
}

#pragma mark - GLLineChartViewDataSource

- (CGFloat)minValueOfLineChart:(GLLineChartView *)lineChart
{
    return [self.dataProvider minValueOfLineChart:lineChart];
}

- (CGFloat)maxValueOfLineChart:(GLLineChartView *)lineChart
{
    return [self.dataProvider maxValueOfLineChart:lineChart];
}

- (NSInteger)latestDateIndexWithDataOfLineChart:(GLLineChartView *)lineChart
{
    return [self.dataProvider latestDateIndexWithDataOfLineChart:lineChart];
}

- (NSInteger)minDateIndexOfLineChart:(GLLineChartView *)lineChart
{
    return [self.dataProvider minDateIndexOfLineChart:lineChart];
}

- (NSInteger)maxDateIndexOfLineChart:(GLLineChartView *)lineChart
{
    return [self.dataProvider maxDateIndexOfLineChart:lineChart];
}

- (NSString *)unitOfLineChart:(GLLineChartView *)lineChart
{
    return [self.dataProvider unitOfLineChart:lineChart];
}

- (NSInteger)numberOfLinesInLineChart:(GLLineChartView *)lineChart
{
    return [self.dataProvider numberOfLinesInLineChart:lineChart];
}

- (NSArray *)lineChart:(GLLineChartView *)lineChart dotsForLineIndex:(NSInteger)lineIndex inRange:(GLLineChartRange)range
{
    return [self.dataProvider lineChart:lineChart dotsForLineIndex:lineIndex inRange:range];
}

- (UIColor *)lineChart:(GLLineChartView *)lineChart lineColorForLineIndex:(NSInteger)lineIndex
{
    if ([self.dataProvider respondsToSelector:@selector(lineChart:lineColorForLineIndex:)]) {
        return [self.dataProvider lineChart:lineChart lineColorForLineIndex:lineIndex];
    }
    return GLOW_COLOR_GREEN;
}

- (UIColor *)lineChart:(GLLineChartView *)lineChart dotColorForLineIndex:(NSInteger)lineIndex
{
    if ([self.dataProvider respondsToSelector:@selector(lineChart:dotColorForLineIndex:)]) {
        return [self.dataProvider lineChart:lineChart dotColorForLineIndex:lineIndex];
    }
    return GLOW_COLOR_GREEN;
}

- (GLLineChartDot *)todayDotOfLineChart:(GLLineChartView *)lineChart
{
    if ([self.dataProvider respondsToSelector:@selector(todayDotOfLineChart:)]) {
        return [self.dataProvider todayDotOfLineChart:lineChart];
    }
    return nil;
}

- (NSSet *)symbolsOfLineChart:(GLLineChartView *)lineChart
{
    if ([self.dataProvider respondsToSelector:@selector(symbolsOfLineChart:)]) {
        return [self.dataProvider symbolsOfLineChart:lineChart];
    }
    return nil;
}

- (NSString *)todayStringOfLineChart:(GLLineChartView *)lineChart
{
    if ([self.dataProvider respondsToSelector:@selector(todayStringOfLineChart:)]) {
        return [self.dataProvider todayStringOfLineChart:lineChart];
    }
    return nil;
}

@end
