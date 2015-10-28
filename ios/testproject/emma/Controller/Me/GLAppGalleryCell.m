//
//  GLAppGalleryCell.m
//  Lexie
//
//  Created by Allen Hsu on 6/5/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import "GLAppGalleryCell.h"

@implementation GLAppGalleryCell

- (void)awakeFromNib {
    self.actionButton.layer.cornerRadius = 4.0;
    self.actionButton.layer.masksToBounds = YES;
    self.actionButton.layer.borderColor = GLOW_COLOR_PURPLE.CGColor;
    self.actionButton.layer.borderWidth = 1.0;
    
    self.iconView.layer.cornerRadius = 12.0;
    self.iconView.layer.masksToBounds = YES;
    self.iconView.layer.borderColor = UIColorFromRGB(0xCCCCCC).CGColor;
    self.iconView.layer.borderWidth = 1.0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
