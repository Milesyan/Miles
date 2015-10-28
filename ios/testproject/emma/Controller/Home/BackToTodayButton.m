//
//  BackToTodayButton.m
//  emma
//
//  Created by Eric Xu on 10/12/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "BackToTodayButton.h"
#define PADDING -1
#define PADDING_TODAY_LABEL 5

@interface BackToTodayButton()
{
    UIImageView *arrowImage;
    UIImage *backImage;
    UILabel *mainLabel;
    UILabel *subLabel;
}

@end
@implementation BackToTodayButton

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
    [self setupWithTitle:@"Today"];
}

- (void)setupWithTitle:(NSString *)title
{
    self.backgroundColor = [UIColor clearColor];

    backImage = [UIImage imageNamed:@"browser-back"];
    backImage = [Utils image:backImage withColor:UIColorFromRGB(0x6C6DD3)];
    
    arrowImage = [[UIImageView alloc] initWithImage:backImage];
    arrowImage.contentMode = UIViewContentModeCenter;
    arrowImage.frame = CGRectMake(-8, 6, backImage.size.width, backImage.size.height);
    [self addSubview:arrowImage];
//    arrowImage.transform = CGAffineTransformRotate(CGAffineTransformIdentity, (90 * M_PI) / 180.0);
    
    mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(backImage.size.width - 12, (self.frame.size.height - 33) * 0.5f, 60, 32)];
    mainLabel.text = title;
    mainLabel.font = [Utils lightFont:19];
    
    mainLabel.backgroundColor = [UIColor clearColor];
    mainLabel.textColor = UIColorFromRGB(0x6C6DD3);
    [self addSubview:mainLabel];
}

@end
