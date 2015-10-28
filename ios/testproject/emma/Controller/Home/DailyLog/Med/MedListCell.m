//
//  MedListCell.m
//  emma
//
//  Created by Peng Gu on 1/7/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "MedListCell.h"


@interface MedListCell ()

@property (nonatomic, assign) BOOL isFertilityTreatmentUser;
@end


@implementation MedListCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (IBAction)checkButtonClicked:(id)sender
{
    [self.crossButton setSelected:NO animated:NO];
    if ([self.delegate respondsToSelector:@selector(medListCell:didUpdateValue:)]) {
        NSInteger value = kMedicalLogNoneValue;
        if (self.checkButton.selected) {
            value = self.isFertilityTreatmentUser ? kMedicalLogCheckValue : kDailyLogCheckValue;
        }
        [self.delegate medListCell:self didUpdateValue:value];
    }
}


- (IBAction)crossButtonClicked:(id)sender
{
    [self.checkButton setSelected:NO animated:NO];
    if ([self.delegate respondsToSelector:@selector(medListCell:didUpdateValue:)]) {
        NSInteger value = kMedicalLogNoneValue;
        if (self.crossButton.selected) {
            value = self.isFertilityTreatmentUser ? kMedicalLogCrossValue : kDailyLogCrossValue;
        }
        [self.delegate medListCell:self didUpdateValue:value];
    }
}


- (void)configureWithValue:(NSInteger)value fertilityUser:(BOOL)isFertilityUser
{
    self.isFertilityTreatmentUser = isFertilityUser;
    
    if (isFertilityUser) {
        self.checkButton.selected = value == kMedicalLogCheckValue;
        self.crossButton.selected = value == kMedicalLogCrossValue;
    }
    else {
        self.checkButton.selected = value == kDailyLogCheckValue;
        self.crossButton.selected = value == kDailyLogCrossValue;
    }
}


@end
