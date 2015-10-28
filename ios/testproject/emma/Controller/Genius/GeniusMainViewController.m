//
//  GeniusMainViewController.m
//  emma
//
//  Created by Ryan Ye on 7/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "AnimationSequence.h"
#import "BadgeView.h"
#import "ChartData.h"
#import "ChartViewController.h"
#import "DropdownMessageController.h"
#import "ExportReportDialog.h"
#import "GeniusChildViewController.h"
#import "GeniusInsightsViewController.h"
#import "GeniusMainViewController.h"
#import "GeniusTutorialViewController.h"
#import "HealthChartViewController.h"
#import "Logging.h"
#import "MyCyclesViewController.h"
#import "PushbackTransitioningDelegate.h"
#import "TabbarController.h"
#import "UIStoryboard+Emma.h"
#import "Utils.h"
#import "ChartConstants.h"
#import <GLFoundation/GLUtils.h>

#define GGSNAPSHOT_ALPHA 0.0
#define GGSNAPSHOT_SCALE 0.85
#define GGSNAPSHOT_CENTER_OFFSET 25
// #define GENIUSMAIN_OFFSET_Y (IOS7_OR_ABOVE ? 64 : 44)

@interface GeniusMainViewController () {
    IBOutlet UIView *blockAnimationView;
    IBOutletCollection(UIView) NSArray *childViews;
    BOOL isFertiltiyAsMajor;
    GeniusTutorialViewController *tutorialViewController;
}


@property (nonatomic) NSDictionary * childConfig;
@property (nonatomic) NSArray * childOrder;
@property (nonatomic) NSMutableDictionary * childContollers;
@property (nonatomic) BOOL firstLaunch;
@end

@implementation GeniusMainViewController

- (id)init {
    if (self = [super init]) {
        GLLog(@"GeniusMainViewController init");
        //if (IOS7_OR_ABOVE) {
        //    transDelegate = [[PushbackTransitioningDelegate alloc] init];
        //    self.transitioningDelegate = transDelegate;
        //}
    }
    return self;
}

- (void)awakeFromNib {
    
}

- (CGRect)getChildRect:(NSInteger)row column:(NSInteger)column isFull:(BOOL)isFull {
    CGFloat x = (column == 0 ? GENIUSMAIN_BLOCK_LEFT_X : GENIUSMAIN_BLOCK_RIGHT_X);
    CGFloat y = row * GENIUSMAIN_BLOCK_HEIGHT + GENIUSMAIN_BLOCK_PADDING;
    CGFloat width = (isFull ? GENIUSMAIN_BLOCK_WIDTH * 2 : GENIUSMAIN_BLOCK_WIDTH);
    CGFloat height = GENIUSMAIN_BLOCK_HEIGHT;
    if (isFull) {
        height += ((IS_IPHONE_4) || (IS_IPHONE_6))  ? 0 : 30;
    }
    return CGRectMake(x + GENIUSMAIN_BLOCK_PADDING,
                      y + GENIUSMAIN_BLOCK_PADDING,
                      width - GENIUSMAIN_BLOCK_PADDING*2,
                      height - GENIUSMAIN_BLOCK_PADDING*2);
}

- (void)initChilds {
    
    self.childConfig =
    @{
      @(TAG_GENIUS_CHILD_INSIGHT): @{
              @"class": [GeniusInsightsViewController.class description],
              },
      @(TAG_GENIUS_CHILD_MY_CYCLES): @{
              @"class": [MyCyclesViewController.class description],
              },
      @(TAG_GENIUS_CHILD_BBT_CHART): @{
              @"class": [ChartViewController.class description],
              },
      @(TAG_GENIUS_CHILD_WEIGHT_CHART): @{
              @"class": [ChartViewController.class description],
              },
      @(TAG_GENIUS_CHILD_CALORIES_CHART): @{
              @"class": [ChartViewController.class description],
              },
      @(TAG_GENIUS_CHILD_NUTRITION_CHART): @{
              @"class": [ChartViewController.class description],
              }
      };
    
    self.childOrder =
    @[
      @(TAG_GENIUS_CHILD_INSIGHT),
      @(TAG_GENIUS_CHILD_MY_CYCLES),
      @(TAG_GENIUS_CHILD_BBT_CHART),
      @(TAG_GENIUS_CHILD_WEIGHT_CHART),
      @(TAG_GENIUS_CHILD_CALORIES_CHART),
      @(TAG_GENIUS_CHILD_NUTRITION_CHART)
      ];
    
    
    if (!self.childContollers) {
        self.childContollers = [[NSMutableDictionary alloc] init];
    }
}

- (void)initChildContainerView {
    int row = 0;
    int col = 0;
    for (NSNumber *tag in self.childOrder) {
        UIView* v = [self getChildContainerView:[tag integerValue]];
        v.frame = [self getChildRect:row column:col isFull:NO];
        v.userInteractionEnabled = YES;
        v.layer.cornerRadius = GENIUSMAIN_BLOCK_CORNER_RADIUS;
        [v setClipsToBounds:YES];
        v.layer.borderColor = UIColorFromRGB(0xdae3e8).CGColor;
        v.layer.borderWidth = 1.f;
        col = col + 1;
        if(col == 2){
            row = row + 1;
            col = 0;
        }
    }
}

