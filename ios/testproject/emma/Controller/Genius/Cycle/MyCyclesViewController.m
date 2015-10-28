//
//  MyCyclesViewControllerTableViewController.m
//  emma
//
//  Created by Xin Zhao on 5/20/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "MyCyclesViewController.h"
#import "GeniusMainViewController.h"
#import "MyCyclesDetailView.h"
#import "CyclesSummarizer.h"
#import "UILinkLabel.h"
#import "Tooltip.h"
#import "User.h"

#define THUMBNAIL_NEXT_PB_TITLE_RECT CGRectMake(10, 49, GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 42)

CG_INLINE float halfTextX(UILabel *l, float fs) {
    CGSize size = [l.text boundingRectWithSize:l.frame.size
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName: [Utils boldFont:fs]}
                                          context:nil].size;
    return roundf(size.width / 2);
}

@interface MyCyclesViewController () {
    __weak IBOutlet UIScrollView *scrollView;
    __weak IBOutlet UIView *titleBgView;
    IBOutlet UILabel *titleLabel;
    IBOutlet UIButton *closeButton;
    IBOutlet UIView *titleDividerView;
    __weak IBOutlet UILabel *nextPbTitleLabel;
    __weak IBOutlet UILabel *nextPbLabel;
    IBOutlet UIView *detailsHeaderView;
    __weak IBOutlet UIView *nextPbTitleView;
    __weak IBOutlet UILabel *cycleDaysNumber;
    __weak IBOutlet UILabel *periodDaysNumber;
    __weak IBOutlet UILabel *follicularPhaseNumber;
    __weak IBOutlet UILabel *lutealPhaseNumber;
    __weak IBOutlet UIView *cycleStatisticContainer;
    
    __weak IBOutlet UILabel *periodDatesLabelPrototype;
    __weak IBOutlet UILabel *durationLabelPrototype;
    __weak IBOutlet UILabel *cycleLengthLabelPrototype;

    __weak IBOutlet UILinkLabel *follicularPhaseTitle;
    __weak IBOutlet UILinkLabel *lutealPhaseTitle;
    CGRect headerFrame;
    CGRect titleFrame;
    CGRect dividerFrame;
    CGRect nextPbFrame;
    NSMutableArray *detailTableRows;

    NSInteger numberOfCycleDetails;
}

@end

@implementation MyCyclesViewController


