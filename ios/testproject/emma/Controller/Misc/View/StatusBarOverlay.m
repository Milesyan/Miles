//
//  StatusBarOverlay.m
//  emma
//
//  Created by Ryan Ye on 3/12/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "StatusBarOverlay.h"
#import "StatusBarOverlayViewController.h"
#import "User.h"

#define kStatusBarProgressColor         [UIColor colorWithRed:90.0/255.0 green:98.0/255.0 blue:210.0/255.0 alpha:1.0]
#define kStatusBarProgressBackground    [UIColor colorWithWhite:1.0 alpha:1.0]
#define kStatusBarBackground            [UIColor colorWithWhite:0.4 alpha:1.0];

@interface MagicGlow : UIView {
    UIImageView *darkView;
    UIImageView *lightView;
    BOOL isAnimating;
}
@end

@implementation MagicGlow
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        darkView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 32)];
        darkView.image = [UIImage imageNamed:@"magicglow-dark"];
        [self addSubview:darkView];
        lightView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 32)];
        lightView.image = [UIImage imageNamed:@"magicglow-light"];
        lightView.alpha = 0.0;
        [self addSubview:lightView];
        self.hidden = YES;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)glow {
    self.hidden = NO;
    if (!isAnimating) {
        isAnimating = YES;
        [self animate];
    }
}

- (void)highlight {
    self.hidden = NO;
    [lightView.layer removeAllAnimations];
    lightView.alpha = 1.0;
    isAnimating = NO;
}

- (void)stopAndHide {
    [lightView.layer removeAllAnimations];
    self.hidden = YES;
    isAnimating = NO;
}

- (void)animate{
    CABasicAnimation* glowingAnimation;
    glowingAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    glowingAnimation.fromValue = @0;
    glowingAnimation.toValue = @1.0;
    glowingAnimation.duration = 0.75;
    glowingAnimation.autoreverses = YES;
    glowingAnimation.repeatCount = 999;
    [lightView.layer addAnimation:glowingAnimation forKey:@"glowingAnimation"];
}

@end

@interface StatusBarOverlay () {
    UILabel *messageLabel;
    BOOL active;
    NSTimer *messageTimer;
    UIActivityIndicatorView *spinner;
    MagicGlow *magicGlow;
    UIView *backgroundView;
    UIImageView *progressView;
}
- (void)messageExpired:(NSTimer *)timer;
- (void)setText:(NSString *)markdown;
- (void)subscribeGlobalEvents;
@end

@implementation StatusBarOverlay

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
        self.windowLevel = UIWindowLevelStatusBar+10.0f;
        self.frame = statusBarFrame;
		self.alpha = 0.f;
		self.hidden = YES;
        self.backgroundColor = [UIColor clearColor];
        backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
        [self addSubview:backgroundView];
        UIImage *barImage = [UIImage imageNamed:@"topnav-progress-glow"];
        barImage = [barImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, barImage.size.width - 1)];
        progressView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -5, 0, 30)];
        progressView.image = barImage;
        progressView.backgroundColor = [UIColor clearColor];
        progressView.hidden = YES;
        [self addSubview:progressView];
        magicGlow = [[MagicGlow alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
        [self addSubview:magicGlow];
        messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [Utils boldFont:13.0];
        messageLabel.textColor = [UIColor colorWithWhite:0.0 alpha:1.0];
        messageLabel.backgroundColor = [UIColor clearColor]; 
        [self addSubview:messageLabel];
        spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(5, 0, 20, 20)];
        spinner.hidesWhenStopped = YES;
        spinner.transform = CGAffineTransformMakeScale(0.7, 0.7);
        [self addSubview:spinner];
        active = NO;
        [self subscribeGlobalEvents];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return nil;
}

+ (StatusBarOverlay *)sharedInstance {
    static StatusBarOverlay *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[StatusBarOverlay alloc] init];
        StatusBarOverlayViewController *vc = [[StatusBarOverlayViewController alloc] init];
        _sharedInstance.backgroundColor = [UIColor clearColor];
        _sharedInstance.rootViewController = vc;
        
//        _sharedInstance.frame = [UIApplication sharedApplication].statusBarFrame;
    });
    return _sharedInstance;
}

