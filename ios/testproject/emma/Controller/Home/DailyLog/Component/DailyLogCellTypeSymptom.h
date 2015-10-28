//
//  SymptomCell.h
//  emma
//
//  Created by Peng Gu on 7/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DailyLogCellTypeExpandable.h"
#import "DailyLogConstants.h"

@class DailyLogCellTypeSymptom;

@protocol DailyLogCellTypeSymptomDelegate <NSObject>

- (void)symptomCellNeedsToPresentSymptomViewController:(DailyLogCellTypeSymptom *)cell;

@end

@interface DailyLogCellTypeSymptom : DailyLogCellTypeExpandable

@property (nonatomic, assign) SymptomType symptomType;

- (void)configureWithValueOne:(uint64_t)valueOne
                     valueTwo:(uint64_t)valueTwo
                  symptomType:(SymptomType)type;

@end
