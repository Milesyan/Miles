//
//  OnboardingDataProviderMakeUpNormalTrack.m
//  emma
//
//  Created by Xin Zhao on 13-12-12.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "MakeUpOnboardingInfoViewController.h"
#import "OnboardingDataProviderMakeUpNormalTrack.h"

@implementation OnboardingDataProviderMakeUpNormalTrack
// Unlick OnboardingDataProviderNormalTrack, this is only for "AvoidPregnancy!"

- (NSArray *)_answerKeys {
    NSArray *missedSettings =
            ((MakeUpOnboardingInfoViewController*)self.receiver).missedSettings;
    NSMutableArray * result = [[NSMutableArray alloc] init];
    /*
    if ([missedSettings indexOfObject:SETTINGS_KEY_TIME_PLANED_CONCEIVE] != NSNotFound) {
        [result addObject:SETTINGS_KEY_TIME_PLANED_CONCEIVE];
    }
    */
    if ([missedSettings indexOfObject:SETTINGS_KEY_BIRTH_CONTROL] != NSNotFound) {
        [result addObject:SETTINGS_KEY_BIRTH_CONTROL];
    }
    //if ([missedSettings indexOfObject:SETTINGS_KEY_EXERCISE] != NSNotFound ||
    if ([missedSettings indexOfObject:SETTINGS_KEY_HEIGHT] != NSNotFound ||
        [missedSettings indexOfObject:SETTINGS_KEY_WEIGHT] != NSNotFound) {
        // [result addObject:SETTINGS_KEY_EXERCISE];
        [result addObject:SETTINGS_KEY_WEIGHT];
    }
    return result;
}

- (NSInteger)numberOfQuestions {
    return [[self _answerKeys] count];
}

- (void)_considerConceivingSelectedRow:(int)row atIndexPath:(NSIndexPath *)indexPath
{
    row += 1;
    self.storedAnswer[SETTINGS_KEY_TIME_PLANED_CONCEIVE] = @(row);
    [self.receiver onDataUpdatedIndexPath:[self indexPathFromChoiceSelectorTag:indexPath.row]];
}

- (NSString *)navigationTitle {
    return nil;
}
@end
