//
//  SymptomViewController.h
//  emma
//
//  Created by Peng Gu on 7/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DailyLogConstants.h"

@class DailyLogUndoManager;
@class UserDailyData;

@class SymptomViewController;

@protocol SymptomViewControllerDelegate <NSObject>

- (void)symptomViewController:(SymptomViewController *)viewController
            didUpdateSymptoms:(NSDictionary *)symptoms
                fieldOneValue:(NSNumber *)value1
                fieldTwoValue:(NSNumber *)value2;

- (void)symptomViewControllerDidAppear:(SymptomViewController *)viewController;

@end


@interface SymptomViewController : UITableViewController

@property (nonatomic, weak) id<SymptomViewControllerDelegate> delegate;
@property (nonatomic, assign) SymptomType symptomType;
@property (nonatomic, strong) DailyLogUndoManager *dailyLogUndoManager;
@property (nonatomic, strong) UserDailyData *userDailyData;

@property (nonatomic, strong) UIView *tableViewHeader;

@end
