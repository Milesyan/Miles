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


#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "CKCalendarView.h"
#import "User.h"
#import "UIView+Cache.h"
#import "Logging.h"
#import "DailyTodo.h"
#import "UserDailyData.h"
#import "UserMedicalLog.h"
#import "Appointment.h"
#import "PagedScrollView.h"
#import "NotesManager.h"
#import "DateButton.h"
#import "HealthProfileData.h"
#import "Utils+DateTime.h"
#import "CalendarDayInfoSummary.h"
#import <BlocksKit/NSArray+BlocksKit.h>

#define BUTTON_MARGIN 0
#define CALENDAR_MARGIN 0
#define TOP_HEIGHT 0
#define DAYS_HEADER_HEIGHT 22
#define LEGENDS_HEIGHT 30

#define ENLARGE_RATE 2.15f
#define ENLARGE_CELL_WIDTH 75.0f
#define BUTTON_FONT_SIZE 24.0f

#define CALENDAR_PADDING (IS_IPHONE_6_PLUS ? 27.0f : (IS_IPHONE_6 ? 23.0f : 20.0f))

#define CALENDAR_EVENT_DATE_BUTTON_CLICKED @"calendar_event_date_button_clicked"
#define CALENDAR_EVENT_MONTH_CHANGE_REQUIRED @"calendar_event_month_change_required"

//#define MAX_PASSED_MONTHS 20
#define MIN_PASSED_MONTHS 36
#define FUTURE_MONTHS 3
#define ON_SCRREN_TILES 2
//#define FULL_PAGE_COUNT 7
#define MT_TAG_BASE 100

typedef void (^Callback)(BOOL finished);

typedef struct Position{
    NSInteger x;
    NSInteger y;
} Position;



#pragma mark -
#pragma mark - Interface MonthTile

@interface MonthTile : UIView

@property (nonatomic, strong) NSMutableArray *dateButtons;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDate *monthShowing;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, assign) CGFloat cellWidth;
@property (nonatomic, assign) startDay calendarStartDay;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) UIColor *selectedDateTextColor;
@property (nonatomic, strong) UIColor *selectedDateBackgroundColor;
@property (nonatomic, strong) UIColor *currentDateTextColor;
@property (nonatomic, strong) UIView *selectedButtonBG;
@property (nonatomic, strong) DateButton *selectedButton;

- (NSInteger)numberOfWeeksInMonthContainingDate:(NSDate *)date;
+ (UIColor *)calculateBackgroundColorForDate:(NSInteger)dateIdx;
@end

#pragma mark -
#pragma mark - Implementation MonthTile

@implementation MonthTile

- (id)initWithStartDay:(startDay)firstDay frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self internalInit:firstDay];
    }
    return self;
}

- (void)awakeFromNib {
    [self internalInit:startMonday];
}

static UIColor *normalDaysColor = nil;
static UIColor *pink = nil;
static UIColor *green = nil;
static UIColor *red = nil;

- (void)internalInit:(startDay)firstDay {
    if (!normalDaysColor || !pink || !green || red) {
        pink = UIColorFromRGBA(0xE55A8CCD);
        red = UIColorFromRGB(0xFA1816);
        green = UIColorFromRGBA(0x6CBA2DD4);
        normalDaysColor = UIColorFromRGBA(0x5A62D200);
    }

    self.calendar = [Utils calendar];
    
    self.cellWidth = DEFAULT_CELL_WIDTH;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    self.dateFormatter.dateFormat = @"LLLL yyyy";

    _selectedDate = [NSDate date];
    _monthShowing = self.selectedDate;
    
    self.calendarStartDay = firstDay;
    
    NSMutableArray *dateButtons = [NSMutableArray array];
    for (NSInteger i = 0; i < 42; i++) {
        DateButton *dateButton = [[DateButton alloc] init];
        dateButton.tag = i;
        dateButton.calendar = self.calendar;
        dateButton.formatter = self.dateFormatter;
        dateButton.frame = [self calculateDateButtonFrame:i];
        [dateButton clearIcons];
        
        [dateButton setUserInteractionEnabled:YES];
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dateButtonPressed:)];
        [tapGestureRecognizer setNumberOfTapsRequired:1];
        [dateButton addGestureRecognizer:tapGestureRecognizer];

        [dateButtons addObject:dateButton];
        
        [self addSubview:dateButton];

    }
    self.dateButtons = dateButtons;
    
    [self setStyles];

    self.selectedButtonBG = [[UIView alloc] initWithFrame:CGRectMake(-100, -100, DEFAULT_CELL_WIDTH, DEFAULT_CELL_WIDTH)];
    self.selectedButtonBG.layer.cornerRadius = DEFAULT_CELL_WIDTH / 2.0;
    [self insertSubview:self.selectedButtonBG atIndex:0];

//    [self.layer setBorderColor:[[UIColor greenColor] CGColor]];
//    [self.layer setBorderWidth:0.4];
}


