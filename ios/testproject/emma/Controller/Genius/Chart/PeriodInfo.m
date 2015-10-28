//
//  PeriodInfo.m
//  emma
//
//  Created by ltebean on 15-4-8.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "PeriodInfo.h"

@interface PeriodInfo()
@property (nonatomic, strong) NSMutableArray *allPbs;
@property (nonatomic, strong) NSMutableArray *allCls;;
@property (nonatomic, strong) NSMutableArray *allOvulationDates;
@property (nonatomic, strong) NSMutableArray *allFertileWindows;

@end

@implementation PeriodInfo
+ (id)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)reloadData
{
    User *user = [User userOwnsPeriodInfo];
    self.allPbs = [NSMutableArray array];
    self.allCls = [NSMutableArray array];
    self.allOvulationDates = [NSMutableArray array];

    self.allFertileWindows = [NSMutableArray array];
    if (!user.prediction) {
        return;
    }
    
    BOOL hasFertile = user.shouldHaveFertileScore;
    for (NSDictionary *p in user.prediction) {
        [self.allFertileWindows addObject:@{
                                       @"pb": @([Utils dateLabelToIntFrom20130101:p[@"pb"]]),
                                       @"pe": @([Utils dateLabelToIntFrom20130101:p[@"pe"]]),
                                       @"fb": @([Utils dateLabelToIntFrom20130101:p[@"fb"]]),
                                       @"ov": @([Utils dateLabelToIntFrom20130101:p[@"ov"]]),
                                       @"fe": @([Utils dateLabelToIntFrom20130101:p[@"fe"]]),
                                       @"cl": p[@"cl"],
                                       @"cover_line": p[@"cover_line"] ? p[@"cover_line"] : @0,
                                       @"hasFertile": @(hasFertile),
                                       }];
    }

    for (NSDictionary *p in self.allFertileWindows) {
        [self.allPbs addObject:p[@"pb"]];
        [self.allCls addObject:p[@"cl"]];
        [self.allOvulationDates addObject:p[@"ov"]];
    }
}

- (NSInteger)cycleDayForDateIndex:(NSInteger)dateIndex
{
    for (NSInteger i = 0; i < [self.allPbs count]; i++) {
        if (dateIndex >= [self.allPbs[i] intValue] &&
            dateIndex < [self.allPbs[i] intValue] + [self.allCls[i] intValue]) {
            return dateIndex - [self.allPbs[i] intValue] + 1;
        }
    }
    return -1;
}

- (NSInteger)ovulationDayForDateIndex:(NSInteger)dateIndex
{
    if (self.allOvulationDates.count == 0) {
        return -1;
    }
    
    for (NSInteger i = 0; i < self.allOvulationDates.count-1; i++) {
        if (dateIndex >= [self.allOvulationDates[i] intValue] &&
            dateIndex < [self.allPbs[i+1] intValue]) {
            return dateIndex - [self.allOvulationDates[i] intValue];
        }
    }
    return -1;
}

- (NSArray *)fertileWindows
{
    return self.allFertileWindows;
}


@end
