//
//  ChartViewController.m
//  emma
//
//  Created by Xin Zhao on 13-7-4.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "AnimationSequence.h"
#import "AppDelegate.h"
#import "ChartConstants.h"
#import "ChartData.h"
#import "ChartInfoView.h"
#import "ChartUtils.h"
#import "ChartViewController.h"
#import "DayPointerEdgeView.h"
#import "GeniusMainViewController.h"
#import "Logging.h"
#import "SingleColorImageView.h"
#import "UIImage+Resize.h"
#import "UIStoryboard+EMma.h"
#import "User.h"
#import "User+Misfit.h"
#import "UserDailyData.h"
#import <QuartzCore/QuartzCore.h>
#import "XYPieChart.h"
#import "Nutrition.h"
#import "StatusBarOverlay.h"
#import "Tooltip.h"
#import "GeniusMainViewController.h"
#import "GLMarkdownLabel.h"
#import "DailyLogViewController.h"

#define ARC4RANDOM_MAX      0x100000000
#define JUST_CAME_TO_FULL_VIEW @"just_came_to_full_view"
#define kChartExtraAreaRatio 1.2

@interface ChartViewController () <XYPieChartDelegate, XYPieChartDataSource>{
    __weak IBOutlet ChartInfoView *infoUIView;
    __weak IBOutlet DayPointerEdgeView *dayPointerBottomEdgeView;
    __weak IBOutlet UIButton *closeButton;
    __weak IBOutlet UILabel *fullTitleLabel;
    __weak IBOutlet UILabel *thumbnailTitleLabel;
    __weak IBOutlet UIView *titleDividerView;
    __weak IBOutlet UITapGestureRecognizer *syncTap;
    __weak IBOutlet UIView *connect3rdPartyOverlay;
    __weak IBOutlet UIButton *goToMePageButton;
    __weak IBOutlet GLMarkdownLabel *hintToConnectLabel;
    __weak IBOutlet UIView *hintToConnectContainer;
    
    UITapGestureRecognizer *tap;
    NSMutableArray *leftScaleLabels;
    NSInteger dateIdxBeforeRotation;
    CGRect currentScreen;
    CGRect originTitleLabelFrame;
    CGRect originTitleDividerFrame;
    CAGradientLayer *gradient;
    NSInteger todayIdx;
    CGRect originParentFrame;
    
    BOOL useMetricUnit;
    BOOL isCelsius;
    NSMutableDictionary *cachedDailyData;
    NSMutableDictionary *cachedNutrition;
    dispatch_queue_t fetchQueue;
    NSInteger dateIdxToFetch;
    NSInteger pointedDate;
}

@property (weak, nonatomic) IBOutlet UIScrollView *interactiveScrollView;
@property (nonatomic, strong) IBOutlet UIView *headerBackgroundCoverView;
@property (nonatomic, strong) ChartData* chartData;
@property (nonatomic, strong) User *user;
@end

@implementation ChartViewController

/*
static CGRect const PORTRAIT_GRID_AREA = (CGRect){{0,84},{320, 294}};
static CGRect const PORTRAIT_GRID_AREA_IOS6 = (CGRect){{0,64},{320, 294}};
static CGRect const WIDE_LANDSCAPE_GRID_AREA =
    (CGRect){{0, 50},{568, 201.666667f}};
static CGRect const NARROW_LANDSCAPE_GRID_AREA =
    (CGRect){{0, 50},{480, 201.666667f}};
static CGRect const WIDE_LANDSCAPE_GRID_AREA_IOS6 =
    (CGRect){{0, 30},{568, 201.666667f}};
static CGRect const NARROW_LANDSCAPE_GRID_AREA_IOS6 =
    (CGRect){{0, 30},{480, 201.666667f}};
*/
 
+ (id)getInstance {
    return (ChartViewController *)[UIStoryboard chart];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.chartData = [ChartData getInstance];
    
    //Record frame in full view of title and dividers
    originTitleLabelFrame = fullTitleLabel.frame;
    originTitleDividerFrame = titleDividerView.frame;
   
    //base init self.segView
    _segView = [[ChartSegmentView alloc] initWithFrame:self.view.bounds];
    [self.segView setBackgroundColor:[UIColor clearColor]];
    [self.segView setRangeXFromParent:ChartRangeMake(0, [self lengthInLandscape:NO])];
    [self.view insertSubview:self.segView belowSubview:self.interactiveScrollView];
//    [self.interactiveScrollView addSubview:self.segView];
   
    //base init self.interactiveScrollView
    self.interactiveScrollView.contentSize = CGSizeMake(self.view.width * 12, self.view.height);
    self.interactiveScrollView.showsVerticalScrollIndicator = NO;
    self.interactiveScrollView.delegate = self;
    self.interactiveScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.interactiveScrollView.directionalLockEnabled = YES;
    
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tap setNumberOfTapsRequired:1];
    [self.interactiveScrollView addGestureRecognizer:tap];
    
    [infoUIView setPieChartDataSource:self];
    [infoUIView setPieChartDelegate:self];
    [infoUIView setPieChartHidden:YES];
    
    [self subscribe:CALORIES_UPDATED obj:nil selector:@selector(updateDataForCalorie)];
    
    infoUIView.currentArrow.layer.anchorPoint = (CGPoint){0.5f, 0.5f};
    infoUIView.currentArrow.transform = CGAffineTransformMakeRotation(M_PI_2);

}

- (void)setupVarsWhenGeniusWillAppear {
    todayIdx = [Utils dateToIntFrom20130101:[NSDate date]];
    dateIdxToFetch = todayIdx;
    fetchQueue = dispatch_queue_create("com.emma.chartfetch", NULL);
    isCelsius = [[Utils getDefaultsForKey:kUnitForTemp] isEqualToString:
        UNIT_CELCIUS];
    useMetricUnit = [[Utils getDefaultsForKey:kUnitForWeight] isEqualToString:
        UNIT_KG];
//    - [self.chartData buildAll];
}

- (void)teardownVarsWhenGeniusWillDisappear {
    fetchQueue = 0;
    cachedDailyData = nil;
    cachedNutrition = nil;
}

