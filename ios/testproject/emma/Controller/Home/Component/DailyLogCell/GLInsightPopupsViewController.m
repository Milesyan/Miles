//
//  GLInsightPopupsViewController.m
//  kaylee
//
//  Created by Bob on 14-9-4.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import "GLInsightPopupsViewController.h"
#import "GLInsightPopupViewController.h"
#import "Insight.h"
#import "User.h"
#import "AppDelegate.h"

#define VERTICAL_SPACING 20

@interface GLInsightPopupsViewController () <UIScrollViewDelegate>
{
    BOOL enterAnimated;
    int currentPage;
    NSArray *vcs;
}
@property (strong, nonatomic) IBOutlet UIView *scollableArea;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentHeight;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (assign, nonatomic) CGSize viewFrameSize;
@end

@implementation GLInsightPopupsViewController

static __weak id presentingInsightPopups;
static GLInsightPopupsViewController *inst;
+ (instancetype)instance
{
    if (!inst) {
        inst = [[UIStoryboard storyboardWithName:@"InsightPopup" bundle:nil] instantiateInitialViewController];
        [inst view];
    }
    return inst;
}

+ (NSMutableArray *)recycledPopups {
    static NSMutableArray *sPopups = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sPopups = [NSMutableArray array];
    });
    return sPopups;
}

+ (GLInsightPopupViewController *)dequeueReusablePopupViewController {
    static int count = 0;
    GLInsightPopupViewController *vc = [[self recycledPopups] firstObject];
    [[self recycledPopups] removeObject:vc];
    if (!vc) {
        count++;
        vc = [[UIStoryboard storyboardWithName:@"InsightPopup" bundle:nil] instantiateViewControllerWithIdentifier:@"one"];
        [vc view];
    }
    vc.view.transform = CGAffineTransformIdentity;
    return vc;
}

+ (void)enqueueReusablePopupViewController:(GLInsightPopupViewController *)vc {
    static int count = 0;
    [vc.view removeFromSuperview];
    if ([vc isKindOfClass:[GLInsightPopupViewController class]]) {
        count++;
        [[self recycledPopups] addObject:vc];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.scollableArea addGestureRecognizer:self.scrollView.panGestureRecognizer];
    [self doLog];
    self.scrollView.scrollsToTop = YES;
    if (IOS8_OR_ABOVE) {
        self.view.backgroundColor = [UIColor clearColor];
        UIBlurEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = self.view.bounds;
        [self.view insertSubview:blurEffectView belowSubview:self.scollableArea];
    }
}

- (void)doLog
{
//    [Logging log:PAGE_IMP_INSIGHT_POPUP eventData:@{@"current_page":@(currentPage),@"total_page":@(self.insights.count)}];
}

- (void)enter
{
    if (!enterAnimated)
    {
        enterAnimated = YES;
        int count = 0;
        for (GLInsightPopupViewController *vc in vcs)
        {
            UIView *v = vc.view;
            CGRect frame = v.frame;
            CGRect originalFrame = frame;
            frame.origin.y = frame.origin.y + frame.size.height;
            v.frame = frame;
            vc.view.alpha = 1;
            [UIView animateWithDuration:0.5
                                  delay:count * 0.05
                 usingSpringWithDamping:0.65
                  initialSpringVelocity:0.1
                                options:0
                             animations:^{
                                    v.frame = originalFrame;
                                }
                             completion:nil];
            count++;
        }
        UIColor *previousColor = self.view.backgroundColor;
        self.view.backgroundColor = [UIColor clearColor];
        [UIView animateWithDuration:0.2 animations:^{
            self.view.backgroundColor = previousColor;
        }];
    }
    GLLog(@"BBaasxxx %@", self.scrollView);

}

- (void)leaveWithCompletion:(void (^)(BOOL finished))completion
{
    int count = 0;
    CGRect localRect = CGRectNull;
    if (!CGRectIsEmpty(self.leaveShrinkToRect))
    {
        localRect = [[[vcs.firstObject view]superview] convertRect:self.leaveShrinkToRect fromView:nil];
    }
    NSMutableArray *visibleVcs = [NSMutableArray array];
    CGFloat minY = self.scrollView.contentOffset.y - self.scrollView.top;
    CGFloat maxY = self.scrollView.contentOffset.y + self.scrollView.height + (self.view.height - self.scrollView.bottom);
    for (GLInsightPopupViewController *vc in vcs)
    {
        BOOL visible = !((vc.view.top < minY && vc.view.bottom < minY) || (vc.view.top > maxY && vc.view.bottom > maxY));
        if (visible) {
            [visibleVcs addObject:vc];
        }
    }
    for (GLInsightPopupViewController *vc in visibleVcs) {
        UIView *v = vc.view;
        CGRect frame;
        CGRect oldFrame = vc.view.frame;
        if (!CGRectIsEmpty(self.leaveShrinkToRect))
        {
            frame = localRect;
        }
        else
        {
            frame = v.frame;
            frame.origin.y += frame.size.height;
        }
        CGAffineTransform transform = CGAffineTransformFromRectToRect(oldFrame, frame);
        [UIView animateWithDuration:0.5
                              delay:count * 0.05
             usingSpringWithDamping:1
              initialSpringVelocity:0
                            options:0
                         animations:^{
                             v.transform = transform;
//                             v.frame = frame;
//                             //v.alpha = 0;
                             [v layoutIfNeeded];
                         }
                         completion:^(BOOL f){
             if (count == visibleVcs.count - 1)
             {
                 if (completion)
                 {
                     completion(f);
                 }
                 presentingInsightPopups = nil;
             }
         }];
        count++;
    }
}