- (void)updateLook:(BOOL) selection
{
    NSInteger numberOfWeeksToShow = 6;
    
    NSDate *date = [self firstDayOfMonthContainingDate:self.monthShowing];
    while ([self placeInWeekForDate:date] != 0) {
        date = [self previousDay:date];
    }

    NSInteger dateIdx = [Utils dateToIntFrom20130101:date];
    NSInteger todayIdx = [Utils dateToIntFrom20130101:[NSDate date]];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setWeekOfMonth:numberOfWeeksToShow];
    NSDate *endDate = [self.calendar dateByAddingComponents:comps toDate:date options:0];
    NSInteger endDateIdx = [Utils dateToIntFrom20130101:endDate];
    
    NSUInteger dateButtonPosition = 0;
    
    NSArray *dailyDatas = @[];
    NSArray *dailyTodos = @[];
    NSArray *dailySexDatas = @[];
    NSArray *medicationLogs = @[];
    NSArray *appointments = @[];

    if (todayIdx > dateIdx) {
        dailyDatas = [[User userOwnsPeriodInfo] dailyDataDateLabelsWithLogOfMonth:self.monthShowing];
        dailyTodos = [DailyTodo dateLabelsForTodosInMonth:self.monthShowing forUser:[User userOwnsPeriodInfo]];
        dailySexDatas = [[User userOwnsPeriodInfo] dailyDataDateLabelsWithSexOfMonth:self.monthShowing];
        medicationLogs = [UserMedicalLog dateLabelsForMedicationLogsInMonth:self.monthShowing];
        appointments = [Appointment dateLabelsForAppointmentsInMonth:self.monthShowing];
        
        NSArray *dailylogsMeds = [[User userOwnsPeriodInfo] dailyDataDateLabelsWithMedsOfMonth:self.monthShowing];
        medicationLogs = [medicationLogs arrayByAddingObjectsFromArray:dailylogsMeds];
    }
    
    while (dateIdx <= endDateIdx ) {
        if (dateButtonPosition >= 42) {
            break;
        }
        DateButton *dateButton = [self.dateButtons objectAtIndex:dateButtonPosition];
        dateButton.date = date;

        NSString *dateLabel = [Utils dailyDataDateLabel:date];
        
        if (dateIdx > todayIdx) {
            dateButton.hasAppointment = [appointments containsObject:dateLabel];
            dateButton.hasMedication = NO;
            dateButton.hasSex = NO;
            dateButton.hasLog = NO;
            [dateButton updateIcons];
        }
        else {
            dateButton.hasAppointment = [appointments containsObject:dateLabel];
            dateButton.hasMedication = [medicationLogs containsObject:dateLabel];
            dateButton.hasSex = [dailySexDatas containsObject:dateLabel];
            dateButton.hasLog = ([dailyDatas containsObject:dateLabel] ||
                                 [dailyTodos containsObject:dateLabel] ||
                                 [medicationLogs containsObject:dateLabel] ||
                                 [NotesManager notesCountForDate:dateLabel] > 0);
            
            // only display icons for date in this month
            if ([self compareByMonth:date toDate:self.monthShowing] == NSOrderedSame) {
                [dateButton updateIcons];
            }
            else {
                [dateButton clearIcons];
            }
        }
        dateButton.alpha = 1.0;
        [dateButton setFont:[self dateIsToday:dateButton.date]? [Utils boldFont:BUTTON_FONT_SIZE]: [Utils defaultFont:BUTTON_FONT_SIZE]];

        dateButton.layer.backgroundColor = [MonthTile calculateBackgroundColorForDate:dateIdx].CGColor;
        
        if ([self date:dateButton.date isSameDayAsDate:self.selectedDate]) {
            [self buttonOnSelect:dateButton animated:NO complete:nil];
        }
        else if ([self compareByMonth:date toDate:self.monthShowing] != NSOrderedSame) {
            dateButton.alpha = 0.25;
            dateButton.layer.backgroundColor = [[UIColor colorWithCGColor:dateButton.layer.backgroundColor ] colorWithAlphaComponent:0.0f].CGColor;
        }

        date = [self nextDay:date];
        dateIdx++;
        dateButtonPosition++;
    }
}

- (NSUInteger) getIndexForDate:(NSDate *)date {
    NSDate *firstDate = [self firstDayOfMonthContainingDate:self.monthShowing];
    while ([self placeInWeekForDate:firstDate] != 0) {
        firstDate = [self previousDay:firstDate];
    }
    NSInteger firstDateIdx = [Utils dateToIntFrom20130101:firstDate];
    NSInteger dateIdx = [Utils dateToIntFrom20130101:date];
    NSInteger indexOfThisMonthTile = dateIdx - firstDateIdx;
    return (indexOfThisMonthTile < 0 || indexOfThisMonthTile >= 42) ? -1 : indexOfThisMonthTile;
}

- (void)updateCheckMarkForDate:(NSDate *)date {
    NSInteger indexOfThisMonthTile = [self getIndexForDate:date];
    
    if (indexOfThisMonthTile >= 0 && indexOfThisMonthTile < 42) {
        DateButton *dateButton = [self.dateButtons objectAtIndex:indexOfThisMonthTile];
        
        NSString *dateLabel = [Utils dailyDataDateLabel:date];
        UserDailyData *data = [UserDailyData getUserDailyData:dateLabel forUser:[User userOwnsPeriodInfo]];
        BOOL hasSex = data && [data hasSex];
        BOOL hasTodo = [DailyTodo hasCheckedTodosOnDate:dateLabel forUser:[User userOwnsPeriodInfo]];
        BOOL hasNote = [NotesManager notesCountForDate:dateLabel] > 0;
        BOOL hasTreatmentLog = [UserMedicalLog user:[User userOwnsPeriodInfo] hasMedicalLogsOnDate:dateLabel];
        
        NSArray * medicationLogs = [UserMedicalLog dateLabelsForMedicationLogsInMonth:self.monthShowing];
        NSArray * appointments = [Appointment dateLabelsForAppointmentsInMonth:self.monthShowing];
        
        dateButton.hasAppointment = [appointments containsObject:dateLabel];
        dateButton.hasMedication = [medicationLogs containsObject:dateLabel];
        dateButton.hasSex = hasSex;
        dateButton.hasLog = [data hasData] || hasTodo || hasNote || hasTreatmentLog;
        [dateButton updateIcons];
    }
}

