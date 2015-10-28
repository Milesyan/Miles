//
//  GLPeriodData.m
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-24.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLCycleData.h"
#import "GLDateUtils.h"

@implementation GLCycleAppearance
+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc]init];
    });
    return sharedInstance;
}
@end


@implementation GLCycleData

- (instancetype)initWithPeriodBeginDate:(NSDate *)beginDate periodEndDate:(NSDate *)endDate
{
    self = [super init];
    if (self) {
        _periodBeginDate = [GLDateUtils cutDate:beginDate];
        _periodEndDate = [GLDateUtils cutDate:endDate];
        if ([_periodBeginDate compare:[GLDateUtils cutDate:[NSDate date]]] == NSOrderedDescending) {
            _isFuture = YES;
        }
    }
    return self;
}

- (void)setPeriodBeginDate:(NSDate *)periodBeginDate
{
    _periodBeginDate = [GLDateUtils cutDate:periodBeginDate];
    if ([_periodBeginDate compare:[GLDateUtils cutDate:[NSDate date]]] == NSOrderedDescending) {
        _isFuture = YES;
    } else {
        _isFuture = NO;
    }
}


+ (instancetype)dataWithPeriodBeginDate:(NSDate *)beginDate periodEndDate:(NSDate *)endDate
{
    return [[GLCycleData alloc] initWithPeriodBeginDate:beginDate periodEndDate:endDate];
}

- (NSInteger)periodLength
{
    return [GLDateUtils daysBetween:self.periodBeginDate and:self.periodEndDate] + 1;
}

- (BOOL)periodContainsDate:(NSDate *)date
{
    NSDate *d = [GLDateUtils cutDate:date];
    if ([d compare:self.periodBeginDate] == NSOrderedAscending) {
        return NO;
    }
    if ([d compare:self.periodEndDate] == NSOrderedDescending) {
        return NO;
    }
    return YES;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"begin:%@ end:%@", [GLDateUtils descriptionForDate:self.periodBeginDate], [GLDateUtils descriptionForDate:self.periodEndDate]];
}

@end