- (NSInteger) _thumbDataType {
    return self.isFertility ? CHART_DATA_TYPE_TEMP : CHART_DATA_TYPE_WEIGHT;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    if (self.underZooming) return;
    
    self.headerBackgroundCoverView.alpha = 0;
    fullTitleLabel.alpha = 0;
    thumbnailTitleLabel.frame = setRectX(thumbnailTitleLabel.frame, 10);

    self.segView.isTtc = self.isFertility;
    self.segView.chartDataType = self.chartDataType;
    self.segView.isMockData = NO;

    // if cycle chart, then display mom's data
    if (self.chartDataType == CHART_DATA_TYPE_TEMP) {
        self.user = (User *)[[User userOwnsPeriodInfo] makeThreadSafeCopy];
    } else {
        self.user = (User *)[[User currentUser] makeThreadSafeCopy];
    }
    
    NSArray *weightData = [self.chartData getRawWeightPointsForUser:self.user];
    if (weightData && weightData.count > 0) {
        [self.segView setWeightFromParent:weightData];
    } else {
        if (self.chartDataType == CHART_DATA_TYPE_WEIGHT) {
            self.segView.isMockData = YES;
            ChartRange range = [self.chartData calculateWeightRangeInCelsius:useMetricUnit forUser:self.user];
            [self.segView setWeightFromParent:[self.chartData getMockedRawWeightPointsInRange:range]];
        } else {
            [self.segView setWeightFromParent:weightData];
        }
    }
    
    [self.segView setBbtFromParent:[self.chartData getRawTempPointsForUser:self.user]];
    [self.segView setBgFromParent:[self.chartData getFertileWindowsForUser:[User userOwnsPeriodInfo]]];
    [self.segView setSexesFromParent:[self.chartData getRawSexPointsForUser:self.user]];
    [self.segView setWeightRangeYFromParent:[self.chartData calculateWeightRangeInCelsius:useMetricUnit forUser:self.user]];
    
    GLLog(@"zx debug %f %f", self.segView.weightRangeY.start, self.segView.weightRangeY.length);
    
    
    TemperatureUnit unit = isCelsius ? Celsius : Fahrenheit;
    self.segView.temperatureRangeY = [self.chartData calculateTempRangeWithUnit:unit];
    
    if (self.chartDataType == CHART_DATA_TYPE_CALORIE) {
        if (![self isConnectedWith3rdPartyHealthApp]){
            self.segView.isMockData = YES;
            [self.segView setCalorieInFromParent:[self.chartData getMockedRawCalorieInPoints]];
            [self.segView setCalorieOutFromParent:[self.chartData getMockedRawCalorieOutPoints]];
        } else {
            [self.segView setCalorieInFromParent:[self.chartData getRawCalorieInPointsForUser:self.user]];
            [self.segView setCalorieOutFromParent:[self.chartData getRawCalorieOutPointsForUser:self.user]];
        }
        [self.segView setCalorieRangeYFromParent:ChartRangeMake([self.chartData getCalorieSpaceStart], [self.chartData getCalorieSpaceLength])];
    }
    
    // setTodayPointInThumb
    [self.segView setTodayPointFromParent:[ChartPoint chartPointWithX:todayIdx y:-1 alpha:-1]];
    NSArray *rawPoints = self.isFertility ? [self.chartData getRawTempPointsForUser:self.user]
    : [self.chartData getRawWeightPointsForUser:self.user];
    for (ChartPoint *cp in rawPoints) {
        if (fabs(cp.x - todayIdx) < 0.1f) {
            self.segView.todayPointInThumb.y = cp.y;
            self.segView.todayPointInThumb.alpha = cp.y;
        }
    }
    if (self.segView.todayPointInThumb.y < 0) {
        CGFloat value = self.isFertility
        ? [self.chartData interpolateTempAtDateIdx:todayIdx]
        : [self.chartData interpolateWeightAtDateIdx:todayIdx];
        self.segView.todayPointInThumb.y = value;
    }
    
//    [self setTodayPointInThumb];
    [self.segView setInCelsiusFromParent:isCelsius];
    dateIdxToFetch = todayIdx;
    [self.segView setRangeXFromParent:[self rangeXLandscape:NO]];
    self.segView.state = ChartSegmentStateThumb;
    [self.segView setNeedsDisplay];
    fullTitleLabel.text = self.dataTypeTitle;
    thumbnailTitleLabel.text = self.dataTypeTitle;
    
    [self _stylishConnectWith3rdPartyOverlay];
    
    if (self.inFullView){
        [self thumbToFullBegin];
        [self thumbToFull];
        [self thumbToFullCompletion];
    }
    
    if (self.chartDataType == CHART_DATA_TYPE_NUTRITION) {
        [self showPieChart];
        [self fullToThumbBegin];
        [self fullToThumb];
        [self fullToThumbCompletion];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.chartData clearAll];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - property shortcut

- (CGFloat)w {
    return self.view.frame.size.width;
}

- (CGFloat)h {
    CGFloat height = self.view.frame.size.height;
    return height;
}

- (CGFloat)dateX {
    return self.segView.rangeX.start +
        (self.currentArrowX / self.gridArea.size.width) *
        self.segView.rangeX.length;
}

- (NSString *)dataTypeTitle {
    User *user = [User currentUser];
    NSDictionary *dataTypeToTitle = @{
             @(CHART_DATA_TYPE_TEMP): user.isSecondary ? TITLE_TEMP_FOR_PARTNER : TITLE_TEMP,
             @(CHART_DATA_TYPE_WEIGHT):  TITLE_WEIGHT,
             @(CHART_DATA_TYPE_CALORIE):  TITLE_CALORIE,
             @(CHART_DATA_TYPE_NUTRITION):  TITLE_NUTRITION,
             };
    return dataTypeToTitle[@(self.segView.chartDataType)];
}

- (BOOL)isConnectedWith3rdPartyHealthApp {
    User *u = [User currentUser];
    return [u isConnectedWith3rdPartyHealthApps] && !self.segView.isMockData;
}

- (float)headerHeightInLands:(BOOL)inLands {
    return inLands ? UPPER_H_LANDSCAPE : UPPER_H;
}

- (float)infoHeightInLands:(BOOL)inLands {
    if (inLands) return INFO_H_LANDSCAPE;
    return INFO_H;
}

-  (CGRect)gridArea {
    BOOL isLands = self.isLandscape;
    return (CGRect){{0, [self headerHeightInLands:isLands]},
        {self.view.frame.size.width,
        (self.view.frame.size.height - [self headerHeightInLands:isLands] -
        [self infoHeightInLands:isLands]) * GRID_AREA_HEIGHT_2_WHOLE}};
}

- (CGRect)chartBodyRect {
    BOOL isLands = self.isLandscape;
    return (CGRect){{0, [self headerHeightInLands:isLands]},
        {self.view.frame.size.width,
        self.view.frame.size.height - [self headerHeightInLands:isLands]}};
}

- (CGRect)segRectInLandscape:(BOOL)isLands {
    float headerH = [self headerHeightInLands:isLands];
    return (CGRect){{0, headerH},
        {self.view.frame.size.width,
        self.view.frame.size.height - headerH -
        [self infoHeightInLands:isLands]}};
}

- (CGRect)infoRectInLandscape:(BOOL)isLandscape {
    float infoH = [self infoHeightInLands:isLandscape];
    return (CGRect){{0, self.view.frame.size.height - infoH},
        {self.view.frame.size.width, infoH}};
}

- (CGFloat)lengthInLandscape:(BOOL)isLandscape {
    if (isLandscape) {
        return MAX(SCREEN_WIDTH, SCREEN_HEIGHT) > 480 ? 21.34f : 18.04f;
    }
    return 12.f;
}

- (BOOL)isLandscape {
    return self.view.frame.size.width > self.view.frame.size.height;
}

- (ChartRange)rangeXLandscape:(BOOL)isLandscape {
    CGFloat s, l;
    l = [self lengthInLandscape:isLandscape];
    if (isLandscape) {
        s = dateIdxToFetch - l + 2.5f;
    }
    else {
        s = dateIdxToFetch - l + 1.5f;
    }
    return ChartRangeMake(s, l);
}

#pragma mark - handlers
- (void) handleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint tapPoint = [recognizer locationInView:self.segView];
    if (CGRectContainsPoint([self.segView getBaseLineNameRect], tapPoint)) {
        if (CHART_DATA_TYPE_TEMP == self.segView.chartDataType) {
            [Tooltip tip:@"Cover line"];
        }
        else if (CHART_DATA_TYPE_CALORIE == self.segView.chartDataType) {
            [Tooltip tip:@"Recommended intake"];
        }
    }
}

- (IBAction)closeButtonClicked:(id)sender {
    [((AppDelegate *)[UIApplication sharedApplication].delegate)
        setRotationEnabled:NO];
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        UIViewController *viewController  = [[UIViewController alloc] init];
        viewController.modalTransitionStyle =
            UIModalTransitionStyleCoverVertical;
        [self.navigationController presentViewController:viewController
            animated:NO completion:^{
            dispatch_after(0, dispatch_get_main_queue(), ^() {
                self.view.frame = CGRectMake(0, 0,
                                             originParentFrame.size.width,
                                             originParentFrame.size.height);
                self.view.superview.frame = originParentFrame;
                [self.segView setNeedsDisplay];
                [self repositionInteractiveScrollViewWithScale:1];
                [self repositionTopViewsToInterfaceOrientation:
                 UIInterfaceOrientationPortrait];
                [self.navigationController dismissViewControllerAnimated:NO
                    completion:^(){
                    [self resetChartToClose];
                }];
            });
        }];
    }
    else {
        [self resetChartToClose];
    }
}

