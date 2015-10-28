//
//  TutorialViewController.m
//  emma
//
//  Created by Ryan Ye on 4/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "TutorialViewController.h"
#import "TinyCalendarView.h"
#import "HomeViewController.h"
#import "CKCalendarView.h"
#import "GLDialogViewController.h"
#import "DropdownMessageController.h"
#import "StatusBarOverlay.h"
#import "AnimationSequence.h"
#import "User.h"

#define ARROW_ANIMATION_DURATION 0.8
#define MESSAGE_DURATION 3.0

#define ARROW_ALPHA 0.7

@interface TutorialViewController () {
    IBOutlet UIImageView *gestureFinger;
    IBOutlet UIImageView *gestureDragdown;
    IBOutlet UIImageView *arrowUp;
    IBOutlet UIImageView *arrowRight;
    IBOutlet UIImageView *arrowLeft;
    IBOutlet UIView *bgView1;
    IBOutlet UIView *bgView2;
    IBOutlet UIView *laterLink;
    IBOutlet UIButton *startLoggingBtn;
    __weak IBOutlet UILabel *topLabel;
    IBOutlet UILabel *textLabel;
    IBOutlet UIViewController *finishContentController;
    __weak IBOutlet UILabel *laterLabel;
    DropdownMessageController *messageController;
    StatusBarOverlay *statusBarOverlay;
    BOOL swipeAnimating;
    BOOL dragdownAnimating;
    BOOL tapAnimating;
    CGFloat dragStartY;
    CGFloat dragLength;
    CGFloat navBarHeight;
}
- (void)step1;
@end

@implementation TutorialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    navBarHeight = 64;
    // Do any additional setup after loading the view from its nib.
    messageController = [DropdownMessageController sharedInstance];
    statusBarOverlay = [StatusBarOverlay sharedInstance];
    bgView1.alpha = bgView2.alpha = 0;
    self.view.backgroundColor = [UIColor clearColor];
    gestureDragdown.alpha = gestureFinger.alpha;
    arrowLeft.alpha = arrowRight.alpha = 0;
    gestureDragdown.image = [[UIImage imageNamed:@"gesture-dragdown"] resizableImageWithCapInsets:UIEdgeInsetsMake(50, 0, 0, 0)];
    textLabel.layer.cornerRadius = 10;
    topLabel.layer.cornerRadius = 10;
    
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:@"Later"];
    [attributeString addAttribute:NSUnderlineStyleAttributeName
                            value:[NSNumber numberWithInt:1]
                            range:(NSRange){0,[attributeString length]}];
    [attributeString addAttribute:NSFontAttributeName
                            value:laterLabel.font
                            range:(NSRange){0,[attributeString length]}];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    [attributeString addAttribute:NSParagraphStyleAttributeName
                            value:paragraphStyle
                            range:(NSRange){0, [attributeString length]}];

    laterLabel.attributedText = attributeString;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.view.frame = [UIScreen mainScreen].bounds;
    self.containerView.frame = self.view.bounds;
    startLoggingBtn.width = self.view.width;
    startLoggingBtn.height = 47;
    bgView2.width = self.view.width;
}

- (void)start {
    [self publish:EVENT_TUTORIAL_DID_START];
    bgView1.frame = CGRectMake(0, TINY_CAL_HEIGHT + navBarHeight, SCREEN_WIDTH, SCREEN_HEIGHT - TINY_CAL_HEIGHT - navBarHeight);
    bgView1.alpha = 0;
    statusBarOverlay.hidden = YES;
    [UIView animateWithDuration:0.3 animations:^{
        bgView1.alpha = 1.0;
    }];
    [self step1];
}

- (void)setBgGradientForView:(UIView *)view fromColor:(UIColor *)fromColor toColor:(UIColor *)toColor
{
    view.backgroundColor = [UIColor clearColor];
    NSArray *colors = @[(id)fromColor.CGColor, (id)toColor.CGColor];
    NSArray *locations = [NSArray arrayWithObjects:@(0.0), @(1.0), nil];
    CAGradientLayer *bgLayer = [CAGradientLayer layer];
    bgLayer.frame = CGRectMake(0, 0, view.width, view.height);
    bgLayer.colors = colors;
    bgLayer.locations = locations;
    [view.layer insertSublayer:bgLayer atIndex:0];
}

