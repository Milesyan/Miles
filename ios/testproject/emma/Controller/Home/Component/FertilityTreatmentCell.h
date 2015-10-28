//
//  AddMedicalLogCell.h
//  emma
//
//  Created by Peng Gu on 10/16/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalendarCell.h"


@class FertilityTreatmentCell;


@protocol FertilityTreatmentCellDelegate <NSObject>

- (void)tableViewCell:(UITableViewCell *)cell needsPerformSegue:(NSString *)segueIdentifier;

@end


@interface FertilityTreatmentCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UIView *appointmentView;
@property (nonatomic, strong) IBOutlet UIView *treatmentEndView;
@property (nonatomic, strong) IBOutlet UIView *medicalLogView;
@property (nonatomic, strong) IBOutlet UIView *summaryView;
@property (nonatomic, strong) IBOutlet UIView *seperatorView;
@property (weak, nonatomic) IBOutlet UIButton *logButton;

@property (nonatomic, weak) IBOutlet UILabel *appointmentTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *appointmentDateLabel;
@property (nonatomic, weak) IBOutlet UIImageView *appointmentArrowImageView;

@property (weak, nonatomic) IBOutlet UIButton *treatmentEndAskPregnancy;
@property (weak, nonatomic) IBOutlet UIButton *startCycleButton;

@property (nonatomic, assign) CGFloat heightThatFits;
@property (nonatomic, assign) BOOL hasLogs;

@property (nonatomic, weak) id<FertilityTreatmentCellDelegate> delegate;


- (void)configureWithDate:(NSDate *)date dateRelation:(DateRelationOfToday)dateRelation;

@end
