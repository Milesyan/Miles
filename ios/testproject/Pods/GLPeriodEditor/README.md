
## GLPeriodEditor

#### Usage
Set up the calendar appearance by calling the method in AppDelegate
```objective-c
[GLPeriodEditorAppearance setupAppearance];
```

Create your `GLPeriodEditorViewController` subclass, then implement some template methods, for example:
```objective-c
- (NSMutableArray *)initialData
{
    // convert your model to GLCycleData instance
    NSMutableArray *data = [NSMutableArray array];
    NSInteger futureCycleCount = 0;
    for (NSDictionary *p in self.user.prediction) {
        NSDate *pb = [Utils dateWithDateLabel:[p objectForKey:@"pb"]];
        NSDate *pe = [Utils dateWithDateLabel:[p objectForKey:@"pe"]];
        NSDate *fb = [Utils dateWithDateLabel:[p objectForKey:@"fb"]];
        NSDate *fe = [Utils dateWithDateLabel:[p objectForKey:@"fe"]];
        GLCycleData *cycleData = [GLCycleData dataWithPeriodBeginDate:pb periodEndDate:pe];
        if (fb && fe) {
            cycleData.fertileWindowBeginDate = fb;
            cycleData.fertileWindowEndDate = fe;
        }
        [data addObject:cycleData];
        if (cycleData.isFuture) {
            futureCycleCount ++;
        }
        if (futureCycleCount >= 3) {
            break;
        }
    }
    return data;
}

- (void)didAddCycleData:(GLCycleData *)cycleData
{
    [super didAddCycleData:cycleData];
    [self updatePeriod:cycleData.periodBeginDate value:LOG_VAL_PERIOD_BEGAN];
    [self updatePeriod:[Utils dateByAddingDays:1 toDate:cycleData.periodEndDate] value:LOG_VAL_PERIOD_ENDED];
    [self dataUpdated];
}

- (void)didUpdateCycleData:(GLCycleData *)cycleData withPeriodBeginDate:(NSDate *)periodBeginDate periodEndDate:(NSDate *)periodEndDate
{
    // unset previous value
    [self updatePeriod:cycleData.periodBeginDate value:@(0)];
    [self updatePeriod:[Utils dateByAddingDays:1 toDate:cycleData.periodEndDate] value:@(0)];
    
    // set current value
    [self updatePeriod:periodBeginDate value:LOG_VAL_PERIOD_BEGAN];
    [self updatePeriod:[Utils dateByAddingDays:1 toDate:periodEndDate] value:LOG_VAL_PERIOD_ENDED];

    [self dataUpdated];

    [super didUpdateCycleData:cycleData withPeriodBeginDate:periodBeginDate periodEndDate:periodEndDate];
    
}

- (void)didRemoveCycleData:(GLCycleData *)cycleData
{
    [super didRemoveCycleData:cycleData];
    [self updatePeriod:cycleData.periodBeginDate value:@(0)];
    [self updatePeriod:[Utils dateByAddingDays:1 toDate:cycleData.periodEndDate] value:@(0)];
    [self dataUpdated];
}

```

Then construct this controller by:
```objective-c
UIViewController *vc = [GLPeriodEditorViewController instanceOfSubClass:@"YourSubClassVCName"]
```


## GLCalendarView
#### Usage
The `GLCalendarView` interface:
```objective-c
@interface GLCalendarView : UIView
@property (nonatomic, copy) NSDate *firstDate; // the first date of the calendar view
@property (nonatomic, copy) NSDate *lastDate; // the last date of the calendar view
@property (nonatomic, strong) NSMutableArray *ranges; // model
@property (nonatomic) BOOL showMaginfier; // show maginifier during dragging or not
@property (nonatomic, weak) id<GLCalendarViewDelegate> delegate;
- (void)reload;
- (void)addRange:(GLCalendarDateRange *)range;
- (void)removeRange:(GLCalendarDateRange *)range;
- (void)updateRange:(GLCalendarDateRange *)range withBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate;
- (void)forceFinishEdit;
- (void)scrollToDate:(NSDate *)date animated:(BOOL)animated;
@end

```

