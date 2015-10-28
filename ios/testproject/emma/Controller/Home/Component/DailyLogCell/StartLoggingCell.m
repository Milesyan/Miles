//
//  startLoggingCell.m
//  emma
//
//  Created by Xin Zhao on 13-5-22.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "StartLoggingCell.h"
#import "Utils.h"
#import "UILinkLabel.h"
#import "UIView+Emma.h"
#import <GLFoundation/UIImage+Utils.h>
#import "DailyLogSummary.h"
#import "UserDailyData.h"
#import "User.h"
#import "Tooltip.h"
#import "GLMeterView.h"
#import "PillButton.h"
#import "GLHealthAwarenessViewController.h"
#import "GLInsightPopupsViewController.h"
#import "GLLogsStatusViewController.h"
#import "RootViewController.h"
#import <DACircularProgressView.h>
#import "HealthAwareness.h"
#import "UserDailyData.h"
#import "UIButton+BackgroundColor.h"

#define SUMMARY_STATUS_PREFIX @"SummaryStatus"
#define SUMMARY_STATUS_KEY [NSString stringWithFormat:@"%@%@", SUMMARY_STATUS_PREFIX, self.dailyData.date]

@interface StartLoggingCell() {
    
}

@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UIView *startLoggingView;
@property (nonatomic, weak) IBOutlet UIView *loadMoreView;
@property (nonatomic, weak) IBOutlet UIView *logSummaryContainer;
@property (nonatomic, weak) IBOutlet UIImageView *loadMoreArrow;

@property (nonatomic, weak) IBOutlet UILabel *healthAwarenessLabel;
@property (nonatomic, weak) IBOutlet GLMeterView *healthAwarenessView;
@property (nonatomic, weak) IBOutlet UIButton *healthAwarenessButton;

@property (nonatomic, weak) IBOutlet UILabel *insightsLabel;
@property (nonatomic, weak) IBOutlet UIButton *insightsButton;
@property (weak, nonatomic) IBOutlet UIButton *logButton;

@property (nonatomic, weak) IBOutlet UILabel *weekLogsLabel;
@property (nonatomic, weak) IBOutlet DACircularProgressView *weekLogsView;
@property (nonatomic, weak) IBOutlet UIButton *weekLogsButton;

@property (nonatomic, strong) DailyLogSummary *dailyLogSummary;
@property (nonatomic, assign) BOOL highlightFlag;

@property (nonatomic, strong) NSDictionary *awarenessScores;

@property (nonatomic, strong) NSArray *insights;
@property (nonatomic, strong) GLInsightPopupsViewController *insightPopupsViewController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *summaryContainerHeight;

@end


@implementation StartLoggingCell


- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.logButton setBackgroundColor:UIColorFromRGB(0x3f47ae) forState:UIControlStateHighlighted];
    self.logButton.adjustsImageWhenHighlighted = NO;

    self.startLoggingView.backgroundColor = GLOW_COLOR_PURPLE;

    [self.containerView addDefaultBorder];
    [self setupLoadMoreView];
    [self setupWeekLogColors];
    
    self.highlighted = YES;
    
    [self.healthAwarenessLabel setTapActionWithBlock:^{
        [Logging log:BTN_CLK_HOME_HEALTH_AWARENESS_TIP];
        [Tooltip tip:@"Today's health awareness"];
    }];
    
    [self.insightsLabel setTapActionWithBlock:^{
        [Logging log:BTN_CLK_HOME_TODAY_INSIGHTS_TIP];
        [Tooltip tip:@"Today's insights"];
    }];
    
    [self.weekLogsLabel setTapActionWithBlock:^{
        [Logging log:BTN_CLK_HOME_LOG_THIS_WEEK_TIP];
        [Tooltip tip:@"Logs this week"];
    }];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(1, 0, SCREEN_WIDTH - 18, 30);
    UIColor *color = [UIColor whiteColor];
    gradient.colors = @[(id)[color colorWithAlphaComponent:0].CGColor, (id)color.CGColor];
    self.loadMoreView.backgroundColor = [UIColor clearColor];
    [self.loadMoreView.layer insertSublayer:gradient atIndex:0];
    
    [self subscribe:EVENT_DAILY_LOG_UNIT_CHANGED selector:@selector(dailyLogUnitChanged)];
}

- (void)dailyLogUnitChanged
{
    [self.dailyLogSummary refresh];
}

- (void)setupWeekLogColors {
    [self.weekLogsView setTintColor:GLOW_COLOR_PURPLE];
    [self.weekLogsView setProgressTintColor:GLOW_COLOR_PURPLE];
    [self.weekLogsView setTrackTintColor:UIColorFromRGBA(0x5B65CE50)];
    [self.weekLogsView setRoundedCorners:YES];
    self.weekLogsView.thicknessRatio = 0.2;
}

