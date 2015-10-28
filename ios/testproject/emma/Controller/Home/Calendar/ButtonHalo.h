//
//  ButtonHalo.h
//  emma
//
//  Created by Peng Gu on 9/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define HALO_WIDTH (IS_IPHONE_6_PLUS ? 233.0f : (IS_IPHONE_6 ? 211.0f : 180.0f))
#define HALO_WIDTH_MIN (IS_IPHONE_6_PLUS ? 177.0f : (IS_IPHONE_6 ? 160.0f : 137.0f))
#define HALO_WIDTH_MAX (IS_IPHONE_6_PLUS ? 350.0f : (IS_IPHONE_6 ? 316.0f : 270.0f))
#define HALO_CALCULATION_ANIMATION_START 1.8f

@interface ButtonHalo : UIView
-(void)zoomIn;
-(void)zoomOut: (float)targetWidth animate:(BOOL)animated;
@end

