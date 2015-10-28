//
//  GeniusInsightsViewController.m
//  emma
//
//  Created by Jirong Wang on 7/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GeniusMainViewController.h"
#import "GeniusInsightsViewController.h"
#import "GeniusInsightsChildViewController.h"
#import "Insight.h"
#import "User.h"
#import "WebViewController.h"
#import "UIStoryboard+Emma.h"
#import "BadgeView.h"
#import "Logging.h"
#import "Tooltip.h"

@interface GeniusInsightsViewController () <UIScrollViewDelegate> {
    CGFloat viewWidth;
    CGFloat textWidth;
    CGFloat textX;
    CGFloat viewX;
    CGFloat viewY;
    NSInteger heightMax;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *titleDividerView;

@property (weak, nonatomic) IBOutlet UIView *cycleView;
@property (weak, nonatomic) IBOutlet UIPageControl *insightPageControl;

@property (weak, nonatomic) IBOutlet UIScrollView *insightsScrollView;
@property (weak, nonatomic) IBOutlet UIView *insightChildView;
@property (weak, nonatomic) IBOutlet UILabel *noInsightLabel;

- (IBAction)closeBtnClicked:(id)sender;
- (IBAction)changeInsightPage:(id)sender;

@property (nonatomic) BadgeView * countThumbView;
@property (nonatomic) BadgeView * countFullView;

@property (nonatomic) NSArray * insights;
@property (nonatomic) NSInteger unreadInsights;
@property (nonatomic) NSInteger currentPage;
// @property (nonatomic) BOOL fullView;

@property (nonatomic) CGRect titleLabelFrame;
@property (nonatomic) CGRect titleDividerFrame;
@property (nonatomic) CGRect insightTimeViewFrame;

@property (nonatomic) GeniusInsightsChildViewController * frontViewController;
@property (nonatomic) NSMutableArray * scrollViewControllers;

@property (nonatomic) BOOL underScrolling;

@end

@implementation GeniusInsightsViewController

+ (id)getInstance {
    return [[GeniusInsightsViewController alloc] init];
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
    
    // Do any additional setup after loading the view from its nib.
    [self.closeButton setImage:[Utils image:[UIImage imageNamed:@"topnav-close"] withColor:[UIColor whiteColor]] forState:UIControlStateNormal];

    self.frontViewController = [[GeniusInsightsChildViewController alloc] init];
    [self.insightChildView addSubview:self.frontViewController.view];
    self.noInsightLabel.hidden = YES;
    self.scrollViewControllers = [[NSMutableArray alloc] init];
    
    self.countFullView = [[BadgeView alloc] initWithFrame:CGRectMake(20, 34, 38, 38)];
    self.countThumbView = [[BadgeView alloc] initWithFrame:CGRectMake(10, 9, 20, 20)];
    [self.view addSubview:self.countFullView];
    [self.view addSubview:self.countThumbView];
    
    self.titleLabelFrame = self.titleLabel.frame;
    self.titleDividerFrame = (CGRect) {{20, 80}, {GG_FULL_CONTENT_W, 1}};
//    self.cycleViewFrame = (CGRect) {
//        {0, self.view.frame.size.height - self.cycleView.frame.size.height - 10},
//        self.view.frame.size};
    heightMax = SCREEN_HEIGHT - 88;
    self.insightsScrollView.frame = setRectHeight(self.insightsScrollView.frame, heightMax);
    self.insightsScrollView.delegate = self;

    // subscribe event
    [self subscribe:EVENT_INSIGHT_UPDATED selector:@selector(insightsUpdated)];
    [self subscribe:EVENT_INSIGHT_WEB_CLICKED selector:@selector(insightWebClicked:)];
    
    [self refreshInsights];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)_showThumbView {
    //CGFloat offsetY = IS_IPHONE_5 ? 10 : 0;
    // 1. count badge and title label
    self.titleLabel.transform = CGAffineTransformMakeScale(0.5, 0.5);
    if (self.unreadInsights == 0) {
        self.countThumbView.alpha = 0;
        self.titleLabel.center = CGPointMake(65 + self.thumbTitleIndent, 20);
    } else {
        self.countThumbView.alpha = 1.0;
        self.titleLabel.center = CGPointMake(90, 20);
    }
    // 2. info button
    self.infoButton.alpha = 0;
    
    // 3. title divider
    self.titleDividerView.frame = CGRectMake(10, 35, GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 1);
    // 4. cycle view
//    self.cycleView.frame = CGRectMake(10, 128 + offsetY, GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 0);
    self.cycleView.alpha = 0;
    // 5. front view
    [self.frontViewController showThumbView];
    self.insightChildView.frame = CGRectMake(0, 37, self.frontViewController.view.frame.size.width, self.frontViewController.view.frame.size.height);
    // 6. no insight label
    self.noInsightLabel.frame = CGRectMake(10, 37, GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 80);
    self.closeButton.hidden = YES;
}

- (void)_showFullView {
    // 1. count badge and title label
    self.titleLabel.transform = CGAffineTransformIdentity;
    self.titleLabel.frame = self.titleLabelFrame;
    CGFloat yTemp = self.titleLabel.center.y;
    if (self.unreadInsights == 0) {
        self.countFullView.alpha = 0;
        self.titleLabel.center = CGPointMake(130, yTemp);
    } else {
        self.countFullView.alpha = 1.0;
        self.titleLabel.center = CGPointMake(175, yTemp);
    }
    // 2. info button
    self.infoButton.alpha = 1;
    NSAttributedString *text = [Utils markdownToAttributedText:self.titleLabel.text
        fontSize:25 color:[UIColor whiteColor]];
    CGSize size = [text size];
    setXOfRect(self.infoButton.frame,
        self.titleLabel.frame.origin.x + size.width + 5);
    
    
    // 3. title divider
    self.titleDividerView.frame = self.titleDividerFrame;
    // 4. cycle view
    self.cycleView.alpha = 1;
//    self.wcycleView.frame = self.cycleViewFrame;
    // 5. front view
    [self.frontViewController showFullView];
    self.insightChildView.frame = CGRectMake(0, 89, self.frontViewController.view.frame.size.width, heightMax);
    // 6. no insight label
    self.noInsightLabel.frame = CGRectMake(20, 89,
        GG_FULL_CONTENT_W, 90);
    self.closeButton.hidden = NO;
}

- (void)toggleInsightViews:(BOOL)isFullView {
    BOOL frontViewHidden = (self.currentPage == 0 ? YES : NO);
    self.insightsScrollView.hidden = isFullView ? frontViewHidden : YES;
    self.insightChildView.hidden = isFullView ? YES : frontViewHidden;
}

- (void)showThumbView {
    // set full view count badge to hidden
    self.countFullView.alpha = 0;
    [self toggleInsightViews:NO];
    // call super, the super showThumbView will call _showThumbView
    [super showThumbView];
}

- (void)showFullView {
    // set thumb view count badge to hidden
    self.countThumbView.alpha = 0;
    [self toggleInsightViews:YES];
    self.insightChildView.hidden = YES;
    // call super, the super showFullView will call _showThumbView
    [super showFullView];
}

- (void)fullToThumbBegin {
    [self setUnreadCount];
    // hide the count badge in full view first
    self.countFullView.alpha = 0;
    // before animation, show the front view
    [self toggleInsightViews:NO];
}

- (void)thumbToFullBegin {
    [self setUnreadCount];
    // hide the count badge in thumb view first
    self.countThumbView.alpha = 0;
}

- (void)thumbToFullCompletion {
    [self setInsightRead];
    // after animation, show the insightViews
    [self toggleInsightViews:YES];
    [Logging log:PAGE_IMP_GNS_CHILD_INSIGHT];
    
    //snap
    self.insightsScrollView.contentOffset = (CGPoint) {
        roundf(self.insightsScrollView.contentOffset.x / SCREEN_WIDTH) * SCREEN_WIDTH,
        self.insightsScrollView.contentOffset.y
    };
}

- (IBAction)infoButtonClicked:(id)sender {
    [Tooltip tip:@"What are insights?"];
}

- (IBAction)closeBtnClicked:(id)sender {
    [self publish:EVENT_UNREAD_INSIGHTS_CLEARED];
    [self close];
}

- (IBAction)changeInsightPage:(id)sender {
    CGRect frame;
    frame.origin.x = SCREEN_WIDTH * self.insightPageControl.currentPage;
    frame.origin.y = 0;
    frame.size = self.insightsScrollView.frame.size;
    if (self.currentPage != self.insightPageControl.currentPage + 1) {
        self.currentPage = self.insightPageControl.currentPage + 1;
        self.underScrolling = YES;
        [self.insightsScrollView scrollRectToVisible:frame animated:YES];
        [self pageChanged];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    if (self.underScrolling) {
        return;
    }
    NSInteger page = floor((self.insightsScrollView.contentOffset.x - SCREEN_WIDTH / 2) / SCREEN_WIDTH) + 1;
    if ((page < 0) || (page >= self.insights.count)) {
        return;
    }
    self.insightPageControl.currentPage = page;
    if (self.currentPage != page + 1) {
        self.currentPage = page + 1;
        [self pageChanged];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.underScrolling = NO;
}

- (void)refreshInsights {
    self.insights = [Insight sortedInsightsForGenius:[User currentUser]];
    self.currentPage = self.insights.count > 0 ? 1 : 0;
    
    self.cycleView.hidden = self.currentPage == 0 ? YES : NO;
    self.noInsightLabel.hidden = self.currentPage == 0 ? NO : YES;
    
    // set front page data
    [self drawFrontPage];
    // set data to scroll views
    [self drawInsightsPages];
    // set number of insight cycles
    [self drawCycleViews];
    
    // set number of unread insights
    [self setUnreadCount];
}

- (void)setUnreadCount {
    self.unreadInsights = [User currentUser].unreadInsightCount;
    self.titleLabel.text = self.unreadInsights > 0 ? @"NEW INSIGHTS" : @"INSIGHTS";
    [self.countFullView setCount:self.unreadInsights];
    [self.countThumbView setCount:self.unreadInsights];
}

- (void)drawInsightsPages {
    NSInteger current = self.scrollViewControllers.count;
    NSInteger i, j;
    if (current < self.insights.count) {
        // add more
        NSInteger c = self.insights.count - current;
        for (i = 0; i < c; i++) {
            GeniusInsightsChildViewController * g = [[GeniusInsightsChildViewController alloc] init];
            
            [self.scrollViewControllers addObject:g];
            [self.insightsScrollView addSubview:g.view];
        }
    } else if (current > self.insights.count) {
        // (current > self.insights.count) remove,
        NSInteger c = current - self.insights.count;
        for (i = 0, j=current-1; i < c; i++, j--) {
            GeniusInsightsChildViewController * g = self.scrollViewControllers[j];
            [self.scrollViewControllers removeObject:g];
            [g.view removeFromSuperview];
        }
    }
    // set data to every page
    NSInteger yMax = 0;
    for (i = 0; i < self.insights.count; i++) {
        GeniusInsightsChildViewController * g = self.scrollViewControllers[i];
        [g setInsight:self.insights[i]];
        NSInteger h = self.insightsScrollView.frame.size.height;
        g.view.frame = CGRectMake(SCREEN_WIDTH*i, 0, SCREEN_WIDTH, h);
        [g replaceViewsToFit];
        if (h > yMax) yMax = h;
    }
    [self.insightsScrollView setContentSize:CGSizeMake(SCREEN_WIDTH*self.insights.count, heightMax)];
    [self.insightsScrollView setContentOffset:CGPointMake(0, 0)];
}

- (void)drawFrontPage {
    if (self.currentPage == 0) {
        return;
    }
    Insight * ins = self.insights[self.currentPage - 1];
    [self.frontViewController setInsight:ins];
    [self.frontViewController calculateViewsToFit];
}

- (void)drawCycleViews {
    [self.insightPageControl setNumberOfPages:self.insights.count];
    if (self.insights.count > 0) {
        self.insightPageControl.currentPage = 0;
    }
}

- (void)refreshViewsImmediately {
    if (self.inFullView) {
        [self showFullView];
    } else {
        [self showThumbView];
    }
}

- (Insight *)currentInsight {
    if (self.insights.count <= 0) {
        return nil;
    } else {
        NSInteger x = self.currentPage-1;
        x = (x < 0) ? 0 : x;
        x = (x > self.insights.count-1) ? self.insights.count-1 : x;
        return self.insights[x];
    }
}

- (void)setInsightRead {
    [Insight setInsightsRead:[NSDate date]];
}

- (void)pageChanged {
    if (!self.inFullView) {
        return;
    }
    [self drawFrontPage];
    [self setInsightRead];
}

- (void)insightsUpdated {
    [self refreshInsights];
    [self refreshViewsImmediately];
}

- (void)insightWebClicked:(Event *)event {
    /*
     We put the logic in here, not in "genius insight child view controller" is because
     If the user opened a web page, and then click "HOME" button, after he re-enter our 
     App, the "genius insight child view" will be updated/removed. Then the user clicks
     "Back button" on navigation bar will cause unexpected problem - presenting view 
     controller is dismissed.
                                           - jirong
     */
    NSDictionary * d = (NSDictionary *)event.data;
    NSString * url = [d objectForKey:@"url"];
    WebViewController *controller = (WebViewController *)[UIStoryboard webView];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:nil];
    [controller openUrl:url];
}

@end
