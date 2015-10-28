//
//  TinyCalendarView.m
//  emma
//
//  Created by Eric Xu on 2/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TinyCalendarView.h"
#import "CKCalendarView.h"
#import "User.h"
#import "Logging.h"
#import "AnimationSequence.h"
#import "VariousPurposesConstants.h"
#import "ChartData.h"
#import "HealthProfileData.h"
#import "NewDateButton.h"
#import "ButtonHalo.h"
#import "RotationLabels.h"
#import "UserMedicalLog.h"
#import "MedicalLogItem.h"
#import "CalendarDayInfoSummary.h"

#define CALENDAR_MARGIN 0

#define VISIBLE_PAGE_COUNT 6


@interface TinyCalendarView() <UIScrollViewDelegate> {
    NSDate *dateBeforeScroll;
    NSDate *dateForCenterIndex;
    NSMutableArray *buttonQueue;
    BOOL userDragging;
    
    NSDate *mininumDateCap;
    BOOL needCalculationAnimation;
    
    UIColor *purple;
    UIColor *pink;
    UIColor *green;
    UIColor *red;
}

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSCalendar *calendar;

@property (nonatomic, strong) PagedScrollView *scrollView;

@property (nonatomic, strong) NSDate *selectedDate;

@property (nonatomic, readonly) NewDateButton *centerButton;

@property (nonatomic, strong) NSTimer *calculationTimer;
@property (nonatomic, strong) NSTimer *buttonColorTimer;
@property (nonatomic) float calculationTimeElapsed;
@property (nonatomic) NSInteger calculationLabelUpdatedTime;

@property (nonatomic, strong) NSArray *hcgTriggerShotDates;
@property (nonatomic) BOOL isAnimatingBounce;
@end

@implementation TinyCalendarView
@synthesize selectedDate;

- (void)internalInit:(startDay)firstDay {
    [self _setupConst];

    needCalculationAnimation = NO;

    self.calendarStartDay = firstDay;
    self.selectedDate = [NSDate date];
    self.calendar = [Utils calendar];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];

    self.frame = CGRectMake(0, 0, TINY_CAL_WIDTH, TINY_CAL_HEIGHT);
    self.backgroundColor = [UIColor clearColor];
    self.halo = [[ButtonHalo alloc] initWithFrame:CGRectMake(70, -10, HALO_WIDTH, HALO_WIDTH)];
    self.halo.center = CGPointMake(SCREEN_WIDTH/2, BUTTONS_CENTER_Y);
    [self addSubview:self.halo];

    [self calculateMinimumDate];
    [self calculateMaximumDate];

    [self initScrollView];
    [self initButtonQueue];
    [self subscribe:EVENT_DAILY_DATA_UPDATE_TO_CAL_ANIME selector:@selector(setNeedCalculationAnimation)];
    [self.scrollView setPageIndex:[self pageIndexForDate:self.selectedDate] animated:NO];
    
    [self startCenterButtonTipsRotation];
    
}

- (void)_setupConst {
    purple = UIColorFromRGBA(0x5A62D2E1);
    pink = UIColorFromRGBA(0xE55A8CD4);
    green = UIColorFromRGBA(0x6CBA2DD4);
    red = UIColorFromRGB(0xFA1816);
}

- (BOOL)isCalculating
{
    return self.calculationTimer != nil || needCalculationAnimation;
}

- (void)setNeedCalculationAnimation {
    if ([self.selectedDate isFutureDay]) {
        return;
    }
    needCalculationAnimation = YES;
    self.halo.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
    [self stopCenterButtonTipsRotation];
//        HALO_CALCULATION_ANIMATION_START, HALO_CALCULATION_ANIMATION_START);
    [UIView animateWithDuration:1.0f animations:^{
        self.halo.transform = CGAffineTransformMakeScale(2.0f, 2.0f);
    }];
}

