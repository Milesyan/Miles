//
//  CalendarCell.m
//  emma
//
//  Created by Peng Gu on 9/24/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "CalendarCell.h"
#import "TinyCalendarView.h"
#import "CKCalendarView.h"
#import "UserDailyData.h"
#import "User.h"
#import "ButtonHalo.h"
#import "UIImage+blur.h"
#import "UIImage+Resize.h"
#import <GLCommunity/ForumEvents.h>

#define kMotionDiffHorizontal   20.0
#define kMotionDiffVertical     30.0

#define kbackgroundImageViewBottomOffset 60.0

#define animationDuration 0.5

@interface CalendarCell ()

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *calendarConstraintHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *calendarConstraintTop;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tinyCalendarConstraintTop;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *indicatorConstraintTop;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *containerConstraintTop;

@end


@implementation CalendarCell


- (void)setupViews
{
    self.contentView.clipsToBounds = NO;
    self.contentView.superview.clipsToBounds = NO;
    
    [self.indicator.layer setCornerRadius:15];
    [self.indicator.superview bringSubviewToFront:self.indicator];
    
    self.calendar.selectedDate = self.selectedDate;
    self.calendar.legends.alpha = 0;
    self.calendar.legends.center = CGPointMake(SCREEN_WIDTH/2, CALENDAR_HEIGHT+15);
    self.calendarConstraintHeight.constant = CALENDAR_HEIGHT;
    self.calendarConstraintTop.constant = -(CALENDAR_HEIGHT + 50);
    
    self.showFullCalendar = NO;
    [self subscribe:EVENT_APP_BECOME_ACTIVE selector:@selector(startTinyCalendarCenterButtonTipsRotation)];
    [self subscribe:EVENT_APP_BECOME_INACTIVE selector:@selector(stopTinyCalendarCenterButtonTipsRotation)];
    [self subscribe:EVENT_BACKGROUND_IMAGE_CHANGED selector:@selector(backgroundImageChanged:)];
    
    User * u = [User currentUser];
    UIImage * backgroundImg = nil;
    if (u && u.settings) {
        backgroundImg = u.settings.backgroundImage;
    }
    if (!backgroundImg) {
        backgroundImg = [UIImage imageNamed:@"home-babies.jpeg"];
    }
    [self setBackgroundImage:backgroundImg];
    self.backgroundBlurredImageView.hidden = YES;
}

- (void)layoutTinyCalendar
{
    if (!self.showFullCalendar) {
        [self.tinyCalendar setNeedsLayout];
        [self.tinyCalendar layoutIfNeeded];
        [self.tinyCalendar scrollEnded:NO];
        [self.tinyCalendar startCalculationAnimation];
    }
}


- (CGFloat)cellHeight
{
    return self.showFullCalendar ? CALENDAR_HEIGHT : TINY_CAL_HEIGHT;
}


- (void)moveToDate:(NSDate *)date animated:(BOOL)animated
{
    if (animated) {
        [self.calendar moveCalendarToDate:date animated:self.showFullCalendar];
        [self.tinyCalendar moveToDate:date animated:!self.showFullCalendar];
    }
    else {
        [self.calendar moveCalendarToDate:date animated:NO];
        [self.tinyCalendar moveToDate:date animated:NO];
    }
}


- (void)updateCalendarCellMask
{
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    float h = !self.showFullCalendar? CALENDAR_HEIGHT: TINY_CAL_HEIGHT;
    CGRect maskRect = CGRectMake(0, -h, SCREEN_WIDTH, CALENDAR_HEIGHT + TINY_CAL_HEIGHT);
    CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
    maskLayer.path = path;
    CGPathRelease(path);
    self.layer.mask = maskLayer;
}

- (void)pullDownWithDistance:(CGFloat)distance maxValue:(CGFloat)maxValue;
{
    float progress = distance / maxValue;
    [self.tinyCalendar updateButtonsForPulling:progress];
    self.indicatorArrow.transform = CGAffineTransformMakeRotation( progress * M_PI + M_PI);
    
    CGFloat height = self.showFullCalendar ? CALENDAR_HEIGHT : TINY_CAL_HEIGHT;
    
    self.backgroundImageConstraintBottom.constant = height + kbackgroundImageViewBottomOffset + distance;

    CGFloat offset = MIN(distance, height);
    self.containerConstraintTop.constant = offset;

    if (!self.showFullCalendar) {
        if(distance == 0){
            self.tinyCalendar.halo.hidden = NO;
        }else{
            self.tinyCalendar.halo.hidden = YES;
        }
        self.backgroundButton.transform = CGAffineTransformMakeTranslation(0, distance);
    }
}

- (void)updateAlphaTo:(CGFloat)alpha animated:(BOOL)animated;
{
    UIImageView *imageView = self.showFullCalendar? self.backgroundBlurredImageView : self.backgroundImageView;
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.alpha = alpha;
            imageView.alpha = alpha;
        } completion:nil];
    } else {
        self.alpha = alpha;
        imageView.alpha = alpha;
    }
}


#pragma mark - tiny calendar center button tips
- (void)startTinyCalendarCenterButtonTipsRotation
{
    if (!self.showFullCalendar) {
        if (![self.tinyCalendar isCalculating])
        {
            [self.tinyCalendar startCenterButtonTipsRotation];
        }
    }
}