- (UIView *)getChildContainerView:(NSInteger)childTag {
    for (UIView * v in childViews) {
        if (v.tag == childTag) return v;
    }
    return nil;
}

- (GeniusChildViewController *)getGeniucChildController:(NSInteger)childTag {
    return (GeniusChildViewController *)[self.childContollers objectForKey:@(childTag)];
}

- (UIView *)getBlockAnimationView {
    return blockAnimationView;
}

- (void)initChildControllers {
    for (NSNumber * childNumer in self.childOrder) {
        NSInteger tag = [childNumer integerValue];
        NSDictionary * conf = [self.childConfig objectForKey:childNumer];
        Class class = NSClassFromString([conf objectForKey:@"class"]);
        GeniusChildViewController * child = (GeniusChildViewController * )[class getInstance];
        child.view.tag = tag;
        child.view.alpha = 1;
        // find container view
        UIView * container = [self getChildContainerView:tag];
        child.view.frame = CGRectMake(0, 0, container.frame.size.width, container.frame.size.height);
        [self addChildViewController:child];
        child.view.clipsToBounds = YES;
        [container addSubview:child.view];
        
        if (TAG_GENIUS_CHILD_BBT_CHART == tag) {
            ((ChartViewController *) child).isFertility = YES;
            ((ChartViewController *) child).chartDataType = CHART_DATA_TYPE_TEMP;
        }
        else if (TAG_GENIUS_CHILD_WEIGHT_CHART == tag) {
            ((ChartViewController *) child).isFertility = NO;
            ((ChartViewController *) child).chartDataType = CHART_DATA_TYPE_WEIGHT;
        }
        else if (TAG_GENIUS_CHILD_CALORIES_CHART == tag) {
            ((ChartViewController *) child).isFertility = NO;
            ((ChartViewController *) child).chartDataType = CHART_DATA_TYPE_CALORIE;
        }
        
        else if (TAG_GENIUS_CHILD_NUTRITION_CHART == tag) {
            ((ChartViewController *) child).isFertility = NO;
            ((ChartViewController *) child).chartDataType = CHART_DATA_TYPE_NUTRITION;
        }
        
        [self.childContollers setObject:child forKey:childNumer];
    }
    
    [self setupTutorialViewController];
    //    tutorialViewController.view.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // This must be the first init part
    [self reinitAllChildOnPage];
    
    self.firstLaunch = YES;
    self.animationLocked = NO;
    
    blockAnimationView.hidden = YES;
    blockAnimationView.backgroundColor = [UIColor clearColor];
    blockAnimationView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    self.view.backgroundColor = UIColorFromRGB(0xe8f7ff);
    
    if ([User currentUser].isSecondaryOrSingleMale) {
        self.navigationItem.leftBarButtonItem = nil;
    }
    
}

- (void)reinitAllChildOnPage {
    [self initChilds];
    [self initChildContainerView];
    if ([self.childContollers allKeys].count == 0) {
        [self initChildControllers];
    } else {
        [self refreshChildrenLayout];
    }
    CGRect rect = [self getChildRect:3 column:1 isFull:NO];
    
    self.containerScrollView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.containerScrollView.contentSize = CGSizeMake(SCREEN_WIDTH, rect.origin.y);
}

- (NSArray *)firstLaunchChildDelays {
    NSArray * delays = @[@0.0, @0.2, @0.4, @0.6, @0.8];
    NSArray *shuffled = [Utils shuffle:delays];
    return shuffled;
}

- (void)viewWillAppear:(BOOL)animated {
    [Logging log:PAGE_IMP_GENIUS_MAIN];
    self.view.userInteractionEnabled = YES;
    
    if (self.firstLaunch) {
        self.firstLaunch = NO;
        for (GeniusChildViewController * child in [self.childContollers allValues]) {
            [child.view setNeedsDisplay];
            [child firstLaunchChild];
            //[child.view setNeedsDisplay];
        }
    }
    
    [self subscribe:EVENT_GENIUS_THUMB_VIEW_CLICKED selector:@selector(onThumbViewClicked:)];
    [self subscribe:EVENT_GENIUS_THUMB_VIEW_CLOSED selector:@selector(onThumbViewClosed:)];
    
    for (GeniusChildViewController * child in [self.childContollers allValues]){
        if (child) {
            [child setupVarsWhenGeniusWillAppear];
        }
    }
    
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unsubscribe:EVENT_GENIUS_THUMB_VIEW_CLICKED];
    [self unsubscribe:EVENT_GENIUS_THUMB_VIEW_CLOSED];
    
    for (GeniusChildViewController * child in [self.childContollers allValues]){
        if (child) {
            [child teardownVarsWhenGeniusWillDisappear];
        }
    }
    //    [ChartData clearAll];
}

