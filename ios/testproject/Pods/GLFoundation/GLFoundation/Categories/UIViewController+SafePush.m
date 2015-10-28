//
//  UIViewController+SafePush.m
//  emma
//
//  Created by Jirong Wang on 2/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <objc/runtime.h>
#import "UIViewController+SafePush.h"

@implementation UIViewController (SafePush)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        
        SEL originalSelector = @selector(shouldPerformSegueWithIdentifier:sender:);
        SEL swizzledSelector = @selector(gl_shouldPerformSegueWithIdentifier:sender:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (BOOL)gl_shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    NSLog(@"swizzled shouldPerformSegue");
    if (self.navigationController) {
        return [self canPerformSafeSegue];
    }
    return [self gl_shouldPerformSegueWithIdentifier:identifier sender:sender];
}

- (BOOL)canPerformSafeSegue
{
    if (self.navigationController) {
        UIViewController *topParent = self.parentViewController;
        while (topParent.parentViewController
               && ![topParent.parentViewController isKindOfClass:[UINavigationController class]]
               && ![topParent.parentViewController isKindOfClass:[UITabBarController class]]) {
            topParent = topParent.parentViewController;
        }
        if (self.navigationController.topViewController && self.navigationController.topViewController != self && self.navigationController.topViewController != topParent) {
            return NO;
        }
    }
    return YES;
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender from:(UIViewController *)viewController {
    if (![viewController canPerformSafeSegue]) {
        return;
    }
    [self performSegueWithIdentifier:identifier sender:sender];
}

@end
