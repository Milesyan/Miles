//
//  PillButton.h
//  emma
//
//  Created by Eric Xu on 2/22/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "PairButton.h"
#define FONT_SIZE 15

#define EVENT_PILLBUTTON_ANIMATION_END @"pillbutton_animation_end"

@interface PillButton : PairButton
@property (nonatomic, retain) NSString *iconName;
@property (nonatomic, strong) UIColor *buttonColor;
@property (readonly) BOOL inAnimation;
@property (nonatomic) BOOL noAnimate;
@property (nonatomic, weak) id assistant;

- (id)initWithIcon:(NSString *)iconName label:(NSString *) label tintColor:(UIColor *)color;
- (id)initAndLayoutWithTitle:(NSString *)title tintColor:(UIColor *)color
    offset:(CGSize)offset;
- (void)setLabelMarkdown:(NSString *)markdown;
- (void)setLabelText:(NSString *)text bold:(BOOL)bold;
- (void)animateOff;
- (void)toggle:(BOOL)animated;
- (void)setSelected: (BOOL)selected animated:(BOOL)animated;
@end


@class ExclusivePillButtonGroup;

@interface GroupedPillButton : PillButton
@property (nonatomic, strong) id groupValue;
@property (nonatomic, weak) ExclusivePillButtonGroup *group;
@end

@protocol ExclusivePillButtonGroupDelegate <NSObject>
- (void)pillButtonDidChange:(GroupedPillButton *)button;
@end

@interface ExclusivePillButtonGroup : NSObject

@property (nonatomic, strong) id<ExclusivePillButtonGroupDelegate> delegate;

- (void)addButton:(GroupedPillButton *)button;
- (void)removeAll;
- (void)onSelectedButton:(GroupedPillButton *)selected;
- (id)getGroupValue;

@end