- (void)onThumbViewClicked:(Event *)evt {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    TabbarController * tab = (TabbarController *)self.tabBarController;
    [tab hideWithAnimation:YES];
}

- (void)onThumbViewClosed:(Event *)evt {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    TabbarController * tab = (TabbarController *)self.tabBarController;
    [tab showWithAnimation:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [CrashReport leaveBreadcrumb:@"GeniusMainViewController"];
    [self refreshChildrenLayout];
    
    // below is the old genius main page animation
    /*
     NSArray * delays = [self firstLaunchChildDelays];
     for (NSInteger i=0; i<self.childOrder.count; i++) {
     double delayInSeconds = [delays[i] floatValue];
     NSInteger tag = [self.childOrder[i] intValue];
     dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
     
     dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
     GeniusChildViewController * child = [self.childContollers objectForKey:@(tag)];
     
     [child showThumbViewImmediately];
     [child.view setNeedsDisplay];
     [child animateDebutForPos];
     // [self reorderChildView:child];
     });
     }
     */
    // [self refreshChildrenLayout];
    // [self goToUnreadViewIn:1.3];
    
    [self tryStartingTutorial];
    
    if (self.unreadViewTag) {
        [self showUnreadView:self.unreadViewTag afterSeconds:0.6];
        self.unreadViewTag = nil;
    }
    
}

- (BOOL)anyChildOpened
{
    for (GeniusChildViewController *child in self.childContollers.allValues) {
        if (child.inFullView) {
            return YES;
        }
    }
    return NO;
}


- (void)reorderChildView:(GeniusChildViewController *)child {
    // [self.view bringSubviewToFront:child.view];
    // [self.view bringSubviewToFront:navigationBar];
}

- (void)refreshChildrenLayout {
    for (NSNumber * childTag in self.childOrder) {
        GeniusChildViewController *child = [self.childContollers objectForKey:childTag];
        if (!child.inFullView) {
            UIView * container = [self getChildContainerView:[childTag integerValue]];
            //            CGRect rectFromConfig = [self.childConfig[childTag][@"rect"] CGRectValue];
            child.view.frame = CGRectMake(0, 0, container.frame.size.width, container.frame.size.height);;
            //child.view.frame = [rectFromConfig CGRectValue];
            //            child.view.frame = CGRectMake(0, 0, rectFromConfig.size.width, rectFromConfig.size.height);;
        }
        [child.view setNeedsDisplay];
        if ([childTag intValue] == TAG_GENIUS_CHILD_BBT_CHART || [childTag intValue] == TAG_GENIUS_CHILD_WEIGHT_CHART || [childTag intValue] == TAG_GENIUS_CHILD_CALORIES_CHART || [childTag intValue] == TAG_GENIUS_CHILD_NUTRITION_CHART) {
            [((ChartViewController*) child).segView setNeedsDisplay];
        }
    }
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGRect)viewFrameOfChild:(GeniusChildViewController *)childViewController {
    UIView * v = [self getChildContainerView:childViewController.view.tag];
    CGRect result = [v convertRect:v.bounds toView:nil];
    // in IOS7 or above, the top of "self.view" is behind navigation bar, which is 0
    // But in IO6, the top of "self.view" is downstairs of navigation bar, which is 64 + 20
    result = setRectY(result, result.origin.y);
    return result;
}

/*
 - (void)setChildController:(UIViewController *)controller at:(NSString *)pos {
 UIViewController *currentController = posToChildControllers[pos];
 if (currentController) {
 [currentController willMoveToParentViewController:nil];
 [currentController.view removeFromSuperview];
 [currentController removeFromParentViewController];
 }
 [self addChildViewController:controller];
 [self.view addSubview:controller.view];
 [self.view sendSubviewToBack:controller.view];
 posToChildControllers[pos] = controller;
 [controller didMoveToParentViewController:self];
 }
 */

- (IBAction)exportClicked {
    [Logging log:BTN_CLK_GENIUS_EXPORT];
    [[[ExportReportDialog alloc] initWithUser:[User currentUser]] present];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    for (GeniusChildViewController *child in [self.childContollers allValues]) {
        if (child.inFullView) {
            @try {
                return [child preferredStatusBarStyle];
            }
            @catch (NSException *exception) {
                // some child view controller may not implement this function
                return UIStatusBarStyleDefault;
            }
        }
    }
    return UIStatusBarStyleDefault;
}

#pragma mark - rotation
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //    if (((ChartViewController*)posToChildControllers[TOPRIGHT]).needCorrectFrameAfterRotation) {
    //        CGRect frame = self.view.frame;
    //        self.view.frame = CGRectMake(frame.origin.x, scrollFrame.origin.y, scrollFrame.size.height + 20, scrollFrame.size.width - 20);
    //    }
}




#pragma mark - tutorial
- (BOOL)isTutorialCompleted {
    if (FORCE_SHOW_GG_TUTORIAL) return NO;
    return [[Utils getDefaultsForKey:DEFAULTS_GG_TUTORED] boolValue];
}

- (void)setupTutorialViewController {
    if (self.isTutorialCompleted) {
        return;
    }
    tutorialViewController = [[GeniusTutorialViewController alloc] init];
    tutorialViewController.mainViewController = self;
}

