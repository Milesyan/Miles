//
//  HomeCardOperationButton.m
//  emma
//
//  Created by ltebean on 15/5/19.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "HomeCardOperationButton.h"
#import "UIView+Emma.h"
#define spacing 50

@implementation HomeCardOperationButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    [self addDefaultBorder];
    [self setTitleColor:UIColorFromRGB(0xb9bbdd) forState:UIControlStateDisabled];
    [self setTitleColor:UIColorFromRGB(0x3f47ae) forState:UIControlStateHighlighted];
}

@end
