//
//  GeneralPicker.m
//  emma
//
//  Created by Eric Xu on 12/6/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GLGeneralPicker.h"
#import "GLPickerViewController.h"
#import "GLUtils.h"
#import "UIView+Helpers.h"

@interface GLSimplePickerDelegate : NSObject<GLGeneralPickerDelegate, GLGeneralPickerDataSource> {
    Callback doneCb;
    Callback cancelCb;
    NSArray *rows;
}
@property (nonatomic) GLGeneralPicker *picker;

@end

@implementation GLSimplePickerDelegate
- (GLSimplePickerDelegate *)initWithTitle:(NSString *)title
                                   rows:(NSArray *)r
                             showCancel:(BOOL)showCancel
                         doneCompletion:(Callback)doneCompletion
                       cancelCompletion:(Callback)cancelCompletion  {
    self = [super init];
    if (self) {
        self.picker = [GLGeneralPicker picker];
        self.picker.delegate = self;
        self.picker.datasource = self;
//        self.picker.showCustomButton = NO;
        [self.picker updateTitle:title];
        if (!showCancel || !cancelCompletion) {
            self.picker.showStartOverButton = NO;
        }
        doneCb = doneCompletion;
        cancelCb = cancelCompletion;
        rows = r;
    }
    return self;
}

- (void)doneButtonPressed {
    if (doneCb) {
        doneCb([self.picker selectedRowInComponent:0], 0);
    }
    [self.picker dismiss];
}

