//
//  IOS67CompatibleUIButton.m
//  emma
//
//  Created by Xin Zhao on 13-10-21.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "IOS67CompatibleUIButton.h"

@implementation IOS67CompatibleUIButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (UIEdgeInsets)alignmentRectInsets {
    UIEdgeInsets insets;
    if (self.isRight) {
        insets = UIEdgeInsetsMake(-1.0f, 0, 0, 8.0f);
    }
    else { // IF_ITS_A_LEFT_BUTTON
        insets = UIEdgeInsetsMake(-1.0f, 8.0f, 0, 0);
    }
    return insets;
}

@end