- (void)updateCheckmarks {
    NSInteger numberOfWeeksToShow = 6;
    
    NSDate *date = [self firstDayOfMonthContainingDate:self.monthShowing];
    while ([self placeInWeekForDate:date] != 0) {
        date = [self previousDay:date];
    }
    NSInteger dateIdx = [Utils dateToIntFrom20130101:date];
    NSInteger todayIdx = [Utils dateToIntFrom20130101:[NSDate date]];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setWeekOfMonth:numberOfWeeksToShow];
    NSDate *endDate = [self.calendar dateByAddingComponents:comps toDate:date options:0];
    NSInteger endDateIdx = [Utils dateToIntFrom20130101:endDate];
    
    NSUInteger dateButtonPosition = 0;

    NSArray *dailyDatas = @[];
    NSArray *dailyTodos = @[];
    NSArray *dailySexDatas = @[];
    NSArray *medicationLogs = @[];
    NSArray *appointments = @[];
    
    if (todayIdx > dateIdx) {
        dailyDatas = [[User userOwnsPeriodInfo] dailyDataDateLabelsWithLogOfMonth:self.monthShowing];
        dailyTodos = [DailyTodo dateLabelsForTodosInMonth:self.monthShowing forUser:[User userOwnsPeriodInfo]];
        dailySexDatas = [[User userOwnsPeriodInfo] dailyDataDateLabelsWithSexOfMonth:self.monthShowing];
        medicationLogs = [UserMedicalLog dateLabelsForMedicationLogsInMonth:self.monthShowing];
        appointments = [Appointment dateLabelsForAppointmentsInMonth:self.monthShowing];
        
        NSArray *dailylogsMeds = [[User userOwnsPeriodInfo] dailyDataDateLabelsWithMedsOfMonth:self.monthShowing];
        medicationLogs = [medicationLogs arrayByAddingObjectsFromArray:dailylogsMeds];
    }
    
    while (dateIdx <= endDateIdx ) {
        if (dateButtonPosition >= 42) {
            break;
        }
        DateButton *dateButton = [self.dateButtons objectAtIndex:dateButtonPosition];
        NSString *dateLabel = [Utils dailyDataDateLabel:date];
        
        if (dateIdx > todayIdx) {
            dateButton.hasAppointment = [appointments containsObject:dateLabel];
            dateButton.hasMedication = NO;
            dateButton.hasSex = NO;
            dateButton.hasLog = NO;
            [dateButton updateIcons];
        }
        else {
            dateButton.hasAppointment = [appointments containsObject:dateLabel];
            dateButton.hasMedication = [medicationLogs containsObject:dateLabel];
            dateButton.hasSex = [dailySexDatas containsObject:dateLabel];
            dateButton.hasLog = ([dailyDatas containsObject:dateLabel] ||
                                 [dailyTodos containsObject:dateLabel] ||
                                 [UserMedicalLog user:[User userOwnsPeriodInfo] hasMedicalLogsOnDate:dateLabel] ||
                                 [NotesManager notesCountForDate:dateLabel] > 0);
            
            // only display icons for date in this month
            if ([self compareByMonth:date toDate:self.monthShowing] == NSOrderedSame) {
                [dateButton updateIcons];
            }
            else {
                [dateButton clearIcons];
            }
        }
        
        date = [self nextDay:date];
        dateIdx++;
        dateButtonPosition++;
    }
    
}

- (void) updateColor
{
    NSInteger numberOfWeeksToShow = 6;
    
    NSDate *date = [self firstDayOfMonthContainingDate:self.monthShowing];
    NSInteger monthStartIdx = [Utils dateToIntFrom20130101:date];
    NSDateComponents *monthComps = [[NSDateComponents alloc] init];
    [monthComps setMonth:1];
    NSDate *nextMonthStart = [self.calendar dateByAddingComponents:monthComps toDate:date options:0];
    NSInteger nextMonthStartIdx = [Utils dateToIntFrom20130101:nextMonthStart];
    
    while ([self placeInWeekForDate:date] != 0) {
        date = [self previousDay:date];
    }
    NSInteger dateIdx = [Utils dateToIntFrom20130101:date];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setWeekOfMonth:numberOfWeeksToShow];
    NSDate *endDate = [self.calendar dateByAddingComponents:comps toDate:date options:0];
    NSInteger endDateIdx = [Utils dateToIntFrom20130101:endDate];
    
    NSUInteger dateButtonPosition = 0;
    
    NSInteger selectedIdx = [Utils dateToIntFrom20130101:self.selectedDate];
    while (dateIdx <= endDateIdx ) {
        if (dateButtonPosition >= 42) {
            break;
        }
        DateButton *dateButton = [self.dateButtons objectAtIndex:dateButtonPosition];

        dateButton.layer.backgroundColor = [MonthTile calculateBackgroundColorForDate:dateIdx].CGColor;
        if (dateIdx == selectedIdx) {
            [self buttonOnSelect:dateButton animated:NO complete:nil];
        } else if (dateIdx < monthStartIdx || dateIdx >= nextMonthStartIdx) {
            dateButton.alpha = 0.25;
            dateButton.layer.backgroundColor = [[UIColor colorWithCGColor: dateButton.layer.backgroundColor] colorWithAlphaComponent:0.0f].CGColor;
        }
        dateIdx++;
        dateButtonPosition++;
    }
}


- (void)updateSelectionForDate:(NSDate *)date {
    for (DateButton *b in self.dateButtons) {
        if ([Utils date:b.date isSameDayAsDate:date]) {
            //
            [self buttonOnSelect:b animated:NO complete:nil];
            return;
        }
    }
    
}

- (void)setDaySameAsDate: (NSDate *)date {
    if ([Utils date:[NSDate date] isSameMonthAsDate:self.monthShowing]) {
        self.selectedDate = [NSDate date];
    } else {
        NSDateComponents *comp = [self.calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:self.monthShowing];
        [comp setDay:1];
        self.selectedDate = [self.calendar dateFromComponents:comp];
    }
    [self updateSelectionForDate:self.selectedDate];
}

 - (void)setStyles {
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectedDateTextColor:[UIColor whiteColor]];
}


- (NSInteger)numberOfWeeksInMonthContainingDate:(NSDate *)date {
    return [self.calendar rangeOfUnit:NSWeekCalendarUnit inUnit:NSMonthCalendarUnit forDate:date].length;
}

- (void)setSelectedDate:(NSDate *)selectedDate {
    _selectedDate = [self normalize:selectedDate];
}

#pragma mark - Calendar helpers
- (NSDate *)normalize:(NSDate *)date {
    NSDateComponents *comps = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
    comps.hour = 12;
    comps.minute = 0;
    comps.second = 0;
    return [self.calendar dateFromComponents:comps];
}

- (NSDate *)firstDayOfMonthContainingDate:(NSDate *)date {
    NSDateComponents *comps = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
    comps.day = 1;
    comps.hour = 12;
    comps.minute = 0;
    comps.second = 0;
    return [self.calendar dateFromComponents:comps];
}

- (NSDate *)firstDayOfNextMonthContainingDate:(NSDate *)date {
    NSDateComponents *comps = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
    comps.day = 1;
    comps.month = comps.month + 1;
    comps.hour = 12;
    comps.minute = 0;
    comps.second = 0;
    return [self.calendar dateFromComponents:comps];
}

- (NSComparisonResult)compareByMonth:(NSDate *)date toDate:(NSDate *)otherDate {
    NSDateComponents *day = [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:date];
    NSDateComponents *day2 = [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:otherDate];
    
    if (day.year < day2.year) {
        return NSOrderedAscending;
    } else if (day.year > day2.year) {
        return NSOrderedDescending;
    } else if (day.month < day2.month) {
        return NSOrderedAscending;
    } else if (day.month > day2.month) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSInteger)placeInWeekForDate:(NSDate *)date {
    NSDateComponents *compsFirstDayInMonth = [self.calendar components:NSWeekdayCalendarUnit fromDate:date];
    return (compsFirstDayInMonth.weekday - 1 - self.calendar.firstWeekday + 8) % 7;
}

