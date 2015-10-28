//
//  GLNutritionViewController.m
//  kaylee
//
//  Created by Allen Hsu on 12/10/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <XYPieChart/XYPieChart.h>
#import <GLFoundation/GLPillGradientButton.h>
#import "NutritionViewController.h"
#import "User.h"
#import "Nutrition.h"
#import "StatusBarOverlay.h"

@interface NutritionViewController () <XYPieChartDelegate, XYPieChartDataSource>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *titleDividerView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet XYPieChart *chartView;
@property (assign, nonatomic) NSInteger currentDateIndex;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *prevButton;
@property (weak, nonatomic) IBOutlet UILabel *labelCarb;
@property (weak, nonatomic) IBOutlet UILabel *labelCarbGoal;
@property (weak, nonatomic) IBOutlet UILabel *labelFat;
@property (weak, nonatomic) IBOutlet UILabel *labelFatGoal;
@property (weak, nonatomic) IBOutlet UILabel *labelProtein;
@property (weak, nonatomic) IBOutlet UILabel *labelProteinGoal;
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UIView *dateContainer;
@property (weak, nonatomic) IBOutlet UIButton *syncButton;
@property (weak, nonatomic) IBOutlet UIView *dotCarb;
@property (weak, nonatomic) IBOutlet UIView *dotFat;
@property (weak, nonatomic) IBOutlet UIView *dotProtein;
@property (strong, nonatomic) Nutrition *nutrition;
@property (assign, nonatomic) BOOL demoMode;
@property (weak, nonatomic) IBOutlet GLPillGradientButton *gotoButton;
@property (weak, nonatomic) IBOutlet UIView *emptyOverlay;

@end

@implementation NutritionViewController

+ (id)getInstance
{
    return [[UIStoryboard storyboardWithName:@"chart" bundle:nil] instantiateViewControllerWithIdentifier:@"NutritionChart"];
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
}

- (void)backToToday
{
    NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    [self updateDateForPieChart:todayIndex];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.demoMode = YES;
    
    self.nextButton.transform = CGAffineTransformMakeScale(-1, 1);
    self.chartView.delegate = self;
    self.chartView.dataSource = self;
    
    self.emptyOverlay.hidden = YES;
    
    self.dotCarb.layer.cornerRadius = self.dotCarb.width / 2.0;
    self.dotFat.layer.cornerRadius = self.dotFat.width / 2.0;
    self.dotProtein.layer.cornerRadius = self.dotProtein.width / 2.0;
    
    [self.gotoButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    
    [self setPieChartParameters];
    NSInteger todayIndex = [Utils dateToIntFrom20130101:[NSDate date]];
    [self updateDateForPieChart:todayIndex];
    
    
//    @weakify(self)
//    [self subscribe:EVENT_CHART_NEEDS_UPDATE handler:^(Event *event) {
//        @strongify(self)
//        self.syncButton.enabled = YES;
//        [self reloadPieChart];
//    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([User currentUser].isConnectedWith3rdPartyHealthApps) {
        self.chartView.alpha = 1.0;
        self.chartView.showLabel = YES;
    } else {
        self.chartView.alpha = 0.2;
        self.chartView.showLabel = NO;
    }
    [self reloadPieChart];
}

- (void)setPieChartParameters {
    CGFloat radius = MIN(self.view.width - 40.0, self.infoView.top - self.headerView.bottom - 40.0) / 2.0;
    [self.chartView setStartPieAngle:M_PI * 2];
    //    [self.chartView setAnimationSpeed:1.0];
    [self.chartView setLabelFont:[Utils defaultFont:20]];
    [self.chartView setLabelRadius:radius / 2.0];
    [self.chartView setPieRadius:radius];
    [self.chartView setPieCenter:CGPointMake(self.chartView.width / 2.0, self.chartView.height / 2.0)];
    [self.chartView setShowPercentage:YES];
    [self.chartView setPieBackgroundColor:UIColorFromRGB(0xB4B4B4)];
    [self.chartView setUserInteractionEnabled:YES];
    [self.chartView setLabelShadowColor:[UIColor grayColor]];
}

- (IBAction)prevPieChartDate:(id)sender {
    [self updateDateForPieChart:self.currentDateIndex - 1];
}

- (IBAction)nextPieChartDate:(id)sender {
    [self updateDateForPieChart:self.currentDateIndex + 1];
}

