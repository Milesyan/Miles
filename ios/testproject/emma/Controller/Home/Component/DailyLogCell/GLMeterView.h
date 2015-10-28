//
//  GLMeterView.h
//  kaylee
//
//  Created by Eric Xu on 11/17/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLMeterView : UIView
    
@property (nonatomic) BOOL small;
@property (nonatomic, assign) BOOL showProgressLabel;

- (void)setProgress:(float)progress animated:(BOOL)animated;

- (void)drawHeart;
@end
