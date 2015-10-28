//
//  UIView+GLMotionEffects.m
//  kaylee
//
//  Created by Allen Hsu on 6/24/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "UIView+GLMotionEffects.h"

@implementation UIView (GLMotionEffects)

- (void)addMotionEffectWithMovement:(CGPoint)movement;
{
    if (![self respondsToSelector:@selector(addMotionEffect:)]) return; // ios7 check
    UIInterpolatingMotionEffect *hMotion = [self motionEffectWithType:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis keyPath:@"center.x" value:movement.x];
    UIInterpolatingMotionEffect *vMotion = [self motionEffectWithType:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis keyPath:@"center.y" value:movement.y];
    if (hMotion && vMotion) {
        UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
        group.motionEffects = @[hMotion, vMotion];
        [self addMotionEffect:group];
    }
}

- (UIInterpolatingMotionEffect *)motionEffectWithType:(UIInterpolatingMotionEffectType)type keyPath:(NSString *)keyPath value:(CGFloat)value
{
    return [self motionEffectWithType:type keyPath:keyPath minValue:-value maxValue:value];
}

- (UIInterpolatingMotionEffect *)motionEffectWithType:(UIInterpolatingMotionEffectType)type keyPath:(NSString *)keyPath minValue:(CGFloat)minValue maxValue:(CGFloat)maxValue
{
    if ((minValue == 0 && maxValue == 0) || keyPath == nil) return nil; // check needed values
    
	UIInterpolatingMotionEffect *effect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:keyPath type:type];
	effect.minimumRelativeValue = @(minValue);
	effect.maximumRelativeValue = @(maxValue);
    return effect;
}

- (void)removeAllMotionEffects {
    for (UIMotionEffect *effect in self.motionEffects) {
        [self removeMotionEffect:effect];
    }
}

@end