- (void)cancelButtonPressed {
    if (cancelCb) {
        cancelCb(0, 0);
    }
    [self.picker dismiss];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [rows count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return rows[row];
}
@end

@interface GLCancelableSimplePickerDelegate : NSObject<GLGeneralPickerDelegate, GLGeneralPickerDataSource> {
    Callback doneCb;
    Callback cancelCb;
    NSArray *rows;
}
@property (nonatomic) GLGeneralPicker *picker;
@end

@implementation GLCancelableSimplePickerDelegate
- (GLCancelableSimplePickerDelegate *)initWithTitle:(NSString *)title
                                   rows:(NSArray *)r
                         doneCompletion:(Callback)doneCompletion
                       cancelCompletion:(Callback)cancelCompletion  {
    self = [super init];
    if (self) {
        self.picker = [GLGeneralPicker picker];
        self.picker.delegate = self;
        self.picker.datasource = self;
//        self.picker.showCustomButton = NO;
        [self.picker updateTitle:title];
        self.picker.showStartOverButton = YES;
        doneCb = doneCompletion;
        cancelCb = cancelCompletion;
        rows = r;
    }
    return self;
}

- (void)startOverPressed
{
    if (cancelCb) {
        cancelCb(0, 0);
    }
    [self.picker dismiss];
}

- (void)doneButtonPressed {
    if (doneCb) {
        doneCb([self.picker selectedRowInComponent:0], 0);
    }
    [self.picker dismiss];
}

- (void)cancelButtonPressed {
    if (cancelCb) {
        cancelCb(0, 0);
    }
    [self.picker dismiss];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [rows count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return rows[row];
}
@end

@interface GLGeneralPicker () <UIPickerViewDataSource, UIPickerViewDelegate>
{
    int rowToSelect;
    int componentToSelect;
    NSString *titleLabelText;
}


@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *spacer;

- (IBAction)startOverButtonPressed:(id)sender;
- (IBAction)doneButtonPressed:(id)sender;

@end

@implementation GLGeneralPicker


#pragma mark - GeneralPicker interfaces
+ (GLGeneralPicker *)picker {
    GLGeneralPicker *picker = [[GLGeneralPicker alloc] initWithNibName:@"GLGeneralPicker" bundle:nil];
//    picker.showCustomButton = NO;
    picker.showStartOverButton = NO;

    return picker;
}

+ (void)presentSimplePickerWithTitle:(NSString *)title
                                rows:(NSArray *)rows
                         selectedRow:(int)selectedRow
                          showCancel:(BOOL)showCancel
                      doneCompletion:(Callback)doneCompletion
                    cancelCompletion:(Callback)cancelCompletion {
    GLSimplePickerDelegate *pickerDelegate = [[GLSimplePickerDelegate alloc] initWithTitle:title
                                            rows:rows
                                            showCancel:showCancel
                                            doneCompletion:doneCompletion
                                            cancelCompletion:cancelCompletion];
    [pickerDelegate.picker present];
    [pickerDelegate.picker selectRow:selectedRow inComponent:0];
}

+ (void)presentSimplePickerWithTitle:(NSString *)title
                                rows:(NSArray *)rows
                         selectedRow:(int)selectedRow
                          showCancel:(BOOL)showCancel
                       withAnimation:(BOOL)animation
                      doneCompletion:(Callback)doneCompletion
                    cancelCompletion:(Callback)cancelCompletion {
    GLSimplePickerDelegate *pickerDelegate = [[GLSimplePickerDelegate alloc] initWithTitle:title
                                                                                  rows:rows
                                                                            showCancel:showCancel
                                                                        doneCompletion:doneCompletion
                                                                      cancelCompletion:cancelCompletion];
    [pickerDelegate.picker present];
    [pickerDelegate.picker selectRow:selectedRow inComponent:0 animation:animation];
}

+ (void)presentCancelableSimplePickerWithTitle:(NSString *)title rows:(NSArray *)rows
    selectedRow:(int)selectedRow doneTitle:(NSString *)doneTitle
    showCancel:(BOOL)showCancel withAnimation:(BOOL)animation
    doneCompletion:(Callback)doneCompletion
    cancelCompletion:(Callback)cancelCompletion
{
    GLCancelableSimplePickerDelegate *pickerDelegate = [[GLCancelableSimplePickerDelegate alloc]
        initWithTitle:title rows:rows
        doneCompletion:doneCompletion cancelCompletion:cancelCompletion];
    [pickerDelegate.picker present];
    pickerDelegate.picker.startOverButton.title = @"Cancel";
//    [pickerDelegate.picker setShowStartOverButton:YES];
    [pickerDelegate.picker setDoneButtonTitle:doneTitle];
    [pickerDelegate.picker selectRow:selectedRow inComponent:0 animation:animation];
}

+ (void)presentStartoverSimplePickerWithTitle:(NSString *)title
                                         rows:(NSArray *)rows
                                  selectedRow:(int)selectedRow
                               doneCompletion:(Callback)doneCompletion
                          startoverCompletion:(Callback)startoverCompletion
{
    GLCancelableSimplePickerDelegate *pickerDelegate = [[GLCancelableSimplePickerDelegate alloc]
                                                        initWithTitle:title rows:rows
                                                        doneCompletion:doneCompletion cancelCompletion:startoverCompletion];
    [pickerDelegate.picker present];
    pickerDelegate.picker.startOverButton.title = @"Clear";
    [pickerDelegate.picker setDoneButtonTitle:@"Done"];
    [pickerDelegate.picker selectRow:selectedRow inComponent:0 animation:YES];
}

- (void)present {
    [[GLPickerViewController sharedInstance] presentWithContentController:self];
}

- (void)selectRow:(int)row inComponent:(int)component {
    if (![self.view superview]) {
        rowToSelect = row;
        componentToSelect = component;
    } else
        if (component >= 0 && component < self.picker.numberOfComponents) {
            if (row >= 0 && row < [self.picker numberOfRowsInComponent:component]) {
                [self.picker selectRow:row inComponent:component animated:YES];
            }
        }
}

- (void)selectRow:(int)row inComponent:(int)component animation:(BOOL)animation {
    if (![self.view superview]) {
        rowToSelect = row;
        componentToSelect = component;
    } else
        if (component >= 0 && component < self.picker.numberOfComponents) {
            if (row >= 0 && row < [self.picker numberOfRowsInComponent:component]) {
                [self.picker selectRow:row inComponent:component animated:animation];
            }
        }
}

- (int)selectedRowInComponent:(int)component {
    return (int)[self.picker selectedRowInComponent:component];
}

- (void)dismiss {
    self.delegate = nil;
    self.datasource = nil;
    [[GLPickerViewController sharedInstance] dismiss];
}

#pragma mark - View/Controller lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    rowToSelect = -1;
    componentToSelect = -1;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.picker reloadAllComponents];

    if (rowToSelect > -1 && componentToSelect > -1) {
        [self selectRow:rowToSelect inComponent:componentToSelect];
        rowToSelect = -1;
        componentToSelect = -1;
    }

    [self updateButtons];

    if (titleLabelText) {
        self.titleLabel.text = titleLabelText;
    } else {
        self.titleLabel.text = @"";
    }
}

