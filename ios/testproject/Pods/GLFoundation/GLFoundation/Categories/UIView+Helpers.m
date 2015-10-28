//
//  UIView+Utils.m
//  Borrowed from Three20
//
//  Copyright (c) 2013 iOS. No rights reserved.
//

#import "UIView+Helpers.h"

#import <objc/runtime.h>

static char kDTActionHandlerTapBlockKey;
static char kDTActionHandlerTapGestureKey;
static char kDTActionHandlerLongPressBlockKey;
static char kDTActionHandlerLongPressGestureKey;

@implementation UIView (Helpers)


- (CGFloat)left {
    return self.frame.origin.x;
}



- (void)setLeft:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}



- (CGFloat)top {
    return self.frame.origin.y;
}



- (void)setTop:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}



- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}



- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}



- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}



- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}



- (CGFloat)centerX {
    return self.center.x;
}



- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}



- (CGFloat)centerY {
    return self.center.y;
}



- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}



- (CGFloat)width {
    return self.frame.size.width;
}



- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}



- (CGFloat)height {
    return self.frame.size.height;
}



- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)_getSuperConstraint:(NSLayoutAttribute)attr {
    if (!self.superview)
        return 0;
    for(NSLayoutConstraint *constraint in self.superview.constraints) {
        if (((constraint.firstItem == self) && (constraint.firstAttribute == attr))
            && (attr == NSLayoutAttributeTop || attr == NSLayoutAttributeLeading)
            ) {
            // for top and left
            return constraint.constant;
        } else if (((constraint.secondItem == self) && (constraint.firstAttribute == attr))
            && (attr == NSLayoutAttributeTrailing || attr == NSLayoutAttributeBottom)
            ) {
            // for right and bottom
            return constraint.constant;
        }
    }
    return 0;
}
- (void)_setSuperConstraint:(NSLayoutAttribute)attr value:(CGFloat)value {
    if (!self.superview)
        return;
    for(NSLayoutConstraint *constraint in self.superview.constraints) {
        if (((constraint.firstItem == self) && (constraint.firstAttribute == attr))
            && (attr == NSLayoutAttributeTop || attr == NSLayoutAttributeLeading)
            ) {
            // for top and left
            constraint.constant = value;
        } else if (((constraint.secondItem == self) && (constraint.firstAttribute == attr))
            && (attr == NSLayoutAttributeTrailing || attr == NSLayoutAttributeBottom)
            ) {
            // for right and bottom
            constraint.constant = value;
        }
    }
    return;
}
- (CGFloat)aLeft {
    return [self _getSuperConstraint:NSLayoutAttributeLeading];
}
- (void)setALeft:(CGFloat)aLeft {
    [self _setSuperConstraint:NSLayoutAttributeLeading value:aLeft];
}
- (CGFloat)aRight {
    return [self _getSuperConstraint:NSLayoutAttributeTrailing];
}
- (void)setARight:(CGFloat)aRight {
    [self _setSuperConstraint:NSLayoutAttributeTrailing value:aRight];
}
- (CGFloat)aTop {
    return [self _getSuperConstraint:NSLayoutAttributeTop];
}
- (void)setATop:(CGFloat)aTop {
    [self _setSuperConstraint:NSLayoutAttributeTop value:aTop];
}
- (CGFloat)aBottom {
    return [self _getSuperConstraint:NSLayoutAttributeBottom];
}
- (void)setABottom:(CGFloat)aBottom {
    [self _setSuperConstraint:NSLayoutAttributeBottom value:aBottom];
}


- (CGFloat)_getSelfConstraint:(NSLayoutAttribute)attr {
    for(NSLayoutConstraint *constraint in self.constraints) {
        if (((constraint.firstItem == self) && (constraint.firstAttribute == attr))
            && (attr == NSLayoutAttributeWidth || attr == NSLayoutAttributeHeight)
            ) {
            return constraint.constant;
        }
    }
    return 0;
}
- (void)_setSelfConstraint:(NSLayoutAttribute)attr value:(CGFloat)value {
    for(NSLayoutConstraint *constraint in self.constraints) {
        if (((constraint.firstItem == self) && (constraint.firstAttribute == attr))
            && (attr == NSLayoutAttributeWidth || attr == NSLayoutAttributeHeight)
            ) {
            constraint.constant = value;
        }
    }
}
- (CGFloat)aWidth {
    return [self _getSelfConstraint:NSLayoutAttributeWidth];
}
- (void)setAWidth:(CGFloat)aWidth {
    [self _setSelfConstraint:NSLayoutAttributeWidth value:aWidth];
}
- (CGFloat)aHeight {
    return [self _getSelfConstraint:NSLayoutAttributeHeight];
}
- (void)setAHeight:(CGFloat)aHeight {
    [self _setSelfConstraint:NSLayoutAttributeHeight value:aHeight];
}

- (CGFloat)screenX {
    CGFloat x = 0.0f;
    for (UIView* view = self; view; view = view.superview) {
        x += view.left;
    }
    return x;
}



- (CGFloat)screenY {
    CGFloat y = 0.0f;
    for (UIView* view = self; view; view = view.superview) {
        y += view.top;
    }
    return y;
}



- (CGFloat)screenViewX {
    CGFloat x = 0.0f;
    for (UIView* view = self; view; view = view.superview) {
        x += view.left;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            x -= scrollView.contentOffset.x;
        }
    }
    
    return x;
}



- (CGFloat)screenViewY {
    CGFloat y = 0;
    for (UIView* view = self; view; view = view.superview) {
        y += view.top;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            y -= scrollView.contentOffset.y;
        }
    }
    return y;
}