- (void)startCalculationAnimation
{
    if (!needCalculationAnimation) return;
    
    [self setCenterButtonTipsIndex:0];
    [self.halo.layer removeAllAnimations];
    self.calculationTimeElapsed = 0;
    self.calculationLabelUpdatedTime = 0;
    self.calculationTimer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(calculationTimerTick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.calculationTimer forMode:NSRunLoopCommonModes];
//    self.buttonColorTimer = [NSTimer timerWithTimeInterval:0.002 target:self selector:@selector(buttonColorTimerTick:) userInfo:nil repeats:YES];
//    [[NSRunLoop mainRunLoop] addTimer:self.buttonColorTimer forMode:NSRunLoopCommonModes];
    
    
    NewDateButton *button = [self centerButton];
    [self updateButtonsForPrediction];
    float targetWidth = HALO_WIDTH;
    if (self.centerButton.percentageChance) {
        targetWidth = HALO_WIDTH_MIN + (self.centerButton.percentageChance - 1.0)/(33.0 - 1.0) * (HALO_WIDTH_MAX - HALO_WIDTH_MIN);
    }
    [button.parentCalendar shineToTargetWidth:targetWidth];
    
    [Utils performInMainQueueAfter:3.0 callback:^()
    {
        [self.calculationTimer invalidate];
        self.calculationTimer = nil;
    }];
//    [Utils performInMainQueueAfter:3.2 callback:^()
//     {
//         [self.buttonColorTimer invalidate];
//         self.buttonColorTimer = nil;
//     }];
//    [Utils performInMainQueueAfter:3.5 callback:^()
//     {
//         [self startCenterButtonTipsRotation];
//     }];
}

- (void)buttonColorTimerTick:(NSTimer *)timer
{
    CGColorRef color = (__bridge CGColorRef)([[self.halo.layer presentationLayer] backgroundColor]);
    UIColor *bgColor = [[UIColor colorWithCGColor:color] colorWithAlphaComponent:1];
    if ([bgColor isEqual:[UIColor whiteColor]])
    {
        bgColor = [UIColor colorWithCGColor:color];
    } else {
    }
    [self centerButton].backgroundColor = bgColor;
}

- (void)calculationTimerTick:(NSTimer *)timer
{
    self.calculationTimeElapsed += 0.05;

	float animationPercent;
    
    
    if (self.calculationTimeElapsed < 0.6)
    {
        animationPercent = self.calculationTimeElapsed / 0.6 * 0.61;
    }
    else
    {
        animationPercent = (self.calculationTimeElapsed - 0.6) / 1.6 * 0.3 + 0.61;
    }
    
    NSInteger shouldUpdatedTimes = animationPercent * 40 * 0.81;
//    GLLog(@"animationPercent %f shouldUpdatedTimes %d",animationPercent,shouldUpdatedTimes);
    if (shouldUpdatedTimes > self.calculationLabelUpdatedTime || self.calculationTimeElapsed < 0.6)
    {
        NewDateButton *button = [self centerButton];
//        float destination = button.percentageChance;
//        float percent = animationPercent * destination;
//        GLLog(@"destination percent%f ",percent);
        if (button) {
            DayInfo *dayInfo = [CalendarDayInfoSummary dayInfoForDate:button.date];
            NSArray *tips = [self calculateTipTextWithDayInfo:dayInfo];
            NSString *firstTip = [tips firstObject];
            //firstTip = [firstTip stringByReplacingOccurrencesOfString:@"1" withString:@"5"];
            dispatch_async(dispatch_get_main_queue(), ^(){
                [button setBottomAnimateTip:firstTip];
            });
            self.calculationLabelUpdatedTime = shouldUpdatedTimes;
        }
    }
    if (shouldUpdatedTimes >= 30)
    {
        NewDateButton *button = [self centerButton];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [button hideBottomAnimateTip];
        });
    }
    if (self.calculationTimeElapsed > 5)//fix possible non invalide issue when transition view during animation...
    {
        [timer invalidate];
    }
}


