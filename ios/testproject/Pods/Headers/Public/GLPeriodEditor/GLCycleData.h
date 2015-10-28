//
//  GLPeriodData.h
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-24.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface GLCycleAppearance: NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, strong) UIColor *backgroundColorForPeriod;
@property (nonatomic, copy) NSString *textForPeriodColor;
@end


@interface GLCycleData : NSObject
@property (nonatomic, copy) NSDate *periodBeginDate;
@property (nonatomic, copy) NSDate *periodEndDate;
@property (nonatomic, copy) NSDate *fertileWindowBeginDate;
@property (nonatomic, copy) NSDate *fertileWindowEndDate;
@property (nonatomic, readonly) BOOL isFuture;
@property (nonatomic) BOOL isPrediction;
@property (nonatomic) BOOL showAsPrediction;
@property (nonatomic, readonly) NSInteger periodLength;
@property (nonatomic) NSInteger cycleLength;
@property (strong, nonatomic) id model;

+ (instancetype)dataWithPeriodBeginDate:(NSDate *)beginDate periodEndDate:(NSDate *)endDate;
- (BOOL)periodContainsDate:(NSDate *)date;
@end
