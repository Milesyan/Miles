//
//  MedicalLogNewMedCell.h
//  emma
//
//  Created by Peng Gu on 10/24/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MedicalLogBinaryCell.h"

@interface MedicalLogNewMedCell : MedicalLogBinaryCell

@property (nonatomic, weak) IBOutlet UIImageView *arrowImageView;
@property (nonatomic, weak) IBOutlet UILabel *numberOfLoggedLabel;

@end
