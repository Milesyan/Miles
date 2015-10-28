//
//  AlertViewTransition.m
//  emma
//
//  Created by ltebean on 15-1-4.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "AlertViewTransition.h"
#define zoom  0.88
#define finalAlpha 0.6f

@implementation AlertViewTransition

-(void) updateSourceView:(UIView *) sourceView destinationView:(UIView *) destView withProgress:(CGFloat)percent direction:(SlideDirection)direction
{
    CGFloat sourceViewZoom =1-(1-zoom)*percent;
    sourceView.transform=CGAffineTransformMakeScale(sourceViewZoom, sourceViewZoom);
    sourceView.alpha =  1 - percent*(1-finalAlpha);
    
    if(destView){
        CGFloat destViewZoom = zoom+(1-zoom)*percent;
        destView.transform=CGAffineTransformMakeScale(destViewZoom, destViewZoom);
        destView.alpha = finalAlpha + (1-finalAlpha)*percent;
    }
}

@end
