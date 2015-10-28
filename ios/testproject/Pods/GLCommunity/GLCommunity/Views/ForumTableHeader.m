//
//  ForumTableHeader.m
//  emma
//
//  Created by Xin Zhao on 7/3/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLTheme.h>
#import "ForumTableHeader.h"

@interface ForumTableHeader() {
    UITapGestureRecognizer *tapRightLabelGestureRecognizer;
}

@end

@implementation ForumTableHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setupWithBgColor:(UIColor *)color titleMeta:(NSDictionary *)titleMeta
    rightClickableMeta:(NSDictionary *)rightClickableMeta
{
    self.bg.backgroundColor = color;
    self.titleLabel.text = titleMeta[@"title"];
    self.titleLabel.textColor = titleMeta[@"color"];
    self.titleLabel.font = [GLTheme boldFont:15.0];
    self.rightLabel.font = [GLTheme semiBoldFont:15.0];
    if (rightClickableMeta) {
        self.rightLabel.hidden = NO;
        self.rightLabel.text = rightClickableMeta[@"text"];
        self.rightLabel.textColor = rightClickableMeta[@"color"];
        self.rightLabel.userInteractionEnabled = YES;
        if (!tapRightLabelGestureRecognizer) {
            tapRightLabelGestureRecognizer = [[UITapGestureRecognizer alloc]
                initWithTarget:self action:@selector(rightLabelTapped:)];
            tapRightLabelGestureRecognizer.numberOfTapsRequired = 1;
            [self addGestureRecognizer:tapRightLabelGestureRecognizer];
        }
        tapRightLabelGestureRecognizer.enabled = YES;
    }
    else {
        self.rightLabel.hidden = YES;
        self.rightLabel.userInteractionEnabled = NO;
        if (tapRightLabelGestureRecognizer) {
            tapRightLabelGestureRecognizer.enabled = NO;
        }
    }

}

- (void)rightLabelTapped:(UITapGestureRecognizer *)recognizer {
    if (self.delegate && [self.delegate respondsToSelector:
        @selector(clickSectionHeaderRight:)]) {
        [self.delegate clickSectionHeaderRight:self];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