- (BOOL)dateIsToday:(NSDate *)date {
    return [self date:[NSDate date] isSameDayAsDate:date];
}

- (BOOL)date:(NSDate *)date1 isSameDayAsDate:(NSDate *)date2 {
    return [Utils date:date1 isSameDayAsDate:date2];
}

- (NSInteger)weekNumberInMonthForDate:(NSDate *)date {
    // Return zero-based week in month
    NSInteger placeInWeek = [self placeInWeekForDate:self.monthShowing];
    NSDateComponents *comps = [self.calendar components:(NSDayCalendarUnit) fromDate:date];
    return (comps.day + placeInWeek - 1) / 7;
}


- (NSDate *)nextDay:(NSDate *)date {
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:1];
    return [self.calendar dateByAddingComponents:comps toDate:date options:0];
}

- (NSDate *)previousDay:(NSDate *)date {
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:-1];
    return [self.calendar dateByAddingComponents:comps toDate:date options:0];
}

- (NSInteger)numberOfDaysFromDate:(NSDate *)startDate toDate:(NSDate *)endDate {
    NSInteger startDay = [self.calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:startDate];
    NSInteger endDay = [self.calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:endDate];
    return endDay - startDay;
}

+ (UIColor *)calculateBackgroundColorForDate:(NSInteger)dateIdx {
    NSDate * giveDate = [Utils dateWithDateLabel:[Utils dateIndexToDateLabelFrom20130101:dateIdx]];

    DayInfo *dayInfo = [CalendarDayInfoSummary dayInfoForDate:giveDate];
    
    if (dayInfo.backgroundColorHexValue == GLOW_COLOR_PURPLE_HEX_VALUE) {
        return normalDaysColor;
    } else {
        return UIColorFromRGB(dayInfo.backgroundColorHexValue);
    }
}

- (UIColor *)calculateButtonTextColorForDate:(NSDate *)date
{
    return [UIColor whiteColor];
}

- (Position)calculateDayCellPosition:(NSDate *)date {
    NSInteger numberOfDaysSinceBeginningOfThisMonth = [self numberOfDaysFromDate:self.monthShowing toDate:date];
    NSInteger row = (numberOfDaysSinceBeginningOfThisMonth + [self placeInWeekForDate:self.monthShowing]) / 7;
    NSInteger placeInWeek = [self placeInWeekForDate:date];

    struct Position temp;
    temp.x = placeInWeek;
    temp.y = row;
    return temp;
}

- (Position)calculateDateButtonPosition:(NSInteger)tag {
    //tag [1, 42];
    struct Position temp;
    temp.x = tag % 7;
    temp.y = tag / 7;

    return temp;
}

- (CGRect)calculateDateButtonFrame:(NSInteger) tag {
    Position p = [self calculateDateButtonPosition:tag];
    CGRect f = CGRectMake(p.x* (self.cellWidth + CELL_BORDER_WIDTH) + CALENDAR_PADDING + CELL_BORDER_WIDTH/2, (p.y* (self.cellWidth + CELL_BORDER_WIDTH)) + CELL_BORDER_WIDTH + DAYS_HEADER_HEIGHT, self.cellWidth, self.cellWidth);
    return f;
}

- (void)setCalendarStartDay:(startDay)calendarStartDay {
    _calendarStartDay = calendarStartDay;
    [self.calendar setFirstWeekday:self.calendarStartDay];
//    [self updateDayOfWeekLabels];
//    [self setNeedsLayout];
}

- (void)setLocale:(NSLocale *)locale {
    [self.dateFormatter setLocale:locale];
//    [self updateDayOfWeekLabels];
//    [self setNeedsLayout];
}

- (NSLocale *)locale {
    return self.dateFormatter.locale;
}

- (void)setMonthShowing:(NSDate *)aMonthShowing {
    _monthShowing = [self firstDayOfMonthContainingDate:aMonthShowing];
    [self updateLook:NO];
}

- (void)dateButtonPressed:(UITapGestureRecognizer *)sender {
    DateButton *dateButton = (DateButton *)sender.view;
    
    NSDate *date = dateButton.date;
    
    if (![Utils date:date isSameMonthAsDate:_monthShowing]) {
        [self publish:CALENDAR_EVENT_MONTH_CHANGE_REQUIRED data:date];
        return;
    }

    [self buttonOnSelect:dateButton animated:YES complete:nil];
    [self publish:CALENDAR_EVENT_DATE_CHANGED data:date];
    [self publish:CALENDAR_EVENT_DATE_BUTTON_CLICKED data:date];

    _selectedDate = date;
    
    // logging
    // [Logging log:BTN_CLK_HOME_CK_DAY];
}

- (void)buttonOnSelect:(DateButton *)button animated:(BOOL) animated complete:(Callback)callback{
    [self buttonOnDeselect:self.selectedButton complete:nil];
    
    self.selectedButton = button;
    self.selectedButtonBG.backgroundColor = [[UIColor colorWithCGColor:button.layer.backgroundColor] colorWithAlphaComponent:0.9];
    self.selectedButtonBG.center = button.center;
    
    button.layer.backgroundColor = [[UIColor colorWithCGColor:button.layer.backgroundColor] colorWithAlphaComponent:0].CGColor;

    self.selectedButtonBG.transform = CGAffineTransformIdentity;
    if (animated) {
        [UIView animateWithDuration:0.15 animations:^{
            self.selectedButtonBG.transform = CGAffineTransformMakeScale(ENLARGE_RATE, ENLARGE_RATE);
        }];
    } else {
        self.selectedButtonBG.transform = CGAffineTransformMakeScale(ENLARGE_RATE, ENLARGE_RATE);
    }
}

- (void)buttonOnDeselect:(DateButton *) button complete:(Callback) callback{
    if (self.selectedButtonBG.superview && CGPointEqualToPoint(self.selectedButtonBG.center, button.center)) {
        UIColor *bgColor = [MonthTile calculateBackgroundColorForDate:[Utils dateToIntFrom20130101:button.date]];
        
        if (button.alpha == 1) {
            button.layer.backgroundColor = [bgColor CGColor];
        } else {
            //MonthTile is reused. If current button now is displaying a date that is not current month,
            //the button will show as alpha=0.25, and the bg color should not show(setting to alpha 0).
            button.layer.backgroundColor = [[bgColor colorWithAlphaComponent:0.0] CGColor];
        }
    }
}
@end