- (void)shineToTargetWidth:(float)targetWidth
{
    float transit = targetWidth / HALO_WIDTH;
    
    self.halo.transform = CGAffineTransformMakeScale(
        HALO_CALCULATION_ANIMATION_START, HALO_CALCULATION_ANIMATION_START);
    
    UIColor *beforeColor = self.halo.backgroundColor;
    float beforeAlpha = self.halo.alpha;
    
    float currentTransit = self.halo.frame.size.width / HALO_WIDTH;
    float delta = transit - currentTransit;
    float middleTransit = currentTransit + delta / 5 * 4;
    
    UIColor *beforeButtonColor = [self centerButton].backgroundColor;
//    GLLog(@"zx debug centerbtn %@", centerButton);

    [UIView animateWithDuration:0.5 delay:0.00 options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.halo.transform = CGAffineTransformMakeScale(middleTransit, middleTransit);
    } completion:^(BOOL finished){
        if (!finished) {
            [self _cleanUpShineAnimation];
            return;
        }
        [UIView animateWithDuration:2.2 delay:0.00 options:
            UIViewAnimationOptionCurveEaseOut animations:^{
            self.halo.transform = CGAffineTransformMakeScale(transit, transit);
        } completion:^(BOOL finished) {
            if (!finished) {
                [self _cleanUpShineAnimation];
                return;
            }
            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:
                @"shadowOpacity"];
            anim.fromValue = @0;
            anim.toValue = @(beforeAlpha);
            anim.duration = 0.2;
            [self.halo.layer addAnimation:anim forKey:@"shadowOpacity"];
            [UIView animateWithDuration:0.2 delay:0.00 options:
                UIViewAnimationOptionCurveEaseIn animations:^{
                
                self.halo.backgroundColor = [UIColor whiteColor];
                self.halo.layer.shadowRadius = 5;
                self.halo.layer.shadowColor = [UIColor whiteColor].CGColor;
                [self centerButton].backgroundColor = [UIColor whiteColor];
            } completion:^(BOOL finished){
                if (!finished) {
                    [self _cleanUpShineAnimation];
                    return;
                }
                CABasicAnimation *anim = [CABasicAnimation
                    animationWithKeyPath:@"shadowOpacity"];
                anim.toValue = @0;
                anim.duration = 0.3;
                [self.halo.layer addAnimation:anim forKey:@"shadowOpacity"];
                [UIView animateWithDuration:0.3 delay:0.00 options:
                    UIViewAnimationOptionCurveEaseOut animations:^{
                    
                    self.halo.alpha = beforeAlpha;
                    self.halo.backgroundColor = beforeColor;
                    self.halo.layer.shadowRadius = 0;
                    self.halo.layer.shadowColor = [UIColor whiteColor].CGColor;
                    [self centerButton].backgroundColor = beforeButtonColor;
                } completion:^(BOOL finished){
                    [self _cleanUpShineAnimation];
                }];
            }];
        }];
    }];
}

- (void)_cleanUpShineAnimation {
    needCalculationAnimation = NO;
    NewDateButton *button = [self centerButton];
    dispatch_async(dispatch_get_main_queue(), ^(){
        [button hideBottomAnimateTip];
        [self startCenterButtonTipsRotation];
    });
}

- (void)stopCalculationAnimationAndRestyleButtons {
    if ([self isCalculating]) {
        [self.halo.layer removeAllAnimations];
        [self.calculationTimer invalidate];
        self.calculationTimer = nil;
        needCalculationAnimation = NO;
        [self updateButtonsForPrediction];
    }
}

- (void)updateBeginDate:(NSDate *)beginDate;
{
    if (!beginDate) {
        return;
    }
    NSDate *monthBeginDate = [Utils dateByAddingDays:-2 toDate:[Utils monthFirstDate:beginDate]];
    GLLog(@"updateBeginDate: %@ cap:%@", monthBeginDate, mininumDateCap);
    if ([monthBeginDate compare:mininumDateCap] == NSOrderedDescending) {
        //beginDate is later then the 3-month-ago date.
        self.minimumDate = mininumDateCap;
    } else
        self.minimumDate = monthBeginDate;

    [self initScrollView];
    [self initButtonQueue];
    [self.scrollView setPageIndex:[self pageIndexForDate:self.selectedDate] animated:NO];
}

- (void)initScrollView {
    if (self.scrollView) {
        if ( self.scrollView.superview) {
            [self.scrollView removeFromSuperview];
        }
        self.scrollView = nil;
    }

    NSInteger pageCount = [Utils daysWithinEraFromDate:self.minimumDate toDate:self.maximumDate] + 1;
    self.scrollView = [[PagedScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, TINY_CAL_HEIGHT)
                                                    pageSize:TINY_PAGE_WIDTH
                                                   pageCount:pageCount];
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];
}

