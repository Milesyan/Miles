//
//  FertilityTestInputCell.h
//  emma
//
//  Created by Peng Gu on 7/13/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@class FertilityTestItem;
@class FertilityTestInputCell;

@protocol FertilityTestInputCellDelegate <NSObject>

- (void)fertilityTestInputCell:(FertilityTestInputCell *)cell
                 didInputValue:(NSString *)value
                       forItem:(FertilityTestItem *)item;

@end

@interface FertilityTestInputCell : UITableViewCell

@property (nonatomic, weak) id<FertilityTestInputCellDelegate> delegate;

- (void)configureWithItem:(FertilityTestItem *)item answer:(NSString *)answer;

@end