- (void)resetChartToClose
{
    connect3rdPartyOverlay.hidden = YES;
    [((GeniusMainViewController*)self.parentViewController) refreshChildrenLayout];
    [((AppDelegate *)[UIApplication sharedApplication].delegate)
     setRotationEnabled:NO];
    [self close];
}

#pragma mark - UIView drawing helper
- (void)drawScaleLabels {
    for (UILabel *scaleLabel in leftScaleLabels) {
        [scaleLabel removeFromSuperview];
    }
    leftScaleLabels = [NSMutableArray array];
    
    if (self.segView.chartDataType == CHART_DATA_TYPE_TEMP) {
        [self drawTempLabel];
    } else if (self.segView.chartDataType== CHART_DATA_TYPE_WEIGHT) {
        [self drawWeightLabel];
    } else if (self.segView.chartDataType== CHART_DATA_TYPE_CALORIE) {
        [self drawCalorieLabel];
    } else if (self.segView.chartDataType== CHART_DATA_TYPE_NUTRITION) {

    }
}

- (void)drawTempLabel
{
    CGFloat start = self.segView.temperatureRangeY.start;
    CGFloat end = start + self.segView.temperatureRangeY.length;
    CGFloat interval = self.segView.temperatureRangeY.length / GRID_DIVIDER;
   
    CGFloat screenIntervalY = self.gridArea.size.height / GRID_DIVIDER;
    
    CGFloat highestY = FLT_MIN;
    CGFloat lowestY = FLT_MAX;
    for (ChartPoint *each in self.segView.bbtKnots) {
        if (each.y < lowestY) {
            lowestY = each.y;
        }
        else if (each.y > highestY) {
            highestY = each.y;
        }
    }
    
    if (!isCelsius) {
        start = [Utils fahrenheitFromCelcius:start];
        end = [Utils fahrenheitFromCelcius:end];
        interval = (end - start) / GRID_DIVIDER;
        highestY = [Utils fahrenheitFromCelcius:highestY];
        lowestY = [Utils fahrenheitFromCelcius:lowestY];
    }

    CGFloat indexStart = 0 - 30;    // for extra scrolling area along y axis
    CGFloat indexEnd = 10 + 30;
//    if (lowestY < start + interval * 2) {
//        indexEnd = indexEnd + ceilf((start + interval * 2 - lowestY) / (interval * 2));
//    }
//    if (highestY > end - interval * 2) {
//        indexStart = indexStart - ceilf((highestY - end + interval * 2) / (interval * 2));
//    }

    NSInteger increment = self.isLandscape ? 2 : 1;
    CGRect labelRect = CGRectMake(10, 0, 55, 20);
    
    for (CGFloat i = indexStart; i <= indexEnd; i += increment) {
        CGFloat y = (1 + i * 2) * screenIntervalY;
        CGFloat val = end - (1 + i * 2) * interval;
        UILabel *tempScaleLabel = [[UILabel alloc] initWithFrame:setRectY(labelRect, y - 10)];
        tempScaleLabel.textColor = SCALE_COLOR;
        tempScaleLabel.font = [Utils lightFont:SCALE_LABEL_FONT_SIZE];
        tempScaleLabel.backgroundColor = [UIColor clearColor];
        CGFloat bbt = val;
        CGFloat decimal = bbt - (NSInteger)floor(bbt);
        CGFloat diff = fabs(decimal - roundf(decimal));
        
        if (diff < 0.01) {
            tempScaleLabel.text = [NSString stringWithFormat:@"%.1f", bbt];
        }
        else if (isCelsius) {
            tempScaleLabel.text = [[NSString stringWithFormat:@"%.1f", decimal]
                substringFromIndex:1];
        }
        else {
            tempScaleLabel.text = [[NSString stringWithFormat:@"%.1f", decimal]
                substringFromIndex:1];
        }
        tempScaleLabel.textAlignment = NSTextAlignmentLeft;
//        [self.view insertSubview:tempScaleLabel aboveSubview:self.segView];
        [self.segView addSubview:tempScaleLabel];
        [leftScaleLabels addObject:tempScaleLabel];
    }
}


- (void)updateScaleLabelsPositionWithOffsetY:(CGFloat)offset
{
    CGFloat bottomEdge = self.segView.height * GRID_AREA_HEIGHT_2_WHOLE;
    
    for (UILabel *each in leftScaleLabels) {
        each.top += offset;
        
        if (each.bottom > bottomEdge) {
            CGFloat alpha = 1 - MIN(10, (each.bottom - bottomEdge)) / 10;
            each.alpha = alpha;
        }
        else {
            each.alpha = 1;
        }
    }
}


- (void)drawWeightLabel {
    CGRect labelRect = CGRectMake(10, 0, 55, 20);
    
    CGFloat weightSpaceStart = self.segView.weightRangeY.start;
    CGFloat weightSpaceLength = self.segView.weightRangeY.length;
    CGFloat end, interval;
    interval = weightSpaceLength / GRID_DIVIDER;
    end = weightSpaceStart + weightSpaceLength;
    
    CGFloat screenStartY = self.gridArea.origin.y;
    CGFloat screenIntervalY = self.gridArea.size.height / GRID_DIVIDER;

    NSInteger increment = self.isLandscape ? 2 : 1;

    for (CGFloat i = 0; i <= 10; i += increment) {
        CGFloat y = screenStartY + screenIntervalY + i * 2 * screenIntervalY;
        CGFloat val = end - (1 + i * 2) * interval;
        UILabel *tempScaleLabel = [[UILabel alloc] initWithFrame:setRectY(labelRect, y - 10)];
        tempScaleLabel.textColor = SCALE_COLOR;
        tempScaleLabel.font = [Utils lightFont:SCALE_LABEL_FONT_SIZE];
        tempScaleLabel.textAlignment = NSTextAlignmentRight;
        tempScaleLabel.backgroundColor = [UIColor clearColor];
        CGFloat numberToDisplay = useMetricUnit ? val : [Utils poundsFromKg:val];
        if (useMetricUnit) {
            tempScaleLabel.text = [NSString stringWithFormat:@"%.0f",
                                   numberToDisplay];
        }
        else {
            tempScaleLabel.text = [NSString stringWithFormat:@"%.0f",
                                   numberToDisplay];
        }
        if (0 == i) {
            tempScaleLabel.text = catstr(tempScaleLabel.text,
                useMetricUnit ? @" KG" : @" LB", nil);
        }
        tempScaleLabel.textAlignment = NSTextAlignmentLeft;
        [self.view insertSubview:tempScaleLabel aboveSubview:self.segView];
        [leftScaleLabels addObject:tempScaleLabel];
    }
}

- (void)drawCalorieLabel {
    CGRect labelRect = CGRectMake(10, 0, 55, 20);
    
    CGFloat calorieSpaceStart = [self.chartData getCalorieSpaceStart];
    CGFloat calorieSpaceLength = [self.chartData getCalorieSpaceLength];
    CGFloat end, interval;
    interval = calorieSpaceLength / GRID_DIVIDER;
    end = calorieSpaceStart + calorieSpaceLength;
    
    CGFloat screenStartY = self.gridArea.origin.y;
    CGFloat screenIntervalY = self.gridArea.size.height / GRID_DIVIDER;

    NSInteger increment = self.isLandscape ? 2 : 1;

    for (CGFloat i = 0; i <= 10; i += increment) {
        CGFloat y = screenStartY + screenIntervalY + i * 2 * screenIntervalY;
        CGFloat val = end - (1 + i * 2) * interval;
        UILabel *scaleLabel = [[UILabel alloc] initWithFrame:setRectY(labelRect, y - 10)];
        scaleLabel.textColor = SCALE_COLOR;
        scaleLabel.font = [Utils lightFont:SCALE_LABEL_FONT_SIZE];
        scaleLabel.backgroundColor = [UIColor clearColor];
        scaleLabel.textAlignment = NSTextAlignmentLeft;
        scaleLabel.text = [NSString stringWithFormat:@"%.0f", val];
        if (0 == i) {
            scaleLabel.text = catstr(scaleLabel.text, @" cal", nil);
        }
        [self.view insertSubview:scaleLabel aboveSubview:self.segView];
        [leftScaleLabels addObject:scaleLabel];
    }
}