- (CGRect)screenFrame {
    return CGRectMake(self.screenViewX, self.screenViewY, self.width, self.height);
}



- (CGPoint)origin {
    return self.frame.origin;
}



- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}



- (CGSize)size {
    return self.frame.size;
}



- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}



- (CGFloat)orientationWidth {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
    ? self.height : self.width;
}



- (CGFloat)orientationHeight {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
    ? self.width : self.height;
}



- (UIView*)descendantOrSelfWithClass:(Class)cls {
    if ([self isKindOfClass:cls])
        return self;
    
    for (UIView* child in self.subviews) {
        UIView* it = [child descendantOrSelfWithClass:cls];
        if (it)
            return it;
    }
    
    return nil;
}


- (UIView *)descendantOrSelfWithClassName:(NSString *)clsName
{
    if ([[[self class] description] isEqualToString:clsName])
        return self;
    
    for (UIView* child in self.subviews) {
        UIView* it = [child descendantOrSelfWithClassName:clsName];
        if (it)
            return it;
    }
    
    return nil;
}


- (UIView*)ancestorOrSelfWithClass:(Class)cls {
    if ([self isKindOfClass:cls]) {
        return self;
        
    } else if (self.superview) {
        return [self.superview ancestorOrSelfWithClass:cls];
        
    } else {
        return nil;
    }
}


- (UIView *)ancestorOrSelfWithClassName:(NSString *)clsName
{
    if ([[[self class] description] isEqualToString:clsName]) {
        return self;
    } else if (self.superview) {
        return [self.superview ancestorOrSelfWithClassName:clsName];
    } else {
        return nil;
    }
}

- (BOOL)isAncestorOfView:(UIView *)view {
    while (view.superview) {
        if (self == view) {
            return YES;
        } else {
            view = view.superview;
        }
    }
    return NO;
}


- (void)removeAllSubviews {
    while (self.subviews.count) {
        UIView* child = self.subviews.lastObject;
        [child removeFromSuperview];
    }
}



- (CGPoint)offsetFromView:(UIView*)otherView {
    CGFloat x = 0.0f, y = 0.0f;
    for (UIView* view = self; view && view != otherView; view = view.superview) {
        x += view.left;
        y += view.top;
    }
    return CGPointMake(x, y);
}


- (void)setTapActionWithBlock:(void (^)(void))block
{
	UITapGestureRecognizer *gesture = objc_getAssociatedObject(self, &kDTActionHandlerTapGestureKey);
    
	if (!gesture)
	{
		gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(__handleActionForTapGesture:)];
		[self addGestureRecognizer:gesture];
		objc_setAssociatedObject(self, &kDTActionHandlerTapGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
	}
    
	objc_setAssociatedObject(self, &kDTActionHandlerTapBlockKey, block, OBJC_ASSOCIATION_COPY);
}

- (void)__handleActionForTapGesture:(UITapGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateRecognized)
	{
		void(^action)(void) = objc_getAssociatedObject(self, &kDTActionHandlerTapBlockKey);
        
		if (action)
		{
			action();
		}
	}
}

- (void)setLongPressActionWithBlock:(void (^)(void))block
{
	UILongPressGestureRecognizer *gesture = objc_getAssociatedObject(self, &kDTActionHandlerLongPressGestureKey);
    
	if (!gesture)
	{
		gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(__handleActionForLongPressGesture:)];
		[self addGestureRecognizer:gesture];
		objc_setAssociatedObject(self, &kDTActionHandlerLongPressGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
	}
    
	objc_setAssociatedObject(self, &kDTActionHandlerLongPressBlockKey, block, OBJC_ASSOCIATION_COPY);
}

- (void)__handleActionForLongPressGesture:(UITapGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		void(^action)(void) = objc_getAssociatedObject(self, &kDTActionHandlerLongPressBlockKey);
        
		if (action)
		{
			action();
		}
	}
}

// Gradient Background
- (void)setGradientBackground:(UIColor *)colorOne toColor:(UIColor *)colorTwo {
    [self setGradientBackground:colorOne toColor:colorTwo fromLocation:0.0 toLocation:1.0];
}

- (void)setGradientBackground:(UIColor *)colorOne toColor:(UIColor *)colorTwo fromLocation:(CGFloat)fromLocation toLocation:(CGFloat)toLocation {
    NSArray *colors = @[(id)colorOne.CGColor, (id)(colorTwo.CGColor)];
    NSArray *locations = @[@(fromLocation), @(toLocation)];
    CAGradientLayer *bgLayer = [CAGradientLayer layer];
    bgLayer.colors = colors;
    bgLayer.locations = locations;
    bgLayer.frame = self.layer.bounds;
    bgLayer.cornerRadius = self.layer.cornerRadius;
    [self.layer insertSublayer:bgLayer atIndex:0];
}

- (void)removeGradientBackground
{
    NSMutableArray *layersToRemove = [NSMutableArray array];
    for (CALayer *layer in self.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            [layersToRemove addObject:layer];
        }
    }
    for (CALayer *layer in layersToRemove) {
        [layer removeFromSuperlayer];
    }
}

- (BOOL)hasGradientBackground
{
    for (CALayer *layer in self.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            return YES;
        }
    }
    return NO;
}

- (void)rotateUpDown
{
    self.transform = CGAffineTransformMakeScale(1, -1);
}

- (void)rotateLeftRight
{
    self.transform = CGAffineTransformMakeScale(-1, 1);
}

@end