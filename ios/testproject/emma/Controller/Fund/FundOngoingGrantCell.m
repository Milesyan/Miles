//
//  FundGrantCell.m
//  emma
//
//  Created by Jirong Wang on 11/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundOngoingGrantCell.h"
#import "FundOngoingBaseCell.h"

@interface FundOngoingGrantCell ()

@property (strong, nonatomic) IBOutlet UIView *innerCircle;
@property (strong, nonatomic) IBOutlet UIView *outerCircle;

- (void)animateIn;
- (void)animateOut;

@end

@implementation FundOngoingGrantCell

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
    
    self.outerCircle.layer.cornerRadius = 120;
    self.innerCircle.layer.cornerRadius = 100;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, 200, 200);
    gradient.colors = [NSArray arrayWithObjects:(id)[UIColorFromRGB(0x4149c1) CGColor], (id)[UIColorFromRGB(0x7682dd) CGColor], nil];
    gradient.cornerRadius = 100;
    [self.innerCircle.layer insertSublayer:gradient atIndex:0];
    self.innerCircle.backgroundColor = [UIColor clearColor];
    
    self.innerCircle.transform = CGAffineTransformMakeScale(0.0, 0.0);
    self.outerCircle.transform = CGAffineTransformMakeScale(0.0, 0.0);
}

- (void)animateIn {
    if (self.circleOn) {
        return;
    } else {
        self.circleOn = YES;
    }
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.innerCircle.transform = CGAffineTransformMakeScale(1.0, 1.0);
                         self.outerCircle.transform = CGAffineTransformMakeScale(0.85, 0.85);
                     } completion:^(BOOL finished){
                         [UIView animateWithDuration:0.3 animations:^{
                             self.outerCircle.transform = CGAffineTransformMakeScale(1.0, 1.0);
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
        self.innerCircle.transform = CGAffineTransformMakeScale(0.0, 0.0);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.3 animations:^{
            self.outerCircle.transform = CGAffineTransformMakeScale(0.0, 0.0);
        }];
    }];
}
- (BOOL)shouldAnimate {
    return NO;
}

@end
