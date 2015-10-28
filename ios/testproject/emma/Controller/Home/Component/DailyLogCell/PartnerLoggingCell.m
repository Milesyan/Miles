//
//  PartnerLoggingCell.m
//  emma
//
//  Created by ltebean on 15-3-19.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "PartnerLoggingCell.h"
#import "UIView+Emma.h"
#import "User.h"
#import "DailyLogSummary.h"
#import "UIImage+Utils.h"
#import "UserDailyData.h"
#import "UIButton+BackgroundColor.h"
#import "DropdownMessageController.h"
#import "HomeCardHeaderView.h"

#define SUMMARY_STATUS_PREFIX @"PartnerSummaryStatus"
#define SUMMARY_STATUS_KEY [NSString stringWithFormat:@"%@%@", SUMMARY_STATUS_PREFIX, dailyData.date]

#define LAST_NUDGE_TIME_KEY [NSString stringWithFormat:@"last_nudge_time_%@", [User currentUser].id]

#define INFO_TEXT @"infoText"
#define BUTTON_TEXT @"buttonText"
#define BUTTON_TEXT_NUDGED @"buttonTextNudged"

static CGFloat const HEADER_HEIGHT = 30;
static CGFloat const NUDGE_BUTTON_HEIGHT = 43;

@interface PartnerLoggingCell()
@property (strong, nonatomic) UserDailyData* dailyData;
@property (weak, nonatomic) IBOutlet HomeCardHeaderView *headerView;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *summaryContainer;
@property (weak, nonatomic) IBOutlet UIView *emptyDataContainer;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;

@property (weak, nonatomic) IBOutlet UIView *summaryView;
@property (strong, nonatomic) DailyLogSummary *dailyLogSummary;
@property (weak, nonatomic) IBOutlet UIView *loadMoreView;
@property (weak, nonatomic) IBOutlet UIImageView *loadMoreArrow;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoLabelHeight;
@property (weak, nonatomic) IBOutlet UIButton *nudgeButton;
@property (nonatomic) BOOL nudged;
@property (strong, nonatomic) NSDictionary* text;

@end

@implementation PartnerLoggingCell

static NSDictionary *textForToday;

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.containerView addDefaultBorder];
    
    self.loadMoreArrow.image = [self.loadMoreArrow.image imageWithTintColor:GLOW_COLOR_PURPLE];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(1, 0, SCREEN_WIDTH - 18, 30);
    UIColor *color = [UIColor whiteColor];
    gradient.colors = @[(id)[[color colorWithAlphaComponent:0] CGColor], (id)color.CGColor];
    [self.loadMoreView.layer insertSublayer:gradient atIndex:0];
    self.loadMoreView.backgroundColor = [UIColor clearColor];

    
    self.profileImageView.layer.cornerRadius = self.profileImageView.width / 2;
    self.profileImageView.layer.masksToBounds = YES;
    
    [self subscribe:EVENT_DAILY_LOG_UNIT_CHANGED selector:@selector(dailyLogUnitChanged)];
    
    // clear text cache after logout
    [self subscribe:EVENT_USER_LOGGED_OUT selector:@selector(handelUserLogout:)];
}


# pragma mark - event handler

- (void)dailyLogUnitChanged
{
    [self.dailyLogSummary refresh];
}

- (void)handelUserLogout:(Event *)event
{
    textForToday = nil;
}

# pragma mark - ui helper
- (void)setInfoLableText:(NSString *)text
{
    self.infoLabel.attributedText = [[NSAttributedString alloc] initWithString:text attributes:[PartnerLoggingCell textAttributesWithCalculationMode:NO]];
    self.infoLabelHeight.constant = [self heightForInfoLabelWithText:text];
}

- (void)setNudgeButtonNudged
{
    [self setNudgeButtonTitle:[self textForEmptyView][BUTTON_TEXT_NUDGED]];
    self.nudgeButton.enabled = NO;
}

- (void)setNudgeButtonNormal
{
    [self setNudgeButtonTitle:[self textForEmptyView][BUTTON_TEXT]];
    self.nudgeButton.enabled = YES;
}

- (void)setNudgeButtonTitle:(NSString *)title
{
    NSString *buttonTitle = [NSString stringWithFormat:@"%@", title];
    [self.nudgeButton setTitle:buttonTitle forState:UIControlStateNormal];
    [self.nudgeButton setTitle:buttonTitle forState:UIControlStateHighlighted];
}