#pragma mark -
#pragma mark - Interface CKCalendarView

@interface CKCalendarView () <UIScrollViewDelegate, PagedScrollViewDelegate> {
    BOOL userSwiped;
    NSDate *oldSelectedDate;
    NSDate *monthChangingDate;

    NSInteger totalMonths;
    NSDate *targetDate;
    NSInteger maxPassedMonths;
}

@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) NSArray *dayOfWeekLabels;

@property(nonatomic, strong) NSCalendar *calendar;
@property(nonatomic, strong) NSDateFormatter *dateFormatter;
@property(nonatomic, strong) PagedScrollView *scrollView;
@property(nonatomic, strong) NSMutableArray *monthTiles;

@end

#pragma mark -
#pragma mark - Implementation CKCalendarView

@implementation CKCalendarView
@dynamic locale;

- (void)awakeFromNib {
//    GLLog(@"BEGIN_DATE_LIMIT:%@", BEGIN_DATE_LIMIT);
    maxPassedMonths = [Utils monthsWithinEraFromDate:[self normalize:BEGIN_DATE_LIMIT] toDate:[NSDate date]];
//    GLLog(@"MAX_PASSED_MONTHS:%d", maxPassedMonths);
}

- (id)init {
    return [self initWithStartDay:startSunday];
}

- (id)initWithStartDay:(startDay)firstDay {
    return [self initWithStartDay:firstDay frame:CGRectZero];
}

- (void)internalInit:(startDay)firstDay {
    totalMonths = MIN_PASSED_MONTHS + 1 + FUTURE_MONTHS;

    self.calendar = [Utils calendar];

    self.PAGE_WIDTH = FULL_PAGE_WIDTH;
//    self.PAGE_COUNT = FULL_PAGE_COUNT;

    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    self.dateFormatter.dateFormat = @"LLLL yyyy";

//    [self updateBackgroundTiles:[NSDate date]];
    [self publish:CALENDAR_EVENT_DATE_BUTTON_CLICKED data:[NSDate date]];
    
    self.calendarStartDay = firstDay;

    NSMutableArray *labels = [NSMutableArray array];
    for (NSInteger i = 0; i < 7; ++i) {
        UILabel *dayOfWeekLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        dayOfWeekLabel.textAlignment = NSTextAlignmentCenter;
        dayOfWeekLabel.backgroundColor = [UIColor clearColor];
        dayOfWeekLabel.shadowColor = [UIColor grayColor];
        dayOfWeekLabel.shadowOffset = CGSizeMake(0, 1);

        [labels addObject:dayOfWeekLabel];
        [self addSubview:dayOfWeekLabel];
    }
    self.dayOfWeekLabels = labels;

    self.scrollView = [[PagedScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, CALENDAR_HEIGHT) pageSize:FULL_PAGE_WIDTH pageCount:totalMonths];
    self.scrollView.delegate = self;
    self.scrollView.bounces = YES;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.contentSize = CGSizeMake(totalMonths*FULL_PAGE_WIDTH, CALENDAR_HEIGHT);
    [self addSubview:self.scrollView];

    NSDate *beginDate = [Utils dateByAddingMonths:-1*(totalMonths - 1 - FUTURE_MONTHS) toDate:[NSDate date]];

    self.minimumDate = [Utils monthFirstDate:beginDate];
    self.maximumDate = [self previousDay:[Utils monthFirstDate:[Utils dateByAddingMonths:(FUTURE_MONTHS + 1) toDate:[NSDate date]]]];

    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:ON_SCRREN_TILES];
    for(NSInteger i=0;i <ON_SCRREN_TILES; i ++ ) {
        MonthTile *mt = [[MonthTile alloc] initWithStartDay:firstDay frame:CGRectMake(0, TOP_HEIGHT, SCREEN_WIDTH, CALENDAR_HEIGHT)];
        [self.scrollView addSubview:mt];
        [arr addObject:mt];
    }
    
    self.monthTiles = [NSMutableArray arrayWithArray:arr];

    [self updateDayOfWeekLabels];

    [self setDefaultStyle];

    CGRect lastDayFrame = CGRectMake(CALENDAR_PADDING - CELL_BORDER_WIDTH/2, 0, 0, 0);
    for (UILabel *dayLabel in self.dayOfWeekLabels) {
        dayLabel.frame = CGRectMake(CGRectGetMaxX(lastDayFrame) + CELL_BORDER_WIDTH, lastDayFrame.origin.y, DEFAULT_CELL_WIDTH, DAYS_HEADER_HEIGHT);
        [dayLabel setBackgroundColor:[UIColor clearColor]];
        [dayLabel setTextColor:[UIColor whiteColor]];
        lastDayFrame = dayLabel.frame;
    }

    self.legends = [self legendsView];
    [self addSubview:self.legends];

    __weak CKCalendarView *_self = self;
//    [self subscribe:CALENDAR_EVENT_DATE_BUTTON_CLICKED handler:^(Event *event){
//        NSDate *date = (NSDate *)event.data;
//        [_self updateBackgroundTiles:date];
//    }];
    [self subscribe:CALENDAR_EVENT_MONTH_CHANGE_REQUIRED
            handler:^(Event *event){
                NSDate *date = (NSDate *)event.data;
                
                float offsetX = _self.scrollView.contentOffset.x;

                if ( (offsetX == 0 && [Utils compareByDay:date toDate:_self.minimumDate] == NSOrderedAscending)
                    || (offsetX == FULL_PAGE_WIDTH * (totalMonths - 1) && [Utils compareByDay:date toDate:_self.maximumDate] == NSOrderedDescending) ) {
                    GLLog(@"Do nothing");
                } else {
                    [_self moveCalendarToDate:date animated:YES];
                }

            }];
    [self subscribe:EVENT_USERDAILYDATA_UPDATED_FROM_SERVER handler:^(Event *event) {
        NSString *dateLabel = (NSString *)event.data;
        [_self updateCheckMarkForDate:label2Date(dateLabel)];
    }];
    [self subscribe:EVENT_DAILY_TODO_UPDATED_FROM_SERVER handler:^(Event *event) {
        NSString *dateLabel = (NSString *)event.data;
        [_self updateCheckMarkForDate:label2Date(dateLabel)];
    }];
    [self subscribe:EVENT_DAILY_TODO_CHECKED handler:^(Event *event) {
        NSString *dateLabel = (NSString *)event.data;
        [_self updateCheckMarkForDate:label2Date(dateLabel)];
    }];

    [self subscribe:EVENT_DAILY_LOG_SAVED handler:^(Event *event) {
        NSDate *date = (NSDate *)event.data;
        [_self updateCheckMarkForDate:date];
    }];
    [self subscribe:EVENT_MEDICAL_LOG_SAVED handler:^(Event *event) {
        NSDate *date = (NSDate *)event.data;
        [_self updateCheckMarkForDate:date];
    }];
    [self subscribe:EVENT_USER_LOGGED_OUT selector:@selector(clearFromLogout)];
}


