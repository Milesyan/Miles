//
//  DailyLogCellTypePhysicalDiscomfort.h
//  emma
//
//  Created by Eric Xu on 7/11/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeMood.h"

#define PD_PAIN_DURING_SEX 512

@interface DailyLogCellTypePhysicalDiscomfort : DailyLogCellTypeExpandable
- (User *)user;
@property (weak, nonatomic) IBOutlet UILabel *feelingLabel;
@property (strong, nonatomic) IBOutletCollection(PillButton)
    NSArray *symptomButtons;

@end
