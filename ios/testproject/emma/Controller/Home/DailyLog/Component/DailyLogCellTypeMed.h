//
//  DailyLogCellTypeMed.h
//  emma
//
//  Created by Eric Xu on 12/30/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeBase.h"
#import "PillButton.h"
#import "MedManager.h"

@interface DailyLogCellTypeMed : DailyLogCellTypeBase
@property (nonatomic, strong) NSString *medName;
@property (nonatomic, strong) Medicine *model;

+ (DailyLogCellTypeMed *)getCellForMedName:(NSString *)med;
+ (DailyLogCellTypeMed *)getCellForMedicine:(Medicine *)med;

- (void)setDirectValue:(id)val forDate:(NSDate *)date;
@end