- (void)updateButtons {
    NSMutableArray *buttons = [NSMutableArray array];
    if (self.customButtons && [self.customButtons count]) {
        for (UIView *v in self.customButtons) {
//            CGRect frame = v.frame;
            [buttons addObject:[[UIBarButtonItem alloc] initWithCustomView:v]];
        }
    }

    [buttons addObject:self.spacer];
    
    if ([self showStartOverButton]) {
        [buttons addObject:self.startOverButton];
    }
    
    [buttons addObject:self.doneButton];

    [self.toolbar setItems:nil];
    [self.toolbar setItems:buttons animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setter
- (void)setShowStartOverButton:(BOOL)showStartOverButton {
    _showStartOverButton = showStartOverButton;
//    [self updateButtons];
}

- (void)setCustomButtons:(NSArray *)customButtons
{
    self.titleLabel.hidden = [customButtons count] > 0;
    _customButtons = [NSArray arrayWithArray:customButtons];
//    [self updateButtons];
}

- (void)updateTitle:(NSString *)title {
    titleLabelText = title;
    [self.titleLabel setText:title];
}

- (void)setStartOverButtonTitle:(NSString *)title
{
    [self.startOverButton setTitle:title];
}

- (void)setDoneButtonTitle:(NSString *)title
{
    [self.doneButton setTitle:title];
}

- (void)setCustomButtonTitle:(NSString *)title
{
    [self.customButton setTitle:title];
}

- (void)reload
{
    [self.picker reloadAllComponents];
}


#pragma mark - IBActions
- (IBAction)startOverButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(startOverPressed)]) {
        [self.delegate startOverPressed];
    }
}

- (IBAction)doneButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(doneButtonPressed)]) {
        [self.delegate doneButtonPressed];
    }
}

#pragma mark - UIPickerView DataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if (self.datasource && [self.datasource respondsToSelector:@selector(numberOfComponentsInPickerView:)]) {
        return [self.datasource numberOfComponentsInPickerView:pickerView];
    } else
        return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (self.datasource && [self.datasource respondsToSelector:@selector(pickerView:numberOfRowsInComponent:)]) {
        return [self.datasource pickerView:pickerView numberOfRowsInComponent:component];
    } else
        return 0;
}


#pragma mark - UIPickerView Delegate, add more if you need
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(pickerView:widthForComponent:)]) {
        return [self.delegate pickerView:pickerView widthForComponent:component];
    }
    
    return 320;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if ([self.delegate respondsToSelector:@selector(pickerView:titleForRow:forComponent:)]) {
        return [self.delegate pickerView:pickerView titleForRow:row forComponent:component];
    } else
        return @"Setup Datasource!!!";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([self.delegate respondsToSelector:@selector(pickerView:didSelectRow:inComponent:)]) {
        [self.delegate pickerView:pickerView didSelectRow:row inComponent:component];
    }
}


@end
