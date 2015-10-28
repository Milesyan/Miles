//
//  FundOngoingActivityCell.h
//  emma
//
//  Created by Jirong Wang on 11/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FundOngoingBaseCell.h"

@interface FundOngoingActivityCell : FundOngoingBaseCell

@property (strong, nonatomic) IBOutlet UILabel *monthLabel;
@property (strong, nonatomic) IBOutlet UILabel *activityLabel;
@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;

@property (nonatomic) BOOL active;
@property (nonatomic) float activeLevel;

@end
