//
//  PillButton.m
//  emma
//
//  Created by Eric Xu on 2/22/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "PillButton.h"

#define BUTTON_HEIGHT 36
#define FONT_SIZE 15
#define PADDING_LEFT 14
#define PADDING_MIDDLE 5

#define BORDER_WIDTH 2.0

@interface PillButton() {
    BOOL bgImageInitialized;
}
- (void)setup;
@end

@implementation PillButton

@synthesize inAnimation = _inAnimation;

- (id)initWithIcon:(NSString *)iconName label:(NSString *) labelText tintColor:(UIColor *)color
{
    self = [super init];
    if (self) {
        [self setup];
        [self setTitle:labelText forState:UIControlStateNormal];
        [self setTitleColor:color forState:UIControlStateNormal];
        self.iconName = iconName;
    }
    return self;
}

- (id)initAndLayoutWithTitle:(NSString *)title
                   tintColor:(UIColor *)color
                      offset:(CGSize)offset
{
    self = [self initWithIcon:nil label:title tintColor:color];
    if (self) {
        CGSize size = [self.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: self.titleLabel.font}];
        self.frame = CGRectMake(0, 0, roundf(size.width+2*offset.width), roundf(size.height+2*offset.height));
        [self updateBackgroundImage];
    }
    int pause = 0;
    pause++;
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        UIImage *image = [self imageForState:UIControlStateNormal];
        if (image) {
            [self setImage:[Utils image:image withColor:self.buttonColor] forState:UIControlStateNormal];
            [self setImage:[Utils image:image withColor:[UIColor whiteColor]] forState:UIControlStateSelected];
            [self setImage:[Utils image:image withColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
        }
        [self setup];
        [self updateBackgroundImage];
    }
    return self;
}

- (void)setup {
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    self.adjustsImageWhenHighlighted = NO;
    self.backgroundColor = [UIColor clearColor];
    BOOL boldInXib = [self.titleLabel.font.fontName isEqual:@"ProximaNova-Bold"];
    self.titleLabel.font = boldInXib ? [Utils boldFont:FONT_SIZE]
        : [Utils defaultFont:FONT_SIZE];
    self.exclusiveTouch = YES;
    [self addTarget:self action:@selector(buttonUp) forControlEvents:UIControlEventTouchUpInside];
    [self setClipsToBounds:YES];
}