# pragma mark - update logic
- (void)setDate:(NSDate *)date
{
    _date = date;
    if (!self.user.partner) {
        return;
    }
    self.headerView.title = [NSString stringWithFormat:@"%@'s daily summary", self.user.partner.firstName ];
    self.nudged = NO;
    [self.user.partner loadProfileImage:^(UIImage *profileImage, NSError *err) {
        if (profileImage) {
            self.profileImageView.image = profileImage;
        } else {
            if (self.user.partner.status != USER_STATUS_TEMP) {
                self.profileImageView.image = [UIImage imageNamed:@"profile-empty"];
            } else {
                self.profileImageView.image = [UIImage imageNamed:@"profile-overlay-clear"];
            }
        }
    }];
    self.user.partner.dataStore = self.user.dataStore;
    self.dailyData = [UserDailyData getUserDailyData:[Utils dailyDataDateLabel:date]
                                                  forUser:self.user.partner];
    
    if (self.dailyData && [self.dailyData hasData]) {
        [self updateSummaryView];
    } else {
        self.text = [self textForEmptyView];
        [self updateEmptyDataView];
    }
}


- (void)updateSensitiveDataView
{
    self.summaryContainer.hidden = YES;
    self.emptyDataContainer.hidden = NO;
    [self setInfoLableText:[self sensitiveDataText]];
    self.nudgeButton.hidden = YES;
}

- (void)updateEmptyDataView
{
    self.summaryContainer.hidden = YES;
    self.emptyDataContainer.hidden = NO;

    [self setInfoLableText:self.text[INFO_TEXT]];
    
    if ([self isToday]) {
        self.nudgeButton.hidden = NO;
        if ([self hasNudged]) {
            [self setNudgeButtonNudged];
        } else {
            [self setNudgeButtonNormal];
        }
    } else {
        self.nudgeButton.hidden = YES;
    }
}



- (NSString *)summaryStatusKey
{
    return [NSString stringWithFormat:@"%@%@", SUMMARY_STATUS_PREFIX, self.dailyData.date];
}


- (void)updateSummaryView
{
    self.summaryContainer.hidden = NO;
    self.emptyDataContainer.hidden = YES;
    if (!self.dailyLogSummary) {
        self.dailyLogSummary = [[DailyLogSummary alloc] initWithDailyData:self.dailyData];
    }
    else {
        [self.dailyLogSummary setDailyData:self.dailyData];
    }
    
    if (self.dailyLogSummary.isAllDataSensitive) {
        [self updateSensitiveDataView];
        return;
    }
    UIView *summaryView = [self.dailyLogSummary getSummaryView];
    [self.summaryView addSubview:summaryView];
    
    self.loadMoreView.hidden = !self.dailyLogSummary.hasMore;
    if (!self.loadMoreView.hidden) {
        [self rotateLoadMoreArrow];
    }
}


- (void)rotateLoadMoreArrow
{
    if (![[Utils getDefaultsForKey:[self summaryStatusKey]] boolValue]) {
        self.loadMoreArrow.transform = CGAffineTransformIdentity;
    }
    else {
        self.loadMoreArrow.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI);
    }
}

# pragma mark - text config

- (NSString *)sensitiveDataText
{
    User *partner = self.user.partner;
    NSString *firstName = partner.firstName;
    if ([self isToday]) {
        return [NSString stringWithFormat:@"%@ logged today!", firstName];
    } else {
        return [NSString stringWithFormat:@"%@ logged on this day.", firstName];
    }
}

- (NSDictionary *)textForEmptyView
{
    User *partner = self.user.partner;
    NSString *firstName = partner.firstName;
    NSString *himOrHer = partner.pronoun;
    NSString *heOrShe = partner.isFemale ? @"she" : @"he";

    if (![self isToday]) {
        return @{
                 INFO_TEXT:[NSString stringWithFormat:@"%@ did not log on this day.", firstName],
                 BUTTON_TEXT:@"whatever",
                 BUTTON_TEXT_NUDGED:@"whatever"
                 };
    }
    // for today
    if (textForToday) {
        return textForToday;
    }
    NSArray *options = @[
                         @{
                             INFO_TEXT:[NSString stringWithFormat:@"%@ hasn’t logged today. Tell %@ to hop to it!", firstName, himOrHer],
                             BUTTON_TEXT:[NSString stringWithFormat:@"Nudge %@!", himOrHer],
                             BUTTON_TEXT_NUDGED:@"Nudged"
                         },
                         @{
                             INFO_TEXT:[NSString stringWithFormat:@"%@ hasn’t logged today. Send %@ a friendly nudge.", firstName, himOrHer],
                             BUTTON_TEXT:[NSString stringWithFormat:@"Nudge %@!", himOrHer],
                             BUTTON_TEXT_NUDGED:@"Nudged"
                         },
                         @{
                             INFO_TEXT:[NSString stringWithFormat:@"%@ hasn’t logged today. Do you think %@ has a good excuse?", firstName, heOrShe],
                             BUTTON_TEXT:[NSString stringWithFormat:@"Find out!"],
                             BUTTON_TEXT_NUDGED:@"Pinged"
                         },
                         @{
                             INFO_TEXT:[NSString stringWithFormat:@"%@ hasn’t logged today. Tell %@ to get a move on!", firstName, himOrHer],
                             BUTTON_TEXT:[NSString stringWithFormat:@"Ping %@ to log!", himOrHer],
                             BUTTON_TEXT_NUDGED:@"Pinged"
                         },
                         @{
                             INFO_TEXT:[NSString stringWithFormat:@"%@ hasn’t logged today. But it’s not too late...", firstName],
                             BUTTON_TEXT:[NSString stringWithFormat:@"Ping %@ to log!", himOrHer],
                             BUTTON_TEXT_NUDGED:@"Pinged"
                         }
                       ];
    NSUInteger randomIndex = arc4random() % options.count;
    textForToday = options[randomIndex];
    return textForToday;
}

