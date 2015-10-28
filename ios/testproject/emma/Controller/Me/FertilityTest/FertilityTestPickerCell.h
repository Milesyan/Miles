//
//  FertilityTestPickerCell.h
//  emma
//
//  Created by Peng Gu on 7/23/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FertilityTestItem;
@class FertilityTestPickerCell;

@protocol FertilityTestPickerCellDelegate <NSObject>

- (void)fertilityTestPickerCell:(FertilityTestPickerCell *)cell didClickQuestion:(FertilityTestItem *)item;
- (void)fertilityTestPickerCell:(FertilityTestPickerCell *)cell didClickAnswer:(FertilityTestItem *)item;

@end


@interface FertilityTestPickerCell : UITableViewCell

@property (nonatomic, weak) id<FertilityTestPickerCellDelegate> delegate;

- (void)configureWithItem:(FertilityTestItem *)item answer:(NSString *)answer;

@end
