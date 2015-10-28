//
//  ForumFollowButton.m
//  Pods
//
//  Created by Peng Gu on 6/1/15.
//
//

#import <GLFoundation/GLFoundation.h>
#import "ForumFollowButton.h"
#import <GLFoundation/UIImage+Utils.h>

@implementation ForumFollowButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)setup
{
    [self setTitle:@"Follow" forState:UIControlStateNormal];
    [self setTitle:@"Following" forState:UIControlStateHighlighted];
    [self setTitle:@"Following" forState:UIControlStateSelected];
    
    UIImage *checkImage = [UIImage imageNamed:@"gl-community-check"];
    [self setImage:checkImage forState:UIControlStateSelected];
    [self setImage:checkImage forState:UIControlStateHighlighted];
    [self setImage:[UIImage imageNamed:@"gl-community-follow"] forState:UIControlStateNormal];    
    
    [self setTitleColor:GLOW_COLOR_PURPLE forState:UIControlStateNormal];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    
    self.layer.masksToBounds = NO;
    self.layer.borderColor = [UIColorFromRGB(0xD5D6D7) CGColor];
    self.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.layer.shadowOpacity = 0.15;
    self.layer.shadowRadius = 1;
    self.layer.shadowOffset = CGSizeMake(0, 0.5);
}


- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    self.layer.cornerRadius = self.height / 2;
    if (selected) {
        self.backgroundColor = GLOW_COLOR_PURPLE;
        self.layer.borderWidth = 0;
        self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 4);
    }
    else {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderWidth = 0.5;
        self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 1, 0);
    }
}



@end