#pragma mark - data helper
- (NSInteger)chartStartIdx
{
    return todayIdx - 300;
}

- (void)setTodayPointInThumb
{
    [self.segView setTodayPointFromParent:[ChartPoint chartPointWithX:todayIdx y:-1 alpha:-1]];
    NSArray *rawPoints = self.isFertility ? [self.chartData getRawTempPointsForUser:[User currentUser]]
        : [self.chartData getRawWeightPointsForUser:[User currentUser]];
    for (ChartPoint *cp in rawPoints) {
        if (fabs(cp.x - todayIdx) < 0.1f) {
            self.segView.todayPointInThumb.y = cp.y;
            self.segView.todayPointInThumb.alpha = cp.y;
        }
    }
    if (self.segView.todayPointInThumb.y < 0) {
        CGFloat value = self.isFertility
                ? [self.chartData interpolateTempAtDateIdx:todayIdx]
                : [self.chartData interpolateWeightAtDateIdx:todayIdx];
        self.segView.todayPointInThumb.y = value;
    }
}

#pragma mark - data type switch

- (void)updateDataForCalorie {
    [self.segView setCalorieInFromParent:(self.isConnectedWith3rdPartyHealthApp
        ? [self.chartData getRawCalorieInPointsForUser:[User currentUser]]
        : [self.chartData getMockedRawCalorieInPoints])];
     
    [self.segView setCalorieOutFromParent:(self.isConnectedWith3rdPartyHealthApp
        ? [self.chartData getRawCalorieOutPointsForUser:[User currentUser]]
        : [self.chartData getMockedRawCalorieOutPoints])];
     
    [self.segView setNeedsDisplay];
}


- (void)leaveBreadcrumbForDataType {
    NSInteger type = self.segView.chartDataType;
    if (type == CHART_DATA_TYPE_TEMP) {
        [CrashReport leaveBreadcrumb:@"ChartViewController goto Temperature"];
    } else if (type == CHART_DATA_TYPE_WEIGHT) {
        [CrashReport leaveBreadcrumb:@"ChartViewController goto weight"];
    }
    else if (type == CHART_DATA_TYPE_CALORIE) {
        [CrashReport leaveBreadcrumb:@"ChartViewController goto calorie"];
    }
    else if (type == CHART_DATA_TYPE_NUTRITION) {
        [CrashReport leaveBreadcrumb:@"ChartViewController goto nutrition"];
    }
}

#pragma makr - scroll
- (void)scrollWithStationaryScreenX:(CGFloat)screenX andValueX:(CGFloat)valueX {
    
    CGFloat newX = (valueX - self.chartStartIdx) / self.segView.rangeX.length * self.w;
    CGFloat offsetY = roundf(self.interactiveScrollView.contentOffset.y / self.segView.intervalY) * self.segView.intervalY - 3;
    CGPoint offset = CGPointMake(newX - screenX, offsetY);
    [self.interactiveScrollView setContentOffset:offset animated:YES];
    
    [self updatePointer];
}

- (void)repositionInteractiveScrollViewWithScale:(float)scale
{
    CGFloat segViewLength = self.segView.rangeX.length;
    CGFloat scrollViewWidth = (366 / segViewLength) * self.w;
    self.interactiveScrollView.contentSize = CGSizeMake(scrollViewWidth, self.interactiveScrollView.height * (1 + 2 * kChartExtraAreaRatio));
    CGFloat newContentOffsetX = ((self.segView.rangeX.start - self.chartStartIdx) / self.segView.rangeX.length) * self.w;

    self.interactiveScrollView.contentOffset = CGPointMake(newContentOffsetX, self.interactiveScrollView.height * kChartExtraAreaRatio);
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.segView.chartDataType == CHART_DATA_TYPE_NUTRITION) {
        return;
    }

    BOOL isTemp = (self.segView.chartDataType == CHART_DATA_TYPE_TEMP);
    
    ChartRange newRange = ChartRangeMake(scrollView.contentOffset.x * self.segView.rangeX.length / self.w + self.chartStartIdx, self.segView.rangeX.length);
    CGFloat tempOffset = isTemp ? -(scrollView.contentOffset.y - scrollView.height * kChartExtraAreaRatio) : 0;
    [self.segView setRangeXFromParent:newRange];
    [self.segView setTempOffset:tempOffset];
    [self.segView setNeedsDisplay];
    
    [self updatePointer];
    
    if (isTemp) {
        static CGFloat lastTempOffset = 0;
        [self updateScaleLabelsPositionWithOffsetY:(tempOffset - lastTempOffset)];
        lastTempOffset = tempOffset;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.segView.chartDataType == CHART_DATA_TYPE_NUTRITION) {
        return;
    }
    if (decelerate) {
        return;
    }
    
    // Disable snap cycle now
    //if ([self _snapCycle]) return;
    
    CGFloat screenX = self.currentArrowX;
    CGFloat valueX = roundf(self.segView.rangeX.start + screenX / self.w * self.segView.rangeX.length);
    [self scrollWithStationaryScreenX:screenX andValueX:valueX];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.segView.chartDataType == CHART_DATA_TYPE_NUTRITION) {
        return;
    }

    //Disable snap cycle now
    //if ([self _snapCycle]) return;
    
    CGFloat screenX = self.currentArrowX;
    CGFloat valueX = roundf(self.segView.rangeX.start + screenX / self.w * self.segView.rangeX.length);
    [self scrollWithStationaryScreenX:screenX andValueX:valueX];
}

- (BOOL)_snapCycle {
    NSInteger s = (NSInteger)self.segView.rangeX.start;
    NSInteger l = (NSInteger)self.segView.rangeX.length;
    NSNumber *pb = [self.segView getPbBetweenStart:s toEnd:s + l];
    
    if (!pb) return NO;
    
    CGFloat stationaryScreen = 320.f / 24.f;
    if ([pb intValue] - s > l / 2.f) {
        stationaryScreen = 320.f + stationaryScreen;
    }
    [self scrollWithStationaryScreenX:stationaryScreen andValueX:[pb floatValue]];
    return YES;
}

#pragma mark - rotation
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (!self.inFullView) {
        return;
    }

    if ( [[Utils getDefaultsForKey:JUST_CAME_TO_FULL_VIEW] boolValue]) {
        _needCorrectFrameAfterRotation = YES;
        [Utils setDefaultsForKey:JUST_CAME_TO_FULL_VIEW withValue:nil];
    } else
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) != UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        _needCorrectFrameAfterRotation = YES;
    }
    else {
        _needCorrectFrameAfterRotation = NO;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (!self.inFullView) {
        return;
    }

    if (self.needCorrectFrameAfterRotation) {
        CGFloat width;
        CGFloat height;
        if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
            (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
            width  = MAX(SCREEN_WIDTH, SCREEN_HEIGHT);
            height = MIN(SCREEN_WIDTH, SCREEN_HEIGHT);
        } else {
            width  = MIN(SCREEN_WIDTH, SCREEN_HEIGHT);
            height = MAX(SCREEN_WIDTH, SCREEN_HEIGHT);
        }
        self.view.frame = CGRectMake(0, 0, width, height);
    }
    _needCorrectFrameAfterRotation = YES;

    BOOL toLandscape = NO;
    if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        toLandscape = YES;
    }
    self.segView.frame = [self segRectInLandscape:toLandscape];
    [self.segView setRangeXFromParent:[self rangeXLandscape:toLandscape]];
    
    infoUIView.infoPanel.frame = [self infoRectInLandscape:toLandscape];
    infoUIView.currentDayDot.hidden = infoUIView.extraDayDot.hidden =
        dayPointerBottomEdgeView.hidden = YES;
    infoUIView.hidden = YES;
    [self repositionInteractiveScrollViewWithScale:1];
    [self.segView setNeedsDisplay];
    
    [self repositionTopViewsToInterfaceOrientation:toInterfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (!self.inFullView) {
        return;
    }

    [Logging log:PAGE_IMP_GNS_CHART_ROTATE];
    
    BOOL hideInfoView = NO;
    if (self.segView.chartDataType == CHART_DATA_TYPE_NUTRITION) {
        hideInfoView = YES;
        infoUIView.nutritionView.frame = self.chartBodyRect;
        [infoUIView setupNutritionViewInDataType:self.segView.chartDataType];
    }
    infoUIView.currentDayDot.hidden = infoUIView.extraDayDot.hidden =
        dayPointerBottomEdgeView.hidden = hideInfoView;
    infoUIView.hidden = hideInfoView;
    [infoUIView setupInfoPanelInDataType:self.segView.chartDataType
        landscape:self.isLandscape];
    [self positionCurrentArrowAndPointerEdge];
    [self _repositionOverlay];
    [self drawScaleLabels];
  
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        self.view.superview.frame = self.view.frame = CGRectMake(0, 0,
            MAX(SCREEN_WIDTH, SCREEN_HEIGHT),
            MIN(SCREEN_WIDTH, SCREEN_HEIGHT));
    } else {
        self.view.superview.frame = self.view.frame = CGRectMake(0, 0,
            MIN(SCREEN_WIDTH, SCREEN_HEIGHT),
            MAX(SCREEN_WIDTH, SCREEN_HEIGHT));
    }
}