- (void)stopTinyCalendarCenterButtonTipsRotation
{
    [self.tinyCalendar stopCenterButtonTipsRotation];
}

- (void)switchToFullCalendarView:(BOOL)animated
{
    [self showBlurredBackgroundImage];

    self.showFullCalendar = YES;
    if (animated) {
        self.isSwitchingCalendar = YES;
        
        [self layoutIfNeeded];
        [self.backgroundImageView.superview layoutIfNeeded];
        
        [UIView animateWithDuration:animationDuration
                              delay:0
             usingSpringWithDamping:0.9
              initialSpringVelocity:3
                            options:0
                         animations:^{
                             self.calendarConstraintTop.constant = 0;
                             self.tinyCalendarConstraintTop.constant = - (CALENDAR_HEIGHT + 50);
                             self.indicatorConstraintTop.constant = TINY_CAL_HEIGHT - CALENDAR_HEIGHT - 50;
        
                             self.backgroundImageConstraintBottom.constant = CALENDAR_HEIGHT + kbackgroundImageViewBottomOffset;
                             
                             [self.backgroundImageView.superview layoutIfNeeded];
                             [self layoutIfNeeded];
                             
                             self.backgroundButton.alpha = 0.0;

                         }
                         completion:^(BOOL finished){
                             self.backgroundButton.hidden = YES;
                             [self switchToFullCalendarView:NO];
                             self.isSwitchingCalendar = NO;
                         }];
    } else {
        // [Logging log:PAGE_IMP_HOME_CK_CAL];
        self.calendarConstraintTop.constant = 0;
        self.tinyCalendarConstraintTop.constant = -(TINY_CAL_HEIGHT + 50);
        self.indicatorConstraintTop.constant = -50;
        [self layoutIfNeeded];
        
        self.tinyCalendar.halo.hidden = YES;
        [self.calendar showLegends];
        [self publish:EVENT_SWITCHED_TO_FULL_CALENDAR];
    }
    // seems the tiny calendar animation is not correct
    // we should put below line in place <1>, but put here to see if tiny
    // calendar animation is fixed or not
    [self stopTinyCalendarCenterButtonTipsRotation];
}


- (void)switchToTinyCalendarView:(BOOL)animated
{
    [self hideBlurredBackgroundImage];

    self.showFullCalendar = NO;
    self.tinyCalendar.halo.hidden = NO;
    if (animated) {
        self.isSwitchingCalendar = YES;
        
        [self.calendar hideLegends];
        
        self.backgroundButton.hidden = NO;
        
        [self layoutIfNeeded];
        [self.backgroundImageView.superview layoutIfNeeded];
        
        [UIView animateWithDuration:animationDuration
                              delay:0
             usingSpringWithDamping:0.9
              initialSpringVelocity:3
                            options:0
                         animations:^{
            self.calendarConstraintTop.constant = -(CALENDAR_HEIGHT + 50);
            self.tinyCalendarConstraintTop.constant = 0;
            self.indicatorConstraintTop.constant = -self.indicator.height;
            self.backgroundImageConstraintBottom.constant = TINY_CAL_HEIGHT + kbackgroundImageViewBottomOffset;
            
            [self.backgroundImageView.superview layoutIfNeeded];
            [self layoutIfNeeded];
            
            self.backgroundButton.alpha = 1.0;

        } completion:^(BOOL finished) {
            [self switchToTinyCalendarView:NO];
            self.isSwitchingCalendar = NO;
        }];
        
    }
    else {
        // [Logging log:PAGE_IMP_HOME_TINY_CAL];
        //        self.calendarConstraintTop.constant = -(CALENDAR_HEIGHT + 50);
        self.tinyCalendarConstraintTop.constant = 0;
        [self layoutIfNeeded];
        [self publish:EVENT_SWITCHED_TO_TINY_CALENDAR];

    }
    [self startTinyCalendarCenterButtonTipsRotation];
}

- (void)showBlurredBackgroundImage
{
    self.backgroundBlurredImageView.hidden = NO;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.backgroundImageView.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         self.backgroundImageView.hidden = YES;
                     }];
    
}

- (void)hideBlurredBackgroundImage
{
    self.backgroundImageView.hidden = NO;
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.backgroundImageView.alpha = 1;
                     }
                     completion:^(BOOL finished){
                         self.backgroundBlurredImageView.hidden = YES;
                     }];
}

#pragma mark - background image

- (void)backgroundImageChanged:(Event *)event;
{
    [self setBackgroundImage:[User currentUser].settings.backgroundImage];
}

- (void)setBackgroundImage:(UIImage *)image
{
    if (image.size.height > 480 || image.size.width > 360) {
        image = [image resizeToBackgroundImage];
    }
    self.backgroundImageView.image = [image applyBlurWithRadius:1.0 tintColor:nil saturationDeltaFactor:1.0 maskImage:nil];
    self.backgroundBlurredImageView.image = [image applyBlurWithRadius:10.0 tintColor:nil saturationDeltaFactor:1.0 maskImage:nil];
}


@end





