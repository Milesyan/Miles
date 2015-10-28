//
//  MedListCell.h
//  emma
//
//  Created by Peng Gu on 1/7/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UILinkLabel.h"
#import "PillButton.h"

#define kDailyLogNoneValue 0
#define kDailyLogCheckValue 2
#define kDailyLogCrossValue 1

#define kMedicalLogNoneValue 0
#define kMedicalLogCheckValue 1
#define kMedicalLogCrossValue 2


@class MedListCell;

@protocol MedListCellDelegate <NSObject>

- (void)medListCell:(MedListCell *)cell didUpdateValue:(NSInteger)value;

@end

@interface MedListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILinkLabel *titleLabel;
@property (weak, nonatomic) IBOutlet PillButton *checkButton;
@property (weak, nonatomic) IBOutlet PillButton *crossButton;

@property (weak, nonatomic) id<MedListCellDelegate> delegate;

- (void)configureWithValue:(NSInteger)value fertilityUser:(BOOL)isFertilityUser;

@end
