//
//  UIView+FindAndResignFirstResponder.m
//  emma
//
//  Created by Eric Xu on 2/23/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "UIView+FindAndResignFirstResponder.h"

@implementation UIView (FindAndResignFirstResponder)
- (id)findAndResignFirstResponder
{
    if (self.isFirstResponder) {
        [self resignFirstResponder];
        return self;
    }
    for (UIView *subView in self.subviews) {
        id fr = [subView findAndResignFirstResponder];
        if (fr) {
            return fr;
        }
    }
    return nil;
}

- (id)findFirstResponder
{
    if (self.isFirstResponder) {
//        [self resignFirstResponder];
        return self;
    }
    for (UIView *subView in self.subviews) {
        id fr = [subView findFirstResponder];
        if (fr) {
            return fr;
        }
    }
    return nil;
}

@end