- (void)subscribeGlobalEvents {
    @weakify(self)
    [self subscribe:EVENT_USER_SYNC_STARTED handler:^(Event *evt) {
        @strongify(self)
        [self postMessage:@"Syncing in progress..." options:StatusBarShowSpinner | StatusBarShowProgressBar];
        [self setProgress:0.0 animated:NO];
        [self setProgress:0.7 animated:YES duration:0.5];
        [Utils performInMainQueueAfter:0.75 callback:^{
            @strongify(self)
            [self setProgress:0.8 animated:YES duration:2.0];
        }];
    }];
    [self subscribe:EVENT_USER_SYNC_COMPLETED handler:^(Event *evt) {
        @strongify(self)
        [Utils performInMainQueueAfter:0.8 callback:^{
            @strongify(self)
            [self postMessage:@"Syncing completed." options:StatusBarShowProgressBar duration:2.0];
            [self setProgress:1.0 animated:YES duration:0.25];
        }];
    }];
    [self subscribe:EVENT_USER_SYNC_FAILED handler:^(Event *evt) {
        @strongify(self)
        [self postMessage:@"Failed to sync with server." duration:2.0];
    }];
}

- (void)postMessage:(NSString *)text {
    [self postMessage:text duration:999.f];
}

- (void)postMessage:(NSString *)text duration:(CGFloat)duration {
    [self postMessage:text options:0 duration:duration];
}

- (void)postMessage:(NSString *)text options:(int)options {
    [self postMessage:text options:options duration:999.0f];
}

- (void)textStyleNormal {
    messageLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    messageLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.0];
}

- (void)textStyleGlowing {
    messageLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    messageLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:.8];
}

- (void)postMessage:(NSString *)text options:(int)options duration:(CGFloat)duration {
    if (!active) {
        [self fadeIn];
    } 
    active = YES;
    BOOL showSpinner = options & StatusBarShowSpinner;
    if (showSpinner) {
        [spinner startAnimating];
    } else {
        [spinner stopAnimating];
    }
    if (options & StatusBarGlowing) {
        [self textStyleGlowing];
        [magicGlow glow];
    } else if (options & StatusBarHighlighted) {
        [self textStyleGlowing];
        [magicGlow highlight];
    } else {
        [self textStyleNormal];
        [magicGlow stopAndHide];
    }
    if (options & StatusBarShowProgressBar) {
        progressView.hidden = NO;
        backgroundView.backgroundColor = kStatusBarProgressBackground;
    } else {
        progressView.hidden = YES;
        backgroundView.backgroundColor = kStatusBarBackground;
    }
    backgroundView.hidden = options & StatusBarHideBackground;
    [self setText:text];
    if (messageTimer) {
        [messageTimer invalidate];
    }
    messageTimer = [NSTimer scheduledTimerWithTimeInterval:duration
                                target:self
                                selector:@selector(messageExpired:)
                                userInfo:nil
                                repeats:NO];
}

- (void)messageExpired:(NSTimer *)timer {
    active = NO;
    [magicGlow stopAndHide];
    [self fadeOut:0];
}

- (void)setText:(NSString *)text {
    messageLabel.text = text;
    [messageLabel sizeToFit];
    messageLabel.center = CGPointMake(SCREEN_WIDTH/2, 10);
    spinner.center = CGPointMake((SCREEN_WIDTH - messageLabel.frame.size.width) / 2 - 15, 10);
}

- (void)fadeIn {
    self.hidden = NO;
    self.alpha = 0.f;
    [UIView animateWithDuration:.5 animations:^() {
        self.alpha = 1.f;
    } completion:nil ];
}


- (void)fadeOut:(NSTimeInterval)delay {
    [UIView animateWithDuration:.5 delay:delay options:0 animations:^() {
        self.alpha = 0.f;
    } completion:^(BOOL finished) {
        self.hidden = YES;
        [spinner stopAnimating];
        [self setProgress:0.0 animated:NO];
    }];
}

- (void)clearText:(NSTimeInterval)delay {
    active = NO;
    [messageTimer invalidate];
    [self fadeOut:delay];
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    [self setProgress:progress animated:animated duration:0.5];
}

- (void)setProgress:(float)progress animated:(BOOL)animated duration:(NSTimeInterval)duration
{
    CGFloat width = (SCREEN_WIDTH + 50.0) * progress;
    CGRect frame = progressView.frame;
    frame.size.width = width;
    if (animated) {
        int options = UIViewAnimationCurveEaseOut;
        if (progressView.frame.size.width > 0.0f) {
            options |= UIViewAnimationOptionBeginFromCurrentState;
        }
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            progressView.frame = frame;
        } completion:nil];
    } else {
        progressView.frame = frame;
    }
}


@end