- (void)startSwipeAnimation:(CGFloat)offsetY {
    swipeAnimating = YES;
    gestureFinger.layer.anchorPoint = CGPointMake(0.5, 3.0);
    gestureFinger.center = CGPointMake(SCREEN_WIDTH/2, navBarHeight + TINY_CAL_HEIGHT + offsetY);
    gestureFinger.hidden = NO;
    gestureDragdown.hidden = YES;
    [self swipeFromRightToLeft];
}

- (void)stopSwipeAnimation {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(swipeFromRightToLeft) object:nil];
    swipeAnimating = NO;
}

- (void)swipeFromRightToLeft {
    gestureFinger.transform = CGAffineTransformMakeRotation(0.8 / M_PI);
    gestureFinger.alpha = 0;
    [AnimationSequence performAnimations:@[
        [AnimationBlock duration:0.5 animations:^{
            gestureFinger.alpha = 1.0;
        }],
        [AnimationBlock duration:1.0 animations:^{
            gestureFinger.transform = CGAffineTransformMakeRotation(-0.8 / M_PI);
            gestureFinger.alpha = 1.0;
        }],
        [AnimationBlock duration:0.5 delay:0.5 options:0 animations:^{
            gestureFinger.alpha = 0;
        }]
    ] completion:^(BOOL finished) {
        if (swipeAnimating) 
            [self swipeFromRightToLeft];
    }];
}

- (void)startDragdownAnimation:(CGFloat)startY dragLength:(CGFloat)length {
    dragdownAnimating = YES;
    gestureFinger.hidden = NO;
    gestureDragdown.hidden = NO;
    gestureFinger.layer.anchorPoint = CGPointMake(0.5, 0.5);
    gestureFinger.transform = CGAffineTransformIdentity;
    dragStartY = startY;
    dragLength = length;
    [self dragFromTopToDown];
}

- (void)stopDragdownAnimation {
    dragdownAnimating = NO;
    [gestureFinger.layer removeAllAnimations];
    [gestureDragdown.layer removeAllAnimations];
    gestureFinger.alpha = gestureDragdown.alpha = 0;
}

- (void)dragFromTopToDown {
    gestureDragdown.frame = CGRectMake((SCREEN_WIDTH-55)/2, dragStartY, 55, 50);
    gestureFinger.frame = CGRectMake((SCREEN_WIDTH-55)/2, dragStartY + 22, 80, 105);
    gestureFinger.alpha = gestureDragdown.alpha = 0;

    [AnimationSequence performAnimations:@[
        [AnimationBlock duration:0.5 animations:^{
            gestureDragdown.alpha = gestureFinger.alpha = 1.0;
        }],
        [AnimationBlock duration:1.0 animations:^{
            gestureFinger.center = CGPointMake(gestureFinger.center.x, gestureFinger.center.y + dragLength);
            gestureDragdown.frame = setRectHeight(gestureDragdown.frame, gestureDragdown.frame.size.height + dragLength);
        }],
        [AnimationBlock duration:0.5 delay:0.5 options:0 animations:^{
            gestureFinger.alpha = 0;
            gestureDragdown.alpha = 0;
        }]
    ] completion:^(BOOL finished) {
        if (finished && dragdownAnimating)
            [self dragFromTopToDown];
    }];
}

- (void)hideAllGestures {
    gestureFinger.hidden = YES;
    gestureDragdown.hidden = YES;
    [gestureFinger.layer removeAllAnimations];
    [gestureDragdown.layer removeAllAnimations];
}

- (void)showAllGestures {
    gestureFinger.hidden = NO;
    gestureDragdown.hidden = NO;
    if (swipeAnimating) {
        [self swipeFromRightToLeft];
    }
    if (dragdownAnimating) {
        [self dragFromTopToDown];
    }
}