- (void)repositionTopViewsToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    BOOL isPortraint = !UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    float osOffsetY = -18;
    float originY = originTitleLabelFrame.origin.y;
    if (isPortraint) {
        float y = originY;
        fullTitleLabel.frame = setRectY(fullTitleLabel.frame, y);
        closeButton.frame = setRectY(closeButton.frame, y);
    }
    else {
        float y = originTitleLabelFrame.origin.y + osOffsetY;
        fullTitleLabel.frame = setRectY(fullTitleLabel.frame, y);
        closeButton.frame = setRectY(closeButton.frame, y);
    }
    
    self.headerBackgroundCoverView.height = [self headerHeightInLands:[self isLandscape]];
    
    infoUIView.nutritionView.frame = self.chartBodyRect;
    [infoUIView updatePieChartInRect:self.chartBodyRect];
}
#pragma mark - InfoView & Day Pointer Edges

- (CGFloat)currentArrowX {
    if (self.isLandscape) {
        return self.gridArea.size.width * (1 - 2.5f /
            [self lengthInLandscape:YES]);
    }
    return self.gridArea.size.width * (1 - 1.5f / [self lengthInLandscape:NO]);
}

- (void)positionCurrentArrowAndPointerEdge {
    CGFloat y = [self infoRectInLandscape:self.isLandscape].origin.y - 2;
    CGFloat x = self.currentArrowX;
    infoUIView.currentArrow.center = (CGPoint){x, y};
    dayPointerBottomEdgeView.frame = setRectX(dayPointerBottomEdgeView.frame, x - 1);
}

- (void)updatePointer
{
    CGFloat dateX = self.dateX;
    CGFloat x = self.currentArrowX;
    CGFloat y = -1, screenY = 1000, screenIn = 1000, screenOut = 1000;
    if (CHART_DATA_TYPE_TEMP == self.segView.chartDataType) {
        y = [self.chartData interpolateTempAtDateIdx:dateX];
        y = y < 0 ? -9999 : y;
        CGFloat tempOffset = -(self.interactiveScrollView.contentOffset.y - self.interactiveScrollView.height * kChartExtraAreaRatio);
        screenY = yValueToScreen(y, self.gridArea, self.segView.temperatureRangeY) + tempOffset;
    }
    else if (CHART_DATA_TYPE_WEIGHT == self.segView.chartDataType) {
        y = [self.chartData interpolateWeightAtDateIdx:dateX];
        y = y < 0 ? -9999 : y;
        screenY = yValueToScreen(y, self.gridArea, self.segView.weightRangeY);
    }
    else if (CHART_DATA_TYPE_CALORIE == self.segView.chartDataType) {
        y = [self.chartData interpolateCalorieInAtDateIdx:dateX];
        y = y < 0 ? -9999 : y;
        CGFloat yOut = [self.chartData interpolateCalorieOutAtDateIdx:dateX];
        yOut = yOut < 0 ? -9999 : yOut;
        screenIn = yValueToScreen(y, self.gridArea, self.segView.calorieRangeY);
        screenOut = yValueToScreen(yOut, self.gridArea,
            self.segView.calorieRangeY);
        screenY = MIN(screenIn, screenOut);
    }
    dayPointerBottomEdgeView.frame = setRectY(dayPointerBottomEdgeView.frame, screenY);
   
    if (CHART_DATA_TYPE_CALORIE == self.segView.chartDataType) {
        [infoUIView posCurrentDotAtX:x y:screenIn inDataType:
            self.segView.chartDataType withRadius:DOT_RADIUS
            extra:@[@(x), @(screenOut)]];
    }
    else {
        [infoUIView posCurrentDotAtX:x y:(y == -1 ? 1000 : screenY)
            inDataType: self.segView.chartDataType withRadius:DOT_RADIUS
            extra:nil];
    }
    
    CGFloat bottomEdge = self.segView.height * GRID_AREA_HEIGHT_2_WHOLE;
    CGFloat dotBottom = infoUIView.currentDayDot.bottom - [self headerHeightInLands:[self isLandscape]];
    if (dotBottom > bottomEdge) {
        CGFloat alpha = 1 - MIN(10, (dotBottom - bottomEdge)) / 10;
        infoUIView.currentDayDot.alpha = alpha;
        dayPointerBottomEdgeView.alpha = alpha;
    }
    else {
        infoUIView.currentDayDot.alpha = 1;
        dayPointerBottomEdgeView.alpha = 1;
    }
    
    [infoUIView updateDateWithDateIdx:(NSInteger)roundf(dateX)
                            cycleDay:[self.segView getCdForDateIdx:(NSInteger)roundf(dateX)]
                          ovulationDay:[self.segView getOvulationForDateIndex:(NSInteger)roundf(dateX)]];
   
    dateIdxToFetch = (NSInteger)roundf(self.dateX);
    [self updateInfoUIView];
}

- (void)updateInfoUIView {
    NSInteger dateIdx = dateIdxToFetch;
    
    if (!cachedDailyData) {
        cachedDailyData = [@{} mutableCopy];
    }
    
    if (cachedDailyData[@(dateIdx)]) {
        id daily = cachedDailyData[@(dateIdx)];
        [infoUIView updateInfoPanelWithDailyData:!isNSNull(daily) ?
         (UserDailyData *)daily : nil];
    }
    
    if (CHART_DATA_TYPE_CALORIE == self.segView.chartDataType ||
        CHART_DATA_TYPE_NUTRITION == self.segView.chartDataType) {
        if (!cachedNutrition) {
            cachedNutrition = [@{} mutableCopy];
        }
        NSDictionary *desc = cachedNutrition[@(dateIdx)];
        if (!desc) {
            desc = [self _getNutritionFromChartDataAtDateIdx:dateIdx];
            cachedNutrition[@(dateIdx)] = desc;
        }
        if (CHART_DATA_TYPE_CALORIE == self.segView.chartDataType) {
            [infoUIView updateInfoPanelWithNutritionDesc:desc];
        } else {
            [infoUIView updateNutritionLegendsWithNutrition:desc
                atDateIdx:dateIdx];
        }
    }
    
    if (cachedDailyData[@(dateIdx)]) {
        return;
    }
    if (!fetchQueue) {
        return;
    }
    dispatch_async(fetchQueue, ^{
        UserDailyData *daily = [UserDailyData getUserDailyData:
            [Utils dateIndexToDateLabelFrom20130101:dateIdx] forUser:self.user];
        if (dateIdx == dateIdxToFetch) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [infoUIView updateInfoPanelWithDailyData:daily];
                cachedDailyData[@(dateIdx)] = daily ? daily : [NSNull null];
            });
        }
    });
    
}

