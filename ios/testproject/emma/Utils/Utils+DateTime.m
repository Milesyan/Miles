//
//  Utils+DateTime.m
//  emma
//
//  Created by Xin Zhao on 13-12-21.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "Utils+DateTime.h"

@implementation Utils (DateTime)

+ (NSDate *)dateOfYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:day];
    [components setMonth:month];
    [components setYear:year];
    return [calendar dateFromComponents:components];
}

+ (NSDate *)dateOfHour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    [components setHour:hour];
    [components setMinute:minute];
    [components setSecond:second];
    return [calendar dateFromComponents:components];
}

+ (NSDate *)dateOfYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day hour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:day];
    [components setMonth:month];
    [components setYear:year];
    [components setHour:hour];
    [components setMinute:minute];
    [components setSecond:second];
    return [calendar dateFromComponents:components];
}

+ (NSInteger)daysWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate {
    return [endDate toDateIndex] - [startDate toDateIndex];
}

+ (NSInteger)monthsWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *day = [calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit fromDate:startDate];
    NSDateComponents *day2 = [calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit fromDate:endDate];

    return (day2.year - day.year) * 12 + day2.month - day.month;
}

+ (BOOL)date:(NSDate *)date1 isSameDayAsDate:(NSDate *)date2 {
    if (date1 == nil || date2 == nil) {
        return NO;
    }

    NSCalendar *calendar = [Utils calendar];

    NSDateComponents *day = [calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date1];
    NSDateComponents *day2 = [calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date2];
    return ([day2 day] == [day day] &&
            [day2 month] == [day month] &&
            [day2 year] == [day year] &&
            [day2 era] == [day era]);
}

+ (NSString *)dailyDataDateLabel:(NSDate *)date {
    NSCalendar *cal = [Utils calendar];
    NSDateComponents *components = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    NSInteger year = [components year];
    NSInteger month = [components month];
    NSInteger day = [components day];
    NSString *dateLabel = [NSString stringWithFormat:@"%04ld/%02ld/%02ld", year, month, day];

    return dateLabel;
}

+ (NSString *)reminderDateLabel:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"h:mm a"];
    NSString *hm = [dateFormatter stringFromDate:date];
    
    if ([Utils date:date isSameDayAsDate:[NSDate date]]) {
        return [NSString stringWithFormat:@"Today, %@", hm];
    } else {
        dateFormatter.dateFormat = @"MMM d";
        return [NSString stringWithFormat:@"%@, %@", [dateFormatter stringFromDate:date] ,hm];
    }
}

+ (NSString *)reminderDateSmallLabel:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"h:mm a"];
    NSString *hm = [dateFormatter stringFromDate:date];
    
    if ([Utils date:date isSameDayAsDate:[NSDate date]]) {
        return [NSString stringWithFormat:@"Today, %@", hm];
    } else {
        dateFormatter.dateFormat = @"M/d";
        return [NSString stringWithFormat:@"%@, %@", [dateFormatter stringFromDate:date] ,hm];
    }
}

+ (NSDate *)dateWithDateLabel:(NSString *)dateLabel {
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSMutableDictionary *dict = [threadDictionary objectForKey:@"dateWithDateLabelCache"];
    
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
    }
    NSDate *date = [dict objectForKey:dateLabel];
    if (!date) {
        NSArray *dateSplit = [dateLabel componentsSeparatedByString:@"/"];
        date = [self dateOfYear:[[dateSplit objectAtIndex:0] integerValue] month:[[dateSplit objectAtIndex:1] integerValue] day:[[dateSplit objectAtIndex:2] integerValue]];
        [dict setObject:date forKey:dateLabel];
        [threadDictionary setObject:dict forKey:@"dateWithDateLabelCache"];
    }
    return date;
}

+ (NSComparisonResult)compareByDay:(NSDate *)date toDate:(NSDate *)otherDate {
    NSCalendar *calendar = [Utils calendar];

    NSDateComponents *day = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
    NSDateComponents *day2 = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:otherDate];
    
    if (day.year < day2.year) {
        return NSOrderedAscending;
    } else if (day.year > day2.year) {
        return NSOrderedDescending;
    } else if (day.month < day2.month) {
        return NSOrderedAscending;
    } else if (day.month > day2.month) {
        return NSOrderedDescending;
    } else if (day.day < day2.day) {
        return NSOrderedAscending;
    } else if (day.day > day2.day) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

+ (BOOL)date:(NSDate *)date1 isSameMonthAsDate:(NSDate *)date2 {
    if (date1 == nil || date2 == nil) {
        return NO;
    }
    NSCalendar *calendar = [Utils calendar];
    
    NSDateComponents *day = [calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date1];
    NSDateComponents *day2 = [calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date2];
    return ([day2 month] == [day month] &&
            [day2 year] == [day year] &&
            [day2 era] == [day era]);
}

+ (BOOL)date:(NSDate *)date1 isSameYearAsDate:(NSDate *)date2 {
    if (date1 == nil || date2 == nil) {
        return NO;
    }
    NSCalendar *calendar = [Utils calendar];
    
    NSDateComponents *day = [calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date1];
    NSDateComponents *day2 = [calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date2];
    return ([day2 year] == [day year] &&
            [day2 era] == [day era]);
}