- (void)step1 {
    [self setBgGradientForView:bgView1 fromColor:[UIColor colorWithWhite:0 alpha:0] toColor:[UIColor blackColor]];
    [self fadeInView:textLabel];

    arrowLeft.alpha = arrowRight.alpha = 0;
    arrowLeft.center = CGPointMake(SCREEN_WIDTH/2 - arrowLeft.frame.size.width / 2, navBarHeight + TINY_CAL_HEIGHT/2);
    arrowRight.center = CGPointMake(SCREEN_WIDTH/2 + arrowRight.frame.size.width / 2, navBarHeight + TINY_CAL_HEIGHT/2);
    [self startSwipeAnimation:230];
    [UIView animateWithDuration:ARROW_ANIMATION_DURATION animations:^{
        arrowLeft.alpha = arrowRight.alpha = ARROW_ALPHA;
        arrowLeft.frame = setRectX(arrowLeft.frame, 0);
        arrowRight.frame = setRectX(arrowRight.frame, SCREEN_WIDTH - arrowRight.frame.size.width);
    }];
    
    @weakify(self)
    [self subscribeOnce:EVENT_TINY_CALENDAR_SWIPE handler:^(Event *evt) {
        @strongify(self)
        [self stopSwipeAnimation];
        [UIView animateWithDuration:0.5 animations:^{
            arrowLeft.alpha = arrowRight.alpha = 0;
        } completion:^(BOOL finished) {
            [self step2];
        }];
    }];
    [self setInstructionText:@"**Swipe left or right**\nto see different days"];
    [self publish:EVENT_TUTORIAL_ENTER_STEP1];
}

- (void)step2 {

    [self startDragdownAnimation:100.0 dragLength:100.0];
    [self publish:EVENT_TUTORIAL_ENTER_STEP2];
    [self setInstructionText:@"**Pull down** to see\nthe full calendar view"];

    @weakify(self)
    [self subscribeOnce:EVENT_SWITCHED_TO_FULL_CALENDAR handler:^(Event *evt) {
        @strongify(self)
        [self stopDragdownAnimation];
        bgView1.top = navBarHeight + CALENDAR_HEIGHT + 8;
        textLabel.alpha = 0;
        [self step3];
    }];
}

- (void)step3 {
    [self fadeInView:textLabel];
    
    [self startDragdownAnimation:100.0 dragLength:150.0];
    [self publish:EVENT_TUTORIAL_ENTER_STEP3];
    [self setInstructionText:@"**Pull down** to see\nthe small calendar view"];
    
    @weakify(self)
    [self subscribeOnce:EVENT_SWITCHED_TO_TINY_CALENDAR handler:^(Event *evt) {
        @strongify(self)
        bgView1.frame = setRectY(bgView1.frame, navBarHeight + TINY_CAL_HEIGHT);
        self.view.userInteractionEnabled = YES;
        textLabel.hidden = YES;
        [Utils performInMainQueueAfter:0.3 callback:^{
            [self publish:EVENT_HOME_GOTO_TODAY];
        }];
        [Utils performInMainQueueAfter:1.3 callback:^{
            [self step4];
        }];
    }];
}

