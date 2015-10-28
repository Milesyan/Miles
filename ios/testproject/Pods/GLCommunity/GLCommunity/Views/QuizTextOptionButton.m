//
//  QuizTextOptionButton.m
//  GLCommunity
//
//  Created by Allen Hsu on 8/17/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <GLFoundation/UIColor+Utils.h>
#import "QuizTextOptionButton.h"

@interface QuizTextOptionButton ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bgBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bgTop;

@end

@implementation QuizTextOptionButton

+ (QuizTextOptionButton *)button {
    return [[[NSBundle mainBundle] loadNibNamed:@"QuizTextOption" owner:nil options:nil] firstObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.cornerRadius = 5.0;
    self.layer.masksToBounds = YES;
    self.backgroundView.layer.cornerRadius = 5.0;
    self.backgroundView.layer.masksToBounds = YES;
    [self updateText];
}

- (void)setOption:(ForumQuizOption *)option {
    if (_option != option) {
        _option = option;
        [self updateText];
    }
}

- (void)updateText {
    self.textLabel.text = self.option.title;
    [self setNeedsLayout];
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
        self.backgroundColor = UIColorFromRGB(0x424ab5);
        self.backgroundView.backgroundColor = UIColorFromRGB(0x5a62d2);
        self.textLabel.textColor = [UIColor whiteColor];
        self.bgTop.constant = 4.0;
        self.bgBottom.constant = 0.0;
    } else {
        self.backgroundColor = UIColorFromRGB(0xe4e5e7);
        self.backgroundView.backgroundColor = [UIColor whiteColor];
        self.textLabel.textColor = UIColorFromRGB(0x5a62d2);
        self.bgTop.constant = 0.0;
        self.bgBottom.constant = 4.0;
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
