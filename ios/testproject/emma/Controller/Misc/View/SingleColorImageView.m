//
//  SingleColorImage.m
//  emma
//
//  Created by Xin Zhao on 13-12-6.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "SingleColorImageView.h"

@implementation SingleColorImageView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.image = [Utils image:self.image withColor:self.color];
}

@end
