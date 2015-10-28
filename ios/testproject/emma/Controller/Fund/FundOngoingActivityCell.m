//
//  FundOngoingActivityCell.m
//  emma
//
//  Created by Jirong Wang on 11/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundOngoingActivityCell.h"

#define ACTIVE_COLOR UIColorFromRGB(0x6cba2d)
#define INACTIVE_COLOR UIColorFromRGB(0xdc4234)

@interface FundOngoingActivityCell()

@property (strong, nonatomic) IBOutlet UIView *bgCircle;
@property (strong, nonatomic) IBOutlet UIView *circle;

@end

@implementation FundOngoingActivityCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.circle.layer.cornerRadius = 70;
    self.bgCircle.layer.cornerRadius = 80;
    [self.contentView.superview setClipsToBounds:NO];
}

- (void)prepareForReuse {
    self.bgCircle.transform = CGAffineTransformMakeScale(0.85, 0.85);
    self.circle.transform = CGAffineTransformMakeScale(1, 1);
}

- (void)willShow {
    BOOL shouldAnimate = [self shouldAnimate];
    
    if (shouldAnimate) {
        self.bgCircle.transform = CGAffineTransformMakeScale(0, 0);
        self.circle.transform = CGAffineTransformMakeScale(0, 0);
    } else {
        self.bgCircle.transform = CGAffineTransformMakeScale(1 + self.activeLevel, 1 + self.activeLevel);
        self.circle.transform = CGAffineTransformMakeScale(1, 1);
    }
    self.circleOn = ![self shouldAnimate];
}

- (void)setActive:(BOOL)active {
    _active = active;
    self.bgCircle.hidden = !active;
    self.circle.backgroundColor = active? ACTIVE_COLOR: INACTIVE_COLOR;
    
    if (self.circleOn) {
        self.circle.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } else {
        self.circle.transform = CGAffineTransformMakeScale(0, 0);
    }
}

- (void)setActiveLevel:(float)activeLevel {
    if (activeLevel > 1) {
        activeLevel = 1;
    } else if(activeLevel < 0) {
        activeLevel = 0;
    }
    
    _activeLevel = activeLevel;
    
    if (self.circleOn) {
        self.bgCircle.transform = CGAffineTransformMakeScale(1 + activeLevel, 1 + activeLevel);
    } else {
        self.bgCircle.transform = CGAffineTransformMakeScale(0, 0);
    }
}

- (void)animateIn {
    if (!self.circleOn) {
        self.circleOn = YES;
    }
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.circle.transform = CGAffineTransformMakeScale(1.0, 1.0);
                         if (self.bgCircle.transform.a < 0.85) {
                             self.bgCircle.transform = CGAffineTransformMakeScale(0.85, 0.85);
                         }
                         
                     } completion:^(BOOL finished){
                         [UIView animateWithDuration:0.3 animations:^{
                             self.bgCircle.transform = CGAffineTransformMakeScale(1.0 + _activeLevel, 1.0 + _activeLevel);
                         }];
                     }];
}
- (void)animateOut {
    if (self.circleOn) {
        self.circleOn = NO;
    } else {
        return;
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.circle.transform = CGAffineTransformMakeScale(0.0, 0.0);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.3 animations:^{
            self.bgCircle.transform = CGAffineTransformMakeScale(0.0, 0.0);
        }];
    }];
}

@end