+ (NSDate *)dateByAddingDays:(NSInteger )days toDate:(NSDate *)date {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:days];
    return [calendar dateByAddingComponents:comps toDate:date options:0];
}

+ (NSDate *)dateByAddingMonths:(NSInteger )months toDate:(NSDate *)date {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMonth:months];
    return [calendar dateByAddingComponents:comps toDate:date options:0];
}

+ (NSDate *)dateByAddingYears:(NSInteger )years toDate:(NSDate *)date {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:years];
    return [calendar dateByAddingComponents:comps toDate:date options:0];
}

+ (NSString *)agoStringForDate:(NSDate *)date {
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:date];
    
    if (interval >= 2592000) {//60*60*24*30 One Month
        NSInteger months = (NSInteger)interval / 2592000;
        return [NSString stringWithFormat:@"%ld month%@ ago", (long)months, months == 1? @"": @"s"];
    } else if (interval >= 86400) {//60*60*24 One Day
        NSInteger days = (NSInteger)interval / 86400;
        return [NSString stringWithFormat:@"%ld day%@ ago", days, days == 1? @"" : @"s"];
    } else if (interval >= 3600) {//60*60 One Hour
        NSInteger hours = (NSInteger)interval / 3600;
        return [NSString stringWithFormat:@"%ld hour%@ ago", hours, hours == 1? @"" : @"s"];
    }  else if (interval >= 60) {//60 One Minute
        NSInteger minutes = (NSInteger)interval / 60;
        return [NSString stringWithFormat:@"%ld minute%@ ago", minutes, minutes == 1? @"" : @"s"];
    }  else if (interval >= 0) {//60 One Minute
        NSInteger seconds = (NSInteger)interval;
        if  (seconds == 0) { seconds = 1;};
        return [NSString stringWithFormat:@"%ld second%@ ago", seconds, seconds == 1? @"" : @"s"];
    }
    
    return @"";
}


+ (NSString *)dateLabelAfterDateLabel:(NSString *)dateLabel withDays:(NSInteger)days {
    NSDate *date = [self dateWithDateLabel:dateLabel];
    NSDate *dateAfter = [self dateByAddingDays:days toDate:date];
    return [self dailyDataDateLabel:dateAfter];
}

+ (NSInteger)daysBeforeDateLabel:(NSString *)dateLabel1 sinceDateLabel:(NSString *)dateLabel2 {
    NSDate *date1 = [self dateWithDateLabel:dateLabel1];
    NSDate *date2 = [self dateWithDateLabel:dateLabel2];
    return [self daysBeforeDate:date1 sinceDate:date2];
}

+ (NSInteger)dateLabel:(NSString *)dateLabel1 minus:(NSString *)dateLabel2 {
    return [Utils daysBeforeDateLabel:dateLabel1 sinceDateLabel:dateLabel2];
}

+ (NSInteger)daysBeforeDate:(NSDate *)date1 sinceDate:(NSDate *)date2 {
    return (NSInteger)round([date1 timeIntervalSinceDate:date2] / 86400.0f);
}

static NSDate *day20130101 = nil;
+ (NSDate *)cachedDay20130101 {
    if (!day20130101) {
        day20130101 = [self dateOfYear:2013 month:01 day:01];
    }
    return day20130101;
}

+ (NSInteger) dateToIntFrom20130101:(NSDate *)date {
    NSInteger timeInterval = [[date truncatedSelf] timeIntervalSinceDate:self.cachedDay20130101];
    return (NSInteger)round((double)timeInterval / 86400.0f);
}

+ (NSInteger) dateLabelToIntFrom20130101:(NSString *)dateLabel {
    return [self dateToIntFrom20130101:[self dateWithDateLabel:dateLabel]];
}

+ (NSDate *)dateIndexToDate:(NSInteger)dateIndex {
    return [self dateByAddingDays:dateIndex toDate:self.cachedDay20130101];
}

+ (NSString *) dateIndexToDateLabelFrom20130101:(NSInteger)idx {
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSMutableDictionary *dict = [threadDictionary objectForKey:@"dateIndexToDateLabel"];
    
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
    }
    if (!dict[@(idx)]) {
        dict[@(idx)] = [self dateLabelAfterDateLabel:@"2013/01/01" withDays:idx];
        [threadDictionary setObject:dict forKey:@"dateIndexToDateLabel"];
    }
    return dict[@(idx)];
}

