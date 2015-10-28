//
//  OnboardingDataProviderTTC.h
//  emma
//
//  Created by Eric Xu on 12/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//


#import "OnboardingDataProvider.h"


@interface OnboardingDataProviderTTC : OnboardingDataProvider

// - (NSString *)_exerciseButtonTextWithAnswer:(id)answer;
- (NSString *)_weightButtonTextWithAnswer:(id)answer;
- (NSString *)_heightButtonTextWithAnswer:(id)answer;

- (void)_showWeightPickerWithAnswer:(id)answer
                        atIndexPath:(NSIndexPath *)indexPath;
- (void)_showHeightPickerWithAnswer:(id)answer
                        atIndexPath:(NSIndexPath *)indexPath;
- (NSString *)_BMIText;
@end
