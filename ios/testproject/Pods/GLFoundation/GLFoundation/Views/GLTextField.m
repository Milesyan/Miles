//
//  EmmaTextField.m
//  emma
//
//  Created by Allen Hsu on 1/3/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "GLTextField.h"
#import "UIColor+Utils.h"

@implementation GLTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.edgeInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.edgeInsets = UIEdgeInsetsZero;
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

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, self.edgeInsets)];
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [super editingRectForBounds:UIEdgeInsetsInsetRect(bounds, self.edgeInsets)];
}

- (void)setBorderColor:(UIColor *)borderColor width:(CGFloat)width
{
    self.layer.borderColor = borderColor.CGColor;
    self.layer.borderWidth = width;
}

- (void)setCornerRadius:(CGFloat)radius
{
    self.layer.cornerRadius = radius;
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
    _edgeInsets = edgeInsets;
    [self setNeedsLayout];
}

- (void)setupDefaultStyle
{
    [self setBorderColor:UIColorFromRGB(0xd5d5d2) width:1.0];
    [self setCornerRadius:5.0];
    [self setEdgeInsets:UIEdgeInsetsMake(5.0, 10.0, 5.0, 10.0)];
}

@end
