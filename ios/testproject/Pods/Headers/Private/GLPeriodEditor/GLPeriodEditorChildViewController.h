//
//  GLPeriodEditorChildViewController.h
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-23.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLPeriodEditorViewController.h"

@interface GLPeriodEditorChildViewController : UIViewController
@property (nonatomic, weak) GLPeriodEditorViewController* containerViewController;
@property (nonatomic, weak) NSMutableArray *cycleDataList;
@property (nonatomic) MODE mode;
+ (instancetype)instance;
- (void)leftNavButtonPressed:(UIButton *)sender;
- (void)rightNavButtonPressed:(UIButton *)sender;

- (void)reloadData;
- (void)updateCycleData:(GLCycleData *)cycleData withPeriodBeginDate:(NSDate *)periodBeginDate periodEndDate:(NSDate *)periodEndDate;
- (void)addCycleData:(GLCycleData *)cycleData;
- (void)removeCycleData:(GLCycleData *)cycleData;
- (void)sendLoggingEvent:(LOGGING_EVENT)event data:(id)data;

- (BOOL)isLatestCycle:(GLCycleData *)cycleData;

@end
