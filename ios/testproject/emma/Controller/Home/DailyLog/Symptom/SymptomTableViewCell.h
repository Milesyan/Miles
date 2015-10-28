//
//  SymptomTableViewCell.h
//  emma
//
//  Created by Peng Gu on 7/23/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DailyLogConstants.h"

@class SymptomTableViewCell;

@protocol SymptomTableViewCellDelegate <NSObject>

- (void)SymptomTableViewCell:(SymptomTableViewCell *)cell didChangeSymptomIntensity:(SymptomIntensity)intensity;

@end


@interface SymptomTableViewCell : UITableViewCell

@property (nonatomic, weak) id<SymptomTableViewCellDelegate> delegate;
@property (nonatomic, weak) IBOutlet UILabel *symptomLabel;
@property (nonatomic, assign) SymptomType symptomType;

- (void)configureWithSymptomName:(NSString *)name
                     symptomType:(SymptomType)symptomType
                       intensity:(SymptomIntensity)intensity
                        delegate:(id<SymptomTableViewCellDelegate>)delegate;

@end
