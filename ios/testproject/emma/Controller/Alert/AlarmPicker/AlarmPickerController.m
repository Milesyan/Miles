//
//  AlarmPickerController.m
//  emma
//
//  Created by Ryan Ye on 3/8/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "AlarmPickerController.h"
#import <GLFoundation/GLPickerViewController.h>

@interface AlarmPickerController () {
    IBOutlet UIDatePicker *alarmPickerView;
    NSInteger hour;
    NSInteger minute;
    DatePickedCallback cb;
    DatePickerCancelCallback cancelCallback;
    IBOutlet UIToolbar *toolbar;
}
@property (nonatomic, retain) NSDate *minDate;
@property (nonatomic, retain) NSDate *maxDate;


- (IBAction)clickDone:(id)sender;
- (IBAction)clickCancel:(id)sender;
@end

@implementation AlarmPickerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _datePickerMode = UIDatePickerModeTime;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    /*
    if (!IOS7_OR_ABOVE) {
        toolbar.barStyle = UIBarStyleBlackTranslucent;
    }
    */
}

- (void)viewWillAppear:(BOOL)animated {
    alarmPickerView.datePickerMode = _datePickerMode;
    alarmPickerView.minimumDate = _minDate;
    alarmPickerView.maximumDate = _maxDate;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickDone:(id)sender {
    GLLog(@"done!");
    if (cb) {
        cb(alarmPickerView.date);
    }
    [self dismiss];
}

- (IBAction)clickCancel:(id)sender {
    if (cancelCallback) {
        cancelCallback();
    }
    [self dismiss];
}

- (void)present:(UIView *)parentView withPickDateCallback:(DatePickedCallback)callback withCancelCallback:(DatePickerCancelCallback)cancelCb {
    cb = callback;
    cancelCallback = cancelCb;
    [[GLPickerViewController sharedInstance] presentWithContentController:self];
    [self selectDefaultTime];
}

- (void)dismiss {
    [[GLPickerViewController sharedInstance] dismiss];
}

- (NSInteger)selectedHour {
    return [alarmPickerView.date getHour];
}

- (NSInteger)selectedMinute {
    return [alarmPickerView.date getMinute];
}

- (void)selectDefaultTime {
    [alarmPickerView setDate:_selectedDate? _selectedDate: [Utils dateOfHour:hour minute:minute second:0]];
    _selectedDate = nil;
}

- (void)setDatePickerMode:(UIDatePickerMode)mode {
    _datePickerMode = mode;
}

- (void)setSelectedDate:(NSDate *)date {
    _selectedDate = date;
}

- (void)setMinDate:(NSDate *)date
{
    _minDate = date;
}

- (void)setMaxDate:(NSDate *)date
{
    _maxDate = date;
}

@end