+ (NSString *) dateIndexToShortDateLabelFrom20130101:(NSInteger)idx {
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSMutableDictionary *dict = [threadDictionary objectForKey:@"dateIndexToShortDateLabel"];
    
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
    }
    if (!dict[@(idx)]) {
        NSString *dateLabel = [self dateLabelAfterDateLabel:@"2013/01/01" withDays:idx];
        dateLabel = [dateLabel substringFromIndex:5];
        NSString *month = [dateLabel substringWithRange:NSMakeRange(0, 2)];
        NSString *day = [dateLabel substringWithRange:NSMakeRange(3, 2)];
        if ([month hasPrefix:@"0"]) {
            month = [month substringFromIndex:1];
        }
        if ([day hasPrefix:@"0"]) {
            day = [day substringFromIndex:1];
        }
        dateLabel = [NSString stringWithFormat:@"%@/%@", month, day];
        dict[@(idx)] = dateLabel;
        [threadDictionary setObject:dict forKey:@"dateIndexToShortDateLabel"];
    }
    return dict[@(idx)];
}


+ (BOOL)date:(NSDate *)date isSameDayAsLabel:(NSString *)dateLabel {
    return [dateLabel isEqualToString:date2Label(date)];
}

+ (NSDate *)monthFirstDate:(NSDate *)date {
    NSCalendar *cal = [Utils calendar];
    NSDateComponents *components = [cal components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    NSDateComponents *result = [[NSDateComponents alloc] init];
    [result setDay:1];
    [result setMonth:[components month]];
    [result setYear:[components year]];
    [result setHour:12];
    [result setMinute:0];
    [result setSecond:0];

    return [cal dateFromComponents:result];
}

+ (NSDate *)monthLastDate:(NSDate *)date {
    NSDate *tmp = [Utils monthFirstDate:date];
    tmp = [Utils dateByAddingMonths:1 toDate:tmp];
    return [Utils dateByAddingDays:-1 toDate:tmp];
}

+ (NSDate *)weekFirstDate:(NSDate *)date {
    NSCalendar *cal = [Utils calendar];
    NSDateComponents *components = [cal components:NSCalendarUnitWeekday fromDate:date];
    NSInteger weekday = components.weekday;//1 for Sunday

    if (weekday == 1) {
        return date;
    } else {
        return [Utils dateByAddingDays:(1 - weekday) toDate:date];
    }
}
+ (NSDate *)weekLastDate:(NSDate *)date {
    NSCalendar *cal = [Utils calendar];
    NSDateComponents *components = [cal components:NSCalendarUnitWeekday fromDate:date];
    NSInteger weekday = components.weekday;//1 for Sunday

    if (weekday == 7) {//7 for Saturday
        return date;
    } else {
        return [Utils dateByAddingDays:(7 - weekday) toDate:date];
    }
}

+ (NSString *)getMonthShortString:(NSDate *)date {
    NSArray * shorts = @[@"", @"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec"];
    NSInteger m = [date getMonth];
    return [shorts objectAtIndex:m];
}

+ (NSString *)monthDayOrToday:(NSDate *)date
{
    if (!date) {
        return @"";
    } else if ([Utils date:date isSameDayAsDate:[NSDate date]]) {
        return @"today";
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"M/d"];
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateFormatter setLocale:usLocale];

        return [dateFormatter stringFromDate:date];
    }
}
@end

@implementation NSDate (Utility)

- (NSNumber *)toTimestamp{
    return [NSNumber numberWithDouble:[self timeIntervalSince1970]];
}

- (NSString *)toDateLabel {
    return [Utils dailyDataDateLabel:self];
}

- (NSString *)toReadableDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    return [dateFormatter stringFromDate:self];
}

- (NSString *)toReadableFullDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    return [dateFormatter stringFromDate:self];
}

- (NSString *)weekdayString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE"];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    return [dateFormatter stringFromDate:self];
}

- (NSInteger)toDateIndex {
    return [Utils dateToIntFrom20130101:self];
}

- (NSDate *)truncatedSelf {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *comp = [calendar components:
            NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
            fromDate:self];
    return [Utils dateOfYear:[comp year] month:[comp month] day:[comp day]];
}

- (BOOL) isFutureDay {
    NSInteger todayIdx = [[NSDate date] toDateIndex];
    return [self toDateIndex] > todayIdx;
}

- (BOOL) isDaysAfterTomorrow{
    NSInteger todayIdx = [[NSDate date] toDateIndex];
    return [self toDateIndex] > todayIdx + 1;
}

- (BOOL)isPassedTime {
    return [self compare:[NSDate date]] == NSOrderedAscending;
}

- (NSInteger)getDay {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *day = [calendar components:
            NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|
            NSDayCalendarUnit fromDate:self];
    return [day day];
}

- (NSInteger)getMonth {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *day = [calendar components:NSEraCalendarUnit|
            NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
            fromDate:self];
    return [day month];
}

- (NSInteger)getYear {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *day = [calendar components:NSEraCalendarUnit|
            NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
            fromDate:self];
    return [day year];
}

- (NSInteger)getWeekDay {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *comps = [calendar components:NSWeekdayCalendarUnit
            fromDate:self];
    return [comps weekday];
}

- (NSInteger)getHour {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *comps = [calendar components:NSHourCalendarUnit
            fromDate:self];
    return [comps hour];
}

- (NSInteger)getMinute {
    NSCalendar *calendar = [Utils calendar];
    NSDateComponents *comps = [calendar components:NSMinuteCalendarUnit
            fromDate:self];
    return [comps minute];
}

@end

