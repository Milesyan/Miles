//
//  FundOngoingBaseCell.m
//  emma
//
//  Created by Jirong Wang on 11/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundOngoingBaseCell.h"

@interface FundOngoingBaseCell()

- (void)cellDidScrolled:(NSValue *)offset;
- (void)animateIn;
- (void)animateOut;
- (BOOL)shouldAnimate;
@end

@implementation FundOngoingBaseCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    self.circleOn = NO;
}

- (void)cellDidScrolled:(NSValue *)vOffset {
    CGPoint point = self.center;
    point.y = point.y *2 /3;
    CGPoint p = [self.superview convertPoint:point toView:nil];
    if (p.y > SCREEN_HEIGHT ){ //|| p.y < 64) {
        [self animateOut];
    } else {
        [self animateIn];
    }
}

- (void)willShow {
}

- (void)animateIn {
    
}

- (void)animateOut {
    
}

- (BOOL)shouldAnimate {
    CGPoint p = [self.superview convertPoint:self.center toView:nil];
    if (p.y > SCREEN_HEIGHT ){ //|| p.y < 64) {
        return YES;
    } else {
        return NO;
    }
}
@end