- (void)updateDateForPieChart:(NSInteger)dateIndex {
    User *user = [User currentUser];
    NSString *dateLabel = [Utils dateIndexToDateLabelFrom20130101:dateIndex];
    if ([user isConnectedWith3rdPartyHealthApps]) {
        self.demoMode = NO;
        self.nutrition = [Nutrition nutritionForDate:dateLabel forUser:user];
        if (self.currentDateIndex != dateIndex) {
            self.currentDateIndex = dateIndex;
            
            NSString *dateLabel = [Utils dateIndexToDateLabelFrom20130101:dateIndex];
            if ([[Utils dateIndexToDate:dateIndex] timeIntervalSinceNow] + NUTRITION_DATA_AUTO_SYNC_INTERVAL > 0) {
                if(![Nutrition isDataSyncedForDay:dateLabel] )
                {
                    [user syncNutritionsAndCaloriesForDate:dateLabel];
                    [self reloadPieChartIn:5];
                } else {
                    Nutrition *n = [Nutrition nutritionForDate:dateLabel forUser:user];
                    if(!n || ![n hasCalories] || [n hasNutritions]) {
                        [user syncNutritionsAndCaloriesForDate:dateLabel];
                        [self reloadPieChartIn:5];
                    }
                }
            }
            [self updateInfo];
        }
    } else {
        self.demoMode = YES;
        self.nutrition = [Nutrition sampleNutrition];
        [self.chartView reloadData];
    }
}

- (void)reloadPieChartIn:(float)seconds {
    int64_t delayInSeconds = seconds;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self reloadPieChart];
    });
}

- (void)reloadPieChart
{
    [self updateDateForPieChart:self.currentDateIndex];
}

- (void)updateInfo
{
    if (self.demoMode) {
        self.labelCarbGoal.text = [NSString stringWithFormat:@"--"];
        self.labelFatGoal.text = [NSString stringWithFormat:@"--"];
        self.labelProteinGoal.text = [NSString stringWithFormat:@"--"];
        self.labelCarb.text = @"--";
        self.labelFat.text = @"--";
        self.labelProtein.text = @"--";
    } else {
        User *user = [User currentUser];
        self.labelCarbGoal.text = [NSString stringWithFormat:@"%ld%%", (long)[user nutritionGoalCarb]];
        self.labelFatGoal.text = [NSString stringWithFormat:@"%ld%%", (long)[user nutritionGoalFat]];
        self.labelProteinGoal.text = [NSString stringWithFormat:@"%ld%%", (long)[user nutritionGoalProtein]];
        
        NSInteger idx = self.currentDateIndex;
        
        NSDate *d = [Utils dateIndexToDate:idx];
        self.dateLabel.text = [NSString stringWithFormat:@"%@ / %@",
                               [d weekdayString], [d toReadableFullDate]];
        float all = self.nutrition.carbohydrates + self.nutrition.fat + self.nutrition.protein;
        if (all > 0) {
            self.labelCarb.text = [Utils stringWithFloatOfOneOrZeroDecimal:@"%f%%" float:self.nutrition.carbohydrates * 100.0 / all];
            self.labelFat.text = [Utils stringWithFloatOfOneOrZeroDecimal:@"%f%%" float:self.nutrition.fat * 100.0 / all];
            self.labelProtein.text = [Utils stringWithFloatOfOneOrZeroDecimal:@"%f%%" float:self.nutrition.protein * 100.0 / all];
        } else {
            self.labelCarb.text = @"--";
            self.labelFat.text = @"--";
            self.labelProtein.text = @"--";
        }
        
        NSString *source =@"";
        if ([user isMFPConnected]) {
            source = [Nutrition srcName:NUTRITION_SRC_MFP];
        } else if (user.jawboneId) {
            source = [Nutrition srcName:NUTRITION_SRC_JAWBONE];
        } else if (user.fitbitId) {
            source = [Nutrition srcName:NUTRITION_SRC_FITBIT];
        } else if ([user isConnectedWithMisfit]) {
            source = [Nutrition srcName:NUTRITION_SRC_MISFIT];
        }
        NSString *title = @"Sync";
        if (self.nutrition && source.length > 0) {
            title = [NSString stringWithFormat:@"Synced via %@", source];
            self.syncButton.enabled = NO;
        } else {
            self.syncButton.enabled = YES;
        }
        
        [self setNutritionButtonSyncButtonTitle:title];
    }
    
    [self.chartView reloadData];
}

- (IBAction)pieChartSwiped:(UISwipeGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
            [self nextPieChartDate:nil];
        } else if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
            [self prevPieChartDate:nil];
        }
    }
}

- (IBAction)selectedProteinLine:(id)sender {
    [self.chartView setSliceDeselectedAtIndex:0];
    [self.chartView setSliceDeselectedAtIndex:1];
    [self.chartView setSliceSelectedAtIndex:2];
}

- (IBAction)selectedFatLine:(id)sender {
    [self.chartView setSliceDeselectedAtIndex:0];
    [self.chartView setSliceSelectedAtIndex:1];
    [self.chartView setSliceDeselectedAtIndex:2];
}