- (void)pageWillAppear:(PagedScrollView *)scrollView pageIndex:(NSInteger)index
{
    NewDateButton *dateButton = (NewDateButton*)[buttonQueue lastObject];
    [buttonQueue removeLastObject];
    NSDate *date = [self dateForPageIndex:index];
    dateButton.tag = PAGE_INDEX_BASE + index;
    NSInteger bmr = [self calculateBMRForDate:date];
    
    DayInfo *dayInfo = [CalendarDayInfoSummary dayInfoForDate:date];
    dateButton.tips = [self calculateTipTextWithDayInfo:dayInfo];
    dateButton.percentageChance = dayInfo.fertileScore;
    dateButton.bmr = bmr;
    dateButton.date = date;
    dateButton.backgroundColor = UIColorFromRGB(dayInfo.backgroundColorHexValue);
    dateButton.center = [self calculateCenterForIndex:index];
    dateButton.alpha = 0.8;
    dateButton.layer.transform = CATransform3DIdentity;
    if (index == self.scrollView.pageIndex) {
        [dateButton showAsCentralButton];
        //[dateButton continueLabelRotationAnimation];
    } else {
        [dateButton showAsNormalButton];
    }
}

- (NSArray *)calculateTipTextWithDayInfo:(DayInfo *)dayInfo
{
    if (dayInfo.textForPregancy) {
        return @[dayInfo.textForPregancy];
    }
    if (dayInfo.textForTreatmentCycleDay) {
        return @[dayInfo.textForTreatmentCycleDay];
    }
    if (dayInfo.textForPeriod) {
        return @[dayInfo.textForPeriod];
    }
    if (dayInfo.textForDaysToNextCycle && dayInfo.textForChancesOfPregancy) {
        return @[dayInfo.textForChancesOfPregancy, dayInfo.textForDaysToNextCycle];
    }
    if (dayInfo.textForDaysToNextCycle) {
        return @[dayInfo.textForDaysToNextCycle];
    }
    if (dayInfo.textForDaysSinceCurrentCycle) {
        return @[dayInfo.textForDaysSinceCurrentCycle];
    }  
    if ([User currentUser].isSecondary || [User currentUser].isMale) {
        return @[@"No period data\n\n"];
    } else {
        return @[@"Log your period\n\n"];
    }
}

- (void)pageDidDisappear:(PagedScrollView *)scrollView pageIndex:(NSInteger)index {
    UIView *dateButton = [scrollView viewWithTag:PAGE_INDEX_BASE + index];
    if (dateButton) {
        dateButton.tag = -1;
//        GLLog(@"pageDidDisappear:%d %@", index, ((NewDateButton *)dateButton).date);
        [buttonQueue addObject:dateButton]; 
    }
}

- (void)updateButtonsForPrediction {
    NSArray *dateButtons = [self visibleDateButtons];
    for (NewDateButton *button in dateButtons) {
        button.bmr = [self calculateBMRForDate:button.date];
        button.calorieIn = [self getCalorieInForDate:button.date];
        
        DayInfo *dayInfo = [CalendarDayInfoSummary dayInfoForDate:button.date];
        button.tips = [self calculateTipTextWithDayInfo:dayInfo];
        button.backgroundColor = UIColorFromRGB(dayInfo.backgroundColorHexValue);
        button.percentageChance = dayInfo.fertileScore;
    }

    [self updateHaloBackgroundColor:self.selectedDate];
    float targetWidth = HALO_WIDTH;
    if (self.centerButton.percentageChance) {
        targetWidth = HALO_WIDTH_MIN + (self.centerButton.percentageChance - 1.0)/(33.0 - 1.0) * (HALO_WIDTH_MAX - HALO_WIDTH_MIN);
    }
    if (![self isCalculating])
    {
        [self.halo zoomOut:targetWidth animate:NO];
    }
    
}

- (NSArray *)visibleDateButtons {
    NSMutableArray *dateButtons = [[NSMutableArray alloc] init];
    for (UIView *button in self.scrollView.subviews) {
        if (button.tag != -1)
            [dateButtons addObject:button];
    }
    return dateButtons;
}

- (void)initButtonQueue {
    buttonQueue = [NSMutableArray array];
    for (NSInteger i = 0; i < VISIBLE_PAGE_COUNT + 2; i++) {
        NewDateButton *b = [[NewDateButton alloc] init];
        b.tag = -1;
        b.calendar = self.calendar;
        b.formatter = self.dateFormatter;
        b.parentCalendar = self;
        [b addTarget:self action:@selector(dateButtonReleased:)];
        [b setContentMode:UIViewContentModeCenter];
        [buttonQueue addObject:b];
        [self.scrollView addSubview:b];
    }
}

