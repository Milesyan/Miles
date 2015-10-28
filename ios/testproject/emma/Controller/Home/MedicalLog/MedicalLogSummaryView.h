//
//  MedicalLogSummary.h
//  emma
//
//  Created by Peng Gu on 10/30/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>


@class UserMedicalLog;
@class UILinkLabel;


@interface MedicalLogSummaryView : UIView


@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UILabel *mainLabel;


- (instancetype)initWithMedicalLog:(UserMedicalLog *)medicalLog;
- (instancetype)initWithMedicationLogs:(NSArray *)medicationLogs;


@end
