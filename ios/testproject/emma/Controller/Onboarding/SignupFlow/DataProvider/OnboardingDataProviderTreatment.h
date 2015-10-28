//
//  OnboardingDataProviderFertility.h
//  emma
//
//  Created by Jirong Wang on 10/31/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "OnboardingDataProvider.h"

@interface OnboardingDataProviderTreatment : OnboardingDataProvider

@property (nonatomic) BOOL isChangeStatus;
@property (nonatomic, assign) BOOL hasSelectedTreatmentType;

- (BOOL)isNatural;
- (BOOL)shouldHideQuestionAtIndexPath:(NSIndexPath *)indexPath;

@end