- (void)tryStartingTutorial {
    if (self.isTutorialCompleted) {
        return;
    }
    for (GeniusChildViewController *child in self.childContollers.allValues) {
        if (child.inFullView) {
            return;
        }
    }
    UIView *navView = self.tabBarController.view;
    [navView addSubview:tutorialViewController.view];
    tutorialViewController.view.alpha = 1.0f;
    UIView *myCycleContainer = [self getChildContainerView:TAG_GENIUS_CHILD_MY_CYCLES];
    [tutorialViewController startTutorialWithView:myCycleContainer];
}

- (void)tutorialDidComplete {
    MyCyclesViewController *myCycleController = (MyCyclesViewController *)
    [self getGeniucChildController:TAG_GENIUS_CHILD_MY_CYCLES];
    [myCycleController thumbClicked];
    [[DropdownMessageController sharedInstance] postMessage:
     @"Great job! Now you're in full control!" duration:3
                                                   inWindow:[GLUtils keyWindow]];
    [tutorialViewController.view removeFromSuperview];
    [Utils setDefaultsForKey:DEFAULTS_GG_TUTORED withValue:@YES];
}

#pragma mark - helper
- (BOOL)_isTtc {
    AppPurposes purpose = [User currentUser].settings.currentStatus;
    return purpose == AppPurposesTTC || purpose == AppPurposesAlreadyPregnant;
}

