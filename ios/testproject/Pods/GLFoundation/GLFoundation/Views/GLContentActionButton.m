//
//  ContentActionButton.m
//  emma
//
//  Created by Jirong Wang on 3/25/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "GLContentActionButton.h"
#import "GLTheme.h"
#import "UIColor+Utils.h"
#import "UIImage+Utils.h"

#define COLOR_BACKGROUND_PINK   UIColorFromRGB(0xe86a97)
#define COLOR_BACKGROUND_NORMAL UIColorFromRGB(0xf1f2f4)
#define COLOR_TEXT_GRAY         UIColorFromRGB(0x8f8f93)

@interface GLContentActionButton()

@property (nonatomic) UIImage * baseImage;
@property (nonatomic) UIImage * normalImage;
@property (nonatomic) UIImage * selectedImage;
@property (nonatomic) UIImageView * imageContainer;
@property (nonatomic) UILabel * textLabel;
@property (nonatomic) UIColor * bgColor;
@property (nonatomic) UIColor * selectedColor;

@property (nonatomic) NSString * normalText;
@property (nonatomic) NSString * selectedText;

@end

@implementation GLContentActionButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)initButtonWithReplyStyle {
    [self initButtonWithImage:@"gl-community-content-comment-btn.png" label:@"Reply" bgColor:COLOR_BACKGROUND_NORMAL selectedColor:COLOR_BACKGROUND_NORMAL];
    self.backgroundColor = self.bgColor;
}

- (void)initButtonWithCommentStyle {
    [self initButtonWithImage:@"gl-community-content-comment-btn.png" label:@"Comment" bgColor:COLOR_BACKGROUND_NORMAL selectedColor:COLOR_BACKGROUND_PINK];
    self.backgroundColor = self.bgColor;
}

- (void)initButtonWithLikeStyle {
    [self initButtonWithImage:@"gl-community-content-like-btn.png" label:@"Like" bgColor:COLOR_BACKGROUND_NORMAL selectedColor:COLOR_BACKGROUND_PINK];
    self.backgroundColor = self.bgColor;
    self.selectedText = @"Liked";
}

- (void)initButtonWithUpvoteStyle {
    [self initButtonWithImage:@"gl-community-content-like-btn.png" label:@"Upvote" bgColor:COLOR_BACKGROUND_NORMAL selectedColor:COLOR_BACKGROUND_PINK];
    self.backgroundColor = self.bgColor;
    self.selectedText = @"Upvoted";
}

- (void)initButtonWithShareStyle {
    [self initButtonWithImage:@"gl-community-content-share-btn.png" label:@"Share" bgColor:COLOR_BACKGROUND_NORMAL selectedColor:COLOR_BACKGROUND_PINK];
    self.backgroundColor = self.bgColor;
}

- (void)initButtonWithFlagStyle {
    [self initButtonWithImage:@"gl-community-content-flag-btn.png" label:@"Flag" bgColor:COLOR_BACKGROUND_NORMAL selectedColor:COLOR_BACKGROUND_PINK];
    self.backgroundColor = self.bgColor;
}

- (void)initButtonWithImage:(NSString *)imageName label:(NSString *)title bgColor:(UIColor *)bgColor selectedColor:(UIColor *)selectedColor {
    self.baseImage = [UIImage imageNamed:imageName];
    self.normalImage = [self.baseImage imageWithTintColor:COLOR_TEXT_GRAY];
    self.selectedImage = [self.baseImage imageWithTintColor:[UIColor whiteColor]];
    
    self.imageContainer = [[UIImageView alloc] initWithImage:self.normalImage];
    self.imageContainer.contentMode = UIViewContentModeCenter;
    // find the image view position
    CGFloat centerHeight = self.frame.size.height / 2.0;
    CGFloat y = centerHeight - self.normalImage.size.height / 2.0 + 0.5;
    self.imageContainer.frame = CGRectMake(10, y, self.normalImage.size.width, self.normalImage.size.height);
    
    // Text label
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 12, 12)];
    self.textLabel.font = [GLTheme defaultFont:12];
    self.textLabel.text = title;
    self.textLabel.textColor = COLOR_TEXT_GRAY;
    self.textLabel.contentMode = UIViewContentModeCenter;
    self.textLabel.backgroundColor = [UIColor clearColor];
    [self.textLabel sizeToFit];
    self.textLabel.frame = CGRectMake(15 + self.normalImage.size.width, y, self.textLabel.frame.size.width + 10, self.normalImage.size.height);
    
    self.normalText = title;
    self.selectedText = title;
    
    // colors
    self.bgColor = bgColor;
    self.selectedColor   = selectedColor;
    
    // modify self view
    self.layer.cornerRadius = 5;
    
    // clear self title
    [self setTitle:@"" forState:UIControlStateNormal];
    [self setTitle:@"" forState:UIControlStateSelected];
    
    [self addSubview:self.imageContainer];
    [self addSubview:self.textLabel];
    
    // self.selected = YES;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (self.selected) return;
    self.backgroundColor = highlighted ? self.selectedColor : self.bgColor;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.backgroundColor = selected ? self.selectedColor : self.bgColor;
    self.imageContainer.image = selected ? self.selectedImage : self.normalImage;
    self.textLabel.textColor = selected ? [UIColor whiteColor] : COLOR_TEXT_GRAY;
    self.textLabel.text = selected ? self.selectedText : self.normalText;
}

@end