- (id)initWithStartDay:(startDay)firstDay frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self internalInit:firstDay];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithStartDay:startSunday frame:frame];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self internalInit:startSunday];
    }

    return self;
}

- (void)updateDayOfWeekLabels {
    NSLocale *locale = self.dateFormatter.locale;
    [self.dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    NSArray *weekdays = [self.dateFormatter shortWeekdaySymbols];

    NSUInteger firstWeekdayIndex = [self.calendar firstWeekday] - 1;
    if (firstWeekdayIndex > 0) {
        weekdays = [[weekdays subarrayWithRange:NSMakeRange(firstWeekdayIndex, 7 - firstWeekdayIndex)]
                    arrayByAddingObjectsFromArray:[weekdays subarrayWithRange:NSMakeRange(0, firstWeekdayIndex)]];
    }

    NSUInteger i = 0;
    for (NSString *day in weekdays) {
        [[self.dayOfWeekLabels objectAtIndex:i] setText:[day uppercaseString]];
        i++;
    }
    
    [self.dateFormatter setLocale:locale];
}

- (void)setDefaultStyle {
    [self setDayOfWeekFont:[Utils defaultFont:8.0]];
    [self setDayOfWeekTextColor:UIColorFromRGB(0xDADADA)];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectedDateTextColor:[UIColor whiteColor]];
    [self setCurrentDateTextColor:UIColorFromRGB(0xF2F2F2)];

    self.disabledDateTextColor = [UIColor lightGrayColor];
}


//- (void)updateBackgroundTiles:(NSDate *)date {
//    for (NSInteger i = 0; i < FULL_PAGE_COUNT; i++) {
//        MonthTile *mt = [self.monthTiles objectAtIndex:i];
//        if (![Utils date:date isSameMonthAsDate:mt.selectedDate]) {
//            [mt setDaySameAsDate:date];
//        }
//    }
//}

- (void)moveCalendarToDate:(NSDate *)date animated:(BOOL)animated{

    NSInteger pageIndex = [self indexForMonth:date];
    if (pageIndex == NSNotFound) {
        return;
    }

    NSInteger currentIndex = [self indexForMonth:self.selectedDate];

    if (ABS(currentIndex - pageIndex) > 1) {
        NSInteger adjust = 1 * (currentIndex - pageIndex)/ABS(currentIndex - pageIndex);
        [self.scrollView setContentOffset:CGPointMake((pageIndex + adjust)* FULL_PAGE_WIDTH, 0) animated:NO];
    }

    [self.scrollView setContentOffset:CGPointMake(pageIndex* FULL_PAGE_WIDTH, 0) animated:animated];

    MonthTile *tile = [self monthTileForPageIndex:pageIndex];
    if (tile) {
        tile.selectedDate = date;
        [tile updateSelectionForDate:date];
    } else {
        targetDate = date;
    }

    _selectedDate = date;

}

#pragma mark - Theming getters/setters

- (void)setDayOfWeekFont:(UIFont *)font {
    for (UILabel *label in self.dayOfWeekLabels) {
        label.font = font;
    }
}

- (void)setDayOfWeekTextColor:(UIColor *)color {
    for (UILabel *label in self.dayOfWeekLabels) {
        label.textColor = color;
    }
}


#pragma mark - Calendar helpers

- (NSComparisonResult)compareByMonth:(NSDate *)date toDate:(NSDate *)otherDate {
    NSDateComponents *day = [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:date];
    NSDateComponents *day2 = [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:otherDate];

    if (day.year < day2.year) {
        return NSOrderedAscending;
    } else if (day.year > day2.year) {
        return NSOrderedDescending;
    } else if (day.month < day2.month) {
        return NSOrderedAscending;
    } else if (day.month > day2.month) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSInteger)placeInWeekForDate:(NSDate *)date {
    NSDateComponents *compsFirstDayInMonth = [self.calendar components:NSWeekdayCalendarUnit fromDate:date];
    return (compsFirstDayInMonth.weekday - 1 - self.calendar.firstWeekday + 8) % 7;
}

- (BOOL)dateIsToday:(NSDate *)date {
    return [self date:[NSDate date] isSameDayAsDate:date];
}

- (BOOL)date:(NSDate *)date1 isSameDayAsDate:(NSDate *)date2 {
    // Both dates must be defined, or they're not the same
    if (date1 == nil || date2 == nil) {
        return NO;
    }

    NSDateComponents *day = [self.calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date1];
    NSDateComponents *day2 = [self.calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date2];
    return ([day2 day] == [day day] &&
            [day2 month] == [day month] &&
            [day2 year] == [day year] &&
            [day2 era] == [day era]);
}


- (NSDate *)nextDay:(NSDate *)date {
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:1];
    return [self.calendar dateByAddingComponents:comps toDate:date options:0];
}

- (NSDate *)previousDay:(NSDate *)date {
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:-1];
    return [self.calendar dateByAddingComponents:comps toDate:date options:0];
}

- (NSInteger)numberOfDaysFromDate:(NSDate *)startDate toDate:(NSDate *)endDate {
    NSInteger startDay = [self.calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:startDate];
    NSInteger endDay = [self.calendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:endDate];
    return endDay - startDay;
}

- (UIColor *)calculateButtonTextColorForDate:(NSDate *)date
{
    return [UIColor whiteColor];
}

