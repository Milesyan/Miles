//
//  MedicalLogNewMedCell.m
//  emma
//
//  Created by Peng Gu on 10/24/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "MedicalLogNewMedCell.h"

@implementation MedicalLogNewMedCell


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.arrowImageView.highlightedImage = [Utils imageNamed:@"log-arrow" withColor:[UIColor whiteColor]];
    self.titleLabel.highlightedTextColor = [UIColor whiteColor];
}


- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    self.arrowImageView.highlighted = highlighted;
    self.titleLabel.highlighted = highlighted;
    
    self.backgroundColor = highlighted ? UIColorFromRGB(0x3f47ae) : UIColorFromRGB(0xFBFAF7);
}


- (void)configureWithItem:(MedicalLogItem *)item atIndexPath:(NSIndexPath *)indexPath
{

}

@end
