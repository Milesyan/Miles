//
//  DayPointerEdgeView.h
//  emma
//
//  Created by Xin Zhao on 13-7-22.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DayPointerEdgeView : UIView

@property BOOL leftUpToRightBottom;


- (void) transformWithPoint:(CGPoint)basePoint andPoint:(CGPoint)anotherPoint;

- (CGAffineTransform) bounceTransformWithRotationMultiplier:(CGFloat)multiplier;

- (CGFloat)offsetXWithY:(CGFloat)y andRotationMultiplier:(CGFloat)multiplier;
@end
