//
//  BadgeView.m
//  emma
//
//  Created by Ryan Ye on 4/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "BadgeView.h"

@implementation BadgeView

/*
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = frame.size.height / 2;
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOffset = CGSizeMake(0, 1.0);
        self.layer.shadowRadius = 1.0;
        self.layer.shadowOpacity = 0.5f;

        bgView = [[UIView alloc] initWithFrame:CGRectMake(2, 2, frame.size.width - 4, frame.size.height - 4)];
        bgView.layer.cornerRadius = self.layer.cornerRadius - 2;
        [bgView setGradientBackground:UIColorFromRGB(0xf59ba0) toColor:UIColorFromRGB(0xcb0306)];

        label = [[UILabel alloc] initWithFrame:CGRectMake(2, 2, frame.size.width - 4, frame.size.height - 4)];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.adjustsFontSizeToFitWidth = YES;
        label.font = [UIFont boldSystemFontOfSize:12.0];
        label.textAlignment = NSTextAlignmentCenter;

        [self addSubview:bgView];
        [self addSubview:label];
        self.userInteractionEnabled = NO;
    }
    return self;
}
*/

- (id)init {
    self = [super init];
    [self initValues];
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self initValues];
    [self redrawLabel];
    return self;
}

- (void)initValues {
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor redColor];
    
    label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [Utils boldFont:12.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"0";
    [self addSubview:label];
}

- (void)setTextColor:(UIColor *)color {
    label.textColor = color;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.layer.cornerRadius = frame.size.height / 2;
    if (label) {
        [self redrawLabel];
    }
}

- (void)redrawLabel {
    float height = self.frame.size.height;
    label.font = [Utils boldFont:height * 2 / 3];
    label.frame = CGRectMake(0, 0, height, height);
    [self adjustText];
}

- (void)adjustText {
    //[label sizeToFit];
    float w = self.frame.size.width;
    float h = self.frame.size.height;
    // The number height is not exactly the label height
    // a number, "0...9" is about 2/3 height of a label
    // because the bottom line of character "gyj" is much lower
    // But in this label, we only show number, so add some buffer for height
    // float fontHeight = label.frame.size.height;
    label.center = CGPointMake(w/2, h/2); //  + fontHeight * 0.04);
}

- (void)setCount:(NSInteger)count {
    if (count < 100) {
        label.text = [NSString stringWithFormat:@"%ld", (long)count];
    } else {
        label.text = @"∞";
    }
    _count = count;
    [self adjustText];
}

- (UILabel *)getLabel {
    return label;
}

@end
