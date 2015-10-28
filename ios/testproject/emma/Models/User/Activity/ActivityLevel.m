//
//  FundActiveLevel.m
//  emma
//
//  Created by Eric Xu on 5/7/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ActivityLevel.h"

@interface ActivityLevel () {
    NSDate *month;
}

@end

@implementation ActivityLevel

- (void)setMonth:(NSDate *)newMonth {
    month = newMonth;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"MMMM"];
    [dateFormatter setLocale:usLocale];
    
    self.monthLabel = [dateFormatter stringFromDate:newMonth];

    /*
    NSCalendar *calendar = [Utils calendar];
    if ([Utils date:month isSameMonthAsDate:[NSDate date]]) {
        NSDateComponents *comp = [calendar components:NSDayCalendarUnit fromDate:month];
        [self setTotalDays:comp.day];
    } else {
        NSRange days = [calendar rangeOfUnit:NSDayCalendarUnit
                               inUnit:NSMonthCalendarUnit
                              forDate:month];
        [self setTotalDays:days.length];
    }
    */
}

- (NSDate *)getMonth {
    return month;
}

- (NSString *)activityDescription {
    NSDictionary *s = @{
        @(ACTIVITY_VERY_ACTIVE): @"Very active",
        @(ACTIVITY_MODERATELY): @"Active",
        @(ACTIVITY_OCCASIONALLY): @"Slightly active",
        @(ACTIVITY_INACTIVE): @"Below active",
        };
    return [s objectForKey:@(_activeLevel)];
}

@end
