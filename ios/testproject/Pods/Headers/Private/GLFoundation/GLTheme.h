//
//  GLTheme.h
//  GLFoundation
//
//  Created by Allen Hsu on 8/27/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIColor+Utils.h"

#define GLOW_COLOR_PURPLE UIColorFromRGB(0x5a62d2)
#define GLOW_COLOR_LIGHT_PURPLE UIColorFromRGB(0xabaae3)
#define GLOW_COLOR_GREEN UIColorFromRGB(0x73bd37)

#define FORUMCELL_BG_ODD UIColorFromRGB(0xfbfaf6)
#define FORUMCELL_BG_EVEN UIColorFromRGB(0xf6f5f0)

#define EVENT_COLOR_STYLE_DID_CHANGE            @"event_color_style_did_change"

extern NSString * const GLStatusBarStyleSuccess;
extern NSString * const GLStatusBarStyleError;
extern NSString * const GLStatusBarStyleWarning;

typedef NS_ENUM(NSUInteger, GLColorStyle) {
    GLColorStyleLight,
    GLColorStyleDark,
};

@interface GLTheme : NSObject

@property (assign, nonatomic) GLColorStyle colorStyle;
- (void)setColorStyle:(GLColorStyle)colorStyle;

+ (UIFont *)defaultFontForTableHeaderFooter:(CGFloat)fontSize;
+ (UIFont *)defaultFont:(CGFloat)fontSize;
+ (UIFont *)boldFont:(CGFloat)fontSize;
+ (UIFont *)lightFont:(CGFloat)fontSize;
+ (UIFont *)semiBoldFont:(CGFloat)fontSize;

@end