+ (id)getInstance {
    return [[MyCyclesViewController alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [closeButton setImage:[Utils image:[UIImage imageNamed:@"topnav-close"]
        withColor:[UIColor whiteColor]] forState:UIControlStateNormal];

    titleFrame = titleLabel.frame;
    dividerFrame = (CGRect) {{20, 80}, {GG_FULL_CONTENT_W, 1}};
    nextPbFrame = nextPbLabel.frame;
    detailTableRows = [@[] mutableCopy];
    
//    self.view.backgroundColor = UIColorFromRGB(0x2da4ba);
   if (DETECT_TIPS) {
        follicularPhaseTitle.useHyperlinkColor = NO;
        [follicularPhaseTitle clearCallbacks];
        [follicularPhaseTitle setCallback:^(NSString *str) {
            [Tooltip tip:str];
        } forKeyword:@"Follicular phase" caseSensitive:NO];
       
        lutealPhaseTitle.useHyperlinkColor = NO;
        [lutealPhaseTitle clearCallbacks];
        [lutealPhaseTitle setCallback:^(NSString *str) {
            [Tooltip tip:str];
        } forKeyword:@"Luteal phase" caseSensitive:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.underZooming) return;
    
    scrollView.contentOffset = CGPointMake(0, 0);
    [self showThumbView];
    if ([User currentUser].isSecondary) {
        titleLabel.text = @"HER CYCLES";
    } else {
        titleLabel.text = @"MY CYCLES";
    }
    [CrashReport leaveBreadcrumb:@"MyCyclesViewController"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.underZooming) return;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.underZooming) return;
    [self unsubscribeAll];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - GeniusChildViewController methods override
- (void)showThumbView {
    closeButton.hidden = YES;

    [self _loadCycleSummary];
    [self fullToThumb];
}

- (void)thumbToFull {
    nextPbTitleLabel.text = @"Next period starts on:";
    
    closeButton.alpha = 1;
    
    titleLabel.transform = CGAffineTransformIdentity;
    titleLabel.frame = titleFrame;
    
    titleDividerView.frame = dividerFrame;

    nextPbTitleView.frame = (CGRect) {
        {(SCREEN_WIDTH - 172) / 2, 112}, {172, 22}};
    
    nextPbLabel.transform = CGAffineTransformIdentity;
    nextPbLabel.center = CGPointMake(SCREEN_WIDTH / 2, 164);

    setWidthOfRect(cycleStatisticContainer.frame, scrollView.frame.size.width);
}

- (void)fullToThumb {
    nextPbTitleLabel.text = @"Next period \nstarts on:";

    closeButton.alpha = 0;

    titleLabel.transform = CGAffineTransformMakeScale(0.5, 0.5);
    titleLabel.frame = CGRectMake(10, 11, titleLabel.frame.size.width,
        titleLabel.frame.size.height);

    titleDividerView.frame = CGRectMake(10, 35, GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 1);

    titleBgView.frame = setRectHeight(titleBgView.frame, 36);

    nextPbTitleView.frame = THUMBNAIL_NEXT_PB_TITLE_RECT;
    
    nextPbLabel.transform = CGAffineTransformMakeScale(0.5, 0.5);
    CGSize size = [nextPbLabel.text sizeWithAttributes:@{NSFontAttributeName: [Utils boldFont:40]}];
    nextPbLabel.center = (CGPoint) {
        (nextPbLabel.frame.size.width - size.width / 2) / -2 + 80 + 10,
        103
    };
}

- (void)fullToThumbBegin {
    nextPbTitleView.frame = setRectHeight(nextPbTitleView.frame,
        THUMBNAIL_NEXT_PB_TITLE_RECT.size.height);
    nextPbTitleView.frame = setRectWidth(nextPbTitleView.frame,
        THUMBNAIL_NEXT_PB_TITLE_RECT.size.width);

    scrollView.contentOffset = CGPointMake(0,0);
    scrollView.scrollEnabled = NO;
}

- (void)thumbToFullCompletion {
    titleBgView.frame = setRectHeight(titleBgView.frame, 81);
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width,
        lutealPhaseNumber.superview.frame.origin.y + 
        lutealPhaseNumber.frame.origin.y + lutealPhaseNumber.frame.size.height +
        30 * (1 + numberOfCycleDetails) + 0);
    scrollView.scrollEnabled = YES;
    closeButton.hidden = NO;
    // logging
    [Logging log:PAGE_IMP_GNS_CHILD_CYCLES];
}


- (IBAction)closeButtonClicked:(id)sender {
    [self close];
}

#pragma mark - Cycles details table
- (void)_loadCycleSummary {
    NSString *nextPbSummary = [CyclesSummarizer summaryOfNextPb];
    nextPbLabel.text = nextPbSummary ? nextPbSummary : @"--";

    NSArray *stagesSummary = [CyclesSummarizer summaryOfStages];
    int cycleDays = [stagesSummary[0] intValue],
        periodDays = [stagesSummary[1] intValue],
        follicularPhase = [stagesSummary[2] intValue],
        lutealPhase = [stagesSummary[3] intValue];
    cycleDaysNumber.text = cycleDays == 0 ? @"--"
        : [NSString stringWithFormat:@"%ld", (long)cycleDays];
    periodDaysNumber.text = cycleDays == 0 ? @"--"
        : [NSString stringWithFormat:@"%ld", (long)periodDays];
    follicularPhaseNumber.text = cycleDays == 0 ? @"--"
        : [NSString stringWithFormat:@"%ld", (long)follicularPhase];
    lutealPhaseNumber.text = cycleDays == 0 ? @"--"
        : [NSString stringWithFormat:@"%ld", (long)lutealPhase];

    for (UIView *v in detailTableRows) {
        [v removeFromSuperview];
    }
    NSArray *details = [CyclesSummarizer summaryOfPastCycles];
    numberOfCycleDetails = 0;
    if (details && [details count] > 0) {
        numberOfCycleDetails = [details count] + 1;
        detailsHeaderView.frame = setRectY(detailsHeaderView.frame,
            lutealPhaseNumber.frame.origin.y +
            lutealPhaseNumber.frame.size.height);
        setWidthOfRect(detailsHeaderView.frame, SCREEN_WIDTH);
        [self _layoutCycleDetailRow:detailsHeaderView];
        UIView *summaryContainer = lutealPhaseTitle.superview;
        [summaryContainer addSubview:detailsHeaderView];
        [detailTableRows addObject:detailsHeaderView];
        float y = detailsHeaderView.frame.origin.y;

        for (NSInteger i = [details count] - 1; i >= 0; i--) {
            NSArray *d = details[i];
            y += 30;
            MyCyclesDetailView *view = [[MyCyclesDetailView alloc]
                initWithFrame:detailsHeaderView.frame];
            setYOfRect(view.frame, y);
            [self _layoutCycleDetailRow:view];
            if (i % 2 == 0) {
                view.backgroundColor = UIColorFromRGB(0x4cb2c4);
            }
            else {
                view.backgroundColor = UIColorFromRGB(0x2da4ba);
            }
            [view setDates:d[0] duration:[d[1] intValue] cycleLength:
                [d[2] intValue]];
            [detailTableRows addObject:view];
            [summaryContainer addSubview:view];
            summaryContainer.frame = setRectHeight(summaryContainer.frame,
                view.frame.origin.y + view.frame.size.height);
        }
   }
}

- (BOOL) _layoutCycleDetailRow:(UIView *)row {
    UILabel *dates = (UILabel*) [row viewWithTag:1];
    UILabel *duration = (UILabel*) [row viewWithTag:2];
    UILabel *length = (UILabel*) [row viewWithTag:3];
    if (!dates || !duration || !length) {
        return NO;
    }
    float leftPadding = 20, rightPadding = 20, w = row.frame.size.width;
    setXOfRect(dates.frame, leftPadding);
    setXOfRect(length.frame,
        w - rightPadding - length.frame.size.width);
    setXOfRect(duration.frame,
        w - rightPadding - length.frame.size.width - duration.frame.size.width);
    return YES;
}

@end