- (NSDictionary *)_getNutritionFromChartDataAtDateIdx:(NSInteger)dateIdx {
    CGFloat calIn = -1000, calOut = -1000, recommendedCal = -3000;
    NSString *via, *carb, *fat, *protein;
    via = @"--";
    carb = fat = protein = @"-";
    NSArray *rawCalorieInPoints = (self.isConnectedWith3rdPartyHealthApp
        ? [self.chartData getRawCalorieInPointsForUser:[User currentUser]]
        : [self.chartData getMockedRawCalorieInPoints]);
    for (NSInteger i = 0; i < [rawCalorieInPoints count]; i++) {
        ChartPoint *p = rawCalorieInPoints[i];
        if (fabs(p.x - dateIdx) < 0.5) {
            calIn = p.y;
            break;
        }
    }
    NSArray *rawCalorieOutPoints = (self.isConnectedWith3rdPartyHealthApp
        ? [self.chartData getRawCalorieOutPointsForUser:[User currentUser]]
        : [self.chartData getMockedRawCalorieOutPoints]);
    for (NSInteger i = 0; i < [rawCalorieOutPoints count]; i++) {
        ChartPoint *p = rawCalorieOutPoints[i];
        if (fabs(p.x - dateIdx) < 0.5) {
            calOut = p.y;
            break;
        }
    }
    NSDictionary *rawNutrition = self.isConnectedWith3rdPartyHealthApp
        ? [self.chartData getRawNutritionPointsForUser:[User currentUser]][@(dateIdx)]
        : [self.chartData getMockedRawNutritionPoint];
    if (rawNutrition) {
        via = rawNutrition[NUTRITION_SRC_NAME];
        NSDictionary *calPercentages = [self _calPercentageFrom:rawNutrition];
        float _carb = [calPercentages[NUTRITION_CARBOHYDRATE] floatValue];
        float _fat = [calPercentages[NUTRITION_FAT] floatValue];
        float _protein = [calPercentages[NUTRITION_PROTEIN] floatValue];
        float _all = _carb + _fat + _protein;
        if (_all > 0) {
            carb = [NSString stringWithFormat:@"%.0f%%", _carb];
            fat = [NSString stringWithFormat:@"%.0f%%", _fat];
            protein = [NSString stringWithFormat:@"%.0f%%", _protein];
        }
    } else {
        User *u = [User currentUser];
        if ([u isMFPConnected]) {
            via = [Nutrition srcName:NUTRITION_SRC_MFP];
        } else if (u.jawboneId) {
            via = [Nutrition srcName:NUTRITION_SRC_JAWBONE];
        } else if (u.fitbitId) {
            via = [Nutrition srcName:NUTRITION_SRC_FITBIT];
        } else if ([u isConnectedWithMisfit]) {
            via = [Nutrition srcName:NUTRITION_SRC_MISFIT];
        }
    }
    recommendedCal = [self.chartData getRecommendedCaloire];
    return @{@"calIn": @(calIn), @"calOut": @(calOut), @"via": via,
        @"fat": fat, @"carb": carb, @"protein": protein,
        @"recommendedCal": @(recommendedCal)};
}

#pragma mark - GeniusChildViewController methods
- (void)showThumbView {
    [self hideComponentsForThumb];
    
    CGRect thumbRect = [((GeniusMainViewController*)self.parentViewController)
        viewFrameOfChild:self];
    thumbRect = setRectX(thumbRect, 0);
    thumbRect = CGRectMake(0, THUMB_CHART_TITLE_HEIGHT, thumbRect.size.width, thumbRect.size.height - THUMB_CHART_TITLE_HEIGHT);
    self.segView.frame = thumbRect;
    self.segView.state = ChartSegmentStateThumb;
    [self.segView setNeedsDisplay];
    
    self.headerBackgroundCoverView.alpha = 0;
    fullTitleLabel.alpha = 0;
    thumbnailTitleLabel.frame = setRectX(thumbnailTitleLabel.frame, 10);
    thumbnailTitleLabel.frame = setRectY(thumbnailTitleLabel.frame, 2);
    thumbnailTitleLabel.text = self.isFertility
        ? @"CYCLE CHARTS" : @"HEALTH CHARTS";
    titleDividerView.frame = CGRectMake(10, 35, GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 1);
    self.interactiveScrollView.userInteractionEnabled = NO;
    
    infoUIView.infoPanel.hidden = YES;
    infoUIView.currentArrow.alpha = 0;

    [super showThumbView];

}

- (void)fullToThumbBegin {
    [self hideComponentsForThumb];
    connect3rdPartyOverlay.hidden = YES;
    infoUIView.infoPanel.hidden = YES;
    infoUIView.currentArrow.alpha = 0;
    self.interactiveScrollView.userInteractionEnabled = NO;
    self.segView.state = ChartSegmentStateTransition;
}

- (void)fullToThumb {
    self.segView.state = ChartSegmentStateTransition;
    UIView * container = [self getThumbContainerView];
    CGRect segThumbRect = CGRectMake(0, THUMB_CHART_TITLE_HEIGHT,
        container.frame.size.width,
        container.frame.size.height  - THUMB_CHART_TITLE_HEIGHT);
    
    self.headerBackgroundCoverView.alpha = 0;
    fullTitleLabel.alpha = 0;
    thumbnailTitleLabel.alpha = 1.f;
    thumbnailTitleLabel.frame = setRectX(thumbnailTitleLabel.frame, 10);
    thumbnailTitleLabel.frame = setRectY(thumbnailTitleLabel.frame, 2);
    titleDividerView.frame = CGRectMake(10, 35,
        GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 1);
    self.segView.frame = segThumbRect;
    //infoUIView.nutritionView.alpha = 0;
    if (self.chartDataType == CHART_DATA_TYPE_NUTRITION) {
        infoUIView.nutritionChart.transform = CGAffineTransformMakeScale(0.5, 0.5);
        infoUIView.nutritionChart.left = segThumbRect.size.width/2;
        infoUIView.nutritionChart.top = [self thumbChartViewTop];
    }
}

- (CGFloat)thumbChartViewTop
{
    if (IS_IPHONE_6) {
        return 24;
    } else if (IS_IPHONE_6_PLUS) {
        return 33;
    } else {
        return 10;
    }
}

- (void)fullToThumbCompletion {
    fullTitleLabel.text = self.dataTypeTitle;
    self.segView.state = ChartSegmentStateThumb;
    dateIdxToFetch = todayIdx;
    
    [self.segView setRangeXFromParent:[self rangeXLandscape:NO]];
    [self.segView setTempOffset:0];
    
    if (leadingToMePage) {
        self.parentViewController.view.userInteractionEnabled = NO;
    }
    
    [UIView transitionWithView:self.segView duration:0.3f options:
        UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [self.segView setNeedsDisplay];
    } completion:^(BOOL finished){
        if (leadingToMePage) {
            leadingToMePage = NO;
            [self publish:EVENT_GO_CONNECTING_3RD_PARTY];
        }
    }];
}

- (void)thumbToFullBegin {
    // logging
    if (self.chartDataType == CHART_DATA_TYPE_TEMP) {
        [Logging log:PAGE_IMP_GNS_CHILD_CYCLE_CHART];
    } else if (self.chartDataType == CHART_DATA_TYPE_WEIGHT) {
        [Logging log:PAGE_IMP_GNS_CHILD_WEIGHT_CHART];
    } else if (self.chartDataType == CHART_DATA_TYPE_CALORIE) {
        [Logging log:PAGE_IMP_GNS_CHILD_CALORIES_CHART];
    } else {
        [Logging log:PAGE_IMP_GNS_CHILD_NUTRITION_CHART];
    }
    
    [self _repositionOverlay];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) setRotationEnabled:YES];
    self.segView.state = ChartSegmentStateTransition;
    [self.segView setNeedsDisplay];
}

