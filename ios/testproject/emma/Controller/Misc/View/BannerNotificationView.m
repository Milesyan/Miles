//
//  BannerNotificationView.m
//  emma
//
//  Created by Peng Gu on 7/8/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "BannerNotificationView.h"
#import <QuartzCore/QuartzCore.h>
#import "Utils.h"
#import "Logging.h"
#import <GLFoundation/GLUtils.h>

#define WINDOW_WIDTH [UIScreen mainScreen].bounds.size.width
#define DEFAULT_HEIGHT 108
#define DEFAULT_ANIMATION_DURATION 0.6
#define DEFAULT_PAN_VELOCITY 300


@interface BannerNotificationView ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@property (assign, nonatomic) CGFloat height;
@property (assign, nonatomic) BOOL isDismissing;
@property (assign, nonatomic) CGPoint panBeganPoint;

@end


@implementation BannerNotificationView


+ (BOOL)isShowingNotification
{
    UIWindow *keyWindow = [GLUtils keyWindow];
    for (UIView *view in keyWindow.subviews) {
        if ([view isKindOfClass:[self class]]) {
            return YES;
        }
    }
    return NO;
}


- (instancetype)initFromNib
{
    self = [[[NSBundle mainBundle] loadNibNamed:@"BannerNotification" owner:self options:nil] firstObject];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.85];
        
        self.actionButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.actionButton.layer.borderWidth = 1;
        self.actionButton.layer.cornerRadius = 5;
        self.actionButton.clipsToBounds = YES;
        [self.actionButton addTarget:self
                              action:@selector(actionButtonClicked:)
                    forControlEvents:UIControlEventTouchUpInside];
        
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:self.label.text];
        NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
        [paragrahStyle setLineSpacing:2];
        [attrString addAttribute:NSParagraphStyleAttributeName
                           value:paragrahStyle
                           range:NSMakeRange(0, self.label.text.length)];
        
        NSRange boldRange = [self.label.text rangeOfString:@"Glow Nurture"];
        [attrString addAttribute:NSFontAttributeName value:[Utils boldFont:15] range:boldRange];
        
        self.label.attributedText = attrString;
        
        self.height = DEFAULT_HEIGHT;
        self.frame = [self frameBeforeShowing];
        
        [self setupGestures];
    }
    return self;
}


- (instancetype)initFromNibWithTapAction:(TapAction)action
{
    self = [self initFromNib];
    if (self) {
        self.tapAction = action;
    }
    return self;
}


- (instancetype)initWithImage:(UIImage *)image message:(NSString *)message actionTitle:(NSString *)action
{
    // Reserved for general use later on
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You haven't implemented %@ method.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}


- (void)dealloc
{
}


- (CGRect)frameBeforeShowing
{
    return CGRectMake(0, -self.height, WINDOW_WIDTH, self.height);
}


- (CGRect)frameAfterShowing
{
    return CGRectMake(0, 0, WINDOW_WIDTH, self.height);
}


- (BOOL)show
{
    // Only show one notification at one time
    if ([BannerNotificationView isShowingNotification]) {
        return NO;
    }
    
    UIWindow *keyWindow = [GLUtils keyWindow];
    [keyWindow addSubview:self];
    
    [UIView animateWithDuration:DEFAULT_ANIMATION_DURATION animations:^{
        self.frame = [self frameAfterShowing];
    }];
    
    [Logging log:PAGE_IMP_PREGNANT];
    
    return YES;
}


- (void)dismissWithDelay:(NSTimeInterval)delayInSeconds duration:(NSTimeInterval)duration
{
    if (self.isDismissing) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isDismissing = YES;
        
        [UIView animateWithDuration:duration animations:^{
            self.frame = [self frameBeforeShowing];
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            [Logging log:BTN_CLK_PROMO_PREGNANCY_DISMISS];
        }];
    });
}


#pragma mark - Gestures
- (void)setupGestures
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.minimumNumberOfTouches = 1;
    pan.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:pan];
}


- (void)handlePan:(UIPanGestureRecognizer *)panGesture
{
    CGPoint translatedPoint = [panGesture translationInView:self];

    if (panGesture.state == UIGestureRecognizerStateBegan) {
        self.panBeganPoint = translatedPoint;
    }
    else if (panGesture.state == UIGestureRecognizerStateEnded) {
        if (translatedPoint.y < self.panBeganPoint.y && self.panBeganPoint.y < 0) {
            // calculate duration depends on how fast the user pan
            CGFloat velocity = MAX(DEFAULT_PAN_VELOCITY, fabsf([panGesture velocityInView:self].y));
            CGFloat duration = DEFAULT_ANIMATION_DURATION * DEFAULT_PAN_VELOCITY / velocity;
            [self dismissWithDelay:0 duration:duration];
        }
    }
}


- (void)handleSingleTap:(UITapGestureRecognizer *)tapGesture
{
    [self actionButtonClicked:self];
}


#pragma mark - action Button 

- (void)actionButtonClicked:(id)sender
{
    if (self.tapAction) {
        self.tapAction();
        [Logging log:BTN_CLK_PROMO_PREGNANCY_INSTALL];
    }
    else {
        [self dismissWithDelay:0 duration:DEFAULT_ANIMATION_DURATION];
    }
}

@end




