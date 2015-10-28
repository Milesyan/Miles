//
//  RotationImageView.m
//  emma
//
//  Created by Jirong Wang on 5/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "GLRotationImageView.h"

@interface GLRotationImageView()

@property (nonatomic) BOOL animating;
@property (nonatomic) CGFloat duration;

@end

@implementation GLRotationImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.animating = NO;
    }
    return self;
}

- (void)startSpinWithOneCycleDuration:(CGFloat)seconds {
    if (self.animating) return;
    self.animating = YES;
    self.duration = seconds;
    [self spinWithOptions:UIViewAnimationOptionCurveEaseIn];
}

- (void)stopSpin {
    self.animating = NO;
}

- (void)spinWithOptions:(UIViewAnimationOptions)options {
    [UIView animateWithDuration: self.duration / 4
                          delay: 0.0f
                        options: options
                     animations: ^{
                         self.transform = CGAffineTransformRotate(self.transform, M_PI_2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if (self.animating) {
                                 // if flag still set, keep spinning with constant speed
                                 [self spinWithOptions:UIViewAnimationOptionCurveLinear];
                             } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                 // one last spin, with deceleration
                                 [self spinWithOptions:UIViewAnimationOptionCurveEaseOut];
                             }
                         }
                     }];
}

@end
