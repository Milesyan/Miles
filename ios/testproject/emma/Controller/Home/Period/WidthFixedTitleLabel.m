//
//  WidthFixedTitleLabel.m
//  emma
//
//  Created by ltebean on 15-3-30.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "WidthFixedTitleLabel.h"

@implementation WidthFixedTitleLabel

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setFrame:(CGRect)frame
{
    CGFloat x = (SCREEN_WIDTH - self.frame.size.width) / 2;
    [super setFrame:CGRectMake(x, frame.origin.y, self.frame.size.width, frame.size.height)];
}
@end
