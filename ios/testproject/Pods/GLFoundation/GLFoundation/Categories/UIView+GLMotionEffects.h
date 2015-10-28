//
//  UIView+GLMotionEffects.h
//  kaylee
//
//  Created by Allen Hsu on 6/24/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (GLMotionEffects)

- (void)addMotionEffectWithMovement:(CGPoint)movement;

- (UIInterpolatingMotionEffect *)motionEffectWithType:(UIInterpolatingMotionEffectType)type
                                              keyPath:(NSString*)keyPath
                                                value:(CGFloat)value;

- (UIInterpolatingMotionEffect *)motionEffectWithType:(UIInterpolatingMotionEffectType)type
                                              keyPath:(NSString*)keyPath
                                             minValue:(CGFloat)minValue
                                             maxValue:(CGFloat)maxValue;

- (void)removeAllMotionEffects;

@end