- (void)dateButtonReleased:(UIGestureRecognizer *)gestureRecognizer {
    NewDateButton *b = (NewDateButton *)gestureRecognizer.view;
    if ([Utils daysWithinEraFromDate:self.minimumDate toDate:b.date] < 2 ||  [Utils daysWithinEraFromDate:b.date toDate:self.maximumDate] < 2)
        return;

    if ([self date:b.date isSameDayAsDate:self.selectedDate]) {
        return;
    }
    [self stopCalculationAnimationAndRestyleButtons];
    [self moveToDate:b.date animated:YES];
    // logging
    // NSInteger pageIndex = b.tag - PAGE_INDEX_BASE;
    // [Logging log:BTN_CLK_HOME_TINY_DAY eventData:@{@"button_position": @(pageIndex - self.scrollView.pageIndex)}];
}

- (void)moveToDate:(NSDate *)newDate animated:(BOOL)animated
{
    if (![Utils date:newDate isSameDayAsDate:self.selectedDate]) { 
        self.selectedDate = newDate;
        // self.selectedDate = label2Date(date2Label(newDate));
        [self scrollBegan];
        [self.scrollView setPageIndex:[self pageIndexForDate:newDate] animated:animated];
    }
}

- (float)calculatePercentageChanceForDate:(NSDate *)date {
    if (!date) {
        date = [[NSDate date] truncatedSelf];
    }
    User *currentUser = [User userOwnsPeriodInfo];
    float fertileScore = [currentUser fertileScoreOfDate:date];
    return fertileScore;
}

- (float)calculateBMRForDate:(NSDate *)date {
    User *currentUser = [User userOwnsPeriodInfo];
    NSInteger bmr = [currentUser bmrOfDate:date];
    return bmr;
}

- (float)getCalorieInForDate:(NSDate *)date {
    User *currentUser = [User userOwnsPeriodInfo];
    NSInteger cal = [currentUser calorieInOfDate:date];
    return cal;
}


- (void)calculateMaximumDate {
    // 2 days after the last day of 3 month later
    NSDateComponents *monthDelta = [[NSDateComponents alloc] init];
    [monthDelta setMonth:4];
    NSDate *date = [self.calendar dateByAddingComponents:monthDelta toDate:self.selectedDate options:0];
    NSDateComponents *comps = [self.calendar components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate:date];
    [comps setDay:2];
    self.maximumDate = [self.calendar dateFromComponents:comps];
}

- (void)calculateMinimumDate {
    // 2 days before the first day of 3 month earlier
    NSDateComponents *monthDelta = [[NSDateComponents alloc] init];
    [monthDelta setMonth:-3];
    NSDate *date = [self.calendar dateByAddingComponents:monthDelta toDate:self.selectedDate options:0];
    NSDateComponents *comps = [self.calendar components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate:date];
    [comps setDay:1];
    date = [self.calendar dateFromComponents:comps];
    NSDateComponents *dayDelta = [[NSDateComponents alloc] init];
    [dayDelta setDay:-2];
    self.minimumDate = [self.calendar dateByAddingComponents:dayDelta toDate:date options:0];
    mininumDateCap = self.minimumDate;
}

- (NSInteger) pageIndexForDate:(NSDate *)date {
    return [Utils daysWithinEraFromDate:self.minimumDate toDate:date];
}

- (UIColor *)calculateButtonTextColorForDate:(NSDate *)date
{
    return [UIColor whiteColor];
}

- (CGPoint)calculateCenterForIndex:(NSInteger)index
{
    float centerX = TINY_PAGE_WIDTH * (index + 0.5);
    float curPageIndex = self.scrollView.pageIndex;
    if (index > curPageIndex) {
        centerX += BUTTON_CENTER_SHIFT;
    } else if (index < curPageIndex) {
        centerX -= BUTTON_CENTER_SHIFT;
    }
    
    return CGPointMake(centerX, BUTTONS_CENTER_Y);
}

- (NSDate *)dateForPageIndex:(NSInteger)index {
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:index];
    return [self.calendar dateByAddingComponents:comps toDate:self.minimumDate options:0];
}

- (void)updateSubviewsForScrollOffset:(PagedScrollView *)scrollView offsetX:(CGFloat)offsetX {
    for (UIView* dateButton in self.scrollView.subviews) {
        if (dateButton.tag != -1) {
            [(NewDateButton*)dateButton updateForPosition:offsetX];
        }
    }
}