#pragma mark - unread views
- (void)showUnreadView:(NSNumber *)childTag afterSeconds:(NSInteger)seconds
{
    if (![self isTutorialCompleted]) {
        return;
    }
    
    GeniusChildViewController *child = (GeniusChildViewController*)[self.childContollers objectForKey:childTag];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (child && [child respondsToSelector:@selector(thumbClicked:)]) {
            [child performSelector:@selector(thumbClicked:) withObject:nil];
        }
    });
    
    [self publish:EVENT_GENIUS_UNREAD_VIEW_HAS_BEEN_SHOWN];
    
}
@end
////
////  GeniusMainViewController.m
////  emma
////
////  Created by Ryan Ye on 7/24/13.
////  Copyright (c) 2013 Upward Labs. All rights reserved.
////
//
//#import "AnimationSequence.h"
//#import "BadgeView.h"
//#import "ChartData.h"
//#import "ChartViewController.h"
//#import "DropdownMessageController.h"
//#import "ExportReportDialog.h"
//#import "GeniusActivityViewController.h"
//#import "GeniusChildViewController.h"
//#import "GeniusInsightsViewController.h"
//#import "GeniusMainViewController.h"
//#import "GeniusTutorialViewController.h"
//#import "HealthChartViewController.h"
//#import "Logging.h"
//#import "MyCyclesViewController.h"
//#import "PushbackTransitioningDelegate.h"
//#import "Referral.h"
//#import "TabbarController.h"
//#import "UIStoryboard+Emma.h"
//#import "Utils.h"
//#import "ChartConstants.h"
//#import <GLFoundation/GLUtils.h>
//#import "NutritionViewController.h"
//#import "GLLineChartViewController.h"
//#import "GLChartWeightDataProvider.h"
//#import "GLChartBBTDataProvider.h"
//#import "GLChartCaloriesDataProvider.h"
//#import "PeriodInfo.h"
//
//#define GGSNAPSHOT_ALPHA 0.0
//#define GGSNAPSHOT_SCALE 0.85
//#define GGSNAPSHOT_CENTER_OFFSET 25
//// #define GENIUSMAIN_OFFSET_Y (IOS7_OR_ABOVE ? 64 : 44)
//
//@interface GeniusMainViewController () {
//    IBOutlet UIView *blockAnimationView;
//    IBOutletCollection(UIView) NSArray *childViews;
//    IBOutlet UIView *referralChildView;
//    BOOL isFertiltiyAsMajor;
//    GeniusTutorialViewController *tutorialViewController;
//}
//
//@property (weak, nonatomic) IBOutlet UIImageView *referralArrowImage;
//@property (weak, nonatomic) IBOutlet UILabel *referralTitle;
//@property (weak, nonatomic) IBOutlet UILabel *referralTime;
//@property (weak, nonatomic) IBOutlet UILabel *referralBody;
//@property (nonatomic) BadgeView * referralCountView;
//
//@property (nonatomic) NSDictionary * childConfig;
//@property (nonatomic) NSArray * childOrder;
//@property (nonatomic) NSMutableDictionary * childContollers;
//@property (nonatomic) BOOL firstLaunch;
//@property (nonatomic) CGFloat referralBannerHeight;
//
//@end
//
//@implementation GeniusMainViewController
//
//- (id)init {
//    if (self = [super init]) {
//        GLLog(@"GeniusMainViewController init");
//        //if (IOS7_OR_ABOVE) {
//        //    transDelegate = [[PushbackTransitioningDelegate alloc] init];
//        //    self.transitioningDelegate = transDelegate;
//        //}
//    }
//    return self;
//}
//
//- (void)awakeFromNib {
//    
//}
//
//- (CGRect)getChildRect:(NSInteger)row column:(NSInteger)column isFull:(BOOL)isFull {
//    CGFloat x = (column == 0 ? GENIUSMAIN_BLOCK_LEFT_X : GENIUSMAIN_BLOCK_RIGHT_X);
//    CGFloat y = row * GENIUSMAIN_BLOCK_HEIGHT + GENIUSMAIN_BLOCK_PADDING;
//    CGFloat width = (isFull ? GENIUSMAIN_BLOCK_WIDTH * 2 : GENIUSMAIN_BLOCK_WIDTH);
//    CGFloat height = GENIUSMAIN_BLOCK_HEIGHT;
//    if (isFull) {
//        height += ((IS_IPHONE_4) || (IS_IPHONE_6))  ? 0 : 30;
//    }
//    return CGRectMake(x + GENIUSMAIN_BLOCK_PADDING,
//                      y + GENIUSMAIN_BLOCK_PADDING,
//                      width - GENIUSMAIN_BLOCK_PADDING*2,
//                      height - GENIUSMAIN_BLOCK_PADDING*2);
//}
//
//- (void)initChilds {
//    
//    self.childConfig =
//    @{
//      @(TAG_GENIUS_CHILD_INSIGHT): @{
//              @"class": [GeniusInsightsViewController.class description],
//              },
//      @(TAG_GENIUS_CHILD_MY_CYCLES): @{
//              @"class": [MyCyclesViewController.class description],
//              },
//      @(TAG_GENIUS_CHILD_BBT_CHART): @{
//              @"class": [GLLineChartViewController.class description],
//              },
//      @(TAG_GENIUS_CHILD_WEIGHT_CHART): @{
//              @"class": [GLLineChartViewController.class description],
//              },
//      @(TAG_GENIUS_CHILD_CALORIES_CHART): @{
//              @"class": [GLLineChartViewController.class description],
//              },
//      @(TAG_GENIUS_CHILD_NUTRITION_CHART): @{
//              @"class": [NutritionViewController.class description],
//              }
//      };
//
//    
//    self.childOrder =
//    @[
//        @(TAG_GENIUS_CHILD_INSIGHT),
//        @(TAG_GENIUS_CHILD_MY_CYCLES),
//        @(TAG_GENIUS_CHILD_BBT_CHART),
//        @(TAG_GENIUS_CHILD_WEIGHT_CHART),
//        @(TAG_GENIUS_CHILD_CALORIES_CHART),
//        @(TAG_GENIUS_CHILD_NUTRITION_CHART)
//    ];
//    
//    
//    if (!self.childContollers) {
//        self.childContollers = [[NSMutableDictionary alloc] init];
//    }
//}
//
//- (void)initChildContainerView {
//    int row = 0;
//    int col = 0;
//    for (NSNumber *tag in self.childOrder) {
//        UIView* v = [self getChildContainerView:[tag integerValue]];
//        v.frame = [self getChildRect:row column:col isFull:NO];
//        v.userInteractionEnabled = YES;
//        v.layer.cornerRadius = GENIUSMAIN_BLOCK_CORNER_RADIUS;
//        [v setClipsToBounds:YES];
//        v.layer.borderColor = UIColorFromRGB(0xdae3e8).CGColor;
//        v.layer.borderWidth = 1.f;
//        col = col + 1;
//        if(col == 2){
//            row = row + 1;
//            col = 0;
//        }
//    }
//}
//
//- (UIView *)getChildContainerView:(NSInteger)childTag {
//    for (UIView * v in childViews) {
//        if (v.tag == childTag) return v;
//    }
//    return nil;
//}
//
//- (GeniusChildViewController *)getGeniucChildController:(NSInteger)childTag {
//    return (GeniusChildViewController *)[self.childContollers objectForKey:@(childTag)];
//}
//
//- (UIView *)getBlockAnimationView {
//    return blockAnimationView;
//}
//
//- (void)initChildControllers {
//    for (NSNumber * childNumer in self.childOrder) {
//        NSInteger tag = [childNumer integerValue];
//        NSDictionary * conf = [self.childConfig objectForKey:childNumer];
//        Class class = NSClassFromString([conf objectForKey:@"class"]);
//        GeniusChildViewController * child = (GeniusChildViewController * )[class getInstance];
//        child.view.tag = tag;
//        child.view.alpha = 1;
//        // find container view
//        UIView * container = [self getChildContainerView:tag];
//        child.view.frame = CGRectMake(0, 0, container.frame.size.width, container.frame.size.height);
//        [self addChildViewController:child];
//        child.view.clipsToBounds = YES;
//        [container addSubview:child.view];
//        
//        if (TAG_GENIUS_CHILD_BBT_CHART == tag) {
//            GLLineChartViewController *bbtChart = (GLLineChartViewController *)child;
//            bbtChart.pageImpressionKey = PAGE_IMP_GNS_CHILD_CYCLE_CHART;
//            bbtChart.showExportReportButton = YES;
//            bbtChart.title = @"CYCLE CHART";
//            GLChartBBTDataProvider *dataProvider = [[GLChartBBTDataProvider alloc] init];
//            dataProvider.chartViewController = bbtChart;
//            bbtChart.dataProvider = dataProvider;
//        }
//        else if (TAG_GENIUS_CHILD_WEIGHT_CHART == tag) {
//            GLLineChartViewController *weightChart = (GLLineChartViewController *)child;
//            weightChart.pageImpressionKey = PAGE_IMP_GNS_CHILD_WEIGHT_CHART;
//            weightChart.title = @"WEIGHT";
//            GLChartWeightDataProvider *dataProvider = [[GLChartWeightDataProvider alloc] init];
//            dataProvider.chartViewController = weightChart;
//            weightChart.dataProvider = dataProvider;
//            
//        }
//        else if (TAG_GENIUS_CHILD_CALORIES_CHART == tag) {
//            GLLineChartViewController *caloriesChart = (GLLineChartViewController *)child;
//            caloriesChart.pageImpressionKey = PAGE_IMP_GNS_CHILD_CALORIES_CHART;
//            caloriesChart.title = @"CALORIES";
//            GLChartCaloriesDataProvider *dataProvider = [[GLChartCaloriesDataProvider alloc] init];
//            dataProvider.chartViewController = caloriesChart;
//            caloriesChart.dataProvider = dataProvider;
//        }
//        
//        else if (TAG_GENIUS_CHILD_NUTRITION_CHART == tag) {
//            
//        }
//        [self.childContollers setObject:child forKey:childNumer];
//    }
//    
//    [self setupTutorialViewController];
////    tutorialViewController.view.hidden = YES;
//}
//
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // This must be the first init part
//    [self reinitAllChildOnPage];
//    
//    self.referralArrowImage.transform = CGAffineTransformMakeScale(-1, 1);
//    UITapGestureRecognizer *tapGoReferral = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goReferral:)];
//    referralChildView.userInteractionEnabled = YES;
//    [referralChildView addGestureRecognizer:tapGoReferral];
//
//    self.firstLaunch = YES;
//    self.animationLocked = NO;
//    
//    blockAnimationView.hidden = YES;
//    blockAnimationView.backgroundColor = [UIColor clearColor];
//    blockAnimationView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
//
//    self.view.backgroundColor = UIColorFromRGB(0xe8f7ff);
//    
//    if ([User currentUser].isSecondaryOrSingleMale) {
//        self.navigationItem.leftBarButtonItem = nil;
//    }
//    
//    [self subscribe:EVENT_REFERRAL_BATCH_INFO_UPDATED selector:@selector(referralBatchUpdated)];
//    [self subscribe:EVENT_REFERRAL_UNREAD_UPDATED selector:@selector(referralUserUpdated)];
//    [self subscribe:EVENT_REFERRAL_BATCH_EXIST_CHANGED selector:@selector(referralExistChanged)];
//}
//
//- (void)reinitAllChildOnPage {
//    self.referralBannerHeight = [Referral hasReferral] ? GENIUSMAIN_REFERRAL_H : 0;
//    [self updateReferralPart];
//    [self initChilds];
//    [self initChildContainerView];
//    if ([self.childContollers allKeys].count == 0) {
//        [self initChildControllers];
//    } else {
//        [self refreshChildrenLayout];
//    }
//    CGRect rect = [self getChildRect:3 column:1 isFull:NO];
//
//    self.containerScrollView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
//    self.containerScrollView.contentSize = CGSizeMake(SCREEN_WIDTH, rect.origin.y);
//}
//
//- (NSArray *)firstLaunchChildDelays {
//    NSArray * delays = @[@0.0, @0.2, @0.4, @0.6, @0.8];
//    NSArray *shuffled = [Utils shuffle:delays];
//    return shuffled;
//}
//
//- (void)viewWillAppear:(BOOL)animated {
//    [Logging log:PAGE_IMP_GENIUS_MAIN];
//    self.view.userInteractionEnabled = YES;
//    [[PeriodInfo sharedInstance] reloadData];
//
//    if (self.firstLaunch) {
//        self.firstLaunch = NO;
//        for (GeniusChildViewController * child in [self.childContollers allValues]) {
//            [child.view setNeedsDisplay];
//            [child firstLaunchChild];
//            //[child.view setNeedsDisplay];
//        }
//    }
//    
//    [self subscribe:EVENT_GENIUS_THUMB_VIEW_CLICKED selector:@selector(onThumbViewClicked:)];
//    [self subscribe:EVENT_GENIUS_THUMB_VIEW_CLOSED selector:@selector(onThumbViewClosed:)];
//    
//    for (GeniusChildViewController * child in [self.childContollers allValues]){
//        if (child) {
//            [child setupVarsWhenGeniusWillAppear];
//        }
//    }
//}
//
//- (void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//    [self unsubscribe:EVENT_GENIUS_THUMB_VIEW_CLICKED];
//    [self unsubscribe:EVENT_GENIUS_THUMB_VIEW_CLOSED];
//    
//    for (GeniusChildViewController * child in [self.childContollers allValues]){
//        if (child) {
//            [child teardownVarsWhenGeniusWillDisappear];
//        }
//    }
//}
//
//- (void)onThumbViewClicked:(Event *)evt {
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
//    TabbarController * tab = (TabbarController *)self.tabBarController;
//    [tab hideWithAnimation:YES];
//}
//
//- (void)onThumbViewClosed:(Event *)evt {
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
//    TabbarController * tab = (TabbarController *)self.tabBarController;
//    [tab showWithAnimation:YES];
//}
//
//- (void)viewDidAppear:(BOOL)animated {
//    [CrashReport leaveBreadcrumb:@"GeniusMainViewController"];
//    [self refreshChildrenLayout];
//    
//    [self tryStartingTutorial];
//    
//    if (self.unreadViewTag) {
//        [self showUnreadView:self.unreadViewTag afterSeconds:0.6];
//        self.unreadViewTag = nil;
//    }
//    
//}
//
//- (BOOL)anyChildOpened
//{
//    for (GeniusChildViewController *child in self.childContollers.allValues) {
//        if (child.inFullView) {
//            return YES;
//        }
//    }
//    return NO;
//}
//
//
//- (void)reorderChildView:(GeniusChildViewController *)child {
//    // [self.view bringSubviewToFront:child.view];
//    // [self.view bringSubviewToFront:navigationBar];
//}
//
//- (void)refreshChildrenLayout {
//    for (NSNumber * childTag in self.childOrder) {
//        GeniusChildViewController *child = [self.childContollers objectForKey:childTag];
//        if (!child.inFullView) {
//            UIView * container = [self getChildContainerView:[childTag integerValue]];
//            //            CGRect rectFromConfig = [self.childConfig[childTag][@"rect"] CGRectValue];
//            child.view.frame = CGRectMake(0, 0, container.frame.size.width, container.frame.size.height);;
//            //child.view.frame = [rectFromConfig CGRectValue];
//            //            child.view.frame = CGRectMake(0, 0, rectFromConfig.size.width, rectFromConfig.size.height);;
//        }
//        [child.view setNeedsDisplay];
//        if ([childTag intValue] == TAG_GENIUS_CHILD_BBT_CHART || [childTag intValue] == TAG_GENIUS_CHILD_WEIGHT_CHART || [childTag intValue] == TAG_GENIUS_CHILD_CALORIES_CHART) {
//            //[((ChartViewController*) child).segView setNeedsDisplay];
//        }
//    }
//}
//
//- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
//    return UIBarPositionTopAttached;
//}
//
//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}
//
//- (CGRect)viewFrameOfChild:(GeniusChildViewController *)childViewController {
//    UIView * v = [self getChildContainerView:childViewController.view.tag];
//    CGRect result = [v convertRect:v.bounds toView:nil];
//    // in IOS7 or above, the top of "self.view" is behind navigation bar, which is 0
//    // But in IO6, the top of "self.view" is downstairs of navigation bar, which is 64 + 20
//    result = setRectY(result, result.origin.y);
//    return result;
//}
//
///*
//- (void)setChildController:(UIViewController *)controller at:(NSString *)pos {
//    UIViewController *currentController = posToChildControllers[pos];
//    if (currentController) {
//        [currentController willMoveToParentViewController:nil];
//        [currentController.view removeFromSuperview];
//        [currentController removeFromParentViewController];
//    }
//    [self addChildViewController:controller];
//    [self.view addSubview:controller.view];
//    [self.view sendSubviewToBack:controller.view];
//    posToChildControllers[pos] = controller;
//    [controller didMoveToParentViewController:self];  
//}
//*/
//
//- (IBAction)exportClicked {
//    [Logging log:BTN_CLK_GENIUS_EXPORT];
//    [[[ExportReportDialog alloc] initWithUser:[User currentUser]] present];
//}
//
//- (UIStatusBarStyle)preferredStatusBarStyle {
//    for (GeniusChildViewController *child in [self.childContollers allValues]) {
//        if (child.inFullView) {
//            @try {
//                return [child preferredStatusBarStyle];
//            }
//            @catch (NSException *exception) {
//                // some child view controller may not implement this function
//                return UIStatusBarStyleDefault;
//            }
//        }
//    }
//    return UIStatusBarStyleDefault;
//}
//
//#pragma mark - rotation
//- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
////    if (((ChartViewController*)posToChildControllers[TOPRIGHT]).needCorrectFrameAfterRotation) {
////        CGRect frame = self.view.frame;
////        self.view.frame = CGRectMake(frame.origin.x, scrollFrame.origin.y, scrollFrame.size.height + 20, scrollFrame.size.width - 20);
////    }
//}
//
//#pragma mark - go to Referral
//- (void)goReferral:(UITapGestureRecognizer *)gesture {
//    if (self.animationLocked) return;
//    [Logging log:BTN_CLK_GENIUS_PROMO];
//    [self goReferral];
//}
//
//- (void)goReferral {
//    if (![Referral hasReferral]) return;
//    [Referral clearUnreadCount];
//    [self refreshReferralUnreadCount];
//    [self publish:EVENT_REFERRAL_PAGE_OPENED];
//    [self presentViewController:[UIStoryboard referral] animated:YES completion:nil];
//}
//
//- (void)refreshReferralUnreadCount {
//    NSInteger count = [Referral getUnreadCount];
//    [self.referralCountView setCount:count];
//    self.referralCountView.alpha = count > 0 ? 1 : 0;
//    self.referralTitle.frame = setRectX(self.referralTitle.frame, count > 0 ? 35 : 10);
//}
//
//- (void)refreshReferralBannerText {
//    // title
//    self.referralTitle.text = [Referral getTitleText];
//    
//    // time left
//    NSDate * d = [NSDate dateWithTimeIntervalSince1970:[Referral getEndTime]];
//    NSInteger days = [Utils daysBeforeDate:d sinceDate:[NSDate date]];
//    NSString * daysText = [NSString stringWithFormat:@"**%ld** DAY%s LEFT", (long)days, days==1 ? "" : "S"];
//    self.referralTime.text = @"";
//    self.referralTime.attributedText = [Utils markdownToAttributedText:daysText fontSize:13 color:[UIColor redColor]];
//    
//    // body
//    self.referralBody.text = @"";
//    self.referralBody.attributedText = [Utils markdownToAttributedText:[Referral getBodyText] fontSize:18 color:UIColorFromRGB(0x5a62d2)];
//    [self.referralBody sizeToFit];
//    self.referralBody.frame = setRectWidth(self.referralBody.frame, 260);
//}
//
//- (void)updateReferralPart {
//    BOOL hasReferral = [Referral hasReferral];
//    
//    referralChildView.hidden = !hasReferral;
//    referralChildView.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.referralBannerHeight);
//    self.referralCountView = [[BadgeView alloc] initWithFrame:CGRectMake(10, 9, 20, 20)];
//    self.referralCountView.hidden = !hasReferral;
//    [referralChildView addSubview:self.referralCountView];
//    [self refreshReferralUnreadCount];
//    [self refreshReferralBannerText];
//}
//
//- (void)referralBatchUpdated {
//    [self updateReferralPart];
//}
//
//- (void)referralUserUpdated {
//    [self refreshReferralUnreadCount];
//}
//
//- (void)referralExistChanged {
//    [self reinitAllChildOnPage];
//}
//
//#pragma mark - tutorial
//- (BOOL)isTutorialCompleted {
//    if (FORCE_SHOW_GG_TUTORIAL) return NO;
//    return [[Utils getDefaultsForKey:DEFAULTS_GG_TUTORED] boolValue];
//}
//
//- (void)setupTutorialViewController {
//    if (self.isTutorialCompleted) {
//        return;
//    }
//    tutorialViewController = [[GeniusTutorialViewController alloc] init];
//    tutorialViewController.mainViewController = self;
//}
//
//- (void)tryStartingTutorial {
//    if (self.isTutorialCompleted) {
//        return;
//    }
//    for (GeniusChildViewController *child in self.childContollers.allValues) {
//        if (child.inFullView) {
//            return;
//        }
//    }
//    UIView *navView = self.tabBarController.view;
//    [navView addSubview:tutorialViewController.view];
//    tutorialViewController.view.alpha = 1.0f;
//    UIView *myCycleContainer = [self getChildContainerView:TAG_GENIUS_CHILD_MY_CYCLES];
//    [tutorialViewController startTutorialWithView:myCycleContainer];
//}
//
//- (void)tutorialDidComplete {
//    MyCyclesViewController *myCycleController = (MyCyclesViewController *)
//        [self getGeniucChildController:TAG_GENIUS_CHILD_MY_CYCLES];
//    [myCycleController thumbClicked];
//    [[DropdownMessageController sharedInstance] postMessage:
//        @"Great job! Now you're in full control!" duration:3
//        inWindow:[GLUtils keyWindow]];
//    [tutorialViewController.view removeFromSuperview];
//    [Utils setDefaultsForKey:DEFAULTS_GG_TUTORED withValue:@YES];
//}
//
//#pragma mark - helper
//- (BOOL)_isTtc {
//    AppPurposes purpose = [User currentUser].settings.currentStatus;
//    return purpose == AppPurposesTTC || purpose == AppPurposesAlreadyPregnant;
//}
//
//#pragma mark - unread views
//- (void)showUnreadView:(NSNumber *)childTag afterSeconds:(NSInteger)seconds
//{
//    if (![self isTutorialCompleted]) {
//        return;
//    }
//
//    GeniusChildViewController *child = (GeniusChildViewController*)[self.childContollers objectForKey:childTag];
//    
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        if (child && [child respondsToSelector:@selector(thumbClicked:)]) {
//            [child performSelector:@selector(thumbClicked:) withObject:nil];
//        }
//    });
//    
//    [self publish:EVENT_GENIUS_UNREAD_VIEW_HAS_BEEN_SHOWN];
//
//}
//@end
