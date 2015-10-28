//
//  ContentActionButton.h
//  emma
//
//  Created by Jirong Wang on 3/25/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLContentActionButton : UIButton

- (void)initButtonWithReplyStyle;
- (void)initButtonWithCommentStyle;
- (void)initButtonWithLikeStyle;
- (void)initButtonWithUpvoteStyle;
- (void)initButtonWithShareStyle;
- (void)initButtonWithFlagStyle;

- (void)initButtonWithImage:(NSString *)imageName label:(NSString *)title bgColor:(UIColor *)bgColor selectedColor:(UIColor *)selectedColor;

@end