- (void)setupLoadMoreView
{
    self.loadMoreArrow.image = [self.loadMoreArrow.image imageWithTintColor:GLOW_COLOR_PURPLE];
    self.loadMoreView.hidden = YES;
}

- (void)setCurrentDate:(NSDate *)currentDate
{
    _currentDate = currentDate;
    self.dailyData = [UserDailyData getUserDailyData:[Utils dailyDataDateLabel:currentDate]
                                             forUser:[User currentUser]];
    
    [self updateHeart:self.dailyData];
    [self updateInsights:[currentDate toDateLabel]];
    [self updateLogProgress:currentDate];
    
    if ([self.dailyData hasData]) {
        [self.logButton setTitle:@"Logged" forState:UIControlStateNormal];
        [self.logButton setImage:[UIImage imageNamed:@"check-green"] forState:UIControlStateNormal];
    } else {
        [self.logButton setTitle:@"Complete log!" forState:UIControlStateNormal];
        [self.logButton setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
    }
    
    if (!self.dailyData.hasPositiveData) {
        self.loadMoreView.hidden = YES;
        [self.logSummaryContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.summaryContainerHeight.constant = 0;
        return;
    }
    
    [self updateSummaryView:self.dailyData];
}


- (void)updateSummaryView:(UserDailyData *)dailyData
{
    if (!dailyData) {
        return;
    }
    
    if (!self.dailyLogSummary) {
        self.dailyLogSummary = [[DailyLogSummary alloc] initWithDailyData:dailyData];
    }
    else {
        [self.dailyLogSummary setDailyData:dailyData];
    }
    
    UIView *smv = [self.dailyLogSummary getSummaryView];
    [self.logSummaryContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.logSummaryContainer addSubview:smv];
    self.summaryContainerHeight.constant = smv.height;
    
    self.loadMoreView.hidden = !self.dailyLogSummary.hasMore;
    if (!self.loadMoreView.hidden) {
        [self rotateLoadMoreArrow];
    }
}


- (void)updateHeart:(UserDailyData *)dailyData
{
    if (!dailyData) {
        [self.healthAwarenessButton setTitle:@"0%" forState:UIControlStateNormal];
        self.healthAwarenessButton.superview.alpha = 0.5;
        [self.healthAwarenessView setProgress:0 animated:YES];
        self.awarenessScores = @{
                                 kHealthAwareness:    @(0),
                                 kPhysicalAwareness:  @(0),
                                 kEmotionalAwareness: @(0),
                                 kFertilityAwareness: @(0)
                                 };
        return;
    }
    
    self.awarenessScores = [HealthAwareness allScoreForUserDailyData:dailyData];
    
    float score = [self.awarenessScores[kHealthAwareness] floatValue];
    NSString *title = [NSString stringWithFormat:@"%d%%", (int)(score * 100)];
    [self.healthAwarenessButton setTitle:title forState:UIControlStateNormal];
    self.healthAwarenessButton.superview.alpha = score == 0 ? 0.5 : 1;
    [self.healthAwarenessView setProgress:score animated:YES];
}


- (void)updateInsights:(NSString *)date
{
    if (!date) {
        [self.insightsButton setTitle:@"0" forState:UIControlStateNormal];
        self.insightsButton.superview.alpha = 0.5;
        self.insights = @[];
        return;
    }
    
    self.insights = [Insight sortedInsightsForCurrentUserWithDate:date];
    
    NSString *title = [NSString stringWithFormat:@"%ld", self.insights.count];
    [self.insightsButton setTitle:title forState:UIControlStateNormal];
    self.insightsButton.superview.alpha = self.insights.count == 0 ? 0.5 : 1;
}


- (void)updateLogProgress:(NSDate *)date
{
    if (!date) {
        [self.weekLogsButton setTitle:@"0 / 7" forState:UIControlStateNormal];
        self.weekLogsButton.superview.alpha = 0.5;
        [self.weekLogsView setProgress:0 animated:YES];
        return;
    }
    
    NSArray *logs = [UserDailyData userDailyDataInWeek:date forUser:[User currentUser]];
    NSUInteger number = [logs indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return (obj != [NSNull null]);
    }].count;
    
    NSString *title = [NSString stringWithFormat:@"%ld / 7", number];
    [self.weekLogsButton setTitle:title forState:UIControlStateNormal];
    self.weekLogsButton.superview.alpha = number == 0 ? 0.5 : 1;
    [self.weekLogsView setProgress:number / 7.0 animated:YES];
}


- (IBAction)loadMoreSummary:(id)sender
{
    BOOL dailyLogSummaryExpanded = [[Utils getDefaultsForKey:SUMMARY_STATUS_KEY] boolValue];
    dailyLogSummaryExpanded = !dailyLogSummaryExpanded;
    [Utils setDefaultsForKey:SUMMARY_STATUS_KEY withValue:@(dailyLogSummaryExpanded)];
    
    if ([self.delegate respondsToSelector:@selector(tableViewCellNeedsUpdateHeight:)]) {
        [self.delegate tableViewCellNeedsUpdateHeight:self];
    }
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self rotateLoadMoreArrow];
                     }
                     completion:NULL];
}


