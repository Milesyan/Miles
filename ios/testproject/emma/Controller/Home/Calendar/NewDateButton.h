//
//  NewDateButton.h
//  emma
//
//  Created by Peng Gu on 9/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@class TinyCalendarView;
@class RotationLabels;


#define BUTTON_WIDTH_NORMAL (IS_IPHONE_6_PLUS ? 74.0 : (IS_IPHONE_6 ? 67.0 : 57.5))
#define BUTTON_WIDTH_CENTRAL (IS_IPHONE_6_PLUS ? 149 : (IS_IPHONE_6 ? 135 : 115))
#define BUTTONS_CENTER_Y 90
#define PAGE_INDEX_BASE 1000
#define TINY_CAL_WIDTH SCREEN_WIDTH

#define BUTTON_CENTER_SHIFT (IS_IPHONE_6_PLUS ? 33.5 : (IS_IPHONE_6 ? 30.5 : 26.0))
#define BUTTON_STEP (IS_IPHONE_6_PLUS ? 83 : (IS_IPHONE_6 ? 75 : 64))
#define TINY_PAGE_WIDTH BUTTON_STEP


@interface NewDateButton : UIView {
    NSAttributedString *attributedTips;
    NSMutableArray *attributedTipsArray;
}


@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSArray *tips;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;
@property (nonatomic, strong) UILabel *animateLabel;
@property (nonatomic, strong) RotationLabels *rotationTips;
@property (nonatomic, strong) UIView *breakLine;
@property (nonatomic) BOOL isNormal;

@property (nonatomic, strong) NSString *day;
@property (nonatomic, strong) NSString *weekday;

@property (nonatomic, weak) TinyCalendarView *parentCalendar;
@property (nonatomic) float percentageChance;
@property (nonatomic) NSInteger bmr;
@property (nonatomic) NSInteger calorieIn;
@property (nonatomic,strong) CAGradientLayer *glowLayer;


- (void)updateForPosition:(float)offsetX;
- (void)addTarget:(id)object action:(SEL)selector;
- (void)setBottomAnimateTip:(NSString *)tip;
- (void)hideBottomAnimateTip;
- (void)showAsNormalButton;
- (void)showAsCentralButton;

@end
