//
//  ButtonHalo.m
//  emma
//
//  Created by Peng Gu on 9/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ButtonHalo.h"

@implementation ButtonHalo

-(CGFloat)radiusForBounds:(CGRect)bounds
{
    return fminf(bounds.size.width, bounds.size.height) / 2;
}

-(void)setFrame:(CGRect)frame
{
    self.layer.cornerRadius = [self radiusForBounds:frame];
    [super setFrame:frame];
}

-(void)zoomIn {
    
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.transform = CGAffineTransformMakeScale(0, 0);
                     }
                     completion:nil];
}

-(void)zoomOut: (float) targetWidth animate:(BOOL)animate{
    float transit = targetWidth/HALO_WIDTH;
    self.transform = CGAffineTransformMakeScale(0, 0);
    if (animate) {
        [UIView animateWithDuration:0.45
                              delay:0.05
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.transform = CGAffineTransformMakeScale(transit, transit);
                         }
                         completion:nil];
        
    } else {
        self.transform = CGAffineTransformMakeScale(transit, transit);
    }
    
}

@end