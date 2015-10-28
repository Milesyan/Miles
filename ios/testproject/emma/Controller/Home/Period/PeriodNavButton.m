//
//  PeriodNavButton.m
//  emma
//
//  Created by Jirong Wang on 3/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "PeriodNavButton.h"

@interface PeriodNavButton() {
    UIImageView *iconImageView;
    UIImage *iconImage;
    UILabel *mainLabel;
    UILabel *subLabel;
}

@end

@implementation PeriodNavButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)internalInit
{
    self.backgroundColor = [UIColor clearColor];
    
    iconImage = [UIImage imageNamed:@"nav-edit-period-log"];
    
    iconImageView = [[UIImageView alloc] initWithImage:iconImage];
    iconImageView.contentMode = UIViewContentModeCenter;
    iconImageView.frame = CGRectMake(0, 3, iconImage.size.width, iconImage.size.height);
    [self addSubview:iconImageView];
    
    mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(iconImage.size.width + 4, (self.frame.size.height - 33) * 0.5f, 55, 32)];
    mainLabel.text = @"Period";
    mainLabel.contentMode = UIViewContentModeRight;
    mainLabel.font = [Utils lightFont:19];
    mainLabel.backgroundColor = [UIColor clearColor];
    mainLabel.textColor = UIColorFromRGB(0x6C6DD3);
    [self addSubview:mainLabel];
}

@end
