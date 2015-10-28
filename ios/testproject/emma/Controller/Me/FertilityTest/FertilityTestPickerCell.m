//
//  FertilityTestPickerCell.m
//  emma
//
//  Created by Peng Gu on 7/23/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "FertilityTestPickerCell.h"
#import "FertilityTestItem.h"
#import "UILinkLabel.h"
#import "Tooltip.h"

@interface FertilityTestPickerCell ()

@property (nonatomic, weak) IBOutlet UILabel *questionLabel;
@property (nonatomic, weak) IBOutlet UIButton *answerButton;
@property (nonatomic, weak) IBOutlet UIButton *questionButton;

@property (nonatomic, strong) FertilityTestItem *fertilityItem;
@property (nonatomic, assign) BOOL hasTooltip;

@end


@implementation FertilityTestPickerCell

- (void)configureWithItem:(FertilityTestItem *)item answer:(NSString *)answer
{
    self.fertilityItem = item;

//    NSArray *keywords = [Tooltip keywords];
//    self.hasTooltip = [keywords containsObject:item.question];
//    self.questionButton.hidden = !self.hasTooltip;
    self.questionButton.hidden = item.isClinicItem;
    self.questionLabel.text = item.question;
    
    [self.answerButton setTitle:answer forState:UIControlStateNormal];
}


- (IBAction)questionButtonClicked:(id)sender
{
//    if (!self.hasTooltip) {
//        return;
//    }
    
    if ([self.delegate respondsToSelector:@selector(fertilityTestPickerCell:didClickQuestion:)]) {
        [self.delegate fertilityTestPickerCell:self didClickQuestion:self.fertilityItem];
    }
}


- (IBAction)answerButtonClicked:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(fertilityTestPickerCell:didClickAnswer:)]) {
        [self.delegate fertilityTestPickerCell:self didClickAnswer:self.fertilityItem];
    }
}


@end