- (void)present
{
    if (presentingInsightPopups)
    {
        return;
    }
    
    presentingInsightPopups = self;
    
    UIWindow *window = [GLUtils keyWindow];
    self.view.frame = window.bounds;
//    [window addSubview:self.view];
    
    UIViewController *vc = [AppDelegate topMostController];
    [vc.view addSubview:self.view];
    
    [self setupViews];
}


- (void)setupViews
{
    NSArray *views = [self.contentView subviews];
    for (UIView *v in views)
    {
        [v removeFromSuperview];
    }
    NSMutableArray *arr = [@[] mutableCopy];
    NSArray *newInsgiths = self.insights;
    int count = 0;
    CGFloat top = 0;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    for (Insight *insight in newInsgiths)
    {
        GLInsightPopupViewController *vc = [[self class ] dequeueReusablePopupViewController];
//        GLInsightPopupViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"one"];
        vc.insight = insight;
        vc.view.frame = self.contentView.bounds;
        [vc.view setNeedsLayout];
        [vc.view layoutIfNeeded];
        
        CGSize preferSize = [vc.view systemLayoutSizeFittingSize:self.contentView.bounds.size];
        
        vc.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        vc.view.translatesAutoresizingMaskIntoConstraints = YES;
        vc.view.frame = CGRectMake(0.0, top, self.contentView.width, preferSize.height);
        [vc.view setNeedsLayout];
        [vc.view layoutIfNeeded];
        
        top += vc.view.height + VERTICAL_SPACING;
        
//        vc.view.alpha = 0.0;
        [self.contentView addSubview:vc.view];
        [arr addObject:vc];
        count++;
    }

    vcs = arr;
//top = ceil(top / self.scrollView.bounds.size.height) * self.scrollView.bounds.size.height;
    self.contentHeight.constant = top;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    self.scrollView.contentOffset = CGPointZero;

    enterAnimated = NO;
    [self enter];
}

#pragma mark -
- (IBAction)closeTapped:(id)sender
{
//    BOOL insightsUpdated = [[User currentUser] markAllInsightsAsRead];
//    for (GLInsightPopupViewController *vc in vcs)
//    {
//        if (!vc.insight.unread || [vc.insight.unread boolValue]) {
//            insightsUpdated = YES;
//            vc.insight.unread = @NO;
//            [vc.insight save];
//        }
//    }
//    if (insightsUpdated) {
//        [self publish:EVENT_INSIGHTS_UPDATED];
//    }
    [self leaveWithCompletion:^(BOOL finished) {
        
    }];
    [UIView animateWithDuration:0.5 animations:^(){
        self.view.alpha = 0;
    }completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
//        [self publish:EVENT_NEW_INSIGHTS_DISMISSED];
        presentingInsightPopups = nil;
        enterAnimated = NO;
        self.view.alpha = 1;
        for (GLInsightPopupViewController *vc in vcs)
        {
            [[self class] enqueueReusablePopupViewController:vc];
        }
        vcs = nil;
    }];
}

#pragma mark - UIScrollViewDelegate
- (NSUInteger)pageForY:(CGFloat)y
{
    CGFloat top = y;
    CGFloat minGap = MAXFLOAT;
    NSUInteger index = 0;
    NSUInteger bestIndex = 0;
    
    for (UIViewController *vc in vcs)
    {
        CGFloat currentTop = vc.view.superview.top;
        if (fabs(currentTop - top) < minGap)
        {
            bestIndex = index;
            minGap = fabs(currentTop - top);
        }
        index++;
    }
    return bestIndex;
}

- (NSUInteger)currentPage
{
    return [self pageForY:self.scrollView.contentOffset.y];
}

- (void)logCurrentPage
{
    currentPage = (int)[self currentPage];
    [self doLog];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self logCurrentPage];
    }
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self logCurrentPage];
}

@end