- (void)rotateLoadMoreArrow
{
    if (![[Utils getDefaultsForKey:SUMMARY_STATUS_KEY] boolValue]) {
        self.loadMoreArrow.transform = CGAffineTransformIdentity;
    }
    else {
        self.loadMoreArrow.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI);
    }
}


- (CGFloat)heightThatFits
{
    CGFloat height = 12 + 120 + 43 + 10;
    
    if (self.dailyData.hasPositiveData) {
        
        if (![self.dailyLogSummary hasMore]) {
            height += [self.dailyLogSummary getSummaryShortHeight];
        }
        else if ([[Utils getDefaultsForKey:SUMMARY_STATUS_KEY] boolValue]) {
            height += [self.dailyLogSummary getSummaryFullHeight];
        }
        else {
            height += [self.dailyLogSummary getSummaryShortHeight];
        }
        height += 10;
    }
    
    return height;
}

//- (void)setHighlighted:(BOOL)selected
//{
//    if (selected) {
//        self.startLoggingView.backgroundColor = UIColorFromRGB(0x3f47ae);
//    } else {
//        self.startLoggingView.backgroundColor = UIColorFromRGB(0x5a62d2);
//    }
//}
//
//- (IBAction)startLoggingButtonTouchDown:(id)sender {
//    [self setHighlighted:YES];
//}
//- (IBAction)startLoggingButtonTouchUpOut:(id)sender {
//    [self setHighlighted:NO];
//}

- (IBAction)startLoggingButtonClicked:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(tableViewCell:needsPerformSegue:)]) {
        [self.delegate tableViewCell:self needsPerformSegue:@"startLogging"];
    }
}


#pragma mark - icon clicked
- (IBAction)heartButtonClicked:(id)sender
{
    [Logging log:BTN_CLK_HOME_HEALTH_AWARENESS];
    
    UIView *view = [[UIView alloc] initWithFrame:self.healthAwarenessButton.bounds];
    view.backgroundColor = UIColorFromRGBA(0xFFFFFF80);
    [self.healthAwarenessButton addSubview:view];
    
    @weakify(self)
    [UIView animateWithDuration:0.3 animations:^{
        view.alpha = 0;
    } completion:^(BOOL finished) {
        @strongify(self)
        [view removeFromSuperview];
        GLHealthAwarenessViewController *vc = [GLHealthAwarenessViewController viewController];
        vc.awarenessScores = self.awarenessScores;
        [vc presentForDate:self.currentDate];
    }];
}


- (IBAction)insightsButtonClicked:(id)sender
{
    NSInteger insightCount = 0;
    if (self.insights) {
        insightCount = self.insights.count;
    }
    [Logging log:BTN_CLK_HOME_TODAY_INSIGHTS eventData:@{@"num_insights": @(insightCount)}];
    [self popupInsights];
}

- (void)popupInsights {
    NSInteger insightCount = 0;
    if (self.insights) {
        insightCount = self.insights.count;
    }
    if (insightCount == 0) return;
    
    UIView *view = [[UIView alloc] initWithFrame:self.insightsButton.bounds];
    view.backgroundColor = UIColorFromRGBA(0xFFFFFF80);
    [self.insightsButton addSubview:view];
    
    @weakify(self)
    [UIView animateWithDuration:0.3 animations:^{
        view.alpha = 0;
    } completion:^(BOOL finished) {
        @strongify(self)
        [view removeFromSuperview];
        
        if (!self.insights || [self.insights count] == 0) {
            [Tooltip tip:@"Today's insights"];
            return;
        }
        
        // set insights be read
        [Insight setInsightsRead:self.currentDate];
        
        GLInsightPopupsViewController *vc = self.insightPopupsViewController;
        if (! vc) {
            vc = [GLInsightPopupsViewController instance];
            self.insightPopupsViewController = vc;
        }
        vc.insights = self.insights;
        
        CGRect rect = [self.insightsButton.superview convertRect:self.insightsButton.frame
                                                          toView:self.window];
        
        vc.leaveShrinkToRect = rect;
        [vc present];
    }];
}


- (IBAction)progressButtonClicked:(id)sender
{
    [Logging log:BTN_CLK_HOME_LOG_THIS_WEEK];
    
    UIView *view = [[UIView alloc] initWithFrame:self.weekLogsButton.bounds];
    view.backgroundColor = UIColorFromRGBA(0xFFFFFF80);
    [self.weekLogsButton addSubview:view];
    [UIView animateWithDuration:0.3 animations:^{
        view.alpha = 0;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
        [[GLLogsStatusViewController viewController] presentForDate:self.currentDate];
    }];
}

- (void)dealloc
{
    [self unsubscribeAll];
}


@end