- (IBAction)selectedCarbsLine:(id)sender {
    [self.chartView setSliceSelectedAtIndex:0];
    [self.chartView setSliceDeselectedAtIndex:1];
    [self.chartView setSliceDeselectedAtIndex:2];
}

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart
{
    return 3;
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index
{
    //    int idx = self.currentDateIndex;
    
    if (!self.nutrition) {
        return 0;
    }
    switch (index) {
        case 0:
            return self.nutrition.carbohydrates;
            break;
        case 1:
            return self.nutrition.fat;
            break;
        case 2:
            return self.nutrition.protein;
            break;
        default:
            break;
    }
    return 0;
}

- (UIColor *)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index
{
    if (index > 2) {
        return nil;
    } else {
        return @[UIColorFromRGB(0x5B65CE), UIColorFromRGB(0xF7604A), UIColorFromRGB(0x6EB939)][index];
    }
}

- (NSString *)pieChart:(XYPieChart *)pieChart textForSliceAtIndex:(NSUInteger)index
{
    if (index > 2) {
        return @"";
    } else {
        return [NSString stringWithFormat:@"%lu", (unsigned long)index];
    }
}

- (IBAction)didClickCloseButton:(id)sender {
    if (self.isPresented) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    else {
        [self transitionToThumbView];
    }
    [self publish:EVENT_GENIUS_THUMB_VIEW_CLOSED];
}

- (IBAction)sync:(id)sender {
    self.syncButton.enabled = NO;
    
    NSString *dateLabel = [Utils dateIndexToDateLabelFrom20130101:self.currentDateIndex];
    NSDictionary *d = [Utils getDefaultsForKey:NUTRITION_DATA_MANUALLY_SYNCED];
    if (!d) {
        d = @{};
    }
    if (!d[dateLabel]) {
        NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:d];
        md[dateLabel] = @(YES);
        [Utils setDefaultsForKey:NUTRITION_DATA_MANUALLY_SYNCED withValue:[NSDictionary dictionaryWithDictionary:md]];
        
        User *user = [User currentUser];
        [user syncNutritionsAndCaloriesForDate:dateLabel];
        if ([user isConnectedWithMisfit]) {
            [user syncMisfitActivitiesForDate:dateLabel forced:YES];
        }
        [[StatusBarOverlay sharedInstance] postMessage:@"Sync requested." duration:3];

        NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithAttributedString:self.syncButton.titleLabel.attributedText];
        [mas.mutableString replaceOccurrencesOfString:@"Sync" withString:@"Syncing via" options:0 range:NSMakeRange(0, 3)];
        [mas setAttributes:@{NSForegroundColorAttributeName: UIColorFromRGB(0x889298)}
                     range:NSMakeRange(0, [mas.mutableString length])];
        self.syncButton.titleLabel.attributedText = mas;
        
        [self reloadPieChartIn:4];
    }

}

- (void)setNutritionButtonSyncButtonTitle:(NSString *)title
{
    NSDictionary *attr = @{NSFontAttributeName:self.syncButton.titleLabel.font,
                           NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                           NSForegroundColorAttributeName: [self.syncButton titleColorForState:UIControlStateNormal],
                           };
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:title attributes:attr];
    [self.syncButton setAttributedTitle:attrStr forState:UIControlStateNormal];
}

- (IBAction)gotoMePage:(id)sender {
    [self closeWithCallback:^{
        [self publish:EVENT_GO_CONNECTING_3RD_PARTY];
    }];
}

- (void)thumbToFullBegin
{
    [Logging log:PAGE_IMP_GNS_CHILD_NUTRITION_CHART];
}


- (void)showThumbView {
    [self fullToThumb];
}

- (void)fullToThumb {
    self.headerView.height = 36.0;
    self.titleLabel.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.titleLabel.layer.shouldRasterize = YES;
    self.titleLabel.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.titleLabel.origin = CGPointMake(10.0, 11.0);
    self.titleDividerView.frame = CGRectMake(10, 35, self.view.width - 20.0, 1);
    self.closeButton.alpha = 0;
    
    self.dateContainer.alpha = 0.0;
    self.infoView.alpha = 0.0;
    
    self.chartView.layer.shouldRasterize = YES;
    self.chartView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    CGFloat scale = (self.view.height - self.headerView.bottom - 20.0) / 2.0 / self.chartView.pieRadius;
    self.chartView.transform = CGAffineTransformMakeScale(scale, scale);
    self.chartView.centerY = (self.headerView.bottom + self.view.height) / 2.0;
    
    if (![User currentUser].isConnectedWith3rdPartyHealthApps) {
        self.chartView.alpha = 0.2;
    } else {
        self.chartView.alpha = 1;
    }
    self.chartView.showLabel = !self.demoMode;
    
    [self backToToday];
    [self showEmptyOverlayIfNeeded];

}

- (void)thumbToFull
{
    self.headerView.height = 90.0;
    self.titleLabel.transform = CGAffineTransformIdentity;
    self.titleLabel.origin = CGPointMake(20.0, 36.0);
    self.titleDividerView.frame = CGRectMake(20.0, 80, self.view.width - 40.0, 1);
    self.closeButton.alpha = 1;
    self.dateContainer.alpha = 1.0;
    self.infoView.alpha = 1.0;
    
    self.chartView.transform = CGAffineTransformIdentity;
    self.chartView.centerY = (self.dateContainer.bottom + self.infoView.top) / 2.0;
    self.chartView.alpha = 1.0;
    self.chartView.showLabel = !self.demoMode;
    
    [self backToToday];
    [self showEmptyOverlayIfNeeded];

}

@end