- (void)setIconName:(NSString *)iconName {
    if (iconName && [iconName length] > 0) {
        UIImage *img = [UIImage imageNamed:iconName];
        [self setImage:[Utils image:img withColor:[UIColor whiteColor]] forState:UIControlStateSelected];
        [self setImage:[Utils image:img withColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
        [self setImage:[Utils image:img withColor:self.buttonColor] forState:UIControlStateNormal];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _iconName = iconName;
    }
    else {
        _iconName = nil;
        [self setImage:nil forState:UIControlStateNormal];
    }
}

- (UIColor *)buttonColor {
    return [self titleColorForState:UIControlStateNormal];
}

-(void)setButtonColor:(UIColor *)buttonColor
{
    [self setTitleColor:buttonColor forState:UIControlStateNormal];
    [bgImageCache removeAllObjects];
    bgImageInitialized = NO;
    [self updateBackgroundImage];
}

- (void)setLabelText:(NSString *)text bold:(BOOL) bold{
    self.titleLabel.font = bold ? [Utils boldFont:FONT_SIZE] : [Utils defaultFont:FONT_SIZE];
    [self setTitle:text forState:UIControlStateNormal];
    [self setTitle:text forState:UIControlStateSelected];
}

- (void)setLabelMarkdown:(NSString *)markdown {
    [self setAttributedTitle: [Utils markdownToAttributedText:markdown fontSize:FONT_SIZE color:self.buttonColor] forState:UIControlStateNormal];
    [self setAttributedTitle: [Utils markdownToAttributedText:markdown fontSize:FONT_SIZE color:[UIColor whiteColor]] forState:UIControlStateHighlighted];
    [self setAttributedTitle: [Utils markdownToAttributedText:markdown fontSize:FONT_SIZE color:[UIColor whiteColor]] forState:UIControlStateSelected];
}

- (void)setSelected: (BOOL)selected {
    [self setSelected:selected animated:NO];
}

- (void)setSelected: (BOOL)selected animated:(BOOL)animated {
    [super setSelected: selected];
    self.tintColor = selected ? [UIColor whiteColor] : self.buttonColor;
    if (selected && (self.iconName || [self imageForState:UIControlStateNormal]) && animated && !self.noAnimate) {
        [self animateIcon];
    }
}

-(void)animateIcon {
    self.hidden = YES;
    _inAnimation = YES;
    UIView *animatedButton = [[UIView alloc] initWithFrame:self.frame];
    animatedButton.layer.cornerRadius = self.frame.size.height/2;
    animatedButton.backgroundColor = self.buttonColor;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.imageView.bounds];
    imageView.image = [self imageForState:UIControlStateHighlighted];
    [animatedButton addSubview:imageView];
    [self.superview addSubview:animatedButton];
    [UIView animateWithDuration:0.1 animations:^{
        imageView.transform = CGAffineTransformMakeScale(2.5, 2.5);
    } completion:^(BOOL finished){
    [UIView animateWithDuration:0.1 animations:^{
        imageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [animatedButton removeFromSuperview];
        self.hidden = NO;
        GLLog(@"animateIcon done");
        _inAnimation = NO;
        [self publish:EVENT_PILLBUTTON_ANIMATION_END];
    }];
    }];
}

- (void)updateBackgroundImage {
    if (!bgImageInitialized && self.buttonColor && self.frame.size.height > 0) {
        [self setBackgroundImage:self.bgImageForNormal forState:UIControlStateNormal];
        [self setBackgroundImage:self.bgImageForSelected forState:UIControlStateHighlighted];
        [self setBackgroundImage:self.bgImageForSelected forState:UIControlStateSelected];
        bgImageInitialized = YES;
    }
}

- (void)toggle:(BOOL)animated
{
    [self setSelected:!self.selected animated:animated];
}

- (void)animateOff
{
    if(self.selected) {
        [self toggle:YES];
    }
}

- (void)buttonUp
{
    [self toggle:YES];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGFloat margin = 5.0;
    CGRect area = CGRectInset(self.bounds, -margin, -margin);
    return CGRectContainsPoint(area, point);
}

static NSMutableDictionary *bgImageCache = nil;
- (UIImage *)bgImageForNormal {
    if (!bgImageCache) {
        bgImageCache = [[NSMutableDictionary alloc] init];
    }
    CGFloat radius = self.bounds.size.height / 2.0;
    NSString *cacheKey = [NSString stringWithFormat:@"%f_%@_normal", radius, self.buttonColor];
    UIImage *bgImage = [bgImageCache objectForKey:cacheKey];
    if (!bgImage) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius * 2.0 + 1, radius * 2.0), NO, 0.0);
        CGFloat innerRadius = radius - BORDER_WIDTH;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, radius * 2.0 + 1, radius * 2) cornerRadius: radius];
        [self.buttonColor setFill];
        [path fill];
        UIBezierPath *innerPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(BORDER_WIDTH, BORDER_WIDTH, innerRadius * 2.0 + 1, innerRadius * 2) cornerRadius: innerRadius];
        [[UIColor whiteColor] setFill];
        [innerPath fill];

        bgImage =  UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        bgImage = [bgImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, radius, 0, radius)];
        [bgImageCache setObject:bgImage forKey:cacheKey];
    }
    return bgImage;
}

- (UIImage *)bgImageForSelected {
    if (!bgImageCache) {
        bgImageCache = [[NSMutableDictionary alloc] init];
    }
    CGFloat radius = self.bounds.size.height / 2.0;
    NSString *cacheKey = [NSString stringWithFormat:@"%f_%@_selected", radius, self.buttonColor];
    UIImage *bgImage = [bgImageCache objectForKey:cacheKey];
    if (!bgImage) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius * 2.0 + 1, radius * 2.0), NO, 0.0);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, radius * 2.0 + 1, radius * 2) cornerRadius: radius];
        [self.buttonColor setFill];
        [path fill];
        bgImage =  UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        bgImage = [bgImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, radius, 0, radius)];
        [bgImageCache setObject:bgImage forKey:cacheKey];
    }
    return bgImage;
}

@end

@implementation GroupedPillButton

- (void)_setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [self _setSelected:selected animated:animated];
    if (self.group) {
        [self.group onSelectedButton:self];
    }
}

@end

@interface ExclusivePillButtonGroup() {
    NSMutableArray *buttons;
}

@end

@implementation ExclusivePillButtonGroup

- (void)addButton:(GroupedPillButton *)button
{
    if (!buttons) {
        buttons = [@[] mutableCopy];
    }
    button.group = self;
    [buttons addObject:button];
}

- (void)removeAll
{
    if (!buttons) return;
    for (GroupedPillButton *button in buttons) {
        button.group = nil;
    }
    [buttons removeAllObjects];
}

- (void)onSelectedButton:(GroupedPillButton *)selected {
    for (GroupedPillButton *button in buttons) {
        if (button != selected) {
            [button _setSelected:NO animated:NO];
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:
        @selector(pillButtonDidChange:)]) {
        [self.delegate pillButtonDidChange:selected];
    }
}

- (id)getGroupValue {
    for (GroupedPillButton *btn in buttons) {
        if (btn.isSelected) {
            return btn.groupValue;
        }
    }
    return nil;
}
@end
