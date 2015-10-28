//
//  RotationImageView.h
//  emma
//
//  Created by Jirong Wang on 5/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLRotationImageView : UIImageView

- (void)startSpinWithOneCycleDuration:(CGFloat)seconds;
- (void)stopSpin;

@end
