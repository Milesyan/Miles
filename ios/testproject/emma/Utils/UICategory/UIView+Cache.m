//
//  UIView+Cache.m
//  emma
//
//  Created by Ryan Ye on 3/13/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "UIView+Cache.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

@implementation UIView(Cache)

#define TAG_SNAPSHOT 78965
static char ORIG_HIDDEN_VALUE;
static char LOCK_REF_COUNT;

- (void)lockView {
    NSNumber *refCount = (NSNumber *)objc_getAssociatedObject(self, &LOCK_REF_COUNT);
    if (refCount == nil) {
        refCount = @0;
        // take snapshot of current view
        

        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        for (UIView *subview in self.subviews) {
            objc_setAssociatedObject(subview, &ORIG_HIDDEN_VALUE, @(subview.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            subview.hidden = YES;
        }
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = self.bounds;
        imageView.tag = TAG_SNAPSHOT;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:imageView];
    } 
    refCount = @([refCount intValue] + 1);
    objc_setAssociatedObject(self, &LOCK_REF_COUNT, refCount, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)unlockView {
    NSNumber *refCount = (NSNumber *)objc_getAssociatedObject(self, &LOCK_REF_COUNT);
    if ([refCount intValue] == 1) {
        [[self viewWithTag:TAG_SNAPSHOT] removeFromSuperview];
        for (UIView *subview in self.subviews) {
            NSNumber *hidden = (NSNumber *)objc_getAssociatedObject(subview, &ORIG_HIDDEN_VALUE);
            if (hidden != nil) {
                subview.hidden = [hidden boolValue];
            }
            objc_setAssociatedObject(subview, &ORIG_HIDDEN_VALUE, nil, OBJC_ASSOCIATION_ASSIGN);
        }
    }
    if (refCount != nil) {
        refCount = @([refCount intValue] - 1);
        if ([refCount intValue] <= 0)
            refCount = nil;
        objc_setAssociatedObject(self, &LOCK_REF_COUNT, refCount, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
