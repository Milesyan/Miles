//
//  ForumTabButton.h
//  GLCommunity
//
//  Created by Allen Hsu on 11/3/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumGroup.h"

#define TAB_PLUS_SYMBOL     @"＋"

@interface ForumTabButton : UIControl

@property (strong, nonatomic) UIImageView *background;
@property (strong, nonatomic) UIImageView *dimOverlay;
@property (strong, nonatomic) UIImageView *selectedOverlay;

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) ForumGroup *group;

@end
