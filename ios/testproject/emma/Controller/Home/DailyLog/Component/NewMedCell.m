//
//  NewMedCell.m
//  emma
//
//  Created by Eric Xu on 1/10/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "NewMedCell.h"

@interface NewMedCell() {
    UIColor *origBGColor;
}
@property (nonatomic, strong) UIImage *logArrow;
@property (nonatomic, strong) UIImage *highlightedLogArrow;

@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIImageView *arrow;

@end

@implementation NewMedCell


+ (NSString *)reuseIdentifier
{
    return @"NewMedCellReuseIdentifier";
}


- (void)awakeFromNib {
    self.logArrow = [UIImage imageNamed:@"log-arrow"];
    self.highlightedLogArrow = [Utils imageNamed:@"log-arrow" withColor:[UIColor whiteColor]];
}

- (void)setHighlighted:(BOOL)selected animated:(BOOL)animated
{
    if (selected) {
        origBGColor = self.backgroundColor;
        self.backgroundColor = UIColorFromRGB(0x3f47ae);
        self.label.textColor = [UIColor whiteColor];
        self.arrow.image = self.highlightedLogArrow;
    } else {
        self.backgroundColor = origBGColor;
        self.label.textColor = UIColorFromRGB(0x5a5ad2);
        self.arrow.image = self.logArrow;
    }
}

@end
