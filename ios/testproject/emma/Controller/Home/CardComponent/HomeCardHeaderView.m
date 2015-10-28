//
//  CardHeaderView.m
//  emma
//
//  Created by ltebean on 15/5/19.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "HomeCardHeaderView.h"
@interface HomeCardHeaderView()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *bottomLine;
@end;
@implementation HomeCardHeaderView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.backgroundColor = [UIColor whiteColor];
    self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(-1, 0, 14, 14)];
    self.iconView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.iconView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(17, 0, 200, 20)];
    self.titleLabel.font = [Utils defaultFont:14];
    self.titleLabel.textColor = UIColorFromRGB(0x868686);
    self.titleLabel.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.titleLabel];
    
    self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 29, 100, 0.5)];
    self.bottomLine.backgroundColor = UIColorFromRGB(0xe2e2e2);
    [self addSubview:self.bottomLine];
}

- (void)layoutSubviews
{
    self.iconView.centerY = CGRectGetMidY(self.bounds);
    self.titleLabel.centerY = CGRectGetMidY(self.bounds);
    self.bottomLine.width = self.width;
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (void)setIcon:(UIImage *)icon
{
    self.iconView.image = icon;
}

@end
