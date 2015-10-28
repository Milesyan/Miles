//
//  GLMeterView.m
//  kaylee
//
//  Created by Eric Xu on 11/17/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLMeterView.h"
#import "UIImage+Resize.h"
#import "UIImage+Utils.h"

@interface GLMeterView()
{
//    UIImageView *bgView;
    UIView *bgView ;
    UIImageView *maskView;
//    DPMeterView *meterView;
    UIView *meterView;
    UIView *barView;
    
    float _progress;
}


@end

@implementation GLMeterView

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)awakeFromNib
{
    [self drawHeart];
}


- (void)drawHeart
{
    self.backgroundColor = [UIColor clearColor];
    CGRect f = CGRectMake(0, 0, self.width, self.height);
    
    //    bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.small? @"icon-smallheart":@"icon-bigheart-bg"]];
    bgView = [[UIView alloc] initWithFrame:f];
    bgView.backgroundColor = UIColorFromRGB(0xF5C3BA);
    //    bgView.frame = f;
    [self addSubview:bgView];
    
    //    meterView = [[DPMeterView alloc] initWithFrame:self.frame shape:[UIBezierPath heartShape:self.frame].CGPath];
    
    meterView = [[UIView alloc] initWithFrame:f];
    [meterView setBackgroundColor:UIColorFromRGB(0xF65F4D)];
    
    if (!self.small) {
        UIImageView *heartView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-bigheart-fill"]];
        heartView.frame = f;
        [meterView addSubview:heartView];
    }
    
    barView = [[UIView alloc] initWithFrame:f];
    barView.backgroundColor = UIColorFromRGB(0xF5C3BA);
    [meterView addSubview:barView];
    
    UIImage *_maskingImage = [UIImage imageNamed:self.small?@"icon-smallheart":@"icon-bigheart-bg"];
    _maskingImage = [Utils image:_maskingImage withColor:[UIColor whiteColor] withBlendMode:kCGBlendModeColor];
    CALayer *_maskingLayer = [CALayer layer];
    _maskingLayer.frame = f;
    [_maskingLayer setContents:(id)[_maskingImage CGImage]];
    [self.layer setMask:_maskingLayer];
    
    [self addSubview:meterView];
    
    if (!self.small) {
        maskView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-bigheart-mask"]];
        maskView.frame = f;
        [self addSubview:maskView];
    }
}


- (void)setProgress:(float)progress animated:(BOOL)animated
{
    if (progress > 1.0) {
        progress = 1.0;
    } else if (progress < 0) {
        progress = 0;
    }
    if (progress == _progress) {
        return;
    }
    _progress = progress;
    
    //    barView.height = self.height;
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            barView.height = (1.0 - progress) * self.height;
        } completion:^(BOOL finished) {
            GLLog(@"after: %@", barView);
        }];
    } else {
        barView.height = (1.0 - progress) * self.height;
    }
}

@end
