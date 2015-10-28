//
// Copyright (c) 2012 Jason Kozemczak
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#define CALENDAR_EVENT_DATE_CHANGED @"CalendarEventDateChanged"
#define CALENDAR_EVENT_MONTH_CHANGED @"CalendarEventMonthChanged"
#define CALENDAR_EVENT_MONTH_CHANGING @"calendar_event_month_changing"

#define CALENDAR_HEIGHT (IS_IPHONE_6_PLUS ? 370.0f : (IS_IPHONE_6 ? 340.0f : 292.0f))

#define FULL_PAGE_WIDTH SCREEN_WIDTH

#define BEGIN_DATE_LIMIT [Utils dateOfYear:2013 month:1 day:1]

@protocol CKCalendarDelegate;


@interface CKCalendarView : UIView

enum {
    startSunday = 1,
    startMonday = 2,
};

typedef enum {
    dateTreatmentNone           = 0,
    dateTreatmentCountdown      = 1,
    dateTreatmentStartdate      = 2,
    dateAfterStartBeforeEnd     = 3,
    dateTreatmentLikeTTC        = 4
} DateTypeForTreatment;

typedef NSInteger startDay;

@property (nonatomic) startDay calendarStartDay;
@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) NSDate *minimumDate;
@property (nonatomic, strong) NSDate *maximumDate;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, weak) id<CKCalendarDelegate> delegate;

@property (nonatomic) float PAGE_WIDTH;
//@property (nonatomic) float PAGE_COUNT;
//@property (nonatomic, strong) NSDate *targetDate;
@property(nonatomic, strong) UIView *legends;

- (id)initWithStartDay:(startDay)firstDay;
- (id)initWithStartDay:(startDay)firstDay frame:(CGRect)frame;

- (NSDate *)nextDay:(NSDate *)date;
- (NSDate *)previousDay:(NSDate *)date;
- (BOOL)dateIsToday:(NSDate *)date;
- (BOOL)date:(NSDate *)date1 isSameDayAsDate:(NSDate *)date2;
- (UIColor *)calculateButtonTextColorForDate:(NSDate *)date;

- (void)moveCalendarToDate:(NSDate *)date animated:(BOOL)animated;
//- (void)updateBackgroundTiles:(NSDate *)date;
- (void)updateForPredictionChange;
- (void)updateForPredictionChangeInMonth:(NSDate *)date;
- (void)updateCheckmarks;
- (void)updateDateColors;
- (void)showLegends;
- (void)hideLegends;
- (void)hideOtherMonthTiles;
- (void)showAllMonthTiles;
- (void)updateBeginDate:(NSDate *)beginDate;



@property (nonatomic, strong) UIColor *dateTextColor;
@property (nonatomic, strong) UIColor *selectedDateTextColor;
@property (nonatomic, strong) UIColor *selectedDateBackgroundColor;
@property (nonatomic, strong) UIColor *currentDateTextColor;
@property (nonatomic, strong) UIColor *currentDateBackgroundColor;

@property (nonatomic, strong) UIColor *disabledDateTextColor;
@property (nonatomic, strong) UIColor *disabledDateBackgroundColor;

@end

@protocol CKCalendarDelegate <NSObject>

- (void)calendar:(CKCalendarView *)calendar didSelectDate:(NSDate *)date;

@end
