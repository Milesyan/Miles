//
//  CMPopTipView+Glow.m
//  emma
//
//  Created by Peng Gu on 9/4/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLTheme.h>
#import "CMPopTipView+Glow.h"

@implementation CMPopTipView (Glow)

- (void)customize
{
    self.hasGradientBackground = NO;
    self.has3DStyle = NO;
    self.hasShadow = NO;
    self.borderWidth = 0;
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    self.textFont = [GLTheme defaultFont:14];
    self.textColor = [UIColor whiteColor];
    self.pointerSize = 6;
    self.topMargin = 0;
}

@end