- (void)step4 {
    [messageController clearMessage];
    self.view.userInteractionEnabled = YES;
    
    if ([User currentUser].settings.currentStatus == AppPurposesTTCWithTreatment) {
        [UIView animateWithDuration:0.3 animations:^{
            bgView1.alpha = 0;
            bgView2.alpha = 0;
        } completion:^(BOOL finished) {
            [self publish:EVENT_TUTORIAL_COMPLETED];
        }];
        return;
    }
    [self fadeInView:topLabel];

    gestureFinger.alpha = 1;
    gestureFinger.hidden = NO;
    gestureFinger.transform = CGAffineTransformIdentity;
    gestureFinger.top = navBarHeight + TINY_CAL_HEIGHT + 12 + 126;
    gestureFinger.left = SCREEN_WIDTH / 3 * 2;
    startLoggingBtn.top = navBarHeight + TINY_CAL_HEIGHT + 12 + 126;
    startLoggingBtn.hidden = NO;
    laterLink.hidden = NO;
    tapAnimating = YES;
    [self startClickAnimation];
    
    [UIView animateWithDuration:0.5 animations:^{
        bgView1.alpha = 1.0;
        bgView2.alpha = 1.0;


        bgView1.frame = CGRectMake(0, CGRectGetMaxY(startLoggingBtn.frame),
                                   SCREEN_WIDTH, self.view.height - CGRectGetMaxY(startLoggingBtn.frame) + startLoggingBtn.height);
        bgView2.frame = CGRectMake(0, 0, SCREEN_WIDTH, navBarHeight + TINY_CAL_HEIGHT + 12 + 126);

        [self setBgGradientForView:bgView1 fromColor:[UIColor colorWithWhite:0.8 alpha:0.1] toColor:[UIColor blackColor]];
        [self setBgGradientForView:bgView2 fromColor:[UIColor blackColor] toColor:[UIColor colorWithWhite:0.8 alpha:0.1]];

    } completion:nil];
    [self setInstructionText:@""];
    [self publish:EVENT_TUTORIAL_ENTER_STEP4];
}

- (void)startClickAnimation
{
    if (tapAnimating == NO) {
        return;
    }
    [UIView animateWithDuration:0.4 animations:^{
        gestureFinger.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 animations:^{
            gestureFinger.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:^(BOOL finished) {
            [self startClickAnimation];
        }];
    }];
}

- (void)stopClickAnimation
{
    tapAnimating = NO;
}

- (IBAction)clickStartLogging:(id)sender {
    self.view.userInteractionEnabled = NO;
    tapAnimating = NO;
    [UIView animateWithDuration:0.3 animations:^{
        bgView1.alpha = 0;
        bgView2.alpha = 0;
        gestureFinger.alpha = 0;
        laterLink.alpha = 0;
    } completion:^(BOOL finished) {
//        statusBarOverlay.hidden = NO;
        bgView1.hidden = YES;
        bgView2.hidden = YES;
        gestureFinger.hidden = YES;
        laterLink.hidden = YES;
    }];
    [messageController postMessage:@"Start your first log below!" duration:MESSAGE_DURATION position:40 inView:self.view];
    [self publish:EVENT_TUTORIAL_START_LOGGING];
    @weakify(self)
    [self subscribeOnce:EVENT_DAILY_LOG_EXIT handler:^(Event *evt) {
        @strongify(self)
        [self publish:EVENT_TUTORIAL_COMPLETED];
    }];
}

- (IBAction)clickLater:(id)sender {
    self.view.userInteractionEnabled = NO;
    tapAnimating = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        bgView1.alpha = 0;
        bgView2.alpha = 0;
        gestureFinger.alpha = 0;
        laterLink.alpha = 0;
    } completion:^(BOOL finished) {
        bgView1.hidden = YES;
        bgView2.hidden = YES;
        gestureFinger.hidden = YES;
        laterLink.hidden = YES;
//        statusBarOverlay.hidden = NO;
        [self publish:EVENT_TUTORIAL_COMPLETED];
    }];
}

- (void)setInstructionText:(NSString *)text {
    textLabel.attributedText = [Utils markdownToAttributedText:text fontSize:18 color:[UIColor whiteColor]];
    textLabel.textAlignment = NSTextAlignmentCenter;
    //[textLabel sizeToFit];
//    textLabel.frame = CGRectMake(0, textLabel.frame.origin.y, SCREEN_WIDTH, textLabel.frame.size.height);
}

- (void)fadeInView:(UIView *)view
{
    view.alpha = 0;
    view.transform = CGAffineTransformMakeTranslation(0, -10);
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        view.alpha = 1;
        view.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)pullDownWithDistance:(CGFloat)distance maxValue:(CGFloat)maxValue;
{
    if (distance == 0) {
        return;
    }
    textLabel.transform = CGAffineTransformMakeTranslation(0, distance);
    textLabel.alpha = 1 - fabs(distance/maxValue);
}
@end
