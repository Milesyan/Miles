//
//  Utils+DateTime.h
//  emma
//
//  Created by Xin Zhao on 13-12-21.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "Utils.h"

@interface NSDate (Utility)

- (NSNumber *)toTimestamp;
- (NSString *)toDateLabel;
- (NSString *)toReadableDate;
- (NSString *)toReadableFullDate;
- (NSInteger)toDateIndex;
- (NSDate *)truncatedSelf;
- (NSString *)weekdayString;
- (BOOL)isFutureDay;
- (BOOL)isDaysAfterTomorrow;
- (BOOL)isPassedTime;
- (NSInteger)getDay;
- (NSInteger)getMonth;
- (NSInteger)getYear;
- (NSInteger)getWeekDay;
- (NSInteger)getHour;
- (NSInteger)getMinute;

@end

@interface Utils (DateTime)

+ (NSString *)dailyDataDateLabel:(NSDate *)date;
+ (NSDate *)dateWithDateLabel:(NSString *)dateLabel;
+ (NSInteger) dateToIntFrom20130101:(NSDate *)date;
+ (NSInteger) dateLabelToIntFrom20130101:(NSString *)dateLabel;
+ (NSString *)dateIndexToDateLabelFrom20130101:(NSInteger)idx;
+ (NSDate *)dateIndexToDate:(NSInteger)dateIndex;
+ (NSString *)dateIndexToShortDateLabelFrom20130101:(NSInteger)idx;
+ (NSDate *)dateOfYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
+ (NSDate *)dateOfHour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second;
+ (NSDate *)dateOfYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day hour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second;
+ (NSString *)reminderDateLabel:(NSDate *)date;
+ (NSString *)reminderDateSmallLabel:(NSDate *)date;
+ (NSComparisonResult)compareByDay:(NSDate *)date toDate:(NSDate *)otherDate;
+ (BOOL)date:(NSDate *)date1 isSameDayAsDate:(NSDate *)date2;
+ (BOOL)date:(NSDate *)date1 isSameMonthAsDate:(NSDate *)date2;
+ (BOOL)date:(NSDate *)date1 isSameYearAsDate:(NSDate *)date2;
+ (NSDate *)dateByAddingDays:(NSInteger)days toDate:(NSDate *)date;
+ (NSDate *)dateByAddingMonths:(NSInteger)months toDate:(NSDate *)date;
+ (NSDate *)dateByAddingYears:(NSInteger)years toDate:(NSDate *)date;
+ (NSString *)dateLabelAfterDateLabel:(NSString *)dateLabel withDays:(NSInteger)days;
+ (NSInteger)daysBeforeDateLabel:(NSString *)dateLabel1 sinceDateLabel:(NSString *)dateLabel2;
+ (NSInteger)dateLabel:(NSString *)dateLabel1 minus:(NSString *)dateLabel2;
+ (NSInteger)daysBeforeDate:(NSDate *)date1 sinceDate:(NSDate *)date2;
+ (NSInteger)daysWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate;
+ (NSInteger)monthsWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate;
+ (NSString *)agoStringForDate:(NSDate *)date;
+ (BOOL)date:(NSDate *)date isSameDayAsLabel:(NSString *)dateLabel;
+ (NSDate *)monthFirstDate:(NSDate *)date;
+ (NSDate *)monthLastDate:(NSDate *)date;
+ (NSDate *)weekFirstDate:(NSDate *)date;
+ (NSDate *)weekLastDate:(NSDate *)date;
+ (NSString *)getMonthShortString:(NSDate *)date;
+ (NSString *)monthDayOrToday:(NSDate *)date;
@end