- (NSDate *)normalize:(NSDate *)date {
    NSDateComponents *comps = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:date];
    //Setting hour to 12 to make sure:
    //In most tz(except the one on IDL(International Date Line)), the month/day always be the same digits.
    comps.hour = 12;
    comps.minute = 0;
    comps.second = 0;
    return [self.calendar dateFromComponents:comps];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (userSwiped) {
        CGPoint offset = self.scrollView.contentOffset;
        NSInteger pageIndex = (offset.x + FULL_PAGE_WIDTH/2)/FULL_PAGE_WIDTH;
        MonthTile *tile = [self monthTileForPageIndex:pageIndex];

        if (monthChangingDate != tile.selectedDate) {
            [self publish:CALENDAR_EVENT_MONTH_CHANGING data:tile.selectedDate];
            monthChangingDate = tile.selectedDate;
        }
    }
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    userSwiped = YES;
    oldSelectedDate = self.selectedDate;
    monthChangingDate = self.selectedDate;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self scrollEnded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self scrollEnded];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollEnded];
}

- (void)scrollEnded {
    userSwiped = NO;
    monthChangingDate = nil;
    
    CGPoint offset = self.scrollView.contentOffset;
    NSInteger i = offset.x/FULL_PAGE_WIDTH;
    
    MonthTile *mt = [self monthTileForPageIndex:i];
    if (self.selectedDate != mt.selectedDate) {
        self.selectedDate = mt.selectedDate;
    }

    [self publish:CALENDAR_EVENT_DATE_CHANGED data:self.selectedDate];
    if (![Utils date:oldSelectedDate isSameMonthAsDate:[mt selectedDate]]) {
        [self publish:CALENDAR_EVENT_MONTH_CHANGED];
    }
}

- (void)setSelectedDate:(NSDate *)selectedDate {
    _selectedDate = selectedDate;
    [self moveCalendarToDate:selectedDate animated:NO];
//    self.MonthTile.selectedDate = selectedDate;
}

- (void)updateCheckmarks {
    for (NSInteger i = 0; i < totalMonths; i++) {
        MonthTile *mt = [self monthTileForPageIndex:i];
        if (mt) {
            [mt updateCheckmarks];
        }
    }
}

- (void)updateDateColors
{
    for (NSInteger i = 0; i < totalMonths; i++) {
        MonthTile *mt = [self monthTileForPageIndex:i];
        if (mt) {
            [mt updateColor];
        }
    }
}

- (void)updateForPredictionChange {
    for (NSInteger i = 0; i < totalMonths; i++) {
        MonthTile *mt = [self monthTileForPageIndex:i];
        if (mt) {
            [mt updateColor];
        }
    }

    [self.legends removeFromSuperview];
    self.legends = [self legendsView];
    [self addSubview:self.legends];
}

- (MonthTile *)getValidMonthTile:(NSDate *)date {
    NSInteger pageIndex = [self indexForMonth:date];
    if (pageIndex == NSNotFound) {
        return nil;
    }
    MonthTile *mt = [self monthTileForPageIndex:pageIndex];
    if (mt) {
        return mt;
    }
    
    return nil;
}

- (void)updateForPredictionChangeInMonth:(NSDate *)date {
    MonthTile *mt = [self getValidMonthTile:date];
    if (mt) {
        [mt updateColor];
    }
}

- (void)updateCheckMarkForDate:(NSDate *)date {
    MonthTile *mt = [self getValidMonthTile:date];
    if (mt) {
        [mt updateCheckMarkForDate:date];
    }
}

- (void)showLegends {
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.legends.center = CGPointMake(SCREEN_WIDTH/2, CALENDAR_HEIGHT - 15);
                         self.legends.alpha = 1;
                     }
                     completion:nil];
    
}

- (void)hideLegends {
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.legends.center = CGPointMake(SCREEN_WIDTH/2, CALENDAR_HEIGHT + 15);
                         self.legends.alpha = 0;
                     }
                     completion:nil];
}

- (UIView *)legendsView
{
    CGFloat viewWidth = SCREEN_WIDTH - 8 * 2;
    UIView *legends = [[UIView alloc] initWithFrame:CGRectMake(8, CALENDAR_HEIGHT - 30, viewWidth, 30)];
    legends.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    legends.layer.cornerRadius = 2;
    
    UIImageView *(^addImage)(NSString *, CGFloat) = ^UIImageView *(NSString *imageName, CGFloat originX) {
        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        icon.frame = CGRectMake(originX, 8, 12, 12);
        [legends addSubview:icon];
        return icon;
    };
    
    UIImageView *(^addDot)(DayType, CGFloat) = ^UIImageView *(DayType daytype, CGFloat originX) {
        UIImageView *dot = [[UIImageView alloc] initWithFrame:CGRectMake(originX, 10, 8, 8)];
        dot.backgroundColor = [CKCalendarView legendColor:daytype];
        dot.layer.cornerRadius = 4;
        dot.layer.masksToBounds = YES;
        [legends addSubview:dot];
        return dot;
    };
    
    UILabel *(^addLabel)(NSString *, CGFloat, CGFloat) = ^UILabel *(NSString *text, CGFloat originX, CGFloat width) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(originX, 10, width, 10)];
        label.backgroundColor = [UIColor clearColor];
        label.text = text;
        label.textColor = [UIColor whiteColor];
        label.font = [Utils defaultFont:11];
        [legends addSubview:label];
        return label;
    };
    
    CGFloat offset = 0;
    CGFloat padding = 0;
    if ([User userOwnsPeriodInfo].settings.currentStatus == AppPurposesTTCWithTreatment) {
        offset = (viewWidth - 304) / 4;
        padding = IS_IPHONE_6_PLUS ? 2 : (IS_IPHONE_6 ? 2 : 0);
        
        // Medication
        addImage(@"calendar-medication", 14);
        addLabel(@"Med taken", 28+padding, 55);
        
        // Appointment
        addImage(@"calendar-appointment", 89+offset*1);
        addLabel(@"Appt.", 102+padding+offset*1, 40);
        
        // Sex
        addImage(@"calendar-sex", 137+offset*2);
        addLabel(@"Sex", 151+padding+offset*2, 30);
        
        // Period
        addDot(kDayFertile, 183+offset*3);
        addLabel(@"Fertile", 195+padding+offset*3, 35);
        
        // Logged
        addImage(@"calendar-check", 238+offset*4);
        addLabel(@"Logged", 252+padding+offset*4, 40);
    }
    else {
        offset = (viewWidth - 304) / 4;
        
        // period
        addDot(kDayPeriod, 14);
        addLabel(@"Period", 27, 35);
        
        // Fertile
        addDot(kDayFertile, 72+offset);
        addLabel(@"Fertile", 85+offset, 35);
        
        // Normal
        addImage(@"calendar-medication", 120+offset*2);
        addLabel(@"Med taken", 133+offset*2, 55);
        
        // Logged
        addImage(@"calendar-check", 191+offset*3);
        addLabel(@"Logged", 207+offset*3, 40);
        
        // sex
        addImage(@"calendar-sex", 257+offset*4);
        addLabel(@"Sex", 272+offset*4, 40);
    }

    
    return legends;
}