- (void)updateButtonsForPulling:(float)progress {
//    GLLog(@"progress: %f", progress);
    if (self.isAnimatingBounce) {
        return;
    }
    if (progress <= 1.0) {
        NSInteger centerButtonIndex = self.scrollView.pageIndex;
        
        for (NSInteger i = centerButtonIndex - 2;  i <= centerButtonIndex+2; i++) {
            UIView *b = [self.scrollView viewWithTag:PAGE_INDEX_BASE + i];
            CGPoint c = b.center;
            c.y = BUTTONS_CENTER_Y + (80 - abs((int)(i - centerButtonIndex)) * 30) *progress;
            b.center = c;
        }
    }
}

- (void)finishPulling {
    NSArray *dateButtons = [self visibleDateButtons];
    self.isAnimatingBounce = YES;
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.3 initialSpringVelocity:8 options:0 animations:^{
        for (UIView *b in dateButtons) {
            b.centerY = BUTTONS_CENTER_Y;
        }
    } completion:^(BOOL finished) {
        self.isAnimatingBounce = NO;
    }];
}

- (NewDateButton *)centerButton {
    NSInteger pageIndex = (self.scrollView.contentOffset.x + SCREEN_WIDTH/2) / TINY_PAGE_WIDTH;
    return (NewDateButton*)[self.scrollView viewWithTag:PAGE_INDEX_BASE + pageIndex];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)aScrollView
{
    userDragging = YES;
    [self stopCalculationAnimationAndRestyleButtons];
    [self scrollBegan];
}


- (void)scrollBegan
{
    [self.halo zoomIn];
}

- (void)scrollEnded:(BOOL)animated
{
    self.selectedDate = self.centerButton.date;
    [self updateHaloBackgroundColor: self.selectedDate];
    
    float targetWidth = HALO_WIDTH;
    
    if (self.centerButton.percentageChance) {
        targetWidth = HALO_WIDTH_MIN + (self.centerButton.percentageChance - 1.0)/(33.0 - 1.0) * (HALO_WIDTH_MAX - HALO_WIDTH_MIN);
    }
    else {
        float percentage = [self calculatePercentageChanceForDate:[NSDate date]];
        targetWidth = HALO_WIDTH_MIN + (percentage - 1.0)/(33.0 - 1.0) * (HALO_WIDTH_MAX - HALO_WIDTH_MIN);
    }
    if (animated) {
        [self.halo zoomOut:targetWidth animate:animated];
    }
    
    if (![Utils date:dateForCenterIndex isSameDayAsDate:self.selectedDate]) {
        [self publish:CALENDAR_EVENT_DATE_CHANGED data:self.selectedDate];
        if (userDragging) {
            [self publish:EVENT_TINY_CALENDAR_SWIPE];
        }
    }
    userDragging = NO;
    //[self.centerButton continueLabelRotationAnimation];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    NSLog(@"scrollView did scroll");
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
//    NSLog(@"scrollView Did End Decelerating");
    [self scrollEnded:YES];
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)aScrollView
{
//    NSLog(@"scrollView Did End Scrolling Animation");
    [self scrollEnded:YES];
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
     targetContentOffset->x = [self.scrollView snapToClosestPage: targetContentOffset->x];
}


#pragma mark -

- (void)updateHaloBackgroundColor: (NSDate *)date
{
    DayInfo *dayInfo = [CalendarDayInfoSummary dayInfoForDate:date];
    self.halo.backgroundColor = [UIColorFromRGB(dayInfo.backgroundColorHexValue) colorWithAlphaComponent:0.5];
}

static NSTimer *tipsRotationTimer = nil;
#pragma mark - Tips rotation
- (void)startCenterButtonTipsRotation {
    if (nil != tipsRotationTimer) {
        return;
    }
    
    tipsRotationTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self
        selector:@selector(centerButtonTipsTransition) userInfo:nil repeats:YES];
}

- (void)centerButtonTipsTransition {
    [self.centerButton.rotationTips doLabelRotation];
    self.centerButton.animateLabel.alpha = 0;
}

-(void)stopCenterButtonTipsRotation {
    if (nil != tipsRotationTimer) {
        [tipsRotationTimer invalidate];
    }
    tipsRotationTimer = nil;
}

- (void)setCenterButtonTipsIndex:(NSInteger)index {
    [self.centerButton.rotationTips setCurrentLabelIndex:index];
    [self.centerButton.rotationTips show];
}
@end
