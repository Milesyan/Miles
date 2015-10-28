//
//  QuizImageOptionButton.m
//  GLCommunity
//
//  Created by Allen Hsu on 8/17/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <GLFoundation/UIColor+Utils.h>
#import <GLFoundation/GLTheme.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "QuizImageOptionButton.h"

@interface QuizImageOptionButton ()

@property (weak, nonatomic) IBOutlet UIImageView *selectedIndicator;

@end

@implementation QuizImageOptionButton

+ (QuizImageOptionButton *)button {
    return [[[NSBundle mainBundle] loadNibNamed:@"QuizImageOption" owner:nil options:nil] firstObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.cornerRadius = 5.0;
    self.layer.masksToBounds = YES;
    self.selectedIndicator.layer.cornerRadius = self.selectedIndicator.frame.size.height / 2.0;
    self.selectedIndicator.layer.borderWidth = 1.0;
    self.selectedIndicator.layer.borderColor = GLOW_COLOR_PURPLE.CGColor;
//    self.imageView.layer.cornerRadius = 5.0;
//    self.imageView.layer.masksToBounds = YES;
    [self updateContent];
    [self updateButtonStyle];
}

- (void)setOption:(ForumQuizOption *)option {
    if (_option != option) {
        _option = option;
        [self updateContent];
    }
}

- (void)updateContent {
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:self.option.image]];
    self.textLabel.text = self.option.title;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self updateButtonStyle];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self updateButtonStyle];
}

- (void)updateButtonStyle {
    if (self.selected || self.highlighted) {
        self.selectedIndicator.image = [UIImage imageNamed:@"gl-community-icon-check"];
        self.selectedIndicator.backgroundColor = GLOW_COLOR_PURPLE;
        self.imageView.alpha = 1.0;
    } else {
        self.selectedIndicator.image = nil;
        self.selectedIndicator.backgroundColor = [UIColor whiteColor];
        self.imageView.alpha = 0.5;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
