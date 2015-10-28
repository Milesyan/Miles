//
//  FontReplaceableBarButtonItem.m
//  emma
//
//  Created by Eric Xu on 11/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GLBarButtonItem.h"
#import "GLTheme.h"
#import "GLUtils.h"

@implementation GLBarButtonItem

- (void)awakeFromNib {
    // style done - semiBold
    // style plain / bordered  ( I don't know why they are same, setting in storyboard does not work)
    //      tag <= 10 - default
    //      tag > 10  - light
    UIFont *font = (self.style == UIBarButtonItemStyleDone) ? [GLTheme semiBoldFont:19.0] : ((self.tag > 10) ? [GLTheme lightFont:19.0] : [GLTheme defaultFont:19.0]);
    [self setTitleTextAttributes:@{NSFontAttributeName:font} forState:UIControlStateNormal];
    [self setTitleTextAttributes:@{NSFontAttributeName:font} forState:UIControlStateDisabled];
    [self setTitleTextAttributes:@{NSFontAttributeName:font} forState:UIControlStateHighlighted];
    //        [self setTitleTextAttributes:@{UITextAttributeFont:font} forState:UIControlStateSelected];
}
@end