- (void)thumbToFull
{
    [infoUIView showViewsExceptForChartView];

    CGFloat titleX = originTitleLabelFrame.origin.x + originTitleLabelFrame.size.width * 0.5f;
    CGFloat titleY = originTitleLabelFrame.origin.y + originTitleLabelFrame.size.height;
    
    self.segView.frame = [self segRectInLandscape:NO];
    thumbnailTitleLabel.center = CGPointMake(titleX, titleY);
    titleDividerView.frame = CGRectMake(10, 35, 0, 0);
    thumbnailTitleLabel.alpha = 0;
    fullTitleLabel.alpha = 1.f;
    infoUIView.infoPanel.frame = [self infoRectInLandscape:NO];
    self.headerBackgroundCoverView.alpha = 1;
    infoUIView.nutritionView.alpha = 1;
    if (self.chartDataType == CHART_DATA_TYPE_NUTRITION) {
        [self showPieChart];
        return;
    }
}

- (void)thumbToFullCompletion
{
    self.segView.state = ChartSegmentStateNormal;
    [UIView animateWithDuration:0.2f animations:^{
        [self showComponentsForFull];
    }];
    
    [infoUIView setupPointerWithRadius:DOT_RADIUS];
    [infoUIView setupInfoPanelInDataType:self.segView.chartDataType landscape:NO];
    [self positionCurrentArrowAndPointerEdge];
    [self repositionInteractiveScrollViewWithScale:1];
    [self updatePointer];
    [self drawScaleLabels];
    self.interactiveScrollView.userInteractionEnabled = YES;
    [self.segView setNeedsDisplay];
    
    originParentFrame = self.view.superview.frame;
    //infoUIView.hidden = NO;
    infoUIView.currentDayDot.hidden = infoUIView.extraDayDot.hidden =
        dayPointerBottomEdgeView.hidden = NO;

    [Utils setDefaultsForKey:JUST_CAME_TO_FULL_VIEW withValue:@(YES)];
    
    infoUIView.nutritionView.alpha = 1.f;

}

- (void)showPieChart
{
    [self leaveBreadcrumbForDataType];
    
    infoUIView.currentArrow.alpha = 0;
    infoUIView.currentDayDot.hidden = infoUIView.extraDayDot.hidden =
    dayPointerBottomEdgeView.hidden =
    self.segView.chartDataType == CHART_DATA_TYPE_NUTRITION;
    
    [self.segView setNeedsDisplay];
    [self drawScaleLabels];
    
//    infoUIView.nutritionView.frame = CGRectMake(0, [self headerHeightInLands: self.isLandscape], SCREEN_WIDTH, SCREEN_HEIGHT - [self headerHeightInLands: self.isLandscape]);
    infoUIView.nutritionChart.transform = CGAffineTransformIdentity;
    infoUIView.nutritionView.frame = CGRectMake(0, [self headerHeightInLands: self.isLandscape], SCREEN_WIDTH, SCREEN_HEIGHT - [self headerHeightInLands: self.isLandscape]);
    [infoUIView setupNutritionViewInDataType:self.segView.chartDataType];
    [infoUIView setupInfoPanelInDataType:self.segView.chartDataType landscape:self.isLandscape];
    [self updatePointer];
    [self.segView setNeedsDisplay];
    [self.segView.layer displayIfNeeded];
    
    fullTitleLabel.text = self.dataTypeTitle;
    
    [self _repositionOverlay];
}



#pragma mark - transition helper
- (void)hideComponentsForThumb
{
    [infoUIView hideViewsExceptForChartView];
    infoUIView.currentDayDot.alpha = infoUIView.extraDayDot.alpha =
        dayPointerBottomEdgeView.alpha = 0;
    closeButton.alpha = 0;
    for (UILabel *scale in leftScaleLabels) {
        scale.alpha = 0;
    }
}

- (void)showComponentsForFull
{
    [infoUIView showViewsExceptForChartView];
    infoUIView.alpha = 1;
    infoUIView.currentDayDot.alpha = infoUIView.extraDayDot.alpha =
        dayPointerBottomEdgeView.alpha = 1;
    closeButton.alpha = 1;
    infoUIView.currentArrow.hidden = infoUIView.infoPanel.hidden = NO;
    infoUIView.currentArrow.alpha = infoUIView.infoPanel.alpha = 1;
    if (self.chartDataType == CHART_DATA_TYPE_NUTRITION) {
        infoUIView.infoPanel.hidden = YES;
        infoUIView.currentArrow.hidden = YES;
    }
}

#pragma PieChart DataSource and Delegate
- (NSDictionary *)_calPercentageFrom:(NSDictionary *)d {
    if (!d || !d[NUTRITION_CARBOHYDRATE] || !d[NUTRITION_FAT] ||
        !d[NUTRITION_PROTEIN]) {
        return @{
            NUTRITION_CARBOHYDRATE: @(0),
            NUTRITION_PROTEIN: @(0),
            NUTRITION_FAT: @(0),
        };
    }
    float _carb = [(NSNumber *)d[NUTRITION_CARBOHYDRATE] floatValue] * 4.f;
    float _fat = [(NSNumber *)d[NUTRITION_FAT] floatValue] * 9.f;
    float _prot = [(NSNumber *)d[NUTRITION_PROTEIN] floatValue] * 4.f;
    float _sum = _carb + _fat + _prot;
    float _carbPercent = 100.f * _carb / _sum;
    float _fatPercent = 100.f * _fat / _sum;
    float _protPercent = 100.f * _prot / _sum;
    
    if (fabsf(roundf(_carbPercent) - _carbPercent) < 1e-6) {
        return @{
            NUTRITION_CARBOHYDRATE: @(roundf(_carbPercent)),
            NUTRITION_PROTEIN: @(roundf(_protPercent)),
            NUTRITION_FAT:
                @(100 - roundf(_protPercent) - roundf(_carbPercent)),
        };
        
    } else {
        return @{
            NUTRITION_FAT: @(roundf(_fatPercent)),
            NUTRITION_PROTEIN: @(roundf(_protPercent)),
            NUTRITION_CARBOHYDRATE:
                @(100 - roundf(_protPercent) - roundf(_fatPercent)),
        };
    }
   
}

//@required
- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart {
    return 3;
}
- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index {
    NSInteger idx = dateIdxToFetch;
    GLLog(@"value for dateIdx: %d", idx);
    if (!idx) {
        idx = [Utils dateToIntFrom20130101:[NSDate date]];
        GLLog(@"default value for dateIdx: %d", idx);
    }
    
    NSDictionary *d;
    if (![self isConnectedWith3rdPartyHealthApp]){
        infoUIView.nutritionChart.alpha = 0.2;
        infoUIView.nutritionChart.showLabel = NO;
        d = [self.chartData getMockedRawNutritionPoint];
        if (self.chartDataType == CHART_DATA_TYPE_NUTRITION) {
            self.segView.isMockData = YES;            
        }
    } else {
        infoUIView.nutritionChart.alpha = 1;
        infoUIView.nutritionChart.showLabel = YES;
        d = [self.chartData getRawNutritionPointsForUser:[User currentUser]][@(idx)];
    }
    NSDictionary *calPercentages = [self _calPercentageFrom:d];
    switch (index) {
        case 0:
            return [calPercentages[NUTRITION_CARBOHYDRATE] floatValue];
        case 1:
            return [calPercentages[NUTRITION_FAT] floatValue];
        case 2:
            return [calPercentages[NUTRITION_PROTEIN] floatValue];
        default:
            break;
    }
    return 0;
}
//@optional
- (UIColor *)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index {
    if (index > 2) {
        return nil;
    } else
        return @[UIColorFromRGB(0x5B65CE), UIColorFromRGB(0xF7604A), UIColorFromRGB(0x6EB939)][index];
    
}
- (NSString *)pieChart:(XYPieChart *)pieChart textForSliceAtIndex:(NSUInteger)index {
    if (index > 2) {
        return @"";
    } else {
        return [NSString stringWithFormat:@"%lu", (unsigned long)index];
    }

}

