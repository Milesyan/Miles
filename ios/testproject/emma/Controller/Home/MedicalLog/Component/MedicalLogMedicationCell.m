//
//  MedicalLogMedicationCell.m
//  emma
//
//  Created by Peng Gu on 10/24/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "MedicalLogMedicationCell.h"

@interface MedicalLogMedicationCell ()

@end


@implementation MedicalLogMedicationCell

- (void)awakeFromNib
{
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)configureWithItem:(MedicalLogItem *)item atIndexPath:(NSIndexPath *)indexPath
{
    [super configureWithItem:item atIndexPath:indexPath];
    if (item.isUserCreatedMedication) {
        self.titleLabel.textColor = GLOW_COLOR_PURPLE;
    }
    else {
        self.titleLabel.textColor = [UIColor blackColor];
    }
    self.titleLabel.text = item.name;
}



@end




