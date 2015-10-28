//
//  DailyLogCellTypeMood.h
//  emma
//
//  Created by Eric Xu on 4/26/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeExpandable.h"
#import "User.h"

@interface DailyLogCellTypeMood : DailyLogCellTypeExpandable
- (User *)user;
@property (strong, nonatomic) IBOutlet UILabel *feelingLabel;

@property (strong, nonatomic) IBOutlet PillButton *moodSad;
@property (strong, nonatomic) IBOutlet PillButton *moodMoody;
@property (strong, nonatomic) IBOutlet PillButton *moodStressed;
@property (strong, nonatomic) IBOutlet PillButton *moodAngry;
@property (strong, nonatomic) IBOutlet PillButton *moodAnxious;
@property (strong, nonatomic) IBOutlet PillButton *moodOther;

@end