# pragma mark - height calculation

- (CGFloat)heightForInfoLabelWithText:(NSString *)text
{
    CGFloat width = SCREEN_WIDTH - 8 * 2 - 15 * 2 - 60 - 12;
    CGFloat height = [text boundingRectWithSize:CGSizeMake(width, 500)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:[PartnerLoggingCell textAttributesWithCalculationMode:YES]
                                       context:nil].size.height;
    return MIN(64, height);
}

+ (NSDictionary *)textAttributesWithCalculationMode:(BOOL)isCalculationMode
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 3;
    paragraphStyle.lineBreakMode = isCalculationMode ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail;    return @{NSFontAttributeName: [Utils defaultFont:18], NSParagraphStyleAttributeName:paragraphStyle};
}

- (CGFloat)heightThatFits
{
    CGFloat height = 12 + HEADER_HEIGHT;
    
    if (self.dailyData.hasData) {
        if (self.dailyLogSummary.isAllDataSensitive) {
             return 169 - NUDGE_BUTTON_HEIGHT;
        }
        if (![self.dailyLogSummary hasMore]) {
            height += [self.dailyLogSummary getSummaryShortHeight];
        }
        else if ([[Utils getDefaultsForKey:[self summaryStatusKey]] boolValue]) {
            height += [self.dailyLogSummary getSummaryFullHeight];
        }
        else {
            height += [self.dailyLogSummary getSummaryShortHeight];
        }
        return height + 30;
    } else {
        if ([self isToday]) {
            return 169;
        } else {
            return 169 - NUDGE_BUTTON_HEIGHT;
        }
    }
}

# pragma mark - IBAction

- (IBAction)nudgeButtonPressed:(id)sender
{
    if (self.nudged) {
        return;
    }
    self.nudged = YES;
    [Logging log:BTN_CLK_HOME_NUDGE_PARTNER];
    [self shakeNudgeIcon];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setNudgeButtonNudged];
    });
    [[User currentUser] nudgePartner:^(BOOL success) {
        if (!success) {
            self.nudged = NO;
            [[DropdownMessageController sharedInstance] postMessage:@"Network down, please try again later." duration:2 inWindow:[GLUtils keyWindow]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self setNudgeButtonNormal];
            });
            return;
        }
        [Utils setDefaultsForKey:LAST_NUDGE_TIME_KEY withValue:[NSDate date]];
    }];
}

- (void)shakeNudgeIcon
{
    CGFloat duration = 0.5;
    CGFloat angle = 15 * M_PI / 180;
    CAKeyframeAnimation *wiggle = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    wiggle.values   = @[ @0.0, @(-angle), @(angle), @(-angle), @(angle), @0.0];
    wiggle.keyTimes = @[ @0.0, @0.2,  @0.4, @0.6, @0.8,  @1.0];
    wiggle.duration = duration;
    
    CAKeyframeAnimation *resize = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    resize.duration = 0.5;
    resize.values = @[@1.0, @1.5, @1.0];
    resize.keyTimes = @[@0.0, @0.5, @1.0];
    
    CAAnimationGroup *animGroup = [[CAAnimationGroup alloc] init];
    animGroup.animations = @[wiggle, resize];
    animGroup.duration = duration;
    
    
    [self.nudgeButton.imageView.layer addAnimation:animGroup forKey:@"shake"];
    
}

- (IBAction)loadMoreSummary:(id)sender {
    NSString *key = [self summaryStatusKey];
    BOOL dailyLogSummaryExpanded = [[Utils getDefaultsForKey:key] boolValue];
    dailyLogSummaryExpanded = !dailyLogSummaryExpanded;
    [Utils setDefaultsForKey:key withValue:@(dailyLogSummaryExpanded)];
    [self.delegate tableViewCellNeedsUpdateHeight:self];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self rotateLoadMoreArrow];
                     }
                     completion:NULL];
    
}

# pragma mark - helper

- (User *)user
{
    return [User currentUser];
}

- (BOOL)hasNudged
{
    NSDate *lastNudgeDate = [Utils getDefaultsForKey:LAST_NUDGE_TIME_KEY];
    if (!lastNudgeDate) {
        return NO;
    }
    if ([Utils date:lastNudgeDate isSameDayAsDate:[NSDate date]]) {
        return YES;
    }
    return NO;
}

- (BOOL)isToday
{
    return [Utils date:self.date isSameDayAsDate:[NSDate date]];
}

# pragma mark - dealloc
- (void)dealloc
{
    [self unsubscribeAll];
}

@end