To display ranges in the calendar view, first consruct some `GLCalendarDateRange` objects, set them as the model of the calendar view
```objective-c
NSDate *today = [NSDate date];
NSDate *beginDate = [GLDateUtils dateByAddingDays:-23 toDate:today];
NSDate *endDate = [GLDateUtils dateByAddingDays:-18 toDate:today];
GLCalendarDateRange *range = [GLCalendarDateRange rangeWithBeginDate:beginDate endDate:endDate];
range.backgroundColor = COLOR_BLUE;
range.editable = YES;
range.binding = yourModelObject // you can bind your model to the range

self.calendarView.ranges = [@[range1] mutableCopy];
[self.calendarView reload];
```

Implement the delegate protocal to receive various events:
```objective-c
@protocol GLCalendarViewDelegate <NSObject>
- (BOOL)calenderView:(GLCalendarView *)calendarView canAddRangeWithBeginDate:(NSDate *)beginDate;
- (GLCalendarDateRange *)calenderView:(GLCalendarView *)calendarView rangeToAddWithBeginDate:(NSDate *)beginDate;
- (void)calenderView:(GLCalendarView *)calendarView beginToEditRange:(GLCalendarDateRange *)range;
- (void)calenderView:(GLCalendarView *)calendarView finishEditRange:(GLCalendarDateRange *)range continueEditing:(BOOL)continueEditing;
- (BOOL)calenderView:(GLCalendarView *)calendarView canUpdateRange:(GLCalendarDateRange *)range toBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate;
@end
```

Sample implementation:
```objective-c
- (BOOL)calenderView:(GLCalendarView *)calendarView canAddRangeWithBeginDate:(NSDate *)beginDate
{
    // you should check whether user can add a range with this begin date
    // if return YES, the next method will get called
    return YES;
}

- (GLCalendarDateRange *)calenderView:(GLCalendarView *)calendarView rangeToAddWithBeginDate:(NSDate *)beginDate
{
    // construct a new range object and return it
    NSDate* endDate = [GLDateUtils dateByAddingDays:2 toDate:beginDate];
    GLCalendarDateRange *range = [GLCalendarDateRange rangeWithBeginDate:beginDate endDate:endDate];
    range.backgroundColor = [UIColor redColor];
    range.editable = YES;
    range.binding = yourModel // bind your model to the range instance
    return range;
}

- (void)calenderView:(GLCalendarView *)calendarView beginToEditRange:(GLCalendarDateRange *)range
{
    // save the range to a instance variable so that you make some operation on it
    self.rangeUnderEdit = range;
}

- (void)calenderView:(GLCalendarView *)calendarView finishEditRange:(GLCalendarDateRange *)range continueEditing:(BOOL)continueEditing
{
    // retrieve the model from the range, do some updates to your model
    id yourModel = range.binding;
    self.rangeUnderEdit = nil;
}

- (BOOL)calenderView:(GLCalendarView *)calendarView canUpdateRange:(GLCalendarDateRange *)range toBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate
{
    // you should check whether the beginDate or the endDate is valid
    return YES;
}

```

#### Appearance
`GLCalendarView` 's appearance is fully customizable, you can adjust its look through the appearance api, check the header file to see all customizable fields
```objective-c
[GLCalendarView appearance].rowHeight = 54;
[GLCalendarView appearance].padding = 6;
[GLCalendarView appearance].weekDayTitleAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:8], NSForegroundColorAttributeName:[UIColor grayColor]};
[GLCalendarView appearance].monthCoverAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:30]};
    
[GLCalendarDayCell appearance].editCoverBorderWidth = 2;
[GLCalendarDayCell appearance].editCoverBorderColor = COLOR_DARK_BLUE;
[GLCalendarDayCell appearance].editCoverPointSize = 14;
[GLCalendarDayCell appearance].rangeDisplayMode = RANGE_DISPLAY_MODE_CONTINUOUS;
[GLCalendarDayCell appearance].todayBackgroundColor = COLOR_DARK_BLUE;
```



