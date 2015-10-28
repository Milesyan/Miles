//
//  ForumGroupButton.m
//  emma
//
//  Created by Allen Hsu on 9/1/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ForumGroupButton.h"
#import <Masonry/Masonry.h>
#import <GLFoundation/UIImage+Blur.h>
#import <GLFoundation/UIImage+Utils.h>

@implementation ForumGroupButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    self.arrowImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 5.0, 12.0, 12.0)];
    self.arrowImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.arrowImage setHighlightedImage:[[UIImage imageNamed:@"gl-community-log-arrow"] imageWithTintColor:UIColorFromRGB(0xf8f8f8)]];
    [self addSubview:self.arrowImage];
    [self.arrowImage mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-3);
        make.width.equalTo(@12);
        make.height.equalTo(@12);
        make.centerY.equalTo(self);
    }];
    
    UIImage *backgroundImage = [UIImage imageWithColor:UIColorFromRGB(0xf8f8f8) andSize:self.frame.size];
    [self setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
    [self setBackgroundImage:backgroundImage forState:UIControlStateSelected];
    
    [self setTitleColor:UIColorFromRGB(0x424344) forState:UIControlStateHighlighted];
    [self setTitleColor:UIColorFromRGB(0x424344) forState:UIControlStateSelected];
}


- (void)setThemeColor:(UIColor *)color
{
    [self setTitleColor:color forState:UIControlStateNormal];
//    [self setBackgroundColor:[color brighterAndUnsaturatedColor]];
    
    [self.arrowImage setImage:[[UIImage imageNamed:@"gl-community-log-arrow"] imageWithTintColor:color]];
}


- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self.arrowImage setHighlighted:highlighted];
}


- (CGSize)intrinsicContentSize
{
    CGSize original = [super intrinsicContentSize];
    original.width += 20;
    return original;
}

@end
