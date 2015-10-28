//
//  GLTheme.m
//  GLFoundation
//
//  Created by Allen Hsu on 8/27/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLTheme.h"
#import "NSObject+PubSub.h"

NSString * const GLStatusBarStyleSuccess = @"GLStatusBarStyleSuccess";
NSString * const GLStatusBarStyleError = @"GLStatusBarStyleError";
NSString * const GLStatusBarStyleWarning = @"GLStatusBarStyleWarning";

@implementation GLTheme

- (id)init {
    self = [super init];
    if (self) {
        _colorStyle = GLColorStyleLight;
    }
    return self;
}

#pragma mark - Font
+ (UIFont *)defaultFontForTableHeaderFooter:(CGFloat)fontSize {
    return [UIFont fontWithDescriptor:[UIFontDescriptor fontDescriptorWithFontAttributes:@{@"NSCTFontUIUsageAttribute" : UIFontTextStyleBody,
                                           @"NSFontNameAttribute" : @"ProximaNova-Regular"}]
                          size:fontSize];
}

+ (UIFont *)defaultFont:(CGFloat)fontSize {
    return [UIFont fontWithName:@"ProximaNova-Regular" size:fontSize];
}

+ (UIFont *)boldFont:(CGFloat)fontSize {
    return [UIFont fontWithName:@"ProximaNova-Bold" size:fontSize];
}

+ (UIFont *)lightFont:(CGFloat)fontSize {
    return [UIFont fontWithName:@"ProximaNova-Light" size:fontSize];
}

+ (UIFont *)semiBoldFont:(CGFloat)fontSize {
    return [UIFont fontWithName:@"ProximaNova-Semibold" size:fontSize];
}

- (void)setColorStyle:(GLColorStyle)colorStyle {
    if (_colorStyle != colorStyle) {
        _colorStyle = colorStyle;
        [self publish:EVENT_COLOR_STYLE_DID_CHANGE];
    }
}

@end