//XYPieChartDelegate
- (void)pieChart:(XYPieChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index {
//    GLLog(@"will Select slice at %d", index);
}
- (void)pieChart:(XYPieChart *)pieChart didSelectSliceAtIndex:(NSUInteger)index {
//    GLLog(@"did Select slice at %d", index);
    [infoUIView highLight:index];
}
- (void)pieChart:(XYPieChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index {
//     GLLog(@"will deselect slice at %d", index);
    [infoUIView stopHighLight];
}
- (void)pieChart:(XYPieChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index {
//     GLLog(@"did deselect slice at %d", index);
}

- (IBAction)prevPieChartDate:(id)sender {
    [self updateDateForPieChart:--dateIdxToFetch];
}

- (IBAction)nextPieChartDate:(id)sender {
    [self updateDateForPieChart:++dateIdxToFetch];
}

- (IBAction)pieChartSwiped:(id)sender {
    GLLog(@"swiped: %@", sender);
    UISwipeGestureRecognizer *g = (UISwipeGestureRecognizer *)sender;
    if (g.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self updateDateForPieChart:++dateIdxToFetch];
    } else if (g.direction == UISwipeGestureRecognizerDirectionRight) {
        [self updateDateForPieChart:--dateIdxToFetch];
    }
}

- (void)updateDateForPieChart:(NSInteger)newIdx {
    NSString *dateLabel = [Utils dateIndexToDateLabelFrom20130101:newIdx];
    User *u = [User currentUser];
    
    if ([[Utils dateIndexToDate:newIdx] timeIntervalSinceNow] + NUTRITION_DATA_AUTO_SYNC_INTERVAL > 0) {
        if(![Nutrition isDataSyncedForDay:dateLabel] )
        {
            [u syncNutritionsAndCaloriesForDate:dateLabel];
            [self reloadPieChartIn:5];
        } else {
            Nutrition *n = [Nutrition nutritionForDate:dateLabel forUser:u];
            if(!n || ![n hasCalories] || [n hasNutritions]) {
                [u syncNutritionsAndCaloriesForDate:dateLabel];
                [self reloadPieChartIn:5];
            }
        }
    }
    [self updateInfoUIView];
    [infoUIView stopHighLight];
}

- (IBAction)syncRequest:(id)sender {
    NSString *dateLabel = [Utils dateIndexToDateLabelFrom20130101:dateIdxToFetch];
//    NSDictionary *d = [Utils getDefaultsForKey:NUTRITION_DATA_MANUALLY_SYNCED];
//    if (!d) {
//        d = @{};
//    }
//    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:d];
//    md[dateLabel] = @(YES);
//    [Utils setDefaultsForKey:NUTRITION_DATA_MANUALLY_SYNCED withValue:[NSDictionary dictionaryWithDictionary:md]];
    
    User *user = [User currentUser];
    [user syncNutritionsAndCaloriesForDate:dateLabel];
    if ([user isConnectedWithMisfit]) {
        [user syncMisfitActivitiesForDate:dateLabel forced:YES];
    }
    [[StatusBarOverlay sharedInstance] postMessage:@"Sync requested." duration:3];
    UILabel *label = (UILabel *)[(UITapGestureRecognizer *)sender view];
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithAttributedString:label.attributedText];
    [mas.mutableString replaceOccurrencesOfString:@"Sync via" withString:@"Syncing via" options:0 range:NSMakeRange(0, 8)];
    label.attributedText = mas;
    [self reloadPieChartDataIn:4];
}

- (void)reloadPieChartDataIn:(float)seconds
{
    int64_t delayInSeconds = seconds;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        cachedNutrition = nil;
        [self.chartData rebuildNutritionAndCalorieForUser:self.user];
        [self updateInfoUIView];
    });
}

- (void)reloadPieChartIn:(float)seconds {
    int64_t delayInSeconds = seconds;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self updateInfoUIView];
    });
}

- (IBAction)selectedProteinLine:(id)sender {
    [infoUIView.nutritionChart setSliceDeselectedAtIndex:0];
    [infoUIView.nutritionChart setSliceDeselectedAtIndex:1];
    [infoUIView.nutritionChart setSliceSelectedAtIndex:2];
    [infoUIView highLight:2];
}

- (IBAction)selectedFatLine:(id)sender {
    [infoUIView.nutritionChart setSliceDeselectedAtIndex:0];
    [infoUIView.nutritionChart setSliceSelectedAtIndex:1];
    [infoUIView.nutritionChart setSliceDeselectedAtIndex:2];
    [infoUIView highLight:1];
}

- (IBAction)selectedCarbsLine:(id)sender {
    [infoUIView.nutritionChart setSliceSelectedAtIndex:0];
    [infoUIView.nutritionChart setSliceDeselectedAtIndex:1];
    [infoUIView.nutritionChart setSliceDeselectedAtIndex:2];
    [infoUIView highLight:0];
}


#pragma mark - connect 3rd party overlay
- (void) _stylishConnectWith3rdPartyOverlay
{
    goToMePageButton.layer.borderColor = [UIColor grayColor].CGColor;
    goToMePageButton.layer.borderWidth = 1.f;
    goToMePageButton.layer.cornerRadius = goToMePageButton.frame.size.height / 2;
    goToMePageButton.clipsToBounds = YES;
    connect3rdPartyOverlay.hidden = YES;
    
    // TODO_remove, We may removed below code in v4.6.1
    if (self.chartDataType == CHART_DATA_TYPE_NUTRITION || self.chartDataType == CHART_DATA_TYPE_CALORIE || [User currentUser].isSecondary) {
        return;
    }

    if (self.segView.isMockData) {
        CGPoint center = goToMePageButton.center;
        goToMePageButton.width = 260;
        goToMePageButton.center = center;
        [goToMePageButton setTitle:@"Take me to my health logs" forState:UIControlStateNormal];
    }
}

static BOOL leadingToMePage = NO;
- (IBAction)goToMePageButtonClicked:(id)sender {
    if (self.chartDataType == CHART_DATA_TYPE_NUTRITION || self.chartDataType == CHART_DATA_TYPE_CALORIE) {
        [Logging log:BTN_CLK_GOTOME_FROM_CHART];
        leadingToMePage = YES;
        [self closeButtonClicked:nil];
    } else {
        DailyLogViewController* vc = (DailyLogViewController *)[UIStoryboard dailyLog];
        vc.selectedDate = [NSDate date];
        vc.needsToScrollToWeightCell = YES;        
        UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }

}

- (void)_repositionOverlay {
    hintToConnectLabel.hidden = NO;
    connect3rdPartyOverlay.hidden = NO;
    
    if (self.chartDataType == CHART_DATA_TYPE_CALORIE && !self.isConnectedWith3rdPartyHealthApp) {
        hintToConnectLabel.markdownText = @"In order to see your calories chart,\n you must connect with your \n**MyFitnessPal**, **Fitbit**, **Jawbone UP**, \nor **Misfit** account in your Me page!";
        return;
    }
    if (self.chartDataType == CHART_DATA_TYPE_NUTRITION && !self.isConnectedWith3rdPartyHealthApp) {
        hintToConnectLabel.markdownText = @"In order to see your calories chart,\nyou must connect with your \n**MyFitnessPal**, **Fitbit**, **Jawbone UP**, \nor **Misfit** account in your Me page!";
        return;
    }
    if (self.chartDataType == CHART_DATA_TYPE_WEIGHT && self.segView.isMockData) {
        hintToConnectLabel.markdownText = @"\nIn order to see your weight trends, \nbegin entering weight data in your daily log!";
        [goToMePageButton setTitle:@"Enter my weight now" forState:UIControlStateNormal];
        CGPoint center = goToMePageButton.center;
        goToMePageButton.width = 250;
        goToMePageButton.center = center;
        return;
    }
    connect3rdPartyOverlay.hidden = YES;

}

@end
