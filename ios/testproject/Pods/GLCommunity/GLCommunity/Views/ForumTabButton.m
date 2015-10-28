//
//  ForumTabButton.m
//  GLCommunity
//
//  Created by Allen Hsu on 11/3/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#define MAX_TITLE_WIDTH         90.0
#define MIN_BUTTON_WIDTH        42.0
#define TITLE_PADDING_TOP       3.0
#define TITLE_PADDING_RIGHT     8.0
#define TITLE_PADDING_BOTTOM    3.0
#define TITLE_PADDING_LEFT      8.0

#define BUTTON_HEIGHT_DIFF  5.0

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/UIImage+Utils.h>
#import "ForumTabButton.h"

@implementation ForumTabButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (UIImage *)backgroundImageWithTintColor:(UIColor *)tintColor
{
    UIImage *image = [UIImage imageNamed:@"gl-community-tab-tall"];
    image = [image imageWithTintColor:tintColor];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height / 2.0, 10.0, image.size.height / 2.0, 10.0)];
    return image;
}

//- (UIImage *)selectedBackgroundImageWithTintColor:(UIColor *)tintColor
//{
//    UIImage *image = [UIImage imageNamed:@"gl-community-tab-tall"];
//    image = [image imageWithTintColor:tintColor];
//    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height / 2.0, 10.0, image.size.height / 2.0, 10.0)];
//    return image;
//}

- (UIImage *)dimOverlayImage
{
    static UIImage *sImage = nil;
    if (!sImage) {
        UIImage *image = [UIImage imageNamed:@"gl-community-tab-tall-dim"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height / 2.0, 10.0, image.size.height / 2.0, 10.0)];
        sImage = image;
    }
    return sImage;
}

- (UIImage *)selectedOverlayImage
{
    static UIImage *sImage = nil;
    if (!sImage) {
        UIImage *image = [UIImage imageNamed:@"gl-community-tab-tall-overlay"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height / 2.0, 10.0, image.size.height / 2.0, 10.0)];
        sImage = image;
    }
    return sImage;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect bounds = CGRectMake(0.0, 0.0, frame.size.width, frame.size.height);
        CGRect titleFrame = UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(TITLE_PADDING_TOP, TITLE_PADDING_LEFT, TITLE_PADDING_BOTTOM, TITLE_PADDING_RIGHT));
        self.titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
        self.titleLabel.numberOfLines = 2;
        self.titleLabel.font = [GLTheme semiBoldFont:13.0];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        
        CGRect backgroundFrame = UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0.0, -3.0, 0.0, -3.0));
        self.background = [[UIImageView alloc] initWithFrame:backgroundFrame];
        self.background.image = [self backgroundImageWithTintColor:self.tintColor];
        self.background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.dimOverlay = [[UIImageView alloc] initWithFrame:backgroundFrame];
        self.dimOverlay.image = [self dimOverlayImage];
        self.dimOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//        self.selectedBackground = [[UIImageView alloc] initWithFrame:backgroundFrame];
//        self.selectedBackground.image = [self selectedBackgroundImageWithTintColor:self.tintColor];
//        self.selectedBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.selectedOverlay = [[UIImageView alloc] initWithFrame:backgroundFrame];
        self.selectedOverlay.image = [self selectedOverlayImage];
        self.selectedOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
//        self.selectedBackground.hidden = YES;
//        self.selectedOverlay.hidden = NO;
        
//        [self addSubview:self.selectedBackground];
        [self addSubview:self.background];
        [self addSubview:self.titleLabel];
        [self addSubview:self.selectedOverlay];
        [self addSubview:self.dimOverlay];
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.layer.shadowRadius = 0.5;
        self.layer.shadowOpacity = 0.4;
        self.layer.masksToBounds = NO;
    }
    return self;
}

- (void)sizeToFit
{
    if ([self.titleLabel.text rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location == NSNotFound) {
        self.titleLabel.numberOfLines = 1;
    } else {
        self.titleLabel.numberOfLines = 2;
    }
    if ([self.titleLabel.text isEqualToString:TAB_PLUS_SYMBOL]) {
        self.titleLabel.font = [GLTheme semiBoldFont:24.0];
    } else {
        self.titleLabel.font = [GLTheme semiBoldFont:13.0];
    }
    self.titleLabel.width = MAX_TITLE_WIDTH;
    [self.titleLabel sizeToFit];
    if (self.titleLabel.width > MAX_TITLE_WIDTH) {
        self.titleLabel.width = MAX_TITLE_WIDTH;
    }
    self.titleLabel.height = self.height - self.titleLabel.top - TITLE_PADDING_BOTTOM;
    self.width = MAX(MIN_BUTTON_WIDTH, self.titleLabel.right + TITLE_PADDING_RIGHT);
    self.titleLabel.left = ceilf((self.width - self.titleLabel.width) / 2.0);
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
//    self.dimOverlay.hidden = self.selected;
//    self.background.hidden = self.selected;
//    self.selectedOverlay.hidden = !self.selected;
//    self.selectedBackground.hidden = !self.selected;
//    self.background.hidden = NO;
    
    if (self.selected) {
//        self.titleLabel.alpha = 1.0;
        self.titleLabel.top = ceilf((self.height /*+ 3.0*/ - self.titleLabel.height) / 2.0); // Counting stripe height
        CGRect frame = self.background.frame;
        frame.origin.y = 0.0;
        frame.size.height = self.height;
        self.background.frame = frame;
//        self.background.top = 0.0;
//        self.background.height = self.height;
        self.dimOverlay.alpha = 0.0;
        self.dimOverlay.top = 0.0;
        self.selectedOverlay.alpha = 1.0;
        self.selectedOverlay.top = 0.0;
    } else {
//        self.titleLabel.alpha = 0.5;
        self.titleLabel.top = ceilf((self.height + BUTTON_HEIGHT_DIFF - self.titleLabel.height) / 2.0); // Counting top space
        CGRect frame = self.background.frame;
        frame.origin.y = BUTTON_HEIGHT_DIFF;
        frame.size.height = self.height - BUTTON_HEIGHT_DIFF;
        self.background.frame = frame;
        self.dimOverlay.alpha = 1.0;
        self.dimOverlay.top = BUTTON_HEIGHT_DIFF;
        self.selectedOverlay.alpha = 0.0;
        self.selectedOverlay.top = BUTTON_HEIGHT_DIFF;
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsLayout];
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    if (self.background) {
        self.background.image = [self backgroundImageWithTintColor:self.tintColor];
    }
}

@end