+ (UIColor *)legendColor:(DayType)dayType
{
    if (dayType == kDayPeriod) {
        return UIColorFromRGBA(0xE55A8CCD);
    } else if (dayType == kDayFertile) {
        return UIColorFromRGBA(0x6CBA2DD4);
    } else {
        return UIColorFromRGBA(0x5A62D2D0);
    }
}

- (void)hideOtherMonthTiles {
    for (MonthTile *mt in self.monthTiles) {
        mt.hidden = (mt.selectedDate != self.selectedDate);
    }
}

- (void)showAllMonthTiles {
    for (MonthTile *mt in self.monthTiles) {
        mt.hidden = NO;
    }
}

- (void)updateBeginDate:(NSDate *)beginDate
{
    if ([beginDate isEqualToDate:self.minimumDate]) {
        return;
    } else {
        self.minimumDate = beginDate;
    }

    [monthIndexDict removeAllObjects];

    NSInteger months = [Utils monthsWithinEraFromDate:beginDate toDate:[NSDate date]];

    if (months < MIN_PASSED_MONTHS)
        months = MIN_PASSED_MONTHS;
    if (months > maxPassedMonths)
        months = maxPassedMonths;

    [self updateScrollViewAndContentForNewPassedMonths:months];
}

- (void)updateScrollViewAndContentForNewPassedMonths:(NSInteger)months {
    NSInteger newTotalMonths = months + 1 + FUTURE_MONTHS;

    self.scrollView.contentSize = CGSizeMake(FULL_PAGE_WIDTH * newTotalMonths, CALENDAR_HEIGHT);
    CGPoint oldContentOffset = self.scrollView.contentOffset;

    NSInteger monthDelta = newTotalMonths - totalMonths;
    totalMonths = months + 1 + FUTURE_MONTHS;

    for (NSInteger i = 0; i< totalMonths; i++) {
        MonthTile *tile = [self monthTileForPageIndex:i];
        if (tile) {
            [self setTilePosition:tile];
            [tile setSelectedDate:[self monthForPageIndex:i]];
        }
    }

    if (oldContentOffset.x + monthDelta * FULL_PAGE_WIDTH >= 0) {
        [self.scrollView setContentOffset:CGPointMake(oldContentOffset.x + monthDelta * FULL_PAGE_WIDTH, oldContentOffset.y) animated:YES];
    }
    
    [self moveCalendarToDate:[NSDate date] animated:YES];
    [self publish:CALENDAR_EVENT_DATE_CHANGED data:[NSDate date]];
}

- (void)setTilePosition:(MonthTile *)tile
{
    float x = FULL_PAGE_WIDTH * [self indexForMonth:tile.monthShowing];
    tile.frame = setRectX(tile.frame, x);
}


static NSMutableDictionary *monthIndexDict;
- (void)clearFromLogout {
    monthIndexDict = nil;
}

- (NSInteger)indexForMonth:(NSDate *)date
{
    if (!date) {
        return NSNotFound;
    }

    if (!monthIndexDict) {
        monthIndexDict = [NSMutableDictionary dictionary];
    }
    
    NSInteger m = [date timeIntervalSince1970];
    NSNumber *idxNumber = [monthIndexDict objectForKey:@(m)];
    
    // NSLog(@"AAAAAAA jr debug, date = %@, index =%@", date, idxNumber);
    if (idxNumber) {
        return [idxNumber integerValue];
    }
    else {
        NSInteger monthDiff = [Utils monthsWithinEraFromDate:date toDate:[NSDate date]];
        NSInteger x = (totalMonths - ( monthDiff + 1 + FUTURE_MONTHS));
        if (x < 0 || x >= totalMonths) {
            // NSLog(@"CCCCCCC jr debug, not found");
            return NSNotFound;
        } else {
            // NSLog(@"BBBBBBB jr debug, set date = %@, index =%ld", date, x);
            [monthIndexDict setObject:@(x) forKey:@(m)];
            return x;
        }
    }
}

- (MonthTile *)monthTileForPageIndex:(NSInteger)index {
    MonthTile *tile = (MonthTile *)[self.scrollView viewWithTag:MT_TAG_BASE + index];
    return tile;
}

- (NSDate *)monthForPageIndex:(NSInteger)index {
    NSInteger monthDiff = (index + 1 + FUTURE_MONTHS) - totalMonths;
    if (monthDiff == 0) {
        return [self normalize:[NSDate date]];
    }

    NSDate *currentMonth = [Utils monthFirstDate:[NSDate date]];
    NSDate *targetMonth = [Utils dateByAddingMonths:monthDiff toDate:currentMonth];
    return targetMonth;
}

#pragma mark - PagedScrollViewDelegate
- (void)pageWillAppear:(PagedScrollView *)scrollView pageIndex:(NSInteger)index
{
    MonthTile *tile = [self.monthTiles lastObject];
    [self.monthTiles removeLastObject];

    NSDate *m = [self monthForPageIndex:index];
    if (targetDate && [Utils date:targetDate isSameMonthAsDate:m]) {
        tile.selectedDate = targetDate;
        targetDate = nil;
    } else {
        tile.selectedDate = m;
    }
    tile.monthShowing = tile.selectedDate;
    tile.tag = MT_TAG_BASE + index;
    [self setTilePosition:tile];
}

- (void)pageDidDisappear:(PagedScrollView *)scrollView pageIndex:(NSInteger)index
{
    MonthTile *tile = [self monthTileForPageIndex:index];
    if (tile) {
        tile.tag = -1;
        [self.monthTiles addObject:tile];
    }
}

- (void)updateSubviewsForScrollOffset:(PagedScrollView *)scrollView offsetX:(CGFloat)offsetX
{
}

@end
