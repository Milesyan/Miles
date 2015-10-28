//
//  RatingCell.m
//  emma
//
//  Created by ltebean on 15-5-6.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "RatingCell.h"
#import "Sendmail.h"
#import "UIView+Emma.h"

#define KEY_RATING_CARD_ALREADY_SHOWN @"rating_card_already_shown"
#define KEY_LAUNCH_TIMES @"rating_card_launch_times"
#define KEY_FIRST_LAUCH_TIME @"rating_card_first_launch_time"

typedef NS_ENUM(NSInteger, STATE) {
    STATE_INITIAL,
    STATE_ENJOY,
    STATE_NOT_ENJOY
};

@interface RatingCell()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (nonatomic) STATE state;
@end

@implementation RatingCell

+ (BOOL)needsShow
{
    if ([Utils getDefaultsForKey:KEY_RATING_CARD_ALREADY_SHOWN]) {
        return NO;
    }
    NSDate *firstLaunch = [Utils getDefaultsForKey:KEY_FIRST_LAUCH_TIME];
    NSNumber *launchTimes = [Utils getDefaultsForKey:KEY_LAUNCH_TIMES];
    if (!firstLaunch || !launchTimes) {
        return NO;
    }
    if ([launchTimes intValue] < 5) {
        return NO;
    }
    if ([Utils daysBeforeDate:[NSDate date] sinceDate:firstLaunch] < 10) {
        return NO;
    }
    return YES;
}

+ (void)logLaunch
{
    // first launch date
    NSDate *firstLaunch = [Utils getDefaultsForKey:KEY_FIRST_LAUCH_TIME];
    if (!firstLaunch) {
        [Utils setDefaultsForKey:KEY_FIRST_LAUCH_TIME withValue:[NSDate date]];
    }
    NSNumber *launchTimes = [Utils getDefaultsForKey:KEY_LAUNCH_TIMES];
    int _ltimes = launchTimes ? [launchTimes intValue] : 0;
    [Utils setDefaultsForKey:KEY_LAUNCH_TIMES withValue:@(_ltimes + 1)];
}

- (void)awakeFromNib {
    // Initialization code
    [self.containerView addDefaultBorder];

    self.rightButton.layer.cornerRadius = self.leftButton.height / 2;
    self.rightButton.layer.masksToBounds = YES;
    
    self.leftButton.layer.borderWidth = 2;
    self.leftButton.layer.borderColor = GLOW_COLOR_PURPLE.CGColor;
    self.leftButton.layer.cornerRadius = self.leftButton.height / 2;
    self.leftButton.layer.masksToBounds = YES;
    
    self.state = STATE_INITIAL;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)leftButtonPressed:(id)sender
{
    if (self.state == STATE_INITIAL) {
        [Logging log:BTN_CLK_RATING_CARD_NOT_ENJOY];
        self.state = STATE_NOT_ENJOY;
        return;
    }
    if (self.state == STATE_NOT_ENJOY) {
        [Logging log:BTN_CLK_RATING_CARD_NOT_SEND_FEEDBACK];
        [self dismiss];
        return;
    }
    if (self.state == STATE_ENJOY) {
        [Logging log:BTN_CLK_RATING_CARD_NOT_RATE_US];
        [self dismiss];
        return;
    }
}

- (IBAction)rightButtonPressed:(id)sender
{
    if (self.state == STATE_INITIAL) {
        self.state = STATE_ENJOY;
        [Logging log:BTN_CLK_RATING_CARD_ENJOY];
        return;
    }
    if (self.state == STATE_NOT_ENJOY) {
        [Logging log:BTN_CLK_RATING_CARD_SEND_FEEDBACK];
        [self dismiss];
        [self goToFeedbackPage];
        return;
    }
    if (self.state == STATE_ENJOY) {
        [Logging log:BTN_CLK_RATING_CARD_RATE_US];
        [self dismiss];
        [self goToRatePage];
        return;
    }
}

- (void)setState:(STATE)state
{
    _state = state;
    [UIView animateWithDuration:1 animations:^{
        if (state == STATE_ENJOY) {
            self.label.text = @"How about a rating on the App Store, then?";
            [self.leftButton setTitle:@"No, thanks" forState:UIControlStateNormal];
            [self.rightButton setTitle:@"Ok, sure" forState:UIControlStateNormal];
        }
        else if (state == STATE_NOT_ENJOY) {
            self.label.text = @"Would you mind giving us some feedback?";
            [self.leftButton setTitle:@"No, thanks" forState:UIControlStateNormal];
            [self.rightButton setTitle:@"Ok, sure" forState:UIControlStateNormal];
        }
    }];
}

- (void)setAlreadyShown
{
    [Utils setDefaultsForKey:KEY_RATING_CARD_ALREADY_SHOWN withValue:@(YES)];
}

- (void)dismiss
{
    [Utils setDefaultsForKey:KEY_RATING_CARD_ALREADY_SHOWN withValue:@(YES)];
    [self.delegate ratingCellNeedsDismiss:self];
}

- (void)goToFeedbackPage
{
    [[Sendmail sharedInstance] composeTo:@[FEEDBACK_RECEIVER] subject:@"" body:@"" inViewController:self.viewController];
}

- (void)goToRatePage
{
    NSString * url = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&type=Purple+Software", APP_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

@end